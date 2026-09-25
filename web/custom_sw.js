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
  const url = (event.notification.data && event.notification.data.url) || './';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow(url);
    }),
  );
});
