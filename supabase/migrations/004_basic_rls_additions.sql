-- 004_basic_rls_additions.sql
-- Enable RLS and create baseline policies for commonly-used tables.
-- Review and customize these for your platform rules before using in production.

-- Helper function assumed present from previous file:
-- current_profile_id() returns uuid from profiles where auth_uid = auth.uid()

-- Enable RLS on commonly accessed tables
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE upload_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage_events ENABLE ROW LEVEL SECURITY;

-- Groups: public read, members can select private
CREATE POLICY "groups_select_public_or_member" ON groups
  FOR SELECT USING (
    visibility = 'public' OR owner_id = current_profile_id() OR EXISTS (
      SELECT 1 FROM group_memberships gm WHERE gm.group_id = groups.id AND gm.profile_id = current_profile_id()
    )
  );

CREATE POLICY "groups_insert_authenticated" ON groups
  FOR INSERT WITH CHECK (owner_id = current_profile_id());

CREATE POLICY "groups_update_owner_or_admin" ON groups
  FOR UPDATE USING (owner_id = current_profile_id() OR EXISTS (SELECT 1 FROM admin_roles ar WHERE ar.profile_id = current_profile_id()))
  WITH CHECK (owner_id = current_profile_id() OR EXISTS (SELECT 1 FROM admin_roles ar WHERE ar.profile_id = current_profile_id()));

-- Comments: allow select where post visible; basic owner insert
CREATE POLICY "comments_select_for_post" ON comments
  FOR SELECT USING (TRUE); -- refine to check post visibility as needed

CREATE POLICY "comments_insert_authenticated" ON comments
  FOR INSERT WITH CHECK (author_id = current_profile_id());

CREATE POLICY "comments_update_own_or_moderator" ON comments
  FOR UPDATE USING (author_id = current_profile_id() OR EXISTS (SELECT 1 FROM admin_roles ar WHERE ar.profile_id = current_profile_id()))
  WITH CHECK (author_id = current_profile_id() OR EXISTS (SELECT 1 FROM admin_roles ar WHERE ar.profile_id = current_profile_id()));

-- Reactions: allow select public, insert by authenticated
CREATE POLICY "reactions_select_public" ON reactions FOR SELECT USING (TRUE);
CREATE POLICY "reactions_insert_authenticated" ON reactions FOR INSERT WITH CHECK (profile_id = current_profile_id());

-- Follows: allow insert for current user
CREATE POLICY "follows_insert_self" ON follows FOR INSERT WITH CHECK (follower_id = current_profile_id());
CREATE POLICY "follows_select_public" ON follows FOR SELECT USING (TRUE);

-- Resources & resource_files: public select for non-deleted, insert by uploader
CREATE POLICY "resources_select_public" ON resources FOR SELECT USING (deleted = false OR uploader_id = current_profile_id());
CREATE POLICY "resources_insert_authenticated" ON resources FOR INSERT WITH CHECK (uploader_id = current_profile_id());

CREATE POLICY "resource_files_select_owner_or_resource" ON resource_files
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM resources r WHERE r.id = resource_files.resource_id AND (r.uploader_id = current_profile_id() OR r.institution_id IS NULL))
  );

-- Events: public read, registrations by authenticated
CREATE POLICY "events_select_public" ON events FOR SELECT USING (TRUE);
CREATE POLICY "event_registrations_insert_self" ON event_registrations FOR INSERT WITH CHECK (profile_id = current_profile_id());

-- Opportunities: public read
CREATE POLICY "opportunities_select_public" ON opportunities FOR SELECT USING (TRUE);
CREATE POLICY "opportunities_insert_authenticated" ON opportunities FOR INSERT WITH CHECK (poster_id = current_profile_id());

-- Reports: allow insert for authenticated reporters
CREATE POLICY "reports_insert_authenticated" ON reports FOR INSERT WITH CHECK (reporter_id = current_profile_id());
CREATE POLICY "reports_select_admins" ON reports FOR SELECT USING (EXISTS (SELECT 1 FROM admin_roles ar WHERE ar.profile_id = current_profile_id()));

-- Upload jobs: allow insert for uploader, select for uploader or admins
CREATE POLICY "upload_jobs_insert_self" ON upload_jobs FOR INSERT WITH CHECK (uploader_id = current_profile_id());
CREATE POLICY "upload_jobs_select_owner_or_admin" ON upload_jobs FOR SELECT USING (uploader_id = current_profile_id() OR EXISTS (SELECT 1 FROM admin_roles ar WHERE ar.profile_id = current_profile_id()));

-- Storage usage/events: admin read-only
CREATE POLICY "storage_usage_admin" ON storage_usage FOR SELECT USING (EXISTS (SELECT 1 FROM admin_roles ar WHERE ar.profile_id = current_profile_id()));
CREATE POLICY "storage_events_admin" ON storage_events FOR SELECT USING (EXISTS (SELECT 1 FROM admin_roles ar WHERE ar.profile_id = current_profile_id()));

-- Note: These policies are a baseline. You must adapt and test them thoroughly for your requirements.
