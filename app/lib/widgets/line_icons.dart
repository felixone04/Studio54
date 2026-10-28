import 'package:flutter/material.dart';

/// Icone a tratto sottile, disegnate come quelle del sito (riquadro 24×24,
/// tratto 1,4): frecce, X, download e audio uguali su sito e app.
enum Ico {
  chevronLeft,
  chevronRight,
  expandMore,
  close,
  arrowLeft,
  arrowRight,
  arrowOutward,
  check,
  download,
  play,
  volumeOn,
  volumeOff,
  calendar,
  mail,
  phone,
  send,
  edit,
  folder,
  link,
  lock,
  person,
  eye,
  eyeOff,
  logout,
  camera,
  document,
}

class LineIcon extends StatelessWidget {
  const LineIcon(this.icon, {super.key, this.size = 24, this.color});
  final Ico icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LinePainter(icon, c)),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.icon, this.color);
  final Ico icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_path(icon), p);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.icon != icon || old.color != color;
}

Path _lines(List<List<double>> parts) {
  final p = Path();
  for (final l in parts) {
    p.moveTo(l[0], l[1]);
    for (var i = 2; i < l.length; i += 2) {
      p.lineTo(l[i], l[i + 1]);
    }
  }
  return p;
}

Path _rrect(double x, double y, double w, double h, double r) => Path()
  ..addRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
  );

Path _circle(double x, double y, double r) =>
    Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

Path _eye() => Path()
  ..moveTo(2.5, 12)
  ..quadraticBezierTo(12, 1.5, 21.5, 12)
  ..quadraticBezierTo(12, 22.5, 2.5, 12)
  ..close()
  ..addPath(_circle(12, 12, 3), Offset.zero);

Path _speaker() => _lines([
  [4, 9, 8, 9, 13, 5, 13, 19, 8, 15, 4, 15, 4, 9],
]);

Path _path(Ico i) => switch (i) {
  Ico.chevronLeft => _lines([
    [14.5, 6, 8.5, 12, 14.5, 18],
  ]),
  Ico.chevronRight => _lines([
    [9.5, 6, 15.5, 12, 9.5, 18],
  ]),
  Ico.expandMore => _lines([
    [6, 9.5, 12, 15.5, 18, 9.5],
  ]),
  Ico.close => _lines([
    [6, 6, 18, 18],
    [18, 6, 6, 18],
  ]),
  Ico.arrowLeft => _lines([
    [19, 12, 5, 12],
    [11, 6, 5, 12, 11, 18],
  ]),
  Ico.arrowRight => _lines([
    [5, 12, 19, 12],
    [13, 6, 19, 12, 13, 18],
  ]),
  Ico.arrowOutward => _lines([
    [7, 17, 17, 7],
    [8, 7, 17, 7, 17, 16],
  ]),
  Ico.check => _lines([
    [5, 12.5, 10, 17, 19, 7],
  ]),
  Ico.download => _lines([
    [12, 4, 12, 15],
    [7, 10, 12, 15, 17, 10],
    [5, 19.5, 19, 19.5],
  ]),
  Ico.play => _lines([
    [8, 5, 19, 12, 8, 19, 8, 5],
  ]),
  Ico.volumeOn =>
    _speaker()
      ..moveTo(16, 9)
      ..quadraticBezierTo(18, 12, 16, 15)
      ..moveTo(18.5, 6.5)
      ..quadraticBezierTo(22.5, 12, 18.5, 17.5),
  Ico.volumeOff =>
    _speaker()..addPath(
      _lines([
        [16, 9.5, 21, 14.5],
        [21, 9.5, 16, 14.5],
      ]),
      Offset.zero,
    ),
  Ico.calendar =>
    _rrect(4, 5.5, 16, 14.5, 2)..addPath(
      _lines([
        [4, 10, 20, 10],
        [8, 3.5, 8, 7.5],
        [16, 3.5, 16, 7.5],
      ]),
      Offset.zero,
    ),
  Ico.mail =>
    _rrect(3, 5, 18, 14, 2)..addPath(
      _lines([
        [4, 7, 12, 13, 20, 7],
      ]),
      Offset.zero,
    ),
  // La stessa cornetta del modulo del sito.
  Ico.phone =>
    Path()
      ..moveTo(6.6, 10.8)
      ..arcToPoint(
        const Offset(13.2, 17.4),
        radius: const Radius.circular(15.1),
        clockwise: false,
      )
      ..relativeLineTo(2.2, -2.2)
      ..relativeCubicTo(.3, -.3, .7, -.4, 1, -.2)
      ..relativeCubicTo(1.1, .4, 2.3, .6, 3.6, .6)
      ..relativeCubicTo(.6, 0, 1, .4, 1, 1)
      ..lineTo(21, 20)
      ..relativeCubicTo(0, .6, -.4, 1, -1, 1)
      ..arcToPoint(const Offset(3, 4), radius: const Radius.circular(17))
      ..relativeCubicTo(0, -.6, .4, -1, 1, -1)
      ..relativeLineTo(3.5, 0)
      ..relativeCubicTo(.6, 0, 1, .4, 1, 1)
      ..relativeCubicTo(0, 1.3, .2, 2.5, .6, 3.6)
      ..relativeCubicTo(.1, .3, 0, .7, -.2, 1)
      ..close(),
  Ico.send => _lines([
    [4, 11.5, 20, 4, 13.5, 20, 11, 13, 4, 11.5],
    [11, 13, 20, 4],
  ]),
  Ico.edit => _lines([
    [4, 20, 8, 20, 19, 9, 15, 5, 4, 16, 4, 20],
    [13, 7, 17, 11],
  ]),
  Ico.folder => _lines([
    [3, 18, 3, 6, 9, 6, 11, 8, 21, 8, 21, 18, 3, 18],
  ]),
  Ico.link =>
    Path()
      ..addPath(
        _lines([
          [9.5, 14.5, 14.5, 9.5],
        ]),
        Offset.zero,
      )
      ..moveTo(11, 7)
      ..lineTo(12.5, 5.5)
      ..arcToPoint(const Offset(17.5, 10.5), radius: const Radius.circular(3.5))
      ..lineTo(16, 12)
      ..moveTo(13, 17)
      ..lineTo(11.5, 18.5)
      ..arcToPoint(const Offset(6.5, 13.5), radius: const Radius.circular(3.5))
      ..lineTo(8, 12),
  Ico.lock =>
    _rrect(5, 11, 14, 9.5, 2)
      ..moveTo(8, 11)
      ..lineTo(8, 8)
      ..arcToPoint(const Offset(16, 8), radius: const Radius.circular(4))
      ..lineTo(16, 11),
  Ico.person =>
    _circle(12, 8, 3.5)
      ..moveTo(5, 20)
      ..arcToPoint(const Offset(19, 20), radius: const Radius.circular(7)),
  Ico.eye => _eye(),
  Ico.eyeOff =>
    _eye()..addPath(
      _lines([
        [4, 4, 20, 20],
      ]),
      Offset.zero,
    ),
  Ico.logout => _lines([
    [10, 4, 6, 4, 4, 6, 4, 18, 6, 20, 10, 20],
    [14, 8, 18, 12, 14, 16],
    [18, 12, 9, 12],
  ]),
  Ico.camera =>
    _rrect(3, 7, 18, 13, 2)
      ..addPath(
        _lines([
          [8, 7, 9.5, 4.5, 14.5, 4.5, 16, 7],
        ]),
        Offset.zero,
      )
      ..addPath(_circle(12, 13.5, 3.5), Offset.zero),
  Ico.document => _lines([
    [6, 3, 14, 3, 19, 8, 19, 21, 6, 21, 6, 3],
    [14, 3, 14, 8, 19, 8],
  ]),
};

/// Icona dentro un campo di testo (prima o dopo il testo).
class InputIcon extends StatelessWidget {
  const InputIcon(this.icon, {super.key});
  final Ico icon;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 48,
    child: Center(child: LineIcon(icon, size: 20)),
  );
}
