import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Le barre del telefono (ora e batteria in alto, tasti o lineetta di Android
/// e iPhone in basso): nascoste dove contano le foto — il carosello
/// d'apertura e le foto a schermo intero — e visibili, bianche come l'app,
/// in tutto il resto. Strisciando dal bordo ricompaiono per qualche secondo.
class SystemBars {
  SystemBars._();

  /// Chi chiede le barre nascoste in questo momento (carosello, visore...).
  static final _hiding = <Object>{};
  static bool? _applied;

  /// [who] chiede (o smette di chiedere) lo schermo intero.
  static void hide(Object who, bool on) {
    final changed = on ? _hiding.add(who) : _hiding.remove(who);
    if (changed) _apply();
  }

  static bool get hidden => _hiding.isNotEmpty;

  static void _apply() {
    if (kIsWeb) return;
    final full = _hiding.isNotEmpty;
    if (_applied == full) return;
    _applied = full;
    SystemChrome.setEnabledSystemUIMode(
      full ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }
}
