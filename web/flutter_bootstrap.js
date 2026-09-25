// Custom bootstrap (flutter build web keeps this file as-is instead of
// generating its default one) — the only change from Flutter's default
// bootstrap is pointing the service worker registration at custom_sw.js
// instead of flutter_service_worker.js, so Web Push notifications work
// (custom_sw.js internally imports flutter_service_worker.js, so offline
// caching behaves exactly the same as before).
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
    serviceWorkerUrl: 'custom_sw.js?v=' + {{flutter_service_worker_version}}
  }
});
