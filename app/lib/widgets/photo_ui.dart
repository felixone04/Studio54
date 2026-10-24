import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Marchio e richiami fotografici (mirino, griglia dei terzi, pellicola) usati
// in tutte le sezioni del sito.

// ------------------------------------------------------------------- marchio

const brandLabel = 'Studio 54';

/// Logo completo "STUDIO 54", con l'inchiostro scuro su fondo trasparente:
/// si appoggia direttamente sui toni chiari del sito.
/// (Il logo su fondo nero è quello del caricamento, in web/splash.jpg.)
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/logo.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: brandLabel,
  );
}

/// Solo il "54" del logo.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.height = 24});
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/mark.png',
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
  );
}

// ---------------------------------------------------- richiami fotografici

/// Angoli del mirino (le "staffe" di messa a fuoco di una fotocamera).
/// Con [progress] da 0 a 1 gli angoli "mettono a fuoco": entrano e compaiono.
class Viewfinder extends StatelessWidget {
  const Viewfinder({
    super.key,
    this.color = Colors.white,
    this.length = 22,
    this.stroke = 1.2,
    this.inset = 0,
    this.focusPoint = false,
    this.progress = 1,
  });
  final Color color;
  final double length;
  final double stroke;
  final double inset;
  final bool focusPoint;
  final double progress;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.infinite,
      painter: _ViewfinderPainter(
        color: color,
        length: length,
        stroke: stroke,
        inset: inset,
        focusPoint: focusPoint,
        progress: progress,
      ),
    ),
  );
}

class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter({
    required this.color,
    required this.length,
    required this.stroke,
    required this.inset,
    required this.focusPoint,
    required this.progress,
  });
  final Color color;
  final double length;
  final double stroke;
  final double inset;
  final bool focusPoint;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final t = progress.clamp(0.0, 1.0);
    final p = Paint()
      ..color = color.withValues(alpha: color.a * t)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    // Prima di "mettere a fuoco" gli angoli sono un po' più larghi.
    final d = inset - (1 - t) * 14;
    final l = length;
    final r = Rect.fromLTRB(d, d, size.width - d, size.height - d);
    void corner(Offset o, double sx, double sy, double len) {
      canvas.drawLine(o, o + Offset(len * sx, 0), p);
      canvas.drawLine(o, o + Offset(0, len * sy), p);
    }

    corner(r.topLeft, 1, 1, l);
    corner(r.topRight, -1, 1, l);
    corner(r.bottomLeft, 1, -1, l);
    corner(r.bottomRight, -1, -1, l);

    if (focusPoint) {
      final c = size.center(Offset.zero);
      final f = Rect.fromCenter(center: c, width: l * 1.6, height: l * 1.1);
      final q = l * 0.32;
      corner(f.topLeft, 1, 1, q);
      corner(f.topRight, -1, 1, q);
      corner(f.bottomLeft, 1, -1, q);
      corner(f.bottomRight, -1, -1, q);
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter o) =>
      o.progress != progress ||
      o.color != color ||
      o.inset != inset ||
      o.length != length ||
      o.stroke != stroke ||
      o.focusPoint != focusPoint;
}

/// Mirino che si "mette a fuoco" quando [active] diventa vero.
class FocusFrame extends StatelessWidget {
  const FocusFrame({
    super.key,
    required this.active,
    this.color = Colors.white,
    this.length = 20,
    this.inset = 10,
    this.stroke = 1.2,
    this.focusPoint = false,
  });
  final bool active;
  final Color color;
  final double length;
  final double inset;
  final double stroke;
  final bool focusPoint;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: active ? 1 : 0),
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
    builder: (_, t, _) => Viewfinder(
      color: color,
      length: length,
      inset: inset,
      stroke: stroke,
      focusPoint: focusPoint,
      progress: t,
    ),
  );
}

/// Griglia della regola dei terzi, come nel mirino.
class ThirdsGrid extends StatelessWidget {
  const ThirdsGrid({super.key, this.opacity = 1});
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(size: Size.infinite, painter: _ThirdsPainter(opacity)),
  );
}

class _ThirdsPainter extends CustomPainter {
  _ThirdsPainter(this.opacity);
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 * opacity)
      ..strokeWidth = 0.8;
    for (final f in [1 / 3, 2 / 3]) {
      canvas.drawLine(
        Offset(size.width * f, 0),
        Offset(size.width * f, size.height),
        p,
      );
      canvas.drawLine(
        Offset(0, size.height * f),
        Offset(size.width, size.height * f),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_ThirdsPainter o) => o.opacity != opacity;
}

/// Riga di testo stile display della fotocamera (contatori, numeri).
TextStyle cameraText(double size, {Color color = Palette.stone}) =>
    label(size, color: color, weight: FontWeight.w400, spacing: 0.18);
