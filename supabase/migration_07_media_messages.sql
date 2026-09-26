-- Migration 07: photo/video messages. Run once in the SQL Editor.

alter table public.messages alter column text drop not null;
alter table public.messages add column if not exists attachment_url text;
alter table public.messages add column if not exists attachment_type text check (attachment_type in ('image', 'video'));

-- Storage bucket for chat attachments, public read (so <img>/<video> tags
-- can load them directly by URL), writes restricted to conversation
-- members. Files are stored as "<conversation_id>/<uuid>.<ext>".
insert into storage.buckets (id, name, public)
values ('attachments', 'attachments', true)
on conflict (id) do nothing;

drop policy if exists "attachments are publicly readable" on storage.objects;
create policy "attachments are publicly readable" on storage.objects
  for select using (bucket_id = 'attachments');

drop policy if exists "conversation members can upload attachments" on storage.objects;
create policy "conversation members can upload attachments" on storage.objects
  for insert with check (
    bucket_id = 'attachments'
    and public.is_conversation_member((storage.foldername(name))[1]::uuid)
  );

drop policy if exists "conversation members can delete attachments" on storage.objects;
create policy "conversation members can delete attachments" on storage.objects
  for delete using (
    bucket_id = 'attachments'
    and public.is_conversation_member((storage.foldername(name))[1]::uuid)
  );
