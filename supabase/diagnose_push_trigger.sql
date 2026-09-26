-- Diagnostic only — doesn't change anything. Run in the SQL Editor and
-- paste back the results.

-- 1. Does the trigger exist and is it enabled?
select tgname, tgrelid::regclass as table_name, tgenabled
from pg_trigger
where tgname = 'on_message_insert_send_push';

-- 2. The most recent pg_net HTTP requests this trigger queued, and their
-- actual responses (or errors) — this is where a silent failure shows up.
select
  req.id,
  req.url,
  req.headers,
  resp.status_code,
  resp.content,
  resp.error_msg,
  resp.created as responded_at
from net.http_request_queue req
left join net._http_response resp on resp.id = req.id
order by req.id desc
limit 5;
