import 'package:flutter/material.dart';
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

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _c = PageController(initialPage: widget.start);
  late int _i = widget.start;

  @override
  void initState() {
    super.initState();
    // Solo la foto: le barre del telefono si nascondono.
    SystemBars.hide(this, true);
  }

  @override
  void dispose() {
    SystemBars.hide(this, false);
    _c.dispose();
    super.dispose();
  }

  void _go(int d) {
    final n = widget.photos.length;
    _c.animateToPage(
      (_i + d + n) % n,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final many = widget.photos.length > 1;
    final pad = MediaQuery.paddingOf(context);
    final actions = widget.actions?.call(context, _i) ?? const <Widget>[];
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
            PageView.builder(
              controller: _c,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (context, i) =>
                  widget.itemBuilder?.call(context, i) ??
                  InteractiveViewer(
                    maxScale: 4,
                    child: Center(
                      child: PhotoImage(widget.photos[i], fit: BoxFit.contain),
                    ),
                  ),
            ),
            Positioned(
              top: pad.top + 14,
              right: 14,
              child: RoundIconButton(
                Icons.close_rounded,
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
                        Icons.chevron_left_rounded,
                        () => _go(-1),
                        'Foto precedente',
                      ),
                    for (final a in actions) ...[const SizedBox(width: 12), a],
                    if (many) ...[
                      const SizedBox(width: 12),
                      RoundIconButton(
                        Icons.chevron_right_rounded,
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
