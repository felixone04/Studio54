import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Marchio e richiami fotografici (mirino, griglia dei terzi, pellicola) usati
// in tutte le sezioni del sito.

// ------------------------------------------------------------------- marchio

const _brandLabel = 'Studio Lumen · Wedding & Events';

/// Logo completo (diaframma, nome e "Wedding & Events").
/// [onDark] = logo bianco per sfondi scuri, altrimenti nero.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width, this.height, this.onDark = true});
  final double? width;
  final double? height;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Image.asset(
    onDark ? 'assets/brand/logo_white.png' : 'assets/brand/logo_black.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: _brandLabel,
  );
}

/// Solo il diaframma del logo.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.height = 24, this.onDark = true});
  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Image.asset(
    onDark ? 'assets/brand/mark_white.png' : 'assets/brand/mark_black.png',
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
  );
}

/// Diaframma + nome, per la barra di navigazione.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    required this.name,
    this.height = 22,
    this.onDark = true,
    this.showName = true,
  });
  final String name;
  final double height;
  final bool onDark;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Palette.paper : Palette.ink;
    return Semantics(
      label: name,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(height: height, onDark: onDark),
          if (showName) ...[
            SizedBox(width: height * 0.55),
            Flexible(
              child: Text(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: display(
                  height * 0.74,
                  color: color,
                  weight: FontWeight.w400,
                  spacing: 0.14,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
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

/// Fila di perforazioni di una pellicola 35 mm.
class Sprockets extends StatelessWidget {
  const Sprockets({
    super.key,
    this.height = 22,
    this.color = const Color(0xE6F6F5F2),
  });
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _SprocketPainter(color)),
  );
}

class _SprocketPainter extends CustomPainter {
  _SprocketPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final h = size.height * 0.42;
    final w = h * 1.35;
    const gap = 14.0;
    final y = (size.height - h) / 2;
    for (var x = gap / 2; x + w < size.width; x += w + gap) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          Radius.circular(h * 0.22),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_SprocketPainter o) => o.color != color;
}

/// Grana della pellicola, leggerissima, da appoggiare sopra a una sezione.
/// La trama si genera una sola volta e poi si ripete: costa pochissimo.
class FilmGrain extends StatelessWidget {
  const FilmGrain({super.key, this.intensity = 1});

  /// 1 = grana normale (già molto discreta); 0 = assente.
  final double intensity;

  static ui.Image? _tile;
  static bool _failed = false;

  static ui.Image? _texture() {
    if (_tile != null || _failed) return _tile;
    try {
      const size = 160;
      final r = math.Random(7);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final p = Paint();
      for (var i = 0; i < 2600; i++) {
        final light = r.nextBool();
        final a = 0.04 + r.nextDouble() * 0.09;
        p.color = (light ? Colors.white : Colors.black).withValues(alpha: a);
        c.drawRect(
          Rect.fromLTWH(
            r.nextInt(size).toDouble(),
            r.nextInt(size).toDouble(),
            r.nextDouble() < 0.2 ? 1.6 : 1,
            r.nextDouble() < 0.2 ? 1.6 : 1,
          ),
          p,
        );
      }
      _tile = rec.endRecording().toImageSync(size, size);
    } catch (_) {
      // Se il motore grafico non lo permette, semplicemente niente grana.
      _failed = true;
    }
    return _tile;
  }

  @override
  Widget build(BuildContext context) {
    final tile = intensity <= 0 ? null : _texture();
    if (tile == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GrainPainter(tile, intensity.clamp(0.0, 1.0)),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.tile, this.intensity);
  final ui.Image tile;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..shader = ImageShader(
        tile,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      )
      ..color = Colors.white.withValues(alpha: intensity);
    canvas.drawRect(Offset.zero & size, p);
  }

  @override
  bool shouldRepaint(_GrainPainter o) =>
      o.tile != tile || o.intensity != intensity;
}

/// Riga di testo stile display della fotocamera ("RAW · AF-S · 03/08").
TextStyle cameraText(double size, {Color color = Palette.paper}) =>
    label(size, color: color, weight: FontWeight.w400, spacing: 0.18);
