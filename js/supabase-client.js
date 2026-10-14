import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import appConfig from "./config.js";

export const supabase = createClient(appConfig.supabaseUrl, appConfig.supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

export async function getSession() {
  return supabase.auth.getSession();
}

export async function signIn(email, password) {
  return supabase.auth.signInWithPassword({ email, password });
}

export async function signUp({ email, password, display_name, education_level }) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        display_name,
        education_level,
      },
    },
  });

  if (error) return { error };
  return { data };
}

export async function signOut() {
  return supabase.auth.signOut();
}
