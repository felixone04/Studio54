import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Il marchio (logo e "54") e il testo stile display della fotocamera.

// ------------------------------------------------------------------- marchio

const brandLabel = 'Studio 54';

/// Logo completo "STUDIO 54", con l'inchiostro scuro su fondo trasparente:
/// si appoggia direttamente sui toni chiari del sito.
/// (Il logo su fondo nero è quello del caricamento, in web/splash.jpg.)
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width, this.height, this.light = false});
  final double? width;
  final double? height;

  /// Versione chiara, per stare sopra una foto.
  final bool light;

  @override
  Widget build(BuildContext context) => Image.asset(
    light ? 'assets/brand/logo_light.png' : 'assets/brand/logo.png',
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

// ------------------------------------------------------------------- testo

/// Riga di testo stile display della fotocamera (contatori, numeri).
TextStyle cameraText(double size, {Color color = Palette.stone}) =>
    label(size, color: color, weight: FontWeight.w400, spacing: 0.18);
