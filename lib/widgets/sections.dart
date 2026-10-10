import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'lightbox.dart';

// ============================================================ animazioni

/// Il testo "sale" da dietro una maschera, come nei titoli di testa.
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
    // Al primo avvio aspetta che sparisca il logo d'apertura (web/index.html),
    // così l'animazione si vede invece di avvenire sotto il logo.
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
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutQuart,
        child: widget.child,
      ),
    );
  }
}

// ================================================================= HERO

/// Apertura: foto a tutto schermo in dissolvenza con il nome dello studio
/// gigante, come il manifesto di una mostra.
class HeroSlideshow extends StatefulWidget {
  const HeroSlideshow({super.key, required this.content, required this.photos});
  final SiteContent content;
  final List<GalleryPhoto> photos;

  @override
  State<HeroSlideshow> createState() => _HeroSlideshowState();
}

class _HeroSlideshowState extends State<HeroSlideshow> {
  static const _interval = Duration(seconds: 6);
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    _t?.cancel();
    if (widget.photos.length > 1) {
      _t = Timer.periodic(_interval, (_) => _go(_i + 1, restart: false));
    }
  }

  void _go(int i, {bool restart = true}) {
    final n = widget.photos.length;
    if (n == 0) return;
    setState(() => _i = (i % n + n) % n);
    if (restart) _restart();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    final photos = widget.photos;
    final h = context.screenH;
    final phone = context.isPhone;
    final accent = Theme.of(context).colorScheme.primary;
    final photo = photos.isEmpty ? null : photos[_i % photos.length];
    final nameSize = math.min(context.w * (phone ? 0.2 : 0.15), h * 0.25);
    final words = c.studioName.trim().split(RegExp(r'\s+'));

    return SizedBox(
      height: h,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Palette.ink),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1600),
              child: photo == null
                  ? const SizedBox.shrink()
                  : TweenAnimationBuilder<double>(
                      key: ValueKey(photo.id),
                      tween: Tween(begin: 1.0, end: 1.12),
                      duration: const Duration(seconds: 10),
                      builder: (_, s, child) =>
                          Transform.scale(scale: s, child: child),
                      child: SizedBox.expand(
                        child: PhotoImage(photo.url, dark: true),
                      ),
                    ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x55000000),
                    Color(0x11000000),
                    Color(0x99000000),
                    Color(0xE6000000),
                  ],
                  stops: [0, 0.35, 0.75, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.gutter,
                0,
                context.gutter,
                context.fluid(22, 40),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MaskReveal(child: Tag(c.heroKicker, color: Palette.paper)),
                  SizedBox(height: context.fluid(10, 18)),
                  for (var i = 0; i < words.length; i++)
                    MaskReveal(
                      delay: 120 + i * 140,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          words[i],
                          maxLines: 1,
                          style: display(
                            nameSize,
                            color: i.isOdd ? accent : Palette.paper,
                            italic: i.isOdd,
                            height: 0.92,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: context.fluid(18, 30)),
                  if (c.heroTitle.trim().isNotEmpty)
                    MaskReveal(
                      delay: 500,
                      child: Text(
                        c.heroTitle,
                        style: display(
                          context.fluid(24, 40),
                          color: Palette.paper,
                          italic: true,
                          height: 1.05,
                        ),
                      ),
                    ),
                  SizedBox(height: context.fluid(26, 44)),
                  _HeroBar(
                    index: _i,
                    total: photos.length,
                    photo: photo,
                    interval: _interval,
                    onPrev: () => _go(_i - 1),
                    onNext: () => _go(_i + 1),
                    onSelect: _go,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBar extends StatelessWidget {
  const _HeroBar({
    required this.index,
    required this.total,
    required this.photo,
    required this.interval,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });
  final int index;
  final int total;
  final GalleryPhoto? photo;
  final Duration interval;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 8,
                    ),
                    child: Container(
                      height: 2,
                      color: Colors.white.withValues(alpha: 0.25),
                      alignment: Alignment.centerLeft,
                      child: i == index
                          ? TweenAnimationBuilder<double>(
                              key: ValueKey('bar$index'),
                              tween: Tween(begin: 0, end: 1),
                              duration: interval,
                              builder: (_, v, _) => FractionallySizedBox(
                                widthFactor: v,
                                child: Container(color: accent),
                              ),
                            )
                          : FractionallySizedBox(
                              widthFactor: i < index ? 1 : 0,
                              child: Container(color: Palette.paper),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '${(index + 1).toString().padLeft(2, '0')} — ${total.toString().padLeft(2, '0')}',
              style: label(11, color: Palette.paper),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  photo?.title ?? '',
                  key: ValueKey(photo?.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: display(17, color: Palette.paper, italic: true),
                ),
              ),
            ),
            _RoundIcon(Icons.arrow_back_rounded, onPrev),
            const SizedBox(width: 8),
            _RoundIcon(Icons.arrow_forward_rounded, onNext),
          ],
        ),
      ],
    );
  }
}

class _RoundIcon extends StatefulWidget {
  const _RoundIcon(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_RoundIcon> createState() => _RoundIconState();
}

class _RoundIconState extends State<_RoundIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    const base = Palette.paper;
    const inv = Palette.ink;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hover ? base : Colors.transparent,
            border: Border.all(color: base.withValues(alpha: 0.6)),
          ),
          child: Icon(widget.icon, size: 18, color: _hover ? inv : base),
        ),
      ),
    );
  }
}

// ============================================================ MANIFESTO

class Statement extends StatelessWidget {
  const Statement({super.key, required this.text, required this.number});
  final String text;
  final String number;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').where((e) => e.trim().isNotEmpty).toList();
    final size = context.fluid(38, 108);
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tag('Manifesto', number: number),
          SizedBox(height: context.fluid(28, 48)),
          Reveal(
            child: Text.rich(
              TextSpan(
                children: [
                  for (var i = 0; i < lines.length; i++)
                    TextSpan(
                      text:
                          '${lines[i].trim()}${i < lines.length - 1 ? '\n' : ''}',
                      style: display(
                        size,
                        italic: i.isOdd,
                        color: i.isOdd ? context.accentInk : Palette.ink,
                        height: 1.02,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================== GALLERIA

/// "La mostra": parete con le opere disposte su colonne sfalsate.
class GalleryWall extends StatelessWidget {
  const GalleryWall({
    super.key,
    required this.content,
    required this.photos,
    required this.number,
  });
  final SiteContent content;
  final List<GalleryPhoto> photos;
  final String number;

  static const _ratios = [4 / 5, 3 / 4, 1.0, 4 / 5, 2 / 3, 5 / 4];

  @override
  Widget build(BuildContext context) {
    final cols = context.w < 600 ? 2 : (context.w < 1024 ? 2 : 3);
    final gap = context.fluid(12, 36);
    final stagger = context.fluid(40, 140);
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tag(content.galleryKicker, number: number),
          SizedBox(height: context.fluid(14, 22)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Reveal(
                  child: Text(
                    content.galleryTitle,
                    style: display(context.fluid(64, 200), height: 0.9),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: EdgeInsets.only(top: context.fluid(8, 24)),
                child: Text(
                  '(${photos.length})',
                  style: display(context.fluid(20, 40), italic: true),
                ),
              ),
            ],
          ),
          SizedBox(height: context.fluid(36, 80)),
          LayoutBuilder(
            builder: (context, box) {
              final colW = (box.maxWidth - gap * (cols - 1)) / cols;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < cols; c++) ...[
                    if (c > 0) SizedBox(width: gap),
                    SizedBox(
                      width: colW,
                      child: Padding(
                        padding: EdgeInsets.only(top: c.isOdd ? stagger : 0),
                        child: Column(
                          children: [
                            for (var i = c; i < photos.length; i += cols)
                              Padding(
                                padding: EdgeInsets.only(bottom: gap * 1.6),
                                child: Reveal(
                                  delay: Duration(milliseconds: 80 * c),
                                  child: _Artwork(
                                    photo: photos[i],
                                    number: i + 1,
                                    ratio: _ratios[i % _ratios.length],
                                    onTap: () =>
                                        showPhotoLightbox(context, photos, i),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Artwork extends StatefulWidget {
  const _Artwork({
    required this.photo,
    required this.number,
    required this.ratio,
    required this.onTap,
  });
  final GalleryPhoto photo;
  final int number;
  final double ratio;
  final VoidCallback onTap;

  @override
  State<_Artwork> createState() => _ArtworkState();
}

class _ArtworkState extends State<_Artwork> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final small = context.isPhone;
    return Semantics(
      button: true,
      label: widget.photo.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: widget.ratio,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _hover ? 1.06 : 1,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        child: PhotoImage(widget.photo.url),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: AnimatedScale(
                          scale: _hover ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              size: 18,
                              color: Palette.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: small ? 8 : 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.number.toString().padLeft(2, '0'),
                    style: label(small ? 9.5 : 10.5, color: context.accentInk),
                  ),
                  SizedBox(width: small ? 8 : 14),
                  Expanded(
                    child: Text(
                      widget.photo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: display(
                        small ? 15 : 21,
                        italic: true,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ SERVIZI

/// Striscia orizzontale di grandi card fotografiche, una per servizio.
class ServicesStrip extends StatefulWidget {
  const ServicesStrip({
    super.key,
    required this.title,
    required this.services,
    required this.number,
  });
  final String title;
  final List<ServiceItem> services;
  final String number;

  @override
  State<ServicesStrip> createState() => _ServicesStripState();
}

class _ServicesStripState extends State<ServicesStrip> {
  final _c = ScrollController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _by(double dx) {
    if (!_c.hasClients) return;
    final target = (_c.offset + dx).clamp(0.0, _c.position.maxScrollExtent);
    _c.animateTo(
      target,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.services.where((s) => s.image.isNotEmpty).toList();
    final cardW = context.isPhone ? context.w * 0.72 : context.fluid(260, 400);
    final cardH = cardW * 1.32;
    final gap = context.fluid(12, 24);
    return Container(
      color: Palette.ink,
      padding: EdgeInsets.symmetric(vertical: context.fluid(72, 150)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gutter),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tag(
                        'Servizi',
                        number: widget.number,
                        color: Palette.paper,
                      ),
                      SizedBox(height: context.fluid(14, 22)),
                      Reveal(
                        child: Text(
                          widget.title,
                          style: display(
                            context.fluid(48, 140),
                            color: Palette.paper,
                            height: 0.92,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!context.isPhone) ...[
                  _RoundIcon(Icons.arrow_back_rounded, () => _by(-cardW * 2)),
                  const SizedBox(width: 8),
                  _RoundIcon(Icons.arrow_forward_rounded, () => _by(cardW * 2)),
                ],
              ],
            ),
          ),
          SizedBox(height: context.fluid(36, 70)),
          SizedBox(
            height: cardH,
            child: ListView.separated(
              controller: _c,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: context.gutter),
              itemCount: list.length,
              separatorBuilder: (_, _) => SizedBox(width: gap),
              itemBuilder: (_, i) => SizedBox(
                width: cardW,
                child: _ServiceCard(service: list[i], number: i + 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  const _ServiceCard({required this.service, required this.number});
  final ServiceItem service;
  final int number;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final s = widget.service;
    return Semantics(
      button: true,
      label: s.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => context.go('/preventivo?s=${s.id}'),
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _hover ? 1.07 : 1,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  child: PhotoImage(s.image, dark: true),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33000000),
                        Color(0x00000000),
                        Color(0xD9000000),
                      ],
                      stops: [0, 0.4, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.number.toString().padLeft(2, '0'),
                            style: label(11, color: Palette.paper),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        s.name,
                        style: display(
                          context.fluid(28, 40),
                          color: Palette.paper,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.category.toUpperCase(),
                        style: label(10, color: _hover ? accent : Palette.ash),
                      ),
                    ],
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

/// Apertura a tutto schermo con un'immagine fissa e un titolo gigante
/// (usata dalla biografia).
class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.kicker,
  });
  final String image;
  final String title;
  final String subtitle;
  final String kicker;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final h = context.screenH;
    return SizedBox(
      height: h,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Palette.ink),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.15, end: 1.0),
              duration: const Duration(seconds: 3),
              curve: Curves.easeOutCubic,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: SizedBox.expand(child: PhotoImage(image, dark: true)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x22000000),
                    Color(0xE6000000),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.gutter,
                0,
                context.gutter,
                context.fluid(36, 64),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaskReveal(child: Tag(kicker, color: Palette.paper)),
                  SizedBox(height: context.fluid(10, 18)),
                  MaskReveal(
                    delay: 120,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: display(
                          math.min(context.w * 0.17, h * 0.26),
                          color: Palette.paper,
                          height: 0.95,
                        ),
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: context.fluid(16, 28)),
                    MaskReveal(
                      delay: 300,
                      child: Text(
                        subtitle,
                        style: display(
                          context.fluid(24, 46),
                          color: accent,
                          italic: true,
                          height: 1.1,
                        ),
                      ),
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
