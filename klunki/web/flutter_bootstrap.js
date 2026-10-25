{{flutter_js}}
{{flutter_build_config}}
// Klunki custom bootstrap (KLD-010).
// - No `serviceWorkerSettings`: Flutter's deprecated flutter_service_worker.js
//   is a self-unregistering cleanup worker. If flutter.js registered it, it
//   would take over our scope and unregister klunki_sw.js. index.html
//   registers klunki_sw.js instead.
// - CanvasKit is loaded from the app's own origin (not www.gstatic.com) so
//   klunki_sw.js can cache it and the app starts offline.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
