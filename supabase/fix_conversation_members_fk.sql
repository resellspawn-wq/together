-- One-time fix for projects that already ran the original schema.sql.
-- conversation_members.user_id and messages.sender_id pointed at
-- auth.users(id); PostgREST needs a direct FK to profiles(id) to embed
-- profile data in queries (this is what made "Conversazioni" fail with a
-- 400 error). Safe to run even if already applied.

alter table public.conversation_members
  drop constraint if exists conversation_members_user_id_fkey;
alter table public.conversation_members
  add constraint conversation_members_user_id_fkey
  foreign key (user_id) references public.profiles (id) on delete cascade;

alter table public.messages
  drop constraint if exists messages_sender_id_fkey;
alter table public.messages
  add constraint messages_sender_id_fkey
  foreign key (sender_id) references public.profiles (id) on delete cascade;
