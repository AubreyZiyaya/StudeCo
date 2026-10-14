# StudeCo

StudeCo is a student-focused social networking and academic collaboration platform built with HTML, CSS, JavaScript, and Supabase.

Tagline: "Connect. Learn. Collaborate. Grow."

## Project structure
- `index.html` – public landing page
- `login.html` – sign in
- `register.html` – sign up and onboarding
- `app/` – authenticated app
- `admin/` – admin dashboard
- `assets/` – CSS, images, icons
- `js/` – JavaScript modules
- `supabase/migrations/` – SQL schema and RLS setup
- `docs/` – setup and deployment documentation

## Setup requirements
1. Create a Supabase project.
2. Get the project URL and anon key.
3. Add your service role key only in server-side trusted environments.
4. Run the SQL migrations in `supabase/migrations`.
5. Configure email auth, storage buckets, and RLS policies.

## Public config
Use environment variables or build-time config for:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Do not place `SUPABASE_SERVICE_ROLE_KEY` in frontend JavaScript.

## Local development
A simple local static server works:

```bash
python3 -m http.server 8080
```

Then open:
- `http://localhost:8080/`

## Deployment
Deploy the frontend to any static host such as:
- Cloudflare Pages
- Netlify
- GitHub Pages (for basic static deployment)

Supabase handles the database, auth, storage, and real-time layers.

## Security notes
- All upload enforcement must be server-side.
- RLS policies must be enforced in Postgres.
- Do not expose secrets to the browser.
- Use trusted server functions for admin-only tasks.

## Notes
This scaffold provides the architecture and early production-ready structure for StudeCo. The actual database and storage setup must be completed in your Supabase project before app functionality is fully usable.
