// Seleziona l'implementazione giusta: su web usa Google Identity Services,
// altrove (test, desktop) restituisce un errore esplicito.
export 'google_auth_stub.dart'
    if (dart.library.js_interop) 'google_auth_web.dart';
