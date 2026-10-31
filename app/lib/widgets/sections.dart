import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'line_icons.dart';

import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';

// ============================================================ animazioni

/// Il contenuto "sale" da dietro una maschera, come nei titoli di testa.
class MaskReveal extends StatefulWidget {
  const MaskReveal({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay; // millisecondi

  @override
  State<MaskReveal> createState() => _MaskRevealState();
}

class _MaskRevealState extends State<MaskReveal> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    // Al primo avvio aspetta che sparisca il logo d'apertura, così
    // l'animazione si vede invece di avvenire sotto il logo.
    final sinceStart = DateTime.now().difference(appStartedAt).inMilliseconds;
    final intro = math.max(0, splashMs - sinceStart);
    Future.delayed(Duration(milliseconds: 150 + intro + widget.delay), () {
      if (mounted) setState(() => _on = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSlide(
        offset: _on ? Offset.zero : const Offset(0, 1.1),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutQuart,
        child: AnimatedOpacity(
          opacity: _on ? 1 : 0,
          duration: const Duration(milliseconds: 900),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Bottone tondo e sottile con icona (frecce, chiusura).
class RoundIconButton extends StatefulWidget {
  const RoundIconButton(
    this.icon,
    this.onTap,
    this.tooltip, {
    super.key,
    this.light = false,
    this.size = 42,
  });
  final Ico icon;
  final VoidCallback onTap;
  final String tooltip;

  /// Chiaro, per stare sopra una foto.
  final bool light;
  final double size;

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? (widget.light ? Palette.paper : Palette.ink)
                  : (widget.light
                        ? Colors.transparent
                        : Palette.paper.withValues(alpha: 0.82)),
              border: Border.all(
                color: widget.light
                    ? const Color(0xB3FFFFFF)
                    : Palette.lineStrong,
              ),
            ),
            child: Center(
              child: LineIcon(
                widget.icon,
                size: widget.size * 0.46,
                color: _hover != widget.light ? Palette.paper : Palette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================== CAROSELLO APP

/// L'apertura dell'app: le foto del verso dello schermo, intere, che scorrono da
/// sole, 4 secondi l'una, con una dissolvenza. Niente scritte né frecce: si
/// possono sfogliare anche con il dito.
class AppCarousel extends StatefulWidget {
  const AppCarousel({super.key, required this.photos, required this.height});
  final List<String> photos;
  final double height;

  /// Tempo di ogni foto.
  static const interval = Duration(seconds: 4);

  /// Durata della dissolvenza tra una foto e l'altra.
  static const fade = Duration(milliseconds: 1400);

  @override
  State<AppCarousel> createState() => _AppCarouselState();
}

class _AppCarouselState extends State<AppCarousel> {
  int _i = 0;
  Timer? _t;

  // Con l'app in secondo piano il carosello si ferma.
  late final _life = AppLifecycleListener(
    onHide: () => _t?.cancel(),
    onShow: _restart,
  );

  @override
  void initState() {
    super.initState();
    _life;
    // Aspetta che sparisca il logo d'apertura: così la prima foto dura
    // davvero 4 secondi.
    final wait = introRemainingMs();
    if (wait > 0) {
      Future.delayed(Duration(milliseconds: wait), () {
        if (mounted) _restart();
      });
    } else {
      _restart();
    }
  }

  void _restart() {
    _t?.cancel();
    if (widget.photos.length > 1) {
      _t = Timer.periodic(
        AppCarousel.interval,
        (_) => _go(_i + 1, restart: false),
      );
    }
  }

  void _go(int i, {bool restart = true}) {
    final n = widget.photos.length;
    if (n == 0) return;
    setState(() => _i = (i % n + n) % n);
    if (restart) _restart();
  }

  @override
  void didUpdateWidget(AppCarousel old) {
    super.didUpdateWidget(old);
    if (old.photos.join() != widget.photos.join()) {
      final n = widget.photos.length;
      _i = n == 0 ? 0 : _i % n;
      _restart();
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final url = photos.isEmpty ? null : photos[_i % photos.length];
    final next = photos.length < 2 ? null : photos[(_i + 1) % photos.length];
    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 120) return;
          _go(_i + (v < 0 ? 1 : -1));
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Palette.linen),
            // La foto successiva caricata in anticipo (invisibile).
            if (next != null)
              ExcludeSemantics(
                child: Opacity(
                  opacity: 0,
                  child: PhotoImage(next, key: ValueKey('next-$next')),
                ),
              ),
            // Dissolvenza incrociata: la foto che esce resta piena sotto e
            // quella nuova compare piano sopra, senza lampi del fondo.
            AnimatedSwitcher(
              duration: AppCarousel.fade,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) => AnimatedBuilder(
                animation: animation,
                child: child,
                builder: (_, c) => Opacity(
                  opacity: animation.status == AnimationStatus.reverse
                      ? 1
                      : Curves.easeInOutCubic.transform(animation.value),
                  child: c,
                ),
              ),
              child: url == null
                  ? const SizedBox.shrink()
                  : Semantics(
                      key: ValueKey('$_i-$url'),
                      image: true,
                      label: 'Foto ${_i + 1} di ${photos.length}',
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.04),
                        duration: AppCarousel.interval + AppCarousel.fade,
                        builder: (_, s, child) =>
                            Transform.scale(scale: s, child: child),
                        child: SizedBox.expand(child: PhotoImage(url)),
                      ),
                    ),
            ),
            // Velatura leggera in alto, per leggere logo e menu.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x52000000), Color(0x00000000)],
                    stops: [0, 0.22],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================ LAVORI

/// La scheda di un lavoro, uguale a quella del sito: la foto principale, il
/// nome dei festeggiati, la location e la tipologia.
class WorkCard extends StatelessWidget {
  const WorkCard({super.key, required this.work});
  final Work work;

  @override
  Widget build(BuildContext context) {
    final w = work;
    final info = [w.location, w.category].where((e) => e.trim().isNotEmpty);
    return Semantics(
      button: true,
      label: 'Lavoro ${w.title}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go('/lavori/${w.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 4 / 5, child: PhotoImage(w.coverUrl)),
            const SizedBox(height: 16),
            Text(
              w.title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: display(context.fluid(20, 28), spacing: 0.08, height: 1.2),
            ),
            if (info.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                info.join(' · ').toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: label(10.5, color: Palette.stone),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// I lavori come sul sito: uno per riga sul telefono in verticale, due per
/// riga sugli schermi più larghi (telefono girato, tablet), a tutta larghezza.
class WorkList extends StatelessWidget {
  const WorkList({super.key, required this.works});
  final List<Work> works;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 600 ? 2 : 1;
        final gap = context.fluid(20, 44);
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: context.fluid(44, 72),
          children: [
            for (final work in works)
              SizedBox(
                width: w,
                child: Reveal(child: WorkCard(work: work)),
              ),
          ],
        );
      },
    );
  }
}
