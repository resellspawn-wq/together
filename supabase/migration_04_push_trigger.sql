-- Migration 04: wires up sending a push notification on every new
-- message, via a direct SQL trigger + pg_net instead of the Database
-- Webhooks UI (some projects are missing the internal
-- "supabase_functions" schema that UI depends on — this works either
-- way, since pg_net is enabled on every Supabase project by default).
--
-- BEFORE RUNNING: replace YOUR_SERVICE_ROLE_KEY below with your actual
-- service_role key (Project Settings → API → "service_role" — NOT the
-- anon key). It's safe to store here: this function is only ever
-- readable/editable by the project owner in the SQL editor, same as any
-- other database object. Never put the real key in this file on disk
-- though — fill it in only inside the Supabase SQL Editor itself.

create extension if not exists pg_net;

create or replace function public.trigger_send_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform net.http_post(
    url := 'https://tsvjeixnqicbxtxpxqar.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body := jsonb_build_object('record', to_jsonb(new))
  );
  return new;
end;
$$;

drop trigger if exists on_message_insert_send_push on public.messages;
create trigger on_message_insert_send_push
  after insert on public.messages
  for each row execute function public.trigger_send_push();
