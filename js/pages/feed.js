import { supabase } from "../supabase-client.js";
import { getCurrentUser } from "../supabase-client.js";

export async function loadFeed() {
  const { data: userData, error: userErr } = await getCurrentUser();
  if (userErr || !userData?.user) {
    window.location.href = "../login.html";
    return [];
  }

  const { data, error } = await supabase
    .from("posts")
    .select("*")
    .eq("deleted", false)
    .order("created_at", { ascending: false })
    .limit(20);

  if (error) {
    console.error(error);
    return [];
  }

  return data || [];
}

export async function createPost({ content, visibility = "public" }) {
  const { data: userData } = await getCurrentUser();

  const { data, error } = await supabase
    .from("posts")
    .insert([
      {
        author_id: userData.user.id,
        content,
        visibility,
      },
    ])
    .select();

  if (error) throw error;
  return data?.[0];
}
