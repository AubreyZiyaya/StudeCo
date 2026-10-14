-- 003_auth_profile_trigger.sql
-- Create a trigger to insert a minimal profile row when a new auth user is created.
-- Run this migration in Supabase SQL editor (requires pgcrypto extension present from migration 001).

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger AS $$
BEGIN
  -- Insert a minimal profile linked to the auth user.
  INSERT INTO public.profiles (auth_uid, display_name, email, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.user_metadata->>'display_name', split_part(NEW.email, '@', 1)),
    NEW.email,
    now(),
    now()
  ) ON CONFLICT (auth_uid) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();
