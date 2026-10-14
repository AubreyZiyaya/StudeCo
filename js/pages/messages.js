import { supabase } from '../supabase-client.js';

export async function loadMessages() {
  const { data, error } = await supabase.from('messages').select('*').order('created_at', { ascending: false });
  if (error) throw error;
  return data || [];
}

export async function sendMessage({ conversation_id, content, sender_id }) {
  const { data, error } = await supabase
    .from('messages')
    .insert([
      {
        conversation_id,
        sender_id,
        content,
      },
    ])
    .select();

  if (error) throw error;
  return data?.[0];
}
