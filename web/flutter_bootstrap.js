{{flutter_js}}
{{flutter_build_config}}

// A ogni pubblicazione il programma del sito cambia nome (?v=...): così il
// browser non può continuare a mostrare la versione vecchia che ha in memoria.
(function () {
  var v = {{flutter_service_worker_version}};
  _flutter.buildConfig.builds.forEach(function (b) {
    if (b && b.mainJsPath) b.mainJsPath += '?v=' + v;
  });
})();

// Le versioni precedenti installavano un "service worker" che può servire il
// sito vecchio dalla memoria del browser: lo si rimuove, con la sua cache.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(function (list) {
    list.forEach(function (r) { r.unregister(); });
  });
}
if (window.caches) {
  caches.keys().then(function (keys) {
    keys.forEach(function (k) { caches.delete(k); });
  });
}

_flutter.loader.load();
