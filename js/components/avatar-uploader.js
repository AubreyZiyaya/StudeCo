// Simple avatar uploader helper component
import { supabase } from '../supabase-client.js';

export async function uploadAvatarFile(file) {
  if (!file) throw new Error('No file provided');
  const ext = file.name.split('.').pop();
  const key = `student-profiles/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;
  const { data, error } = await supabase.storage.from('student-profiles').upload(key, file);
  if (error) throw error;
  return key;
}
