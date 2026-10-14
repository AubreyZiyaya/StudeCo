import { supabase } from '../supabase-client.js';

export async function updateProfile(profileData) {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData.session) throw new Error('Not authenticated');

  const result = await supabase
    .from('profiles')
    .update(profileData)
    .eq('auth_uid', sessionData.session.user.id)
    .select();

  if (result.error) throw result.error;
  return result.data?.[0];
}
