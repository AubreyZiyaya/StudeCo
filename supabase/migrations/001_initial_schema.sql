-- StudeCo Initial Schema
-- Production-oriented student social network
-- Run this in Supabase SQL Editor or via CLI migrations

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- PROFILES & AUTH
-- =====================================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  username TEXT UNIQUE,
  bio TEXT,
  avatar_url TEXT,
  education_level TEXT CHECK (education_level IN ('secondary', 'university')) NOT NULL DEFAULT 'secondary',
  institution_id UUID,
  programme TEXT,
  subjects TEXT[] DEFAULT '{}',
  interests TEXT[] DEFAULT '{}',
  is_verified BOOLEAN DEFAULT false,
  is_suspended BOOLEAN DEFAULT false,
  suspension_reason TEXT,
  privacy_settings JSONB DEFAULT '{"profile_visibility": "public", "show_email": false, "show_institution": true}'::jsonb,
  notification_preferences JSONB DEFAULT '{"reactions": true, "comments": true, "messages": true, "group_invites": true, "announcements": true}'::jsonb,
  storage_used_bytes BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_active_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_education_level ON public.profiles(education_level);
CREATE INDEX idx_profiles_institution ON public.profiles(institution_id);
CREATE INDEX idx_profiles_username ON public.profiles(username);

-- =====================================================
-- INSTITUTIONS
-- =====================================================
CREATE TABLE public.institutions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type TEXT CHECK (type IN ('secondary_school', 'university', 'college', 'other')) NOT NULL,
  country TEXT,
  city TEXT,
  website TEXT,
  logo_url TEXT,
  is_verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES public.profiles(id),
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_institutions_type ON public.institutions(type);
CREATE INDEX idx_institutions_verified ON public.institutions(is_verified);

ALTER TABLE public.profiles
  ADD CONSTRAINT fk_profiles_institution
  FOREIGN KEY (institution_id) REFERENCES public.institutions(id) ON DELETE SET NULL;

CREATE TABLE public.institution_memberships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  institution_id UUID NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'student' CHECK (role IN ('student', 'teacher', 'admin', 'representative')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  verification_evidence TEXT,
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, institution_id)
);

-- =====================================================
-- PROGRAMMES & SUBJECTS
-- =====================================================
CREATE TABLE public.programmes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  level TEXT, -- e.g. undergraduate, postgraduate, form_1, form_4
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  category TEXT,
  education_level TEXT CHECK (education_level IN ('secondary', 'university', 'both')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- POSTS & FEED
-- =====================================================
CREATE TABLE public.posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT,
  post_type TEXT DEFAULT 'text' CHECK (post_type IN ('text', 'image', 'video', 'link', 'poll', 'resource')),
  visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'institution', 'group', 'followers', 'private')),
  group_id UUID,
  institution_id UUID REFERENCES public.institutions(id),
  poll_options JSONB,
  poll_ends_at TIMESTAMPTZ,
  link_url TEXT,
  is_edited BOOLEAN DEFAULT false,
  is_pinned BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMPTZ,
  reaction_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_author ON public.posts(author_id);
CREATE INDEX idx_posts_created ON public.posts(created_at DESC);
CREATE INDEX idx_posts_group ON public.posts(group_id);
CREATE INDEX idx_posts_visibility ON public.posts(visibility);

CREATE TABLE public.post_media (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  file_id UUID, -- references uploaded_files
  media_type TEXT CHECK (media_type IN ('image', 'video', 'document')),
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  mime_type TEXT,
  size_bytes BIGINT,
  width INTEGER,
  height INTEGER,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comments_post ON public.comments(post_id);

CREATE TABLE public.reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reaction_type TEXT DEFAULT 'like' CHECK (reaction_type IN ('like', 'love', 'insightful', 'celebrate', 'support')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id),
  UNIQUE(comment_id, user_id),
  CHECK (
    (post_id IS NOT NULL AND comment_id IS NULL) OR
    (post_id IS NULL AND comment_id IS NOT NULL)
  )
);

-- =====================================================
-- FOLLOWS & CONNECTIONS
-- =====================================================
CREATE TABLE public.follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

CREATE TABLE public.friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(requester_id, addressee_id),
  CHECK (requester_id != addressee_id)
);

CREATE TABLE public.user_blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id)
);

-- =====================================================
-- GROUPS
-- =====================================================
CREATE TABLE public.groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  avatar_url TEXT,
  cover_url TEXT,
  group_type TEXT DEFAULT 'public' CHECK (group_type IN ('public', 'private', 'institution_restricted')),
  institution_id UUID REFERENCES public.institutions(id),
  education_level TEXT CHECK (education_level IN ('secondary', 'university', 'both')),
  created_by UUID NOT NULL REFERENCES public.profiles(id),
  member_count INTEGER DEFAULT 0,
  is_verified BOOLEAN DEFAULT false,
  is_suspended BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_groups_type ON public.groups(group_type);
CREATE INDEX idx_groups_institution ON public.groups(institution_id);

ALTER TABLE public.posts
  ADD CONSTRAINT fk_posts_group
  FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE SET NULL;

CREATE TABLE public.group_memberships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('member', 'moderator', 'admin')),
  status TEXT DEFAULT 'active' CHECK (status IN ('pending', 'active', 'banned')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- =====================================================
-- MESSAGING
-- =====================================================
CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_type TEXT DEFAULT 'direct' CHECK (conversation_type IN ('direct', 'group')),
  title TEXT,
  created_by UUID REFERENCES public.profiles(id),
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.conversation_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  last_read_at TIMESTAMPTZ,
  is_muted BOOLEAN DEFAULT false,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'document', 'system')),
  attachment_url TEXT,
  attachment_file_id UUID,
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON public.messages(conversation_id, created_at DESC);

-- =====================================================
-- ACADEMIC RESOURCES
-- =====================================================
CREATE TABLE public.resource_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  education_level TEXT CHECK (education_level IN ('secondary', 'university', 'both')),
  icon TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  uploader_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category_id UUID REFERENCES public.resource_categories(id),
  subject TEXT,
  course TEXT,
  institution_id UUID REFERENCES public.institutions(id),
  education_level TEXT CHECK (education_level IN ('secondary', 'university')),
  file_id UUID, -- references uploaded_files
  file_url TEXT,
  mime_type TEXT,
  size_bytes BIGINT,
  download_count INTEGER DEFAULT 0,
  bookmark_count INTEGER DEFAULT 0,
  is_approved BOOLEAN DEFAULT true,
  is_reported BOOLEAN DEFAULT false,
  visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'institution', 'private')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_resources_uploader ON public.resources(uploader_id);
CREATE INDEX idx_resources_subject ON public.resources(subject);
CREATE INDEX idx_resources_category ON public.resources(category_id);

CREATE TABLE public.resource_bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, resource_id)
);

-- =====================================================
-- EVENTS & OPPORTUNITIES
-- =====================================================
CREATE TABLE public.events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organizer_id UUID REFERENCES public.profiles(id),
  institution_id UUID REFERENCES public.institutions(id),
  title TEXT NOT NULL,
  description TEXT,
  event_type TEXT CHECK (event_type IN ('workshop', 'club', 'conference', 'social', 'academic', 'other')),
  location TEXT,
  is_online BOOLEAN DEFAULT false,
  meeting_url TEXT,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  registration_required BOOLEAN DEFAULT false,
  max_attendees INTEGER,
  is_approved BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.event_registrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'registered' CHECK (status IN ('registered', 'attended', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

CREATE TABLE public.opportunities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  poster_id UUID REFERENCES public.profiles(id),
  title TEXT NOT NULL,
  description TEXT,
  opportunity_type TEXT CHECK (opportunity_type IN ('scholarship', 'internship', 'job', 'competition', 'mentorship')),
  organization TEXT,
  location TEXT,
  is_remote BOOLEAN DEFAULT false,
  application_url TEXT,
  deadline TIMESTAMPTZ,
  eligibility TEXT,
  education_level TEXT CHECK (education_level IN ('secondary', 'university', 'both')),
  is_verified BOOLEAN DEFAULT false,
  is_approved BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- NOTIFICATIONS
-- =====================================================
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES public.profiles(id),
  type TEXT NOT NULL,
  title TEXT,
  body TEXT,
  link TEXT,
  reference_id UUID,
  reference_type TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id) WHERE is_read = false;

-- =====================================================
-- REPORTS & MODERATION
-- =====================================================
CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES public.profiles(id),
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'comment', 'user', 'group', 'resource', 'message', 'event', 'opportunity')),
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
  reviewed_by UUID REFERENCES public.profiles(id),
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE TABLE public.moderation_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  moderator_id UUID NOT NULL REFERENCES public.profiles(id),
  action_type TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID NOT NULL,
  reason TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- UPLOAD SYSTEM (CRITICAL)
-- =====================================================
CREATE TABLE public.upload_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Global toggles
  uploads_enabled BOOLEAN DEFAULT true,
  images_enabled BOOLEAN DEFAULT true,
  pdfs_enabled BOOLEAN DEFAULT true,
  videos_enabled BOOLEAN DEFAULT true,
  documents_enabled BOOLEAN DEFAULT true,
  -- Limits
  max_file_size_bytes BIGINT DEFAULT 10485760, -- 10 MB
  max_files_per_post INTEGER DEFAULT 5,
  max_upload_size_per_user_bytes BIGINT DEFAULT 104857600, -- 100 MB
  max_storage_quota_per_user_bytes BIGINT DEFAULT 524288000, -- 500 MB
  -- Allowed types
  allowed_mime_types TEXT[] DEFAULT ARRAY[
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf',
    'video/mp4', 'video/webm',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation'
  ],
  allowed_extensions TEXT[] DEFAULT ARRAY['.jpg', '.jpeg', '.png', '.gif', '.webp', '.pdf', '.mp4', '.webm', '.doc', '.docx', '.ppt', '.pptx'],
  -- Storage
  storage_provider TEXT DEFAULT 'supabase' CHECK (storage_provider IN ('supabase', 'external')),
  total_storage_capacity_bytes BIGINT DEFAULT 5368709120, -- 5 GB default
  warning_threshold_percent INTEGER DEFAULT 80,
  -- State machine
  upload_state TEXT DEFAULT 'AVAILABLE' CHECK (upload_state IN (
    'AVAILABLE', 'WARNING', 'LIMIT_REACHED', 'PROVIDER_ERROR', 'ADMIN_DISABLED', 'MAINTENANCE'
  )),
  -- User-facing messages (admin configurable)
  unavailable_title TEXT DEFAULT 'Uploads Temporarily Unavailable',
  unavailable_message TEXT DEFAULT 'StudeCo has temporarily reached its current upload capacity. Your existing account and academic resources remain accessible. Please try again later or contact the support team for assistance.',
  short_notice TEXT DEFAULT 'File uploads are currently unavailable.',
  show_remaining_capacity BOOLEAN DEFAULT true,
  estimated_restoration_time TEXT,
  support_email TEXT DEFAULT 'support@studeco.app',
  support_url TEXT,
  -- Alternative destination
  alternative_enabled BOOLEAN DEFAULT false,
  alternative_url TEXT,
  alternative_label TEXT DEFAULT 'Upload via approved external service',
  alternative_domains TEXT[] DEFAULT '{}',
  -- Maintenance
  maintenance_message TEXT,
  restoration_announcement TEXT DEFAULT 'File uploads have been restored. You can upload your academic resources again.',
  -- Versioning for cache invalidation
  config_version INTEGER DEFAULT 1,
  updated_by UUID REFERENCES public.profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Only one active settings row expected (singleton pattern)
INSERT INTO public.upload_settings (id) VALUES ('00000000-0000-0000-0000-000000000001');

CREATE TABLE public.uploaded_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  uploader_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  original_filename TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes BIGINT NOT NULL,
  bucket TEXT DEFAULT 'uploads',
  category TEXT CHECK (category IN ('avatar', 'post_media', 'resource', 'message_attachment', 'other')),
  is_public BOOLEAN DEFAULT false,
  checksum TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'deleted', 'quarantined')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_uploaded_files_uploader ON public.uploaded_files(uploader_id);
CREATE INDEX idx_uploaded_files_status ON public.uploaded_files(status);

CREATE TABLE public.upload_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  file_id UUID REFERENCES public.uploaded_files(id),
  original_filename TEXT,
  mime_type TEXT,
  size_bytes BIGINT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'uploading', 'processing', 'completed', 'failed', 'cancelled')),
  error_code TEXT,
  error_message TEXT,
  progress_percent INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE public.storage_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  total_bytes BIGINT NOT NULL,
  file_count INTEGER NOT NULL,
  by_category JSONB,
  by_institution JSONB,
  source TEXT DEFAULT 'application' CHECK (source IN ('application', 'provider', 'estimate')),
  notes TEXT
);

CREATE TABLE public.storage_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL CHECK (event_type IN (
    'upload_success', 'upload_failed', 'quota_warning', 'quota_exceeded',
    'provider_error', 'admin_disabled', 'admin_restored', 'file_deleted'
  )),
  user_id UUID REFERENCES public.profiles(id),
  file_id UUID REFERENCES public.uploaded_files(id),
  bytes_delta BIGINT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- PLATFORM SETTINGS & ADMIN
-- =====================================================
CREATE TABLE public.platform_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES public.profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.platform_settings (key, value, description) VALUES
  ('platform_name', '"StudeCo"', 'Platform display name'),
  ('tagline', '"Connect. Learn. Collaborate. Grow."', 'Platform tagline'),
  ('registration_enabled', 'true', 'Whether new registrations are allowed'),
  ('maintenance_mode', 'false', 'Global maintenance mode'),
  ('support_email', '"support@studeco.app"', 'Support contact email'),
  ('community_guidelines_url', '"/guidelines"', 'Link to community guidelines'),
  ('privacy_policy_url', '"/privacy"', 'Link to privacy policy'),
  ('terms_url', '"/terms"', 'Link to terms of service');

CREATE TABLE public.admin_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'admin', 'moderator', 'content_reviewer')),
  granted_by UUID REFERENCES public.profiles(id),
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);

CREATE TABLE public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id UUID NOT NULL REFERENCES public.profiles(id),
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  old_value JSONB,
  new_value JSONB,
  ip_address TEXT,
  user_agent TEXT,
  outcome TEXT DEFAULT 'success',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_admin_audit_logs_actor ON public.admin_audit_logs(actor_id);
CREATE INDEX idx_admin_audit_logs_created ON public.admin_audit_logs(created_at DESC);

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, username)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1) || '_' || substr(NEW.id::text, 1, 6))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER posts_updated_at BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.admin_roles
    WHERE user_id = user_uuid
    AND role IN ('super_admin', 'admin')
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_super_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.admin_roles
    WHERE user_id = user_uuid
    AND role = 'super_admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Function to get current upload state (callable by authenticated users)
CREATE OR REPLACE FUNCTION public.get_upload_availability()
RETURNS JSONB AS $$
DECLARE
  settings RECORD;
  used_bytes BIGINT;
  result JSONB;
BEGIN
  SELECT * INTO settings FROM public.upload_settings LIMIT 1;
  
  SELECT COALESCE(SUM(size_bytes), 0) INTO used_bytes
  FROM public.uploaded_files
  WHERE status = 'active';

  result := jsonb_build_object(
    'state', settings.upload_state,
    'uploads_enabled', settings.uploads_enabled AND settings.upload_state = 'AVAILABLE',
    'images_enabled', settings.images_enabled,
    'pdfs_enabled', settings.pdfs_enabled,
    'videos_enabled', settings.videos_enabled,
    'documents_enabled', settings.documents_enabled,
    'max_file_size_bytes', settings.max_file_size_bytes,
    'max_files_per_post', settings.max_files_per_post,
    'allowed_mime_types', settings.allowed_mime_types,
    'allowed_extensions', settings.allowed_extensions,
    'config_version', settings.config_version,
    'unavailable_title', settings.unavailable_title,
    'unavailable_message', settings.unavailable_message,
    'short_notice', settings.short_notice,
    'support_email', settings.support_email,
    'support_url', settings.support_url,
    'alternative_enabled', settings.alternative_enabled,
    'alternative_url', settings.alternative_url,
    'alternative_label', settings.alternative_label,
    'restoration_announcement', settings.restoration_announcement,
    'estimated_restoration_time', settings.estimated_restoration_time,
    'show_remaining_capacity', settings.show_remaining_capacity,
    'total_capacity_bytes', settings.total_storage_capacity_bytes,
    'used_bytes', used_bytes,
    'remaining_bytes', GREATEST(0, settings.total_storage_capacity_bytes - used_bytes)
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- =====================================================
-- SEED DATA
-- =====================================================
INSERT INTO public.resource_categories (name, description, education_level) VALUES
  ('Lecture Notes', 'Course lecture notes and summaries', 'both'),
  ('Past Papers', 'Examination past papers and solutions', 'secondary'),
  ('Revision Guides', 'Study and revision materials', 'both'),
  ('Research Papers', 'Academic research and papers', 'university'),
  ('Presentations', 'Slide decks and presentations', 'both'),
  ('Textbooks', 'Shared textbook excerpts (where permitted)', 'both'),
  ('Tutorials', 'Step-by-step tutorials and guides', 'both');

INSERT INTO public.subjects (name, category, education_level) VALUES
  ('Mathematics', 'STEM', 'both'),
  ('Physics', 'STEM', 'both'),
  ('Chemistry', 'STEM', 'both'),
  ('Biology', 'STEM', 'both'),
  ('Computer Science', 'STEM', 'both'),
  ('English Literature', 'Humanities', 'both'),
  ('History', 'Humanities', 'both'),
  ('Geography', 'Humanities', 'both'),
  ('Economics', 'Social Sciences', 'both'),
  ('Business Studies', 'Social Sciences', 'both'),
  ('Psychology', 'Social Sciences', 'university'),
  ('Engineering', 'STEM', 'university'),
  ('Medicine', 'Health', 'university'),
  ('Law', 'Professional', 'university');
