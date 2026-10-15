# StudeCo – Student Social Networking Platform

**Connect. Learn. Collaborate. Grow.**

StudeCo is a production-oriented student social network built with **HTML, CSS, Vanilla JavaScript** and **Supabase**.

It supports secondary school and university students with academic resource sharing, groups, messaging, events, opportunities, and a comprehensive admin-controlled upload system.

---

## Features Implemented

### Core
- Public landing page with feature sections for secondary & university modes
- Email/password authentication via Supabase Auth (registration, sign-in, email verification flow)
- Profile system with education level selection
- Responsive app shell (sidebar + mobile navigation)
- Home feed with post creation (text + media)
- Dark mode support

### Critical: Admin-Controlled Upload System
- Database-backed `upload_settings` (not hardcoded frontend limits)
- State machine: `AVAILABLE | WARNING | LIMIT_REACHED | PROVIDER_ERROR | ADMIN_DISABLED | MAINTENANCE`
- Admin dashboard page to configure:
  - Global enable/disable of uploads, images, PDFs, videos, documents
  - Max file size, files per post, total storage capacity
  - User-facing unavailable title, message, support contact
  - Optional HTTPS alternative upload destination (with confirmation)
  - Restoration announcement
- Client retrieves availability via RPC `get_upload_availability()`
- Upload service validates against live settings
- Clear notices when capacity is reached; form content is preserved
- Audit logging of admin changes

### Database
- Full SQL migrations for profiles, institutions, posts, groups, messaging, resources, events, opportunities, notifications, reports, upload system, admin roles & audit logs
- Row Level Security (RLS) policies for all tables
- Helper functions for admin checks and upload availability

### Security
- No service-role keys in frontend
- RLS enforced on every table
- Only conversation participants can read messages
- Only admins can modify upload settings
- Audit logs are append-only from the frontend

---

## Project Structure

```
studeCo/
├── index.html              # Landing page
├── login.html / register.html / ...
├── app/                    # Authenticated student app
│   └── index.html          # Home feed + composer
├── admin/                  # Protected admin interface
│   └── uploads.html        # Upload & storage control
├── assets/css/             # Design system + page styles
├── js/
│   ├── config.js
│   ├── supabase-client.js
│   ├── services/
│   │   ├── auth-service.js
│   │   └── upload-service.js
│   └── ...
├── supabase/
│   └── migrations/
│       ├── 001_initial_schema.sql
│       └── 002_rls_policies.sql
├── docs/
└── README.md
```

---

## Setup Instructions

### 1. Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and create a new project.
2. Note your **Project URL** and **anon (public) key**.

### 2. Run Database Migrations

In the Supabase SQL Editor, run in order:

1. `supabase/migrations/001_initial_schema.sql`
2. `supabase/migrations/002_rls_policies.sql`

### 3. Create Storage Bucket

1. Go to **Storage** → Create bucket named `uploads`.
2. Recommended: make it **private** (use signed URLs).
3. Add Storage policies so authenticated users can upload to their own folder (`{user_id}/*`) and read public/own files.

Example Storage policies (adjust as needed):

```sql
-- Allow authenticated uploads to own folder
CREATE POLICY "Users can upload to own folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'uploads' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow users to read own files + public files
CREATE POLICY "Users can read own files"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'uploads' AND (storage.foldername(name))[1] = auth.uid()::text);
```

### 4. Configure Frontend

Edit `js/config.js` (or inject at build time):

```js
SUPABASE_URL: 'https://YOUR_PROJECT_REF.supabase.co',
SUPABASE_ANON_KEY: 'your-anon-key',
```

**Never** put the `service_role` key in frontend code.

### 5. Bootstrap an Administrator

After registering your first user and verifying email:

```sql
INSERT INTO public.admin_roles (user_id, role, granted_by)
VALUES (
  'YOUR_USER_UUID',  -- from auth.users or profiles
  'super_admin',
  'YOUR_USER_UUID'
);
```

### 6. Enable Email Auth

In Supabase Dashboard → Authentication → Providers → Email: enable and configure confirmation templates.

### 7. Deploy (Static Hosting)

The frontend is static-hosting compatible.

**Cloudflare Pages / Netlify / Vercel (static):**

- Set root to the `studeCo` folder.
- Optionally inject environment variables for `SUPABASE_URL` and `SUPABASE_ANON_KEY` at build time into a small `env.js` or replace placeholders.

Example for a simple env injection:

```html
<script>
  window.__ENV__ = {
    SUPABASE_URL: 'https://xxx.supabase.co',
    SUPABASE_ANON_KEY: 'eyJ...'
  };
</script>
```

---

## Admin: Upload Control Workflow

1. Admin opens `/admin/uploads.html`.
2. Changes **Upload State** to `LIMIT_REACHED` or unchecks “Uploads enabled”.
3. Customises the user-facing title/message/support contact.
4. Optionally enables an HTTPS alternative destination.
5. Students see the configured notice on the composer/resource upload areas.
6. Existing posts and resources remain accessible.
7. Admin sets state back to `AVAILABLE` → students can upload again.
8. All changes are recorded in `admin_audit_logs`.

---

## Testing the Critical Upload Scenario

1. Student opens the home feed composer while uploads are `AVAILABLE`.
2. Student successfully uploads a document.
3. Admin sets state to `LIMIT_REACHED` and saves.
4. Student attempts another upload → sees the admin-configured message.
5. Alternative destination appears **only** if enabled and HTTPS.
6. Student can still browse feed, groups, messages, etc.
7. Admin restores to `AVAILABLE`.
8. Student successfully uploads again.

---

## Security Checklist

- [x] Service-role key never in frontend
- [x] RLS enabled on all tables
- [x] Upload settings writable only by admins
- [x] Messages readable only by conversation members
- [x] Audit logs append-only from client
- [x] Filenames and content treated as untrusted (escape on render)
- [x] Alternative destinations require HTTPS + explicit user confirmation
- [ ] Add Edge Function for privileged admin operations if you need service-role actions
- [ ] Configure Storage policies carefully for production
- [ ] Enable CAPTCHA / rate limiting on Auth in production

---

## Extending the Application

- Additional pages (`groups.html`, `resources.html`, `messages.html`, etc.) follow the same app shell pattern.
- Realtime messaging: subscribe to `messages` with filter on `conversation_id` after membership check.
- Edge Functions: place under `supabase/functions/` for operations that must use the service role (e.g. bulk moderation, provider quota reconciliation).

---

## License

This project is provided as a complete foundation for educational and production use. Customise branding, policies and limits for your institution or deployment.

---

**StudeCo** – Connect. Learn. Collaborate. Grow.

---

## Expanded Features (v2)

### Signup fields
- Age (required), Gender, School/University name, Grade/Year

### Student app pages
- **Groups** – discover, my groups, create public/private groups, join/leave, group detail + group posts
- **Resources** – search/filter, upload with admin-controlled limits, download tracking
- **Messages** – conversation list, direct chats, realtime subscription, start chat by user search
- **Profile** – own edit (bio, school, age, gender, interests), public view of others, follow/unfollow
- **Notifications** – list, mark read, mark all read
- **Settings** – dark mode, privacy visibility, notification prefs, account deletion request
- **Events** – list upcoming, create events
- **Opportunities** – scholarships/internships/jobs filters, post opportunities

### Migrations
Run in order:
1. `001_initial_schema.sql`
2. `002_rls_policies.sql`
3. `003_profile_extensions.sql` (age, gender, school_name, etc.)

