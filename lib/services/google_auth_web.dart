import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'google_token.dart';

JSObject? _oauth2() {
  final google = globalContext.getProperty<JSAny?>('google'.toJS);
  if (google.isUndefinedOrNull) return null;
  final accounts = (google as JSObject).getProperty<JSAny?>('accounts'.toJS);
  if (accounts.isUndefinedOrNull) return null;
  final oauth2 = (accounts as JSObject).getProperty<JSAny?>('oauth2'.toJS);
  if (oauth2.isUndefinedOrNull) return null;
  return oauth2 as JSObject;
}

Future<JSObject> _waitForGis() async {
  for (var i = 0; i < 50; i++) {
    final o = _oauth2();
    if (o != null) return o;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw GoogleAuthException(
    'Impossibile caricare Google Identity Services. Controlla la connessione '
    'o eventuali blocchi dello script accounts.google.com.',
  );
}

/// Apre il popup di consenso Google e restituisce un access token.
/// Va chiamata direttamente dal click di un pulsante (altrimenti il browser
/// blocca il popup).
Future<GoogleToken> requestGoogleAccessToken({
  required String clientId,
  required String scope,
  String prompt = '',
}) async {
  final oauth2 = await _waitForGis();
  final completer = Completer<GoogleToken>();

  final config = JSObject();
  config['client_id'] = clientId.toJS;
  config['scope'] = scope.toJS;
  config['callback'] = ((JSObject resp) {
    final error = resp.getProperty<JSString?>('error'.toJS)?.toDart;
    if (error != null) {
      final desc = resp
          .getProperty<JSString?>('error_description'.toJS)
          ?.toDart;
      if (!completer.isCompleted) {
        completer.completeError(GoogleAuthException(desc ?? error));
      }
      return;
    }
    final token = resp.getProperty<JSString?>('access_token'.toJS)?.toDart;
    final expires =
        resp.getProperty<JSNumber?>('expires_in'.toJS)?.toDartInt ?? 3600;
    if (token == null) {
      if (!completer.isCompleted) {
        completer.completeError(GoogleAuthException('Nessun token ricevuto.'));
      }
      return;
    }
    if (!completer.isCompleted) {
      completer.complete(
        GoogleToken(token, DateTime.now().add(Duration(seconds: expires))),
      );
    }
  }).toJS;
  config['error_callback'] = ((JSObject err) {
    final type = err.getProperty<JSString?>('type'.toJS)?.toDart ?? 'errore';
    if (!completer.isCompleted) {
      completer.completeError(
        GoogleAuthException(
          type == 'popup_closed'
              ? 'Finestra di accesso chiusa prima del completamento.'
              : type == 'popup_failed_to_open'
              ? 'Il browser ha bloccato la finestra di accesso Google.'
              : 'Accesso Google non riuscito ($type).',
        ),
      );
    }
  }).toJS;

  final client = oauth2.callMethod<JSObject>('initTokenClient'.toJS, config);
  final override = JSObject();
  override['prompt'] = prompt.toJS;
  client.callMethod<JSAny?>('requestAccessToken'.toJS, override);
  return completer.future;
}
