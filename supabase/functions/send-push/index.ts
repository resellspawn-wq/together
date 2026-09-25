// Sends a Web Push notification to the *other* member of a conversation
// whenever a new message is inserted. Wired up as a Supabase Database
// Webhook (Database → Webhooks in the dashboard) on messages / INSERT,
// pointing at this function — see supabase/PUSH_NOTIFICATIONS.md for the
// exact setup steps.
//
// Needs three secrets set on this function (`supabase secrets set ...`),
// none of which are the Supabase defaults:
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT (e.g. "mailto:you@example.com")
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically by
// the Edge Functions runtime.

import { createClient } from 'npm:@supabase/supabase-js@2';
import webpush from 'npm:web-push@3';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

webpush.setVapidDetails(
  Deno.env.get('VAPID_SUBJECT')!,
  Deno.env.get('VAPID_PUBLIC_KEY')!,
  Deno.env.get('VAPID_PRIVATE_KEY')!,
);

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const message = payload.record;
    if (!message?.conversation_id || !message?.sender_id) {
      return new Response('ignored: not a message insert', { status: 200 });
    }

    const { data: members } = await supabase
      .from('conversation_members')
      .select('user_id')
      .eq('conversation_id', message.conversation_id)
      .neq('user_id', message.sender_id);

    const recipientIds = (members ?? []).map((m) => m.user_id);
    if (recipientIds.length === 0) {
      return new Response('no recipients', { status: 200 });
    }

    const { data: sender } = await supabase
      .from('profiles')
      .select('display_name')
      .eq('id', message.sender_id)
      .maybeSingle();

    const { data: subscriptions } = await supabase
      .from('push_subscriptions')
      .select('id, endpoint, p256dh, auth')
      .in('user_id', recipientIds);

    if (!subscriptions || subscriptions.length === 0) {
      return new Response('no subscriptions', { status: 200 });
    }

    const notificationPayload = JSON.stringify({
      title: sender?.display_name ?? 'Together',
      body: (message.text as string).slice(0, 120),
      url: '/',
    });

    const results = await Promise.allSettled(
      subscriptions.map((sub) =>
        webpush.sendNotification(
          {
            endpoint: sub.endpoint,
            keys: { p256dh: sub.p256dh, auth: sub.auth },
          },
          notificationPayload,
        ).catch(async (err: { statusCode?: number }) => {
          // Subscription no longer valid (unsubscribed, expired, browser
          // data cleared) — remove it so future sends don't keep failing.
          if (err?.statusCode === 404 || err?.statusCode === 410) {
            await supabase.from('push_subscriptions').delete().eq('id', sub.id);
          }
          throw err;
        }),
      ),
    );

    const sent = results.filter((r) => r.status === 'fulfilled').length;
    return new Response(`sent ${sent}/${subscriptions.length}`, { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(`error: ${error}`, { status: 500 });
  }
});
