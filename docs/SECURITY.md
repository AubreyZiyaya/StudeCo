# StudeCo security checklist

## Core rules
- Never expose `SUPABASE_SERVICE_ROLE_KEY` in browser code.
- Treat all user-provided text, filenames, and file metadata as untrusted input.
- Enforce least-privilege access in database Row Level Security (RLS).
- Validate file size and MIME type on the server.
- Use private storage buckets and signed URLs for protected files.
- Use trusted server-side functions for admin operations and privileged logic.

## Database security
- Enable RLS on every table intended for client access.
- Require `auth.uid()` checks and profile mapping for role-based access.
- Avoid user-supplied role values as the source of authorization.
- Audit sensitive actions to `admin_audit_logs`.

## Upload safety
- Validate files server-side before inserting metadata into `uploaded_files`.
- Enforce quotas from authoritative configuration (`upload_settings`).
- Do not redirect users automatically to an external upload destination.
- Ensure alternative destinations use HTTPS and approved domains only.

## Application safety
- Sanitize and limit user-generated HTML output.
- Avoid executing untrusted markdown or HTML inside the browser.
- Use safe rendering patterns for comments, posts, and messages.

## Operational guidance
- Keep backups and restore procedures documented.
- Monitor storage usage and provider status.
- Review access logs and admin actions periodically.
