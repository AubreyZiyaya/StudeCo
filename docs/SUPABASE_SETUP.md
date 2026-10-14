# Supabase setup guide

## 1. Create a Supabase project
- Create a new project in Supabase.
- Copy the project URL and anon key.
- Keep the service role key in a secure secret store only.

## 2. Create required storage buckets
Create private buckets such as:
- `student-profiles`
- `resources`
- `posts`
- `messages`

Use private storage, not public buckets, for sensitive academic material.

## 3. Run database migrations
In the Supabase SQL editor, run:
- `supabase/migrations/001_initial_schema.sql`
- `supabase/migrations/002_rls_policies.sql`
- `supabase/migrations/003_auth_profile_trigger.sql`
- `supabase/migrations/004_basic_rls_additions.sql`

## 4. Configure auth
- Enable email authentication.
- Turn on email confirmation.
- Add password reset flow.

## 5. Configure public frontend env vars
Set these either in a `.env` file or static hosting environment:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## 6. Add server-side secrets only on trusted infra
Never expose these in the browser:
- `SUPABASE_SERVICE_ROLE_KEY`
- SMTP credentials

## 7. Configure admin bootstrap
Create a super-admin account via a trusted server function or direct secure bootstrap workflow.

## 8. Validate RLS
Run tests to confirm:
- Users can access only their own profile rows.
- Private uploads are not publicly readable.
- Message data is only available to conversation participants.

## 9. Deployment notes
- Frontend: static host (Cloudflare Pages / Netlify)
- Backend: Supabase database and functions

## 10. Production hardening
- Restrict admin UI behind server authorization.
- Validate MIME types and size server-side.
- Log admin actions to `admin_audit_logs`.
