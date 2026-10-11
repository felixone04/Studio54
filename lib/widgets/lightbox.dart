import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Visualizzazione a schermo intero di una foto della mostra: frecce,
/// tastiera, swipe e zoom.
Future<void> showPhotoLightbox(
  BuildContext context,
  List<GalleryPhoto> photos,
  int start,
) {
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.black,
    barrierDismissible: true,
    barrierLabel: 'Chiudi',
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (_, a, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: child,
    ),
    pageBuilder: (_, _, _) => _Lightbox(photos: photos, start: start),
  );
}

class _Lightbox extends StatefulWidget {
  const _Lightbox({required this.photos, required this.start});
  final List<GalleryPhoto> photos;
  final int start;

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late final PageController _c = PageController(initialPage: widget.start);
  late int _i = widget.start;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _go(int d) {
    final n = widget.photos.length;
    _c.animateToPage(
      (_i + d + n) % n,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.photos[_i];
    final accent = Theme.of(context).colorScheme.primary;
    final meta = [
      p.category,
      p.location,
      p.year,
    ].where((e) => e.isNotEmpty).join('  ·  ');
    final wide = context.w > 720;
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          _go(1);
        } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _go(-1);
        } else if (e.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Material(
        color: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _c,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => InteractiveViewer(
                maxScale: 4,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 90 : 0,
                    70,
                    wide ? 90 : 0,
                    110,
                  ),
                  child: PhotoImage(
                    widget.photos[i].url,
                    fit: BoxFit.contain,
                    dark: true,
                  ),
                ),
              ),
            ),
            Positioned(
              left: context.gutter,
              right: context.gutter,
              bottom: 26,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: display(
                            context.fluid(26, 40),
                            color: Palette.paper,
                            italic: true,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            meta.toUpperCase(),
                            style: label(10.5, color: Palette.ash),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${(_i + 1).toString().padLeft(2, '0')} / ${widget.photos.length.toString().padLeft(2, '0')}',
                    style: label(11, color: accent),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Chiudi',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 30,
                  color: Palette.paper,
                ),
              ),
            ),
            if (wide) ...[
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () => _go(-1),
                    tooltip: 'Foto precedente',
                    iconSize: 40,
                    color: Palette.paper,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () => _go(1),
                    tooltip: 'Foto successiva',
                    iconSize: 40,
                    color: Palette.paper,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
