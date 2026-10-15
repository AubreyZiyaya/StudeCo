-- Extend profiles for age, gender, school and related fields
-- Run after 001 and 002

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS age INTEGER CHECK (age IS NULL OR (age >= 10 AND age <= 100)),
  ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IS NULL OR gender IN ('male', 'female', 'non_binary', 'prefer_not_to_say', 'other')),
  ADD COLUMN IF NOT EXISTS school_name TEXT,
  ADD COLUMN IF NOT EXISTS grade_or_year TEXT,
  ADD COLUMN IF NOT EXISTS location_city TEXT,
  ADD COLUMN IF NOT EXISTS location_country TEXT,
  ADD COLUMN IF NOT EXISTS website_url TEXT,
  ADD COLUMN IF NOT EXISTS linkedin_url TEXT,
  ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS profile_visibility TEXT DEFAULT 'public' CHECK (profile_visibility IN ('public', 'institution', 'followers', 'private'));

-- Index for school search
CREATE INDEX IF NOT EXISTS idx_profiles_school ON public.profiles(school_name);

-- Optional: update handle_new_user to accept more metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id, email, display_name, username,
    education_level, age, gender, school_name
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1) || '_' || substr(NEW.id::text, 1, 6)),
    COALESCE(NEW.raw_user_meta_data->>'education_level', 'secondary'),
    CASE WHEN NEW.raw_user_meta_data->>'age' ~ '^[0-9]+$' THEN (NEW.raw_user_meta_data->>'age')::INTEGER ELSE NULL END,
    NEW.raw_user_meta_data->>'gender',
    NEW.raw_user_meta_data->>'school_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
