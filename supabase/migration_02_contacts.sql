-- Migration 02: per-contact nickname + ability to clear/delete a
-- conversation. Run this once in the SQL Editor (safe to re-run).

-- Each member can privately name their side of a 1-1 conversation
-- (e.g. Vlad can call it "Eliza ❤️" while Eliza calls it "Vlad").
alter table public.conversation_members
  add column if not exists nickname text;

-- A member can rename their own side of a conversation.
drop policy if exists "conversation_members update own nickname" on public.conversation_members;
create policy "conversation_members update own nickname" on public.conversation_members
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- "Svuota chat": any member can clear the shared message history.
drop policy if exists "messages delete by member" on public.messages;
create policy "messages delete by member" on public.messages
  for delete using (public.is_conversation_member(conversation_id));

-- "Elimina contatto": any member can delete the conversation outright;
-- conversation_members and messages cascade-delete with it (both already
-- reference conversations.id with ON DELETE CASCADE).
drop policy if exists "conversations delete by member" on public.conversations;
create policy "conversations delete by member" on public.conversations
  for delete using (public.is_conversation_member(id));

-- Let start_conversation_with_username set an initial nickname for the
-- person creating the conversation (what they typed when adding the
-- contact), instead of always falling back to the other user's profile
-- display_name.
create or replace function public.start_conversation_with_username(
  target_username text,
  p_nickname text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_id uuid;
  conv_id uuid;
  existing_conv uuid;
begin
  select id into target_id from public.profiles where username = target_username;
  if target_id is null then
    raise exception 'Nessun utente trovato con username %', target_username;
  end if;
  if target_id = auth.uid() then
    raise exception 'Non puoi avviare una conversazione con te stesso';
  end if;

  select cm1.conversation_id into existing_conv
  from public.conversation_members cm1
  join public.conversation_members cm2 on cm1.conversation_id = cm2.conversation_id
  where cm1.user_id = auth.uid() and cm2.user_id = target_id
  limit 1;

  if existing_conv is not null then
    if p_nickname is not null and length(trim(p_nickname)) > 0 then
      update public.conversation_members
        set nickname = p_nickname
        where conversation_id = existing_conv and user_id = auth.uid();
    end if;
    return existing_conv;
  end if;

  insert into public.conversations default values returning id into conv_id;
  insert into public.conversation_members (conversation_id, user_id, nickname)
    values (conv_id, auth.uid(), nullif(trim(coalesce(p_nickname, '')), ''));
  insert into public.conversation_members (conversation_id, user_id)
    values (conv_id, target_id);
  return conv_id;
end;
$$;
