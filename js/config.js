/**
 * StudeCo Configuration
 * 
 * IMPORTANT SECURITY NOTES:
 * - These values are PUBLIC and visible in the browser.
 * - Never put service_role keys, SMTP secrets, or private API keys here.
 * - Security is enforced via Supabase RLS policies and Edge Functions.
 * - Configure these via environment variables at build/deploy time when possible.
 */

export const CONFIG = {
  // Replace with your Supabase project values
  SUPABASE_URL: window.__ENV__?.SUPABASE_URL || 'https://agwzcchllvksztdmcykj.supabase.co',
  SUPABASE_ANON_KEY: window.__ENV__?.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFnd3pjY2hsbHZrc3p0ZG1jeWtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwMDExNjEsImV4cCI6MjEwNzU3NzE2MX0.PBT7rbsrhnQsrVsZIM4Jxwm5MoFNSVUegToDD1RvDVc',

  // App metadata
  APP_NAME: 'StudeCo',
  TAGLINE: 'Connect. Learn. Collaborate. Grow.',
  SUPPORT_EMAIL: 'support@studeco.app',

  // Feature flags (can be overridden by platform_settings)
  FEATURES: {
    darkMode: true,
    messaging: true,
    resources: true,
    events: true,
    opportunities: true,
    realtime: true
  },

  // Default upload limits (authoritative values come from database)
  DEFAULT_UPLOAD: {
    maxFileSizeMB: 10,
    maxFilesPerPost: 5
  },

  // Routes
  ROUTES: {
    landing: '/',
    login: '/login.html',
    register: '/register.html',
    app: '/app/',
    admin: '/admin/',
    feed: '/app/feed.html',
    profile: '/app/profile.html',
    groups: '/app/groups.html',
    resources: '/app/resources.html',
    messages: '/app/messages.html',
    notifications: '/app/notifications.html',
    events: '/app/events.html',
    opportunities: '/app/opportunities.html',
    settings: '/app/settings.html'
  }
};

export default CONFIG;
