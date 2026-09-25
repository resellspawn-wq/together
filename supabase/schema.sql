-- Together — Supabase schema + Row Level Security
--
-- Run this once in your Supabase project's SQL Editor (Free tier is enough
-- for this MVP). It is idempotent-ish (uses IF NOT EXISTS / OR REPLACE)
-- so it is safe to re-run while iterating.
--
-- After running this, go to Database > Replication and make sure the
-- "messages" table (added below via ALTER PUBLICATION) is enabled for
-- Realtime — the ALTER PUBLICATION statement below does this for you,
-- but double-check it in the dashboard if realtime doesn't seem to fire.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.alphabets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null default 'Il mio alfabeto',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists alphabets_user_id_idx on public.alphabets (user_id);

create table if not exists public.glyphs (
  id uuid primary key default gen_random_uuid(),
  alphabet_id uuid not null references public.alphabets (id) on delete cascade,
  character text not null check (char_length(character) = 1),
  strokes jsonb not null default '[]'::jsonb,
  width double precision not null,
  height double precision not null,
  baseline double precision not null,
  updated_at timestamptz not null default now(),
  unique (alphabet_id, character)
);
create index if not exists glyphs_alphabet_id_idx on public.glyphs (alphabet_id);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);

-- user_id/sender_id below reference profiles(id), not auth.users(id)
-- directly: PostgREST can only auto-embed a related row (e.g.
-- `profiles(username)` from a conversation_members query) when there is a
-- direct foreign key between the two tables being queried. profiles.id
-- already equals auth.users.id 1:1 (set by the signup trigger above), so
-- this is safe and is what makes ConversationRepository's embedded
-- selects work.
create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);
create index if not exists messages_conversation_created_idx
  on public.messages (conversation_id, created_at);

-- ---------------------------------------------------------------------
-- Auto-create a profile row whenever someone signs up.
-- Username/display name come from the signUp() call's `data` payload.
-- ---------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', 'user_' || substr(new.id::text, 1, 8)),
    coalesce(new.raw_user_meta_data ->> 'display_name', new.raw_user_meta_data ->> 'username', 'Utente')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- Helper functions used by RLS policies (security definer = bypasses RLS
-- internally, but only ever returns a boolean / does a scoped lookup, so
-- it cannot be used to leak data).
-- ---------------------------------------------------------------------

-- True if the current user shares at least one conversation with `other_user`.
-- Used so Eliza is allowed to read Vlad's alphabet/glyphs to render his
-- messages, without being able to read a stranger's alphabet.
create or replace function public.shares_conversation_with(other_user uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.conversation_members cm1
    join public.conversation_members cm2 on cm1.conversation_id = cm2.conversation_id
    where cm1.user_id = auth.uid()
      and cm2.user_id = other_user
  );
$$;

create or replace function public.is_conversation_member(conv_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = conv_id and user_id = auth.uid()
  );
$$;

-- Atomically starts (or reuses) a 1-to-1 conversation with a user found by
-- username. Runs as security definer so it can insert the *other* user's
-- conversation_members row too — the client can never do that directly
-- (see the conversation_members policies below, which allow no direct
-- inserts at all).
create or replace function public.start_conversation_with_username(target_username text)
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
    return existing_conv;
  end if;

  insert into public.conversations default values returning id into conv_id;
  insert into public.conversation_members (conversation_id, user_id) values (conv_id, auth.uid());
  insert into public.conversation_members (conversation_id, user_id) values (conv_id, target_id);
  return conv_id;
end;
$$;

-- ---------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.alphabets enable row level security;
alter table public.glyphs enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

-- profiles: readable by any signed-in user (needed for @username search
-- and to show a sender's display name); a profile has no sensitive data
-- beyond a public username/display name. Writable only by its owner.
drop policy if exists "profiles readable by authenticated" on public.profiles;
create policy "profiles readable by authenticated" on public.profiles
  for select using (auth.role() = 'authenticated');

drop policy if exists "profiles insert own" on public.profiles;
create policy "profiles insert own" on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles
  for update using (auth.uid() = id);

-- alphabets: own alphabet, or a conversation partner's (to render their
-- messages with their handwriting). Writable only by the owner.
drop policy if exists "alphabets select own or partner" on public.alphabets;
create policy "alphabets select own or partner" on public.alphabets
  for select using (
    user_id = auth.uid() or public.shares_conversation_with(user_id)
  );

drop policy if exists "alphabets write own" on public.alphabets;
create policy "alphabets write own" on public.alphabets
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- glyphs: same rule as alphabets, resolved through the parent alphabet.
drop policy if exists "glyphs select own or partner" on public.glyphs;
create policy "glyphs select own or partner" on public.glyphs
  for select using (
    exists (
      select 1 from public.alphabets a
      where a.id = glyphs.alphabet_id
        and (a.user_id = auth.uid() or public.shares_conversation_with(a.user_id))
    )
  );

drop policy if exists "glyphs write own" on public.glyphs;
create policy "glyphs write own" on public.glyphs
  for all using (
    exists (select 1 from public.alphabets a where a.id = glyphs.alphabet_id and a.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.alphabets a where a.id = glyphs.alphabet_id and a.user_id = auth.uid())
  );

-- conversations: visible only to members. No direct client inserts —
-- conversations are created exclusively via start_conversation_with_username().
drop policy if exists "conversations select member" on public.conversations;
create policy "conversations select member" on public.conversations
  for select using (public.is_conversation_member(id));

-- conversation_members: visible to any member of that conversation (so you
-- can see who the *other* member is). No direct client inserts/updates/
-- deletes — membership is only ever created via the RPC above.
drop policy if exists "conversation_members select member" on public.conversation_members;
create policy "conversation_members select member" on public.conversation_members
  for select using (public.is_conversation_member(conversation_id));

-- messages: visible to conversation members; only a member can insert a
-- message, and only as themselves.
drop policy if exists "messages select member" on public.messages;
create policy "messages select member" on public.messages
  for select using (public.is_conversation_member(conversation_id));

drop policy if exists "messages insert own in own conversation" on public.messages;
create policy "messages insert own in own conversation" on public.messages
  for insert with check (
    sender_id = auth.uid() and public.is_conversation_member(conversation_id)
  );

-- ---------------------------------------------------------------------
-- Realtime: broadcast row changes on messages so open chats update live.
-- ---------------------------------------------------------------------
alter publication supabase_realtime add table public.messages;
