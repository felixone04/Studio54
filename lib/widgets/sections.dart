import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'lightbox.dart';
import 'photo_ui.dart';

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

/// Titolo di sezione: etichetta piccola + titolo leggero, ben leggibile.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.kicker,
    required this.title,
    this.number,
    this.onDark = false,
    this.trailing,
    this.center = false,
  });
  final String kicker;
  final String title;
  final String? number;
  final bool onDark;
  final Widget? trailing;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Palette.paper : Palette.ink;
    final text = Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Tag(kicker, number: number, color: fg),
        SizedBox(height: context.fluid(14, 20)),
        Reveal(
          child: Text(
            title,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: display(context.fluid(32, 54), color: fg),
          ),
        ),
      ],
    );
    if (trailing == null) return text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        trailing!,
      ],
    );
  }
}

// ================================================================= HERO

/// Apertura: foto a tutto schermo inquadrate da un mirino, con il logo al
/// centro e il "display" della fotocamera in basso.
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
    final photo = photos.isEmpty ? null : photos[_i % photos.length];
    final navH = context.fluid(66, 88);
    final g = context.gutter;
    final logoW = math.min(context.w * 0.64, 470.0);

    return SizedBox(
      height: h,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Palette.ink),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1400),
              child: photo == null
                  ? const SizedBox.shrink()
                  : TweenAnimationBuilder<double>(
                      key: ValueKey(photo.id),
                      tween: Tween(begin: 1.0, end: 1.08),
                      duration: const Duration(seconds: 10),
                      builder: (_, s, child) =>
                          Transform.scale(scale: s, child: child),
                      child: SizedBox.expand(
                        child: PhotoImage(photo.url, dark: true),
                      ),
                    ),
            ),
            // Velatura: più scura al centro per il logo, e in basso.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [Color(0x8C000000), Color(0x40000000)],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x00000000),
                    Color(0xB3000000),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            // Mirino.
            Padding(
              padding: EdgeInsets.fromLTRB(g * 0.7, navH + 6, g * 0.7, g * 0.7),
              child: const Viewfinder(
                color: Color(0x99FFFFFF),
                length: 28,
                stroke: 1,
              ),
            ),
            // Logo e frase.
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: g),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MaskReveal(child: BrandLogo(width: logoW)),
                    if (c.heroTitle.trim().isNotEmpty) ...[
                      SizedBox(height: context.fluid(22, 34)),
                      MaskReveal(
                        delay: 250,
                        child: Text(
                          c.heroTitle.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: display(
                            context.fluid(13, 16),
                            color: Palette.paper,
                            weight: FontWeight.w300,
                            spacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Display della fotocamera.
            Positioned(
              left: g * 0.7 + 18,
              right: g * 0.7 + 18,
              bottom: g * 0.7 + 14,
              child: _CameraBar(
                index: _i,
                total: photos.length,
                photo: photo,
                interval: _interval,
                onPrev: () => _go(_i - 1),
                onNext: () => _go(_i + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraBar extends StatelessWidget {
  const _CameraBar({
    required this.index,
    required this.total,
    required this.photo,
    required this.interval,
    required this.onPrev,
    required this.onNext,
  });
  final int index;
  final int total;
  final GalleryPhoto? photo;
  final Duration interval;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final phone = context.isPhone;
    final counter =
        '${(index + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avanzamento dello scatto corrente.
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.2),
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            key: ValueKey('bar$index'),
            tween: Tween(begin: 0, end: 1),
            duration: interval,
            builder: (_, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: Container(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (!phone) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5483B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('RAW   AF-S', style: cameraText(10.5)),
              const SizedBox(width: 24),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  photo?.title ?? '',
                  key: ValueKey(photo?.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: phone ? TextAlign.start : TextAlign.center,
                  style: display(
                    phone ? 14 : 16,
                    color: Palette.paper,
                    italic: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(counter, style: cameraText(10.5)),
            const SizedBox(width: 12),
            _IconCircle(Icons.chevron_left_rounded, onPrev, 'Foto precedente'),
            const SizedBox(width: 6),
            _IconCircle(Icons.chevron_right_rounded, onNext, 'Foto successiva'),
          ],
        ),
      ],
    );
  }
}

class _IconCircle extends StatefulWidget {
  const _IconCircle(this.icon, this.onTap, this.tooltip);
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  State<_IconCircle> createState() => _IconCircleState();
}

class _IconCircleState extends State<_IconCircle> {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover ? Palette.paper : Colors.transparent,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _hover ? Palette.ink : Palette.paper,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================ MANIFESTO

/// Una frase sola, centrata, sotto la fotocamera del logo.
class Statement extends StatelessWidget {
  const Statement({super.key, required this.text, required this.number});
  final String text;
  final String number;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').where((e) => e.trim().isNotEmpty).toList();
    final size = context.fluid(24, 42);
    return Section(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              const BrandMark(height: 26, onDark: false),
              SizedBox(height: context.fluid(22, 30)),
              Tag('Manifesto', number: number),
              SizedBox(height: context.fluid(22, 34)),
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
                            color: i.isOdd ? Palette.stone : Palette.ink,
                            height: 1.3,
                          ),
                        ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: context.fluid(26, 36)),
              Container(width: 48, height: 1, color: Palette.ink),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================== GALLERIA

/// Il portfolio come un provino a contatto: colonne sfalsate, numero di
/// fotogramma e, al passaggio del mouse, mirino e griglia dei terzi.
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
    final cols = context.w < 1024 ? 2 : 3;
    final gap = context.fluid(10, 28);
    final stagger = context.fluid(30, 110);
    return Section(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            kicker: content.galleryKicker,
            title: content.galleryTitle,
            number: number,
            trailing: Text(
              '${photos.length} SCATTI',
              style: label(10.5, color: Palette.stone),
            ),
          ),
          SizedBox(height: context.fluid(30, 60)),
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
                                padding: EdgeInsets.only(bottom: gap * 1.5),
                                child: Reveal(
                                  delay: Duration(milliseconds: 70 * c),
                                  child: _Frame(
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

class _Frame extends StatefulWidget {
  const _Frame({
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
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final small = context.isPhone;
    final meta = [
      widget.photo.category,
      widget.photo.location,
      widget.photo.year,
    ].where((e) => e.isNotEmpty).join(' · ');
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
                        scale: _hover ? 1.04 : 1,
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        child: PhotoImage(widget.photo.url),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: _hover ? 1 : 0),
                        duration: const Duration(milliseconds: 300),
                        builder: (_, t, _) => ThirdsGrid(opacity: t),
                      ),
                      FocusFrame(
                        active: _hover,
                        length: 16,
                        inset: 12,
                        focusPoint: true,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: small ? 8 : 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.number.toString().padLeft(2, '0'),
                    style: label(small ? 9 : 10, color: Palette.stone),
                  ),
                  SizedBox(width: small ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.photo.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: display(
                            small ? 14 : 17,
                            weight: FontWeight.w400,
                          ),
                        ),
                        if (meta.isNotEmpty && !small) ...[
                          const SizedBox(height: 3),
                          Text(
                            meta.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: label(
                              9.5,
                              color: Palette.stone,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
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

/// I servizi come fotogrammi di una pellicola 35 mm che scorre.
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
    final frameW = context.isPhone ? context.w * 0.68 : context.fluid(240, 340);
    final frameH = frameW * 1.25;
    return Container(
      color: Palette.ink,
      padding: EdgeInsets.symmetric(vertical: context.fluid(70, 130)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gutter),
            child: SectionTitle(
              kicker: 'Servizi',
              title: widget.title,
              number: widget.number,
              onDark: true,
              trailing: context.isPhone
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconCircle(
                          Icons.chevron_left_rounded,
                          () => _by(-frameW * 2),
                          'Indietro',
                        ),
                        const SizedBox(width: 8),
                        _IconCircle(
                          Icons.chevron_right_rounded,
                          () => _by(frameW * 2),
                          'Avanti',
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: context.fluid(34, 56)),
          // La pellicola.
          Container(
            color: const Color(0xFF050505),
            child: Column(
              children: [
                const Sprockets(height: 26, color: Color(0x40F6F5F2)),
                SizedBox(
                  height: frameH,
                  child: ListView.separated(
                    controller: _c,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: context.gutter),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => SizedBox(
                      width: frameW,
                      child: _FilmFrame(service: list[i], number: i + 1),
                    ),
                  ),
                ),
                const Sprockets(height: 26, color: Color(0x40F6F5F2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilmFrame extends StatefulWidget {
  const _FilmFrame({required this.service, required this.number});
  final ServiceItem service;
  final int number;

  @override
  State<_FilmFrame> createState() => _FilmFrameState();
}

class _FilmFrameState extends State<_FilmFrame> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _hover ? 1.05 : 1,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  child: PhotoImage(s.image, dark: true),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x40000000),
                        Color(0x00000000),
                        Color(0xD9000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                FocusFrame(active: _hover, length: 14, inset: 12),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Numerazione del fotogramma, come sul bordo pellicola.
                      Text(
                        '${widget.number.toString().padLeft(2, '0')}A',
                        style: cameraText(10, color: const Color(0xFFE8C27A)),
                      ),
                      const Spacer(),
                      Text(
                        s.name.toUpperCase(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: display(
                          context.fluid(17, 21),
                          color: Palette.paper,
                          weight: FontWeight.w400,
                          spacing: 0.08,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: label(
                          9.5,
                          color: Palette.ash,
                          weight: FontWeight.w400,
                        ),
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

/// Apertura a tutto schermo con immagine fissa, mirino e titolo (biografia).
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
    final h = math.min(context.screenH, context.w * 1.5);
    final navH = context.fluid(66, 88);
    final g = context.gutter;
    return SizedBox(
      height: h,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Palette.ink),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.12, end: 1.0),
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
                    Color(0xD9000000),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(g * 0.7, navH + 6, g * 0.7, g * 0.7),
              child: const Viewfinder(
                color: Color(0x99FFFFFF),
                length: 28,
                stroke: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(g + 8, 0, g + 8, g + 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaskReveal(child: Tag(kicker, color: Palette.paper)),
                  SizedBox(height: context.fluid(12, 18)),
                  MaskReveal(
                    delay: 120,
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: display(
                        context.fluid(34, 62),
                        color: Palette.paper,
                        spacing: 0.1,
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: context.fluid(12, 18)),
                    MaskReveal(
                      delay: 260,
                      child: Text(
                        subtitle,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: display(
                          context.fluid(18, 26),
                          color: Palette.paper.withValues(alpha: 0.85),
                          italic: true,
                          height: 1.35,
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
