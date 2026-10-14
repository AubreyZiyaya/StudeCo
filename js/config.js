// Centralized config loader — prefers runtime STUDECO_CONFIG, then window globals.
const runtime = window.STUDECO_CONFIG || {};

const appConfig = {
  appName: 'StudeCo',
  appTagline: 'Connect. Learn. Collaborate. Grow.',
  supabaseUrl: runtime.SUPABASE_URL || window.__SUPABASE_URL__ || 'https://agwzcchllvksztdmcykj.supabase.co',
  supabaseAnonKey: runtime.SUPABASE_ANON_KEY || window.__SUPABASE_ANON_KEY__ || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFnd3pjY2hsbHZrc3p0ZG1jeWtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwMDExNjEsImV4cCI6MjEwNzU3NzE2MX0.PBT7rbsrhnQsrVsZIM4Jxwm5MoFNSVUegToDD1RvDVc',
  apiBaseUrl: runtime.API_BASE_URL || '/functions/v1',
  appMode: runtime.APP_MODE || 'production',
};

export default appConfig;
