import { supabase } from '../supabase-client.js';

export async function loadAdminOverview() {
  const [{ count: users }, { count: groups }, { count: posts }, { count: resources }] = await Promise.all([
    supabase.from('profiles').select('id', { count: 'exact', head: true }),
    supabase.from('groups').select('id', { count: 'exact', head: true }),
    supabase.from('posts').select('id', { count: 'exact', head: true }),
    supabase.from('resources').select('id', { count: 'exact', head: true }),
  ]);

  return {
    users: users || 0,
    groups: groups || 0,
    posts: posts || 0,
    resources: resources || 0,
  };
}
