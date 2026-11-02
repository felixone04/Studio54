import 'package:flutter/material.dart';

import 'line_icons.dart';

import 'package:flutter/services.dart';

import '../services/system_bars.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'sections.dart' show RoundIconButton;

/// Le foto a schermo intero: solo la foto, grande, con le frecce e la X per
/// uscire. Si sfogliano anche con il dito e si ingrandiscono con due dita.
Future<void> showPhotoViewer(
  BuildContext context,
  List<String> photos,
  int start, {
  List<Widget> Function(BuildContext, int)? actions,
}) {
  return showGeneralDialog(
    context: context,
    barrierColor: Palette.paper,
    barrierDismissible: true,
    barrierLabel: 'Chiudi',
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (_, a, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: child,
    ),
    pageBuilder: (_, _, _) =>
        PhotoViewer(photos: photos, start: start, actions: actions),
  );
}

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.photos,
    required this.start,
    this.actions,
    this.itemBuilder,
  });
  final List<String> photos;
  final int start;

  /// Comandi in più in basso (es. "Scarica" nell'area clienti).
  final List<Widget> Function(BuildContext, int)? actions;

  /// Al posto della foto (es. un video).
  final Widget? Function(BuildContext, int)? itemBuilder;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer>
    with SingleTickerProviderStateMixin {
  late int _i = widget.start;

  /// La foto che esce: resta piena sotto mentre la nuova compare sfumando.
  int? _prev;
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );
  late final _fadeIn = CurvedAnimation(parent: _fade, curve: Curves.easeOut);

  /// Conta i cambi di foto: se nel frattempo se ne chiede un'altra, quella
  /// ancora in arrivo non si mostra più.
  int _turn = 0;

  /// Foto ingrandita: il dito la sposta invece di sfogliare.
  bool _zoomed = false;
  double _dragX = 0;

  @override
  void initState() {
    super.initState();
    // Solo la foto: le barre del telefono si nascondono.
    SystemBars.hide(this, true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareNear());
  }

  @override
  void dispose() {
    SystemBars.hide(this, false);
    _fadeIn.dispose();
    _fade.dispose();
    super.dispose();
  }

  int _wrap(int k) {
    final n = widget.photos.length;
    return (k % n + n) % n;
  }

  /// La foto [k] scaricata in anticipo, grande come lo schermo.
  Future<void> _prepare(int k) async {
    if (!mounted || widget.itemBuilder?.call(context, k) != null) return;
    final p = PhotoImage.providerFor(
      context,
      widget.photos[k],
      MediaQuery.sizeOf(context).width,
    );
    if (p != null) await precacheImage(p, context, onError: (_, _) {});
  }

  /// La foto dopo e quella prima, pronte prima che si chiedano.
  void _prepareNear() {
    if (widget.photos.length < 2) return;
    _prepare(_wrap(_i + 1));
    _prepare(_wrap(_i - 1));
  }

  /// Cambia foto quando la nuova è pronta (al massimo dopo 2,5 secondi):
  /// compare sfumando sopra la vecchia, senza un lampo bianco in mezzo.
  Future<void> _go(int d) async {
    final next = _wrap(_i + d);
    final turn = ++_turn;
    await _prepare(next)
        .timeout(const Duration(milliseconds: 2500), onTimeout: () {});
    if (!mounted || turn != _turn || next == _i) return;
    setState(() {
      _prev = _i;
      _i = next;
      _zoomed = false;
    });
    _fade.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && turn == _turn) setState(() => _prev = null);
    });
    _prepareNear();
  }

  Widget _item(int k) =>
      widget.itemBuilder?.call(context, k) ??
      _ZoomablePhoto(
        url: widget.photos[k],
        onZoom: (z) {
          if (k == _i && z != _zoomed) setState(() => _zoomed = z);
        },
      );

  @override
  Widget build(BuildContext context) {
    final many = widget.photos.length > 1;
    final pad = MediaQuery.paddingOf(context);
    final actions = widget.actions?.call(context, _i) ?? const <Widget>[];
    // Stessa struttura per la foto che esce e per quella che entra: la
    // vecchia non si ricrea passando sotto.
    Widget layer(int k, Animation<double> opacity) => KeyedSubtree(
      key: ValueKey(k),
      child: FadeTransition(opacity: opacity, child: _item(k)),
    );
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowRight && many) {
          _go(1);
        } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft && many) {
          _go(-1);
        } else if (e.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Material(
        color: Palette.paper,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Con il dito verso sinistra la foto dopo, verso destra
                // quella prima (non con la foto ingrandita).
                onHorizontalDragStart: many && !_zoomed
                    ? (_) => _dragX = 0
                    : null,
                onHorizontalDragUpdate: many && !_zoomed
                    ? (u) => _dragX += u.delta.dx
                    : null,
                onHorizontalDragEnd: many && !_zoomed
                    ? (e) {
                        final v = e.velocity.pixelsPerSecond.dx;
                        if (_dragX.abs() > 60 || v.abs() > 300) {
                          _go((_dragX.abs() > 60 ? _dragX : v) < 0 ? 1 : -1);
                        }
                      }
                    : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_prev != null && _prev != _i)
                      layer(_prev!, kAlwaysCompleteAnimation),
                    layer(_i, _fadeIn),
                  ],
                ),
              ),
            ),
            Positioned(
              top: pad.top + 14,
              right: pad.right + 14,
              child: RoundIconButton(
                Ico.close,
                () => Navigator.pop(context),
                'Chiudi',
              ),
            ),
            if (many || actions.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: pad.bottom + 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (many)
                      RoundIconButton(
                        Ico.chevronLeft,
                        () => _go(-1),
                        'Foto precedente',
                      ),
                    for (final a in actions) ...[const SizedBox(width: 12), a],
                    if (many) ...[
                      const SizedBox(width: 12),
                      RoundIconButton(
                        Ico.chevronRight,
                        () => _go(1),
                        'Foto successiva',
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Una foto che si ingrandisce con due dita; dice quando è ingrandita.
class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.url, required this.onZoom});
  final String url;
  final ValueChanged<bool> onZoom;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _t = TransformationController();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    transformationController: _t,
    maxScale: 4,
    onInteractionEnd: (_) => widget.onZoom(_t.value.getMaxScaleOnAxis() > 1.01),
    child: Center(child: PhotoImage(widget.url, fit: BoxFit.contain)),
  );
}
