/// Chi vuole gestire da sé il tasto indietro del telefono (es. l'area
/// clienti: dentro una cartella torna alle cartelle). L'ultimo registrato
/// risponde per primo; se restituisce vero, il tasto è "usato" e l'app non
/// cambia pagina.
class BackHandlers {
  BackHandlers._();

  static final _handlers = <bool Function()>[];

  static void add(bool Function() f) => _handlers.add(f);
  static void remove(bool Function() f) => _handlers.remove(f);

  static bool handle() {
    for (final f in _handlers.reversed.toList()) {
      if (f()) return true;
    }
    return false;
  }

  /// Torna alla pagina precedente come farebbe il tasto indietro (lo imposta
  /// l'app): serve a chi ha fermato il tasto e poi decide di uscire.
  static void Function()? back;
}

/// Pagine che prima di essere lasciate possono chiedere conferma (es. un
/// editor del gestionale con modifiche non salvate).
class LeaveGuards {
  LeaveGuards._();

  static final _guards = <Future<bool> Function()>[];

  static void add(Future<bool> Function() f) => _guards.add(f);
  static void remove(Future<bool> Function() f) => _guards.remove(f);

  /// Vero se si può cambiare pagina.
  static Future<bool> canLeave() async {
    for (final f in _guards.reversed.toList()) {
      if (!await f()) return false;
    }
    return true;
  }
}
