import { supabase } from '../supabase-client.js';

const form = document.getElementById('onboarding-form');
const message = document.getElementById('onboarding-message');
const avatarInput = document.getElementById('avatar-input');

function setMessage(text, isError = false) {
  message.textContent = text;
  message.style.color = isError ? '#d6465f' : '#1a8f5a';
}

async function uploadAvatar(file) {
  // Simple client-side fallback to upload to a public bucket using anon key.
  // For production we recommend using the Edge Function presigned URL flow.
  const filePath = `student-profiles/${Date.now()}_${file.name}`;
  const { data, error } = await supabase.storage.from('student-profiles').upload(filePath, file, { upsert: false });
  if (error) throw error;
  // Make private object: we keep it private by default and use signed URLs to access.
  return filePath;
}

form?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const formData = new FormData(form);
  const display_name = String(formData.get('display_name') || '').trim();
  const institution = String(formData.get('institution') || '').trim();
  const programme = String(formData.get('programme') || '').trim();
  const interests = String(formData.get('interests') || '').trim();

  if (!display_name) {
    setMessage('Display name is required.', true);
    return;
  }

  try {
    setMessage('Saving profile...');

    let avatarPath = null;
    const file = avatarInput?.files?.[0];
    if (file) {
      avatarPath = await uploadAvatar(file);
    }

    const { data: sessionData } = await supabase.auth.getSession();
    if (!sessionData.session) {
      setMessage('Not authenticated. Please sign in again.', true);
      setTimeout(() => (window.location.href = '/login.html'), 800);
      return;
    }

    const profileUpdate = {
      display_name,
      avatar_path: avatarPath,
      bio: '',
      institution_id: null,
      programme_id: null,
      updated_at: new Date().toISOString(),
    };

    // Update the existing profile row via RLS — auth_uid mapping ensures we update the right row
    const { error } = await supabase
      .from('profiles')
      .update(profileUpdate)
      .eq('auth_uid', sessionData.session.user.id);

    if (error) throw error;

    setMessage('Profile saved successfully. Redirecting...');
    setTimeout(() => (window.location.href = '/app/feed.html'), 800);
  } catch (err) {
    console.error(err);
    setMessage(err.message || 'Failed to save profile.', true);
  }
});
