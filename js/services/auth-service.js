/**
 * Authentication & Profile helpers
 */

import { getSupabase, getCurrentUser } from '../supabase-client.js';

export async function getProfile(userId = null) {
  const supabase = getSupabase();
  const uid = userId || (await getCurrentUser())?.id;
  if (!uid) return null;

  const { data, error } = await supabase
    .from('profiles')
    .select('*, institutions(name, type, is_verified)')
    .eq('id', uid)
    .single();

  if (error) {
    console.warn('getProfile error:', error.message);
    return null;
  }
  return data;
}

export async function updateProfile(updates) {
  const user = await getCurrentUser();
  if (!user) throw new Error('Not authenticated');

  const supabase = getSupabase();
  const { data, error } = await supabase
    .from('profiles')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', user.id)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function isAdmin() {
  const user = await getCurrentUser();
  if (!user) return false;

  const supabase = getSupabase();
  const { data } = await supabase
    .from('admin_roles')
    .select('role')
    .eq('user_id', user.id)
    .in('role', ['super_admin', 'admin'])
    .maybeSingle();

  return !!data;
}

export async function getAdminRole() {
  const user = await getCurrentUser();
  if (!user) return null;

  const supabase = getSupabase();
  const { data } = await supabase
    .from('admin_roles')
    .select('role')
    .eq('user_id', user.id)
    .order('role')
    .limit(1)
    .maybeSingle();

  return data?.role || null;
}

export default { getProfile, updateProfile, isAdmin, getAdminRole };
