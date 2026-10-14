import { supabase } from "../supabase-client.js";

export async function requestUploadUrl({ fileName, fileType, category, contentLength }) {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData.session) throw new Error('Not authenticated');

  const response = await fetch(`${window.STUDECO_CONFIG?.API_BASE_URL || '/functions/v1'}/upload-url`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${sessionData.session.access_token}`,
    },
    body: JSON.stringify({ fileName, fileType, category, contentLength }),
  });

  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || 'Unable to request upload URL.');
  }

  return response.json();
}

export async function confirmUpload({ uploadJobId, bucket, objectKey, mimeType, sizeBytes, category }) {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData.session) throw new Error('Not authenticated');

  const response = await fetch(`${window.STUDECO_CONFIG?.API_BASE_URL || '/functions/v1'}/confirm-upload`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${sessionData.session.access_token}`,
    },
    body: JSON.stringify({ uploadJobId, bucket, objectKey, mimeType, sizeBytes, category }),
  });

  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || 'Unable to confirm upload.');
  }

  return response.json();
}
