import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
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
    if (changed) {
      _apply();
      _publish();
    }
  }

  static bool get hidden => _hiding.isNotEmpty;

  /// Vero quando le foto vanno a tutto schermo: la cornice dell'app (vedi
  /// app.dart) smette di riservare lo spazio di notch e lineetta dell'iPhone.
  static final fullScreen = ValueNotifier<bool>(false);

  static void _publish() {
    // Chi lo chiede può essere nel mezzo del disegno di una pagina.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => fullScreen.value = hidden,
      );
      SchedulerBinding.instance.ensureVisualUpdate();
    } else {
      fullScreen.value = hidden;
    }
  }

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
