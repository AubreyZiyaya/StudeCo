// Centralized config loader — prefers runtime STUDECO_CONFIG, then window globals.
const runtime = window.STUDECO_CONFIG || {};

const appConfig = {
  appName: 'StudeCo',
  appTagline: 'Connect. Learn. Collaborate. Grow.',
  supabaseUrl: runtime.SUPABASE_URL || window.__SUPABASE_URL__ || 'https://your-project.supabase.co',
  supabaseAnonKey: runtime.SUPABASE_ANON_KEY || window.__SUPABASE_ANON_KEY__ || 'your-anon-key',
  apiBaseUrl: runtime.API_BASE_URL || '/functions/v1',
  appMode: runtime.APP_MODE || 'production',
};

export default appConfig;
