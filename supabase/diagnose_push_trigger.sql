-- Diagnostic only — doesn't change anything.

-- 1. Does the trigger exist and is it enabled? (already confirmed: yes, 'O')
select tgname, tgrelid::regclass as table_name, tgenabled
from pg_trigger
where tgname = 'on_message_insert_send_push';

-- 2. Actual history of pg_net responses (the queue table itself is only
-- a transient staging area — completed requests don't stay there, but
-- their responses persist here). Empty result = pg_net never even
-- attempted a request, which points at the trigger function itself
-- (or the extension) rather than the HTTP call failing.
select id, status_code, content, error_msg, created
from net._http_response
order by id desc
limit 10;
