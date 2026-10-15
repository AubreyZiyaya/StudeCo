-- StudeCo Row Level Security Policies
-- Critical for security. Run after 001_initial_schema.sql

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.institution_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programmes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.upload_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.uploaded_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.upload_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.storage_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.storage_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PROFILES
-- =====================================================
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users cannot insert profiles directly"
  ON public.profiles FOR INSERT
  WITH CHECK (false); -- Handled by trigger

-- =====================================================
-- INSTITUTIONS
-- =====================================================
CREATE POLICY "Institutions are viewable by everyone"
  ON public.institutions FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create institutions"
  ON public.institutions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can update institutions"
  ON public.institutions FOR UPDATE
  USING (public.is_admin(auth.uid()) OR created_by = auth.uid());

-- =====================================================
-- INSTITUTION MEMBERSHIPS
-- =====================================================
CREATE POLICY "Users can view own memberships"
  ON public.institution_memberships FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Users can request membership"
  ON public.institution_memberships FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can manage memberships"
  ON public.institution_memberships FOR UPDATE
  USING (public.is_admin(auth.uid()));

-- =====================================================
-- POSTS
-- =====================================================
CREATE POLICY "Public posts are viewable"
  ON public.posts FOR SELECT
  USING (
    is_deleted = false AND (
      visibility = 'public'
      OR author_id = auth.uid()
      OR public.is_admin(auth.uid())
      OR (visibility = 'followers' AND EXISTS (
        SELECT 1 FROM public.follows WHERE follower_id = auth.uid() AND following_id = author_id
      ))
      OR (visibility = 'group' AND group_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.group_memberships
        WHERE group_id = posts.group_id AND user_id = auth.uid() AND status = 'active'
      ))
    )
  );

CREATE POLICY "Authenticated users can create posts"
  ON public.posts FOR INSERT
  WITH CHECK (auth.uid() = author_id AND auth.uid() IS NOT NULL);

CREATE POLICY "Authors can update own posts"
  ON public.posts FOR UPDATE
  USING (author_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Authors can soft-delete own posts"
  ON public.posts FOR DELETE
  USING (author_id = auth.uid() OR public.is_admin(auth.uid()));

-- =====================================================
-- COMMENTS
-- =====================================================
CREATE POLICY "Comments on visible posts are viewable"
  ON public.comments FOR SELECT
  USING (
    is_deleted = false AND EXISTS (
      SELECT 1 FROM public.posts p WHERE p.id = post_id AND p.is_deleted = false
    )
  );

CREATE POLICY "Authenticated users can comment"
  ON public.comments FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update own comments"
  ON public.comments FOR UPDATE
  USING (author_id = auth.uid() OR public.is_admin(auth.uid()));

-- =====================================================
-- REACTIONS
-- =====================================================
CREATE POLICY "Reactions are viewable"
  ON public.reactions FOR SELECT
  USING (true);

CREATE POLICY "Users can react"
  ON public.reactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove own reactions"
  ON public.reactions FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- FOLLOWS
-- =====================================================
CREATE POLICY "Follows are viewable"
  ON public.follows FOR SELECT
  USING (true);

CREATE POLICY "Users can follow"
  ON public.follows FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow"
  ON public.follows FOR DELETE
  USING (auth.uid() = follower_id);

-- =====================================================
-- GROUPS
-- =====================================================
CREATE POLICY "Public groups are viewable"
  ON public.groups FOR SELECT
  USING (
    group_type = 'public'
    OR created_by = auth.uid()
    OR public.is_admin(auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.group_memberships
      WHERE group_id = groups.id AND user_id = auth.uid() AND status = 'active'
    )
  );

CREATE POLICY "Authenticated users can create groups"
  ON public.groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Group admins can update groups"
  ON public.groups FOR UPDATE
  USING (
    created_by = auth.uid()
    OR public.is_admin(auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.group_memberships
      WHERE group_id = groups.id AND user_id = auth.uid() AND role IN ('admin', 'moderator') AND status = 'active'
    )
  );

-- =====================================================
-- GROUP MEMBERSHIPS
-- =====================================================
CREATE POLICY "Members can view group memberships"
  ON public.group_memberships FOR SELECT
  USING (
    user_id = auth.uid()
    OR public.is_admin(auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.group_memberships gm
      WHERE gm.group_id = group_memberships.group_id AND gm.user_id = auth.uid() AND gm.status = 'active'
    )
  );

CREATE POLICY "Users can join public groups"
  ON public.group_memberships FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave groups / admins can manage"
  ON public.group_memberships FOR DELETE
  USING (
    user_id = auth.uid()
    OR public.is_admin(auth.uid())
  );

-- =====================================================
-- CONVERSATIONS & MESSAGES (STRICT)
-- =====================================================
CREATE POLICY "Members can view their conversations"
  ON public.conversations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_members
      WHERE conversation_id = conversations.id AND user_id = auth.uid()
    )
    OR public.is_admin(auth.uid())
  );

CREATE POLICY "Authenticated users can create conversations"
  ON public.conversations FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Members can view conversation members"
  ON public.conversation_members FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.conversation_members cm
      WHERE cm.conversation_id = conversation_members.conversation_id AND cm.user_id = auth.uid()
    )
  );

CREATE POLICY "Only members can read messages"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_members
      WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
    )
    OR public.is_admin(auth.uid())
  );

CREATE POLICY "Members can send messages"
  ON public.messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM public.conversation_members
      WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Senders can update own messages"
  ON public.messages FOR UPDATE
  USING (sender_id = auth.uid());

-- =====================================================
-- RESOURCES
-- =====================================================
CREATE POLICY "Public resources are viewable"
  ON public.resources FOR SELECT
  USING (
    is_approved = true AND (
      visibility = 'public'
      OR uploader_id = auth.uid()
      OR public.is_admin(auth.uid())
    )
  );

CREATE POLICY "Authenticated users can upload resources"
  ON public.resources FOR INSERT
  WITH CHECK (auth.uid() = uploader_id);

CREATE POLICY "Uploaders can update own resources"
  ON public.resources FOR UPDATE
  USING (uploader_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Resource categories are public"
  ON public.resource_categories FOR SELECT
  USING (true);

-- =====================================================
-- NOTIFICATIONS
-- =====================================================
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (user_id = auth.uid());

-- =====================================================
-- REPORTS
-- =====================================================
CREATE POLICY "Users can create reports"
  ON public.reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view own reports, admins view all"
  ON public.reports FOR SELECT
  USING (reporter_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Admins can update reports"
  ON public.reports FOR UPDATE
  USING (public.is_admin(auth.uid()));

-- =====================================================
-- UPLOAD SETTINGS (CRITICAL)
-- =====================================================
-- Everyone authenticated can READ the current upload availability
CREATE POLICY "Authenticated users can read upload settings"
  ON public.upload_settings FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ONLY admins can UPDATE upload settings
CREATE POLICY "Only admins can update upload settings"
  ON public.upload_settings FOR UPDATE
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

CREATE POLICY "No direct insert into upload_settings"
  ON public.upload_settings FOR INSERT
  WITH CHECK (false);

CREATE POLICY "No delete of upload_settings"
  ON public.upload_settings FOR DELETE
  USING (false);

-- =====================================================
-- UPLOADED FILES
-- =====================================================
CREATE POLICY "Users can view own files"
  ON public.uploaded_files FOR SELECT
  USING (
    uploader_id = auth.uid()
    OR public.is_admin(auth.uid())
    OR is_public = true
  );

CREATE POLICY "Users can insert own files"
  ON public.uploaded_files FOR INSERT
  WITH CHECK (auth.uid() = uploader_id);

CREATE POLICY "Users can soft-delete own files"
  ON public.uploaded_files FOR UPDATE
  USING (uploader_id = auth.uid() OR public.is_admin(auth.uid()));

-- =====================================================
-- UPLOAD JOBS
-- =====================================================
CREATE POLICY "Users can view own upload jobs"
  ON public.upload_jobs FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Users can create upload jobs"
  ON public.upload_jobs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- STORAGE USAGE & EVENTS (Admin primarily)
-- =====================================================
CREATE POLICY "Admins can view storage usage"
  ON public.storage_usage FOR SELECT
  USING (public.is_admin(auth.uid()));

CREATE POLICY "Admins can view storage events"
  ON public.storage_events FOR SELECT
  USING (public.is_admin(auth.uid()));

CREATE POLICY "System can insert storage events"
  ON public.storage_events FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- =====================================================
-- PLATFORM SETTINGS
-- =====================================================
CREATE POLICY "Everyone can read platform settings"
  ON public.platform_settings FOR SELECT
  USING (true);

CREATE POLICY "Only super admins can update platform settings"
  ON public.platform_settings FOR UPDATE
  USING (public.is_super_admin(auth.uid()));

-- =====================================================
-- ADMIN ROLES
-- =====================================================
CREATE POLICY "Admins can view admin roles"
  ON public.admin_roles FOR SELECT
  USING (public.is_admin(auth.uid()) OR user_id = auth.uid());

CREATE POLICY "Only super admins can manage roles"
  ON public.admin_roles FOR ALL
  USING (public.is_super_admin(auth.uid()));

-- =====================================================
-- ADMIN AUDIT LOGS (immutable from frontend)
-- =====================================================
CREATE POLICY "Admins can view audit logs"
  ON public.admin_audit_logs FOR SELECT
  USING (public.is_admin(auth.uid()));

CREATE POLICY "Admins can insert audit logs"
  ON public.admin_audit_logs FOR INSERT
  WITH CHECK (public.is_admin(auth.uid()) AND actor_id = auth.uid());

-- No update or delete policies → immutable

-- =====================================================
-- EVENTS & OPPORTUNITIES
-- =====================================================
CREATE POLICY "Approved events are public"
  ON public.events FOR SELECT
  USING (is_approved = true OR organizer_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Authenticated users can create events"
  ON public.events FOR INSERT
  WITH CHECK (auth.uid() = organizer_id);

CREATE POLICY "Approved opportunities are public"
  ON public.opportunities FOR SELECT
  USING (is_approved = true OR poster_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Authenticated users can post opportunities"
  ON public.opportunities FOR INSERT
  WITH CHECK (auth.uid() = poster_id);

-- =====================================================
-- SUBJECTS & PROGRAMMES
-- =====================================================
CREATE POLICY "Subjects are public"
  ON public.subjects FOR SELECT
  USING (true);

CREATE POLICY "Programmes are public"
  ON public.programmes FOR SELECT
  USING (true);
