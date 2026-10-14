import { supabase } from '../supabase-client.js';

export function redirectIfLoggedOut() {
  supabase.auth.getSession().then(({ data, error }) => {
    if (error || !data.session) {
      window.location.href = '../login.html';
    }
  });
}

export function redirectIfLoggedIn() {
  supabase.auth.getSession().then(({ data, error }) => {
    if (!error && data.session) {
      window.location.href = 'app/feed.html';
    }
  });
}
