import { supabase } from '../supabase-client.js';

export async function loadGroups() {
  const { data, error } = await supabase.from('groups').select('*').order('created_at', { ascending: false });
  if (error) throw error;
  return data || [];
}

export async function createGroup({ name, description, visibility = 'public' }) {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData.session) throw new Error('Unauthorized');

  const { data, error } = await supabase
    .from('groups')
    .insert([
      {
        name,
        description,
        visibility,
        owner_id: sessionData.session.user.id,
      },
    ])
    .select();

  if (error) throw error;
  return data?.[0];
}
