import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Contratto di persistenza: un semplice archivio chiave → JSON.
///
/// Oggi i dati vivono nel browser ([LocalRepository]). Per condividerli tra
/// dispositivi e visitatori basta scrivere un'altra implementazione (l'API
/// su Cloudflare) con questi due metodi: tutto il resto dell'app non
/// cambia.
abstract class Repository {
  Future<Object?> read(String key);
  Future<void> write(String key, Object value);
}

class LocalRepository implements Repository {
  LocalRepository(this._prefs);
  final SharedPreferences _prefs;

  // v4: nuovi dati (caroselli separati, lavori in evidenza, modulo
  // preventivo, foto e video dei clienti). Si riparte dagli esempi.
  // v5: clienti d'esempio con cartelle e video. Si riparte dagli esempi.
  static const _prefix = 'studio.v5.';

  static Future<LocalRepository> open() async =>
      LocalRepository(await SharedPreferences.getInstance());

  @override
  Future<Object?> read(String key) async {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Object value) async {
    await _prefs.setString('$_prefix$key', jsonEncode(value));
  }
}
