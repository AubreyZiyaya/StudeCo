# StudeCo deployment guide

## Prerequisites
- Supabase project
- Static hosting account (Cloudflare Pages or Netlify)
- Domain or preview URL
- Access to environment variables

## 1. Set public frontend config
Set environment variables in your host:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Do not set the service-role key in browser code.

## 2. Configure storage buckets
Create these private buckets in Supabase Storage:
- `student-profiles`
- `resources`
- `posts`
- `messages`

## 3. Run SQL migrations
Apply files in:
- `supabase/migrations/001_initial_schema.sql`
- `supabase/migrations/002_rls_policies.sql`
- `supabase/migrations/003_auth_profile_trigger.sql`
- `supabase/migrations/004_basic_rls_additions.sql`

## 4. Configure Auth
- Email sign-up
- Email confirmation
- Password reset
- Session persistence

## 5. Deploy frontend
Host this static project on:
- Cloudflare Pages
- Netlify
- Vercel static build

Use:
- `npm install`
- `python3 -m http.server 8080` for local testing

## 6. Deploy Edge Functions
Deploy the Supabase Edge Functions:
- `supabase/functions/create-admin-bootstrap`
- `supabase/functions/upload-url`
- `supabase/functions/confirm-upload`

## 7. Bootstrap admin
Use the trusted server-side function to assign the first user as `superadmin`:
- call the admin bootstrap Edge Function with the authenticated user’s ID

## 8. Production checks
- Ensure all uploads are behind trusted server enforcement.
- Confirm RLS is enabled on all tables.
- Verify admin-only modifications are protected.
- Ensure alternative upload destinations require explicit user action and HTTPS.
- Confirm storage bucket privacy and signed URL handling are configured.
