-- Migration 03: Web Push subscriptions. Run this once in the SQL Editor.
--
-- This only creates the table that stores each device's push
-- subscription. The actual "send a push on new message" trigger is set
-- up separately as a Database Webhook in the Supabase dashboard (no SQL
-- needed there — see the deploy notes for send-push), because that UI
-- already wires up pg_net + secrets for you instead of hand-rolling them
-- in SQL with hardcoded URLs/keys.

create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  created_at timestamptz not null default now()
);

create index if not exists push_subscriptions_user_id_idx on public.push_subscriptions (user_id);

alter table public.push_subscriptions enable row level security;

-- A user manages only their own subscriptions from the client.
drop policy if exists "push_subscriptions select own" on public.push_subscriptions;
create policy "push_subscriptions select own" on public.push_subscriptions
  for select using (user_id = auth.uid());

drop policy if exists "push_subscriptions insert own" on public.push_subscriptions;
create policy "push_subscriptions insert own" on public.push_subscriptions
  for insert with check (user_id = auth.uid());

drop policy if exists "push_subscriptions delete own" on public.push_subscriptions;
create policy "push_subscriptions delete own" on public.push_subscriptions
  for delete using (user_id = auth.uid());

-- The send-push Edge Function reads subscriptions for the *other* member
-- of a conversation using the service_role key, which bypasses RLS
-- entirely — no extra policy needed for that.
