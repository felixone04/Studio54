import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../theme/app_theme.dart';

// ------------------------------------------------------------------ immagini

final _dataCache = <String, Uint8List>{};

Uint8List _decode(String url) => _dataCache.putIfAbsent(
  url,
  () => base64Decode(url.substring(url.indexOf(',') + 1)),
);

/// Mostra un'immagine da URL web oppure da un caricamento locale (data URL).
class PhotoImage extends StatelessWidget {
  const PhotoImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.dark = false,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final bool dark;

  Widget _placeholder() => ColoredBox(
    color: dark ? Palette.ink2 : Palette.paper2,
    child: Center(
      child: Icon(
        Icons.photo_camera_outlined,
        color: dark ? Palette.ash : Palette.stone,
        size: 28,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _placeholder();
    if (url.startsWith('data:')) {
      return Image.memory(
        _decode(url),
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: true,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      frameBuilder: (context, child, frame, sync) {
        if (sync) return child;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            if (frame == null) _placeholder(),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }
}

// -------------------------------------------------------------------- reveal

/// Fa comparire il contenuto (dissolvenza + scorrimento) quando entra nella
/// finestra visibile.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 40,
  });
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  final _key = UniqueKey();
  bool _triggered = false;
  bool _shown = false;

  void _onVisible(VisibilityInfo info) {
    if (_triggered || info.visibleFraction < 0.05) return;
    _triggered = true;
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: _onVisible,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _shown ? 1 : 0),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutQuart,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

// ----------------------------------------------------------------- layout

/// Sezione a tutta larghezza con margini laterali fluidi.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.child,
    this.color,
    this.top,
    this.bottom,
  });
  final Widget child;
  final Color? color;
  final double? top;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    final v = context.fluid(72, 150);
    return Container(
      color: color,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        top ?? v,
        context.gutter,
        bottom ?? v,
      ),
      child: child,
    );
  }
}

/// Piccola etichetta tipo cartellino: "(01) — La mostra".
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.number, this.color = Palette.ink});
  final String text;
  final String? number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final accent = color == Palette.ink ? context.accentInk : context.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (number != null) ...[
          Text('($number)', style: label(11, color: accent)),
          const SizedBox(width: 12),
        ],
        Container(width: 28, height: 1, color: color.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(text.toUpperCase(), style: label(11, color: color)),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- bottoni

/// Bottone a pillola con freccia che scivola al passaggio del mouse.
class PillButton extends StatefulWidget {
  const PillButton(
    this.text, {
    super.key,
    required this.onTap,
    this.onDark = false,
    this.filled = true,
    this.big = false,
    this.loading = false,
    this.icon = Icons.arrow_outward_rounded,
  });
  final String text;
  final VoidCallback? onTap;
  final bool onDark;
  final bool filled;
  final bool big;
  final bool loading;
  final IconData icon;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final base = widget.onDark ? Palette.paper : Palette.ink;
    final Color bg;
    final Color fg;
    if (widget.filled) {
      bg = _hover ? accent : base;
      fg = _hover ? Palette.ink : (widget.onDark ? Palette.ink : Palette.paper);
    } else {
      bg = _hover ? base : Colors.transparent;
      fg = _hover ? (widget.onDark ? Palette.ink : Palette.paper) : base;
    }
    final enabled = widget.onTap != null && !widget.loading;
    final h = widget.big ? 64.0 : 50.0;
    return Semantics(
      button: true,
      label: widget.text,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            height: h,
            padding: EdgeInsets.only(left: h * 0.5, right: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(h),
              border: Border.all(color: widget.filled ? bg : base, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.text.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: label(widget.big ? 13 : 11.5, color: fg),
                  ),
                ),
                SizedBox(width: h * 0.3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: h - 12,
                  height: h - 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fg.withValues(alpha: _hover ? 0.14 : 0.1),
                  ),
                  child: widget.loading
                      ? Padding(
                          padding: EdgeInsets.all(h * 0.28),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: fg,
                          ),
                        )
                      : AnimatedRotation(
                          turns: _hover ? 0.125 : 0,
                          duration: const Duration(milliseconds: 260),
                          child: Icon(widget.icon, size: h * 0.38, color: fg),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Link testuale con sottolineatura animata.
class HoverLink extends StatefulWidget {
  const HoverLink(
    this.text, {
    super.key,
    required this.onTap,
    required this.style,
    this.active = false,
  });
  final String text;
  final VoidCallback onTap;
  final TextStyle style;
  final bool active;

  @override
  State<HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = _hover || widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.text, style: widget.style),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                height: 1.2,
                width: on ? 24 : 0,
                color: widget.style.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Istante di avvio dell'app (impostato in `main`).
DateTime appStartedAt = DateTime.now();

/// Durata del logo d'apertura definito in `web/index.html` (2 s + dissolvenza).
const splashMs = 2300;
