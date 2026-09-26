-- Migration 06: profile photos. Run once in the SQL Editor.

alter table public.profiles add column if not exists avatar_url text;

-- A user can rename themselves and set their own avatar_url.
-- (profiles update own already existed; this just re-affirms full-row
-- update stays scoped to your own id — no change needed there.)

-- Storage bucket for avatar images, public read (so <img>/CircleAvatar
-- can load them directly by URL), writes restricted to the owner.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "avatar images are publicly readable" on storage.objects;
create policy "avatar images are publicly readable" on storage.objects
  for select using (bucket_id = 'avatars');

-- Files are stored as "<user_id>/avatar.<ext>" — the policy checks that
-- the path's first segment matches the uploader's own id.
drop policy if exists "users can upload their own avatar" on storage.objects;
create policy "users can upload their own avatar" on storage.objects
  for insert with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users can update their own avatar" on storage.objects;
create policy "users can update their own avatar" on storage.objects
  for update using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
