import { supabase } from "../supabase-client.js";

export async function loadUploadSettings() {
  const { data, error } = await supabase.from("upload_settings").select("*").limit(1);
  if (error) throw error;
  return data?.[0] || null;
}

export async function saveUploadSettings(settingsPayload) {
  const existing = await supabase.from("upload_settings").select("id").limit(1);
  const id = existing?.data?.[0]?.id || null;

  if (!id) throw new Error('No upload_settings row found.');

  const nextVersion = Number(settingsPayload.version || 0) + 1;
  const { data, error } = await supabase
    .from("upload_settings")
    .update({ ...settingsPayload, version: nextVersion, updated_at: new Date().toISOString() })
    .eq("id", id)
    .select();

  if (error) throw error;
  return data?.[0];
}

export function buildDefaultAdminMessage() {
  return {
    title: 'Uploads Temporarily Unavailable',
    message: 'StudeCo has temporarily reached its current upload capacity. Your existing account and academic resources remain accessible. Please try again later or contact the support team for assistance.',
    short_notice: 'Uploads are temporarily unavailable.',
    contact_email: 'support@studeco.example',
    support_url: 'https://example.com/support',
  };
}
