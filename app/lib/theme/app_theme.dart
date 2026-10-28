import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette del marchio Studio 54: fondo bianco e l'inchiostro del logo, con
/// un accento discreto scelto dal titolare. Tutto lo spazio è per le foto.
class Palette {
  /// Inchiostro caldo del logo: testi e segni.
  static const ink = Color(0xFF1E1B17);

  /// Fondo del sito e dell'app.
  static const paper = Color(0xFFFFFFFF);

  /// Schede e campi.
  static const ivory = Color(0xFFFFFFFF);

  /// Segnaposto delle foto e fondi leggeri del gestionale.
  static const linen = Color(0xFFF4F4F2);

  static const stone = Color(0xFF6B635A); // testo secondario
  static const ash = Color(0xFF8F867C); // testo di contorno (etichette)
  static const line = Color(0x241E1B17);
  static const lineStrong = Color(0x591E1B17);
  static const error = Color(0xFFB3261E);
}

/// Colori tra cui il titolare può scegliere l'accento del sito.
const accentChoices = <String, int>{
  'Sabbia': 0xFFB89B72,
  'Argento': 0xFFC9C5BC,
  'Bianco': 0xFFFFFFFF,
  'Oro': 0xFFD4A85A,
  'Rosa cipria': 0xFFE2A7A0,
  'Salvia': 0xFF93AB8C,
  'Blu notte': 0xFF6E8CC8,
};

/// Variante dell'accento abbastanza scura da leggersi bene su chiaro.
Color accentOnPaper(Color accent) {
  final hsl = HSLColor.fromColor(accent);
  return hsl.lightness > 0.42 ? hsl.withLightness(0.36).toColor() : accent;
}

extension AccentX on BuildContext {
  Color get accent => Theme.of(this).colorScheme.tertiary;
  Color get accentInk => accentOnPaper(accent);

  /// Colore del brand (uguale sul sito e nell'area riservata).
  Color get brand => Theme.of(this).colorScheme.tertiary;
}

/// Titoli: Josefin Sans leggero, geometrico come il logo.
TextStyle display(
  double size, {
  Color color = Palette.ink,
  bool italic = false,
  FontWeight weight = FontWeight.w300,
  double height = 1.12,
  double spacing = 0.01,
}) => GoogleFonts.josefinSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  height: height,
  letterSpacing: size * spacing,
);

/// Etichette maiuscole spaziate (come "WEDDING & EVENTS" nel logo).
TextStyle label(
  double size, {
  Color color = Palette.ink,
  FontWeight weight = FontWeight.w600,
  double spacing = 0.24,
}) => GoogleFonts.josefinSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1.3,
  letterSpacing: size * spacing,
);

/// Testo corrente.
TextStyle body(
  double size, {
  Color color = Palette.ink,
  FontWeight weight = FontWeight.w400,
  double height = 1.6,
}) => GoogleFonts.jost(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

class AppTheme {
  /// Tema del sito pubblico: tutto chiaro, campi a riquadro ben leggibili.
  static ThemeData site(Color accent) {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: Palette.ink,
        onPrimary: Palette.paper,
        secondary: accentOnPaper(accent),
        tertiary: accent,
        surface: Palette.paper,
        onSurface: Palette.ink,
        onSurfaceVariant: Palette.stone,
        error: Palette.error,
      ),
      scaffoldBackgroundColor: Palette.paper,
    );
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: c, width: w),
    );
    return base.copyWith(
      textTheme: GoogleFonts.jostTextTheme(base.textTheme)
          .apply(bodyColor: Palette.ink, displayColor: Palette.ink),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Palette.ink,
        selectionColor: accent.withValues(alpha: 0.35),
        selectionHandleColor: Palette.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.ivory,
        border: b(Palette.lineStrong),
        enabledBorder: b(Palette.lineStrong),
        focusedBorder: b(Palette.ink, 1.6),
        errorBorder: b(Palette.error),
        focusedErrorBorder: b(Palette.error, 1.6),
        labelStyle: body(15, color: Palette.stone),
        floatingLabelStyle: body(
          14,
          color: Palette.ink,
          weight: FontWeight.w500,
        ),
        hintStyle: body(15, color: Palette.ash),
        helperStyle: body(12.5, color: Palette.stone),
        errorStyle: body(12.5, color: Palette.error),
        suffixIconColor: Palette.stone,
        prefixIconColor: Palette.stone,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: Palette.ink, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Palette.ink : null,
        ),
        checkColor: const WidgetStatePropertyAll(Palette.paper),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Palette.ivory),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Palette.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Palette.ink,
        contentTextStyle: body(14, color: Palette.paper),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Palette.paper,
        headerBackgroundColor: Palette.linen,
        headerForegroundColor: Palette.ink,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  /// Tema chiaro e più "gestionale" per l'area riservata.
  static ThemeData admin(Color accent) {
    const strong = Palette.ink;
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: strong,
        onPrimary: Palette.paper,
        secondary: accentOnPaper(accent),
        tertiary: accent,
        // Filtri selezionati in nero, come il logo.
        secondaryContainer: strong,
        onSecondaryContainer: Palette.paper,
        surface: Colors.white,
        onSurface: Palette.ink,
      ),
      scaffoldBackgroundColor: Palette.paper,
    );
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: BorderSide(color: c, width: w),
    );
    return base.copyWith(
      textTheme: GoogleFonts.jostTextTheme(base.textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: b(const Color(0xFFD8D2C8)),
        enabledBorder: b(const Color(0xFFD8D2C8)),
        focusedBorder: b(strong, 1.4),
        errorBorder: b(const Color(0xFFB3261E)),
        focusedErrorBorder: b(const Color(0xFFB3261E), 1.4),
        labelStyle: GoogleFonts.jost(color: const Color(0xFF6E675D)),
        floatingLabelStyle: GoogleFonts.jost(color: strong),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFD8D2C8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5DFD5)),
        ),
      ),
      dividerColor: const Color(0xFFE5DFD5),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.jost(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.jost(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Larghezza "di progetto" oltre la quale l'intero sito viene ingrandito
/// in proporzione (TV e monitor molto grandi): vedi [ScreenScale].
const designMaxWidth = 1600.0;

/// Breakpoint e misure fluide.
extension Responsive on BuildContext {
  double get w => MediaQuery.sizeOf(this).width;
  double get h => MediaQuery.sizeOf(this).height;
  bool get isPhone => w < 600;
  bool get isMobile => w < 720;
  bool get isTablet => w < 1024;

  /// Valore che cresce linearmente con la larghezza tra telefono (360) e
  /// desktop ampio (1600).
  double fluid(double min, double max) {
    final t = ((w - 360) / (designMaxWidth - 360)).clamp(0.0, 1.0);
    return min + (max - min) * t;
  }

  /// Margine laterale delle sezioni.
  double get gutter => fluid(20, 72);

  /// Altezza della barra di navigazione (con il logo in alto a sinistra).
  double get navH => fluid(72, 100);

  /// Altezza utile per sezioni "a schermo intero" (mai troppo bassa né
  /// troppo alta, anche su schermi in orizzontale di telefoni).
  double get screenH => math.max(h, w < 600 ? 560 : 620);
}

/// Sui display più larghi di [designMaxWidth] (TV, monitor 4K) ingrandisce
/// tutto il sito in modo uniforme, così le proporzioni restano identiche a
/// quelle progettate invece di lasciare enormi spazi vuoti.
class ScreenScale extends StatelessWidget {
  const ScreenScale({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    if (width <= designMaxWidth + 120) return child;
    final s = (width / designMaxWidth).clamp(1.0, 3.0);
    final logical = Size(width / s, mq.size.height / s);
    return MediaQuery(
      data: mq.copyWith(
        size: logical,
        padding: mq.padding / s,
        viewPadding: mq.viewPadding / s,
        viewInsets: mq.viewInsets / s,
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: logical.width,
          height: logical.height,
          child: child,
        ),
      ),
    );
  }
}
