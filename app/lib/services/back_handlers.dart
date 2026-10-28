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
}
