import { supabase } from '../supabase-client.js';

export async function loadResources() {
  const { data, error } = await supabase.from('resources').select('*').order('created_at', { ascending: false });
  if (error) throw error;
  return data || [];
}

export async function createResource({ title, description, category_id }) {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData.session) throw new Error('Unauthorized');

  const { data, error } = await supabase
    .from('resources')
    .insert([
      {
        uploader_id: sessionData.session.user.id,
        title,
        description,
        category_id,
      },
    ])
    .select();

  if (error) throw error;
  return data?.[0];
}
