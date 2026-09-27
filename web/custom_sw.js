// Handles Web Push, registered instead of Flutter's own
// flutter_service_worker.js — see web/flutter_bootstrap.js.
//
// This deliberately does NOT importScripts('flutter_service_worker.js'):
// in current Flutter web builds that generated file no longer does asset
// caching — its 'activate' handler just unregisters itself and reloads
// every open tab. Importing it here made *this* worker (push listeners
// included) self-destruct moments after installing, which is why push
// silently stopped working. Since it has nothing worth inheriting, this
// worker is fully standalone instead.
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', (event) => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (_) {
    data = { title: 'Together', body: event.data ? event.data.text() : '' };
  }

  const title = data.title || 'Together';
  const options = {
    body: data.body || 'Nuovo messaggio',
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
    data: { url: data.url || './' },
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  // Relative to this worker's own scope (e.g. https://host/together/), not
  // the origin root — the app can be deployed under a subpath, and a
  // plain '/' would land outside it.
  const relative = (event.notification.data && event.notification.data.url) || './';
  const url = new URL(relative, self.registration.scope).href;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        // An already-open tab needs to actually navigate to the target
        // conversation, not just come to the front — focus() alone left
        // it sitting on whatever screen it already had open.
        if ('navigate' in client) {
          return client.navigate(url).then((navigated) => (navigated || client).focus());
        }
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow(url);
    }),
  );
});
