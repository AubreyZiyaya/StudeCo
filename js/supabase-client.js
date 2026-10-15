/**
 * Supabase Client Initialization
 * Uses the official @supabase/supabase-js library loaded via CDN or module.
 */

import { CONFIG } from './config.js';

let supabase = null;

/**
 * Initialize and return the Supabase client (singleton).
 */
export function getSupabase() {
  if (supabase) return supabase;

  if (typeof window.supabase === 'undefined') {
    console.error('Supabase JS library not loaded. Include the CDN script.');
    return null;
  }

  supabase = window.supabase.createClient(
    CONFIG.SUPABASE_URL,
    CONFIG.SUPABASE_ANON_KEY,
    {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true,
        storage: window.localStorage
      },
      realtime: {
        params: {
          eventsPerSecond: 10
        }
      }
    }
  );

  return supabase;
}

/**
 * Get the current authenticated user.
 */
export async function getCurrentUser() {
  const client = getSupabase();
  if (!client) return null;

  const { data: { user }, error } = await client.auth.getUser();
  if (error) {
    console.warn('getCurrentUser error:', error.message);
    return null;
  }
  return user;
}

/**
 * Get the current session.
 */
export async function getSession() {
  const client = getSupabase();
  if (!client) return null;

  const { data: { session }, error } = await client.auth.getSession();
  if (error) return null;
  return session;
}

/**
 * Sign out the current user.
 */
export async function signOut() {
  const client = getSupabase();
  if (!client) return;
  await client.auth.signOut();
  window.location.href = CONFIG.ROUTES.login;
}

/**
 * Require authentication. Redirects to login if not authenticated.
 * Returns the user if authenticated.
 */
export async function requireAuth() {
  const user = await getCurrentUser();
  if (!user) {
    const returnTo = encodeURIComponent(window.location.pathname + window.location.search);
    window.location.href = `${CONFIG.ROUTES.login}?returnTo=${returnTo}`;
    return null;
  }
  return user;
}

/**
 * Require admin role. Redirects if not admin.
 */
export async function requireAdmin() {
  const user = await requireAuth();
  if (!user) return null;

  const client = getSupabase();
  const { data, error } = await client
    .from('admin_roles')
    .select('role')
    .eq('user_id', user.id)
    .in('role', ['super_admin', 'admin'])
    .maybeSingle();

  if (error || !data) {
    window.location.href = CONFIG.ROUTES.app;
    return null;
  }
  return { user, role: data.role };
}

export default getSupabase;
