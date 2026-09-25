// Wraps Flutter's own generated service worker (offline caching) and adds
// Web Push handling on top of it. Registered instead of
// flutter_service_worker.js directly — see web/flutter_bootstrap.js.
importScripts('flutter_service_worker.js');

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
