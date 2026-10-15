/**
 * StudeCo Upload Service
 * 
 * CRITICAL: All limits and availability are driven by the database
 * (upload_settings table). Client-side checks are for UX only.
 * Security is enforced by RLS + Storage policies + optional Edge Functions.
 */

import { getSupabase } from '../supabase-client.js';

let cachedAvailability = null;
let cacheVersion = null;
let cacheTimestamp = 0;
const CACHE_TTL_MS = 30_000; // 30 seconds

/**
 * Fetch current upload availability from the database.
 * Uses the get_upload_availability() RPC for a single consistent snapshot.
 */
export async function getUploadAvailability(forceRefresh = false) {
  const now = Date.now();
  if (
    !forceRefresh &&
    cachedAvailability &&
    cacheVersion === cachedAvailability.config_version &&
    (now - cacheTimestamp) < CACHE_TTL_MS
  ) {
    return cachedAvailability;
  }

  const supabase = getSupabase();
  const { data, error } = await supabase.rpc('get_upload_availability');

  if (error) {
    console.error('Failed to fetch upload availability:', error);
    // Fail closed for safety
    return {
      state: 'PROVIDER_ERROR',
      uploads_enabled: false,
      unavailable_title: 'Uploads Temporarily Unavailable',
      unavailable_message: 'We could not determine upload status. Please try again later.',
      short_notice: 'Upload status unavailable.',
      alternative_enabled: false,
      config_version: 0
    };
  }

  cachedAvailability = data;
  cacheVersion = data.config_version;
  cacheTimestamp = now;
  return data;
}

/**
 * Clear the local cache (call after admin restores uploads).
 */
export function clearUploadCache() {
  cachedAvailability = null;
  cacheVersion = null;
  cacheTimestamp = 0;
}

/**
 * Check whether a specific file is allowed under current settings.
 * Returns { allowed: boolean, reason?: string }
 */
export function validateFile(file, availability) {
  if (!availability.uploads_enabled || availability.state !== 'AVAILABLE') {
    return { allowed: false, reason: 'uploads_disabled' };
  }

  const mime = file.type || 'application/octet-stream';
  const ext = '.' + (file.name.split('.').pop() || '').toLowerCase();

  // Category checks
  if (mime.startsWith('image/') && !availability.images_enabled) {
    return { allowed: false, reason: 'images_disabled' };
  }
  if (mime === 'application/pdf' && !availability.pdfs_enabled) {
    return { allowed: false, reason: 'pdfs_disabled' };
  }
  if (mime.startsWith('video/') && !availability.videos_enabled) {
    return { allowed: false, reason: 'videos_disabled' };
  }
  if (
    !mime.startsWith('image/') &&
    !mime.startsWith('video/') &&
    mime !== 'application/pdf' &&
    !availability.documents_enabled
  ) {
    return { allowed: false, reason: 'documents_disabled' };
  }

  // MIME / extension
  const allowedMimes = availability.allowed_mime_types || [];
  const allowedExts = availability.allowed_extensions || [];
  if (allowedMimes.length && !allowedMimes.includes(mime)) {
    return { allowed: false, reason: 'mime_not_allowed' };
  }
  if (allowedExts.length && !allowedExts.includes(ext)) {
    return { allowed: false, reason: 'extension_not_allowed' };
  }

  // Size
  if (file.size > (availability.max_file_size_bytes || 10 * 1024 * 1024)) {
    return { allowed: false, reason: 'file_too_large' };
  }

  return { allowed: true };
}

/**
 * Human-readable error messages for validation failures.
 */
export function getValidationMessage(reason, availability) {
  const messages = {
    uploads_disabled: availability?.short_notice || 'File uploads are currently unavailable.',
    images_disabled: 'Image uploads are currently disabled by the administrator.',
    pdfs_disabled: 'PDF uploads are currently disabled by the administrator.',
    videos_disabled: 'Video uploads are currently disabled by the administrator.',
    documents_disabled: 'Document uploads are currently disabled by the administrator.',
    mime_not_allowed: 'This file type is not allowed.',
    extension_not_allowed: 'This file extension is not allowed.',
    file_too_large: `File exceeds the maximum size of ${formatBytes(availability?.max_file_size_bytes || 10485760)}.`
  };
  return messages[reason] || 'This file cannot be uploaded.';
}

/**
 * Upload a file to Supabase Storage and record metadata.
 * Returns { success, fileId?, path?, error? }
 */
export async function uploadFile(file, { category = 'other', isPublic = false, onProgress } = {}) {
  const availability = await getUploadAvailability(true);

  const validation = validateFile(file, availability);
  if (!validation.allowed) {
    return {
      success: false,
      error: getValidationMessage(validation.reason, availability),
      code: validation.reason
    };
  }

  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return { success: false, error: 'You must be signed in to upload files.', code: 'auth_required' };
  }

  // Create upload job record
  const { data: job, error: jobError } = await supabase
    .from('upload_jobs')
    .insert({
      user_id: user.id,
      original_filename: file.name,
      mime_type: file.type,
      size_bytes: file.size,
      status: 'uploading'
    })
    .select()
    .single();

  if (jobError) {
    console.error('Job creation failed:', jobError);
  }

  const fileId = crypto.randomUUID();
  const ext = file.name.split('.').pop() || 'bin';
  const storagePath = `${user.id}/${category}/${fileId}.${ext}`;

  try {
    // Upload to Supabase Storage
    const { data: storageData, error: storageError } = await supabase.storage
      .from('uploads')
      .upload(storagePath, file, {
        cacheControl: '3600',
        upsert: false,
        contentType: file.type
      });

    if (storageError) {
      // Detect quota / limit errors from provider
      const msg = storageError.message?.toLowerCase() || '';
      let code = 'upload_failed';
      if (msg.includes('quota') || msg.includes('storage limit') || msg.includes('payload too large')) {
        code = 'quota_exceeded';
        // Optionally notify via storage_events
        await supabase.from('storage_events').insert({
          event_type: 'quota_exceeded',
          user_id: user.id,
          metadata: { error: storageError.message, filename: file.name }
        });
      }

      if (job) {
        await supabase.from('upload_jobs').update({
          status: 'failed',
          error_code: code,
          error_message: storageError.message,
          completed_at: new Date().toISOString()
        }).eq('id', job.id);
      }

      return {
        success: false,
        error: code === 'quota_exceeded'
          ? (availability.unavailable_message || 'Storage quota has been reached.')
          : storageError.message,
        code
      };
    }

    // Record file metadata
    const { data: fileRecord, error: metaError } = await supabase
      .from('uploaded_files')
      .insert({
        id: fileId,
        uploader_id: user.id,
        storage_path: storagePath,
        original_filename: file.name,
        mime_type: file.type,
        size_bytes: file.size,
        bucket: 'uploads',
        category,
        is_public: isPublic,
        status: 'active'
      })
      .select()
      .single();

    if (metaError) {
      // Attempt to clean up storage object
      await supabase.storage.from('uploads').remove([storagePath]);
      return { success: false, error: 'Failed to record file metadata.', code: 'metadata_failed' };
    }

    // Update user storage_used_bytes
    await supabase.rpc('increment_user_storage', {
      user_uuid: user.id,
      bytes_delta: file.size
    }).catch(() => {
      // Fallback if RPC not present
      supabase.from('profiles').update({
        storage_used_bytes: (await getUserStorageUsed(user.id)) + file.size
      }).eq('id', user.id);
    });

    // Log success
    await supabase.from('storage_events').insert({
      event_type: 'upload_success',
      user_id: user.id,
      file_id: fileId,
      bytes_delta: file.size
    });

    if (job) {
      await supabase.from('upload_jobs').update({
        status: 'completed',
        file_id: fileId,
        progress_percent: 100,
        completed_at: new Date().toISOString()
      }).eq('id', job.id);
    }

    // Get public or signed URL
    let url;
    if (isPublic) {
      const { data: urlData } = supabase.storage.from('uploads').getPublicUrl(storagePath);
      url = urlData.publicUrl;
    } else {
      const { data: signed } = await supabase.storage
        .from('uploads')
        .createSignedUrl(storagePath, 3600);
      url = signed?.signedUrl;
    }

    return {
      success: true,
      fileId,
      path: storagePath,
      url,
      size: file.size,
      mimeType: file.type
    };
  } catch (err) {
    console.error('Upload exception:', err);
    if (job) {
      await supabase.from('upload_jobs').update({
        status: 'failed',
        error_message: err.message,
        completed_at: new Date().toISOString()
      }).eq('id', job.id);
    }
    return { success: false, error: err.message || 'Upload failed unexpectedly.', code: 'exception' };
  }
}

async function getUserStorageUsed(userId) {
  const supabase = getSupabase();
  const { data } = await supabase
    .from('uploaded_files')
    .select('size_bytes')
    .eq('uploader_id', userId)
    .eq('status', 'active');
  return (data || []).reduce((sum, f) => sum + (f.size_bytes || 0), 0);
}

export function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

/**
 * Render the admin-configured unavailable notice.
 * Call this when uploads are not available.
 */
export function renderUnavailableNotice(availability, container) {
  if (!container) return;

  const showAlt = availability.alternative_enabled &&
    availability.alternative_url &&
    availability.alternative_url.startsWith('https://');

  container.innerHTML = `
    <div class="alert alert-warning upload-unavailable-notice">
      <h4 style="margin-bottom:0.5rem;">${escapeHtml(availability.unavailable_title || 'Uploads Temporarily Unavailable')}</h4>
      <p>${escapeHtml(availability.unavailable_message || '')}</p>
      ${availability.show_remaining_capacity && availability.remaining_bytes != null
        ? `<p class="text-sm">Remaining capacity: ${formatBytes(availability.remaining_bytes)}</p>`
        : ''}
      ${availability.estimated_restoration_time
        ? `<p class="text-sm">Estimated restoration: ${escapeHtml(availability.estimated_restoration_time)}</p>`
        : ''}
      <div style="margin-top:1rem;display:flex;gap:0.75rem;flex-wrap:wrap;">
        ${availability.support_email
          ? `<a href="mailto:${escapeHtml(availability.support_email)}" class="btn btn-secondary btn-sm">Contact Support</a>`
          : ''}
        ${availability.support_url
          ? `<a href="${escapeHtml(availability.support_url)}" target="_blank" rel="noopener" class="btn btn-secondary btn-sm">Support Page</a>`
          : ''}
        ${showAlt
          ? `<a href="${escapeHtml(availability.alternative_url)}" target="_blank" rel="noopener noreferrer" class="btn btn-accent btn-sm"
               onclick="return confirm('You are leaving StudeCo to an administrator-approved external service. Continue?')">
               ${escapeHtml(availability.alternative_label || 'Use alternative upload')}
             </a>`
          : ''}
        <button type="button" class="btn btn-ghost btn-sm" id="retryUploadAvailability">Try Again</button>
      </div>
    </div>
  `;

  container.querySelector('#retryUploadAvailability')?.addEventListener('click', async () => {
    clearUploadCache();
    const fresh = await getUploadAvailability(true);
    if (fresh.uploads_enabled && fresh.state === 'AVAILABLE') {
      container.innerHTML = `
        <div class="alert alert-success">
          ${escapeHtml(fresh.restoration_announcement || 'File uploads have been restored.')}
        </div>
      `;
      // Optionally reload the upload UI
      window.dispatchEvent(new CustomEvent('studeco:uploads-restored'));
    } else {
      renderUnavailableNotice(fresh, container);
    }
  });
}

function escapeHtml(str) {
  if (!str) return '';
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

export default {
  getUploadAvailability,
  clearUploadCache,
  validateFile,
  getValidationMessage,
  uploadFile,
  formatBytes,
  renderUnavailableNotice
};
