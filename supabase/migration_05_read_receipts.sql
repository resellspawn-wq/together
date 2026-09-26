-- Migration 05: WhatsApp-style delivered/read receipts. Run once in the
-- SQL Editor.

alter table public.messages add column if not exists delivered_at timestamptz;
alter table public.messages add column if not exists read_at timestamptz;

-- Any member of the conversation can mark a message delivered/read —
-- needed so the *recipient* (not the sender) can stamp these columns.
-- A personal 2-person app doesn't need finer-grained column-level checks.
drop policy if exists "messages update receipts by member" on public.messages;
create policy "messages update receipts by member" on public.messages
  for update using (public.is_conversation_member(conversation_id))
  with check (public.is_conversation_member(conversation_id));
