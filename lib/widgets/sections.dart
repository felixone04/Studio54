import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    this.trailing,
  });
  final String kicker;
  final String title;
  final String? number;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tag(kicker, number: number),
        SizedBox(height: context.fluid(14, 20)),
        Reveal(child: Text(title, style: display(context.fluid(32, 54)))),
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

/// Bottone tondo con icona (frecce del carosello).
class RoundIconButton extends StatefulWidget {
  const RoundIconButton(
    this.icon,
    this.onTap,
    this.tooltip, {
    super.key,
    this.light = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  /// Chiaro, per stare sopra una foto.
  final bool light;

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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? (widget.light ? Palette.paper : Palette.ink)
                  : Colors.transparent,
              border: Border.all(
                color: widget.light
                    ? const Color(0x99FFFAF0)
                    : Palette.lineStrong,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              // Chiaro su foto, scuro su carta; al passaggio si invertono.
              color: _hover != widget.light ? Palette.paper : Palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================= HERO

/// Apertura: carosello delle sole foto orizzontali, a tutto schermo e
/// racchiuse dagli angoli del mirino.
class HeroSlideshow extends StatefulWidget {
  const HeroSlideshow({super.key, required this.content, required this.photos});
  final SiteContent content;
  final List<GalleryPhoto> photos;

  /// Tempo di ogni foto.
  static const interval = Duration(seconds: 4);

  @override
  State<HeroSlideshow> createState() => _HeroSlideshowState();
}

class _HeroSlideshowState extends State<HeroSlideshow> {
  final _aspects = PhotoAspects.instance;
  int _i = 0;
  Timer? _t;
  List<GalleryPhoto> _shown = const [];

  @override
  void initState() {
    super.initState();
    _aspects.addListener(_refresh);
    _aspects.resolveAll(widget.photos.map((p) => p.url));
    _shown = _filter();
    _restart();
  }

  /// Nel carosello solo foto orizzontali: quelle verticali (scoperte appena
  /// se ne leggono le proporzioni) si saltano.
  List<GalleryPhoto> _filter() =>
      widget.photos.where((p) => !_aspects.notLandscape(p.url)).toList();

  void _refresh() {
    final next = _filter();
    if (next.length == _shown.length) return;
    // Resta sulla foto che si stava guardando, se c'è ancora.
    final current = _shown.isEmpty ? null : _shown[_i % _shown.length].id;
    final keep = next.indexWhere((p) => p.id == current);
    setState(() {
      _shown = next;
      _i = keep >= 0 ? keep : 0;
    });
    _restart();
  }

  void _restart() {
    _t?.cancel();
    if (_shown.length > 1) {
      _t = Timer.periodic(
        HeroSlideshow.interval,
        (_) => _go(_i + 1, restart: false),
      );
    }
  }

  void _go(int i, {bool restart = true}) {
    final n = _shown.length;
    if (n == 0) return;
    setState(() => _i = (i % n + n) % n);
    if (restart) _restart();
  }

  @override
  void didUpdateWidget(HeroSlideshow old) {
    super.didUpdateWidget(old);
    // Le foto possono cambiare (galleria modificata): indice nei limiti e
    // timer avviato o fermato secondo il nuovo numero di foto.
    String ids(List<GalleryPhoto> l) => l.map((p) => '${p.id} ${p.url}').join();
    if (ids(old.photos) != ids(widget.photos)) {
      _aspects.resolveAll(widget.photos.map((p) => p.url));
      _shown = _filter();
      final n = _shown.length;
      _i = n == 0 ? 0 : _i % n;
      _restart();
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _aspects.removeListener(_refresh);
    super.dispose();
  }

  /// La foto corrente con dissolvenza, e la successiva caricata in anticipo
  /// (invisibile): al cambio è già pronta e non si vede il fondo vuoto.
  /// Con [zoom] la foto si avvicina piano mentre resta in mostra.
  Widget _photoStack(
    GalleryPhoto? photo,
    GalleryPhoto? next, {
    BoxFit fit = BoxFit.contain,
    bool zoom = false,
  }) => Stack(
    fit: StackFit.expand,
    children: [
      if (next != null)
        ExcludeSemantics(
          child: Opacity(
            opacity: 0,
            child: PhotoImage(
              next.url,
              key: ValueKey('next-${next.id}'),
              fit: fit,
            ),
          ),
        ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 900),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        child: photo == null
            ? const SizedBox.shrink()
            : Semantics(
                key: ValueKey(photo.id),
                container: true,
                image: true,
                label: photo.title,
                child: !zoom
                    ? PhotoImage(photo.url, fit: fit)
                    : TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.05),
                        duration:
                            HeroSlideshow.interval +
                            const Duration(milliseconds: 900),
                        builder: (_, s, child) =>
                            Transform.scale(scale: s, child: child),
                        child: SizedBox.expand(
                          child: PhotoImage(photo.url, fit: fit),
                        ),
                      ),
              ),
      ),
    ],
  );

  /// Sfoglia col dito (telefono, tablet) o trascinando con il mouse.
  Widget _swipe(Widget child) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onHorizontalDragEnd: (d) {
      final v = d.primaryVelocity ?? 0;
      if (v.abs() < 120) return;
      _go(_i + (v < 0 ? 1 : -1));
    },
    child: child,
  );

  /// In verticale: barra in alto, la foto al centro, grande quanto lo
  /// schermo permette e racchiusa dagli angoli del mirino, e subito sotto
  /// la descrizione e i comandi. Tutto insieme riempie lo schermo e si legge
  /// come un'unica composizione.
  Widget _portrait(
    List<GalleryPhoto> photos,
    GalleryPhoto? photo,
    GalleryPhoto? next,
  ) {
    final g = context.gutter;
    final w = context.w;
    // Gli angoli stanno appena fuori dalla foto: le lasciano tutta la
    // larghezza possibile.
    const corner = 9.0;
    final photoW = math.min(w - (corner + 6) * 2, 760.0);
    final photoH = photoW / 1.5;
    final total = photos.length;
    final phrase = widget.content.heroTitle.replaceAll('\n', ' ').trim();
    final meta = photo == null
        ? ''
        : [
            photo.category,
            photo.location,
            photo.year,
          ].where((e) => e.trim().isNotEmpty).join(' · ');

    final framed = _swipe(
      SizedBox(
        width: photoW + corner * 2,
        height: photoH + corner * 2,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(corner),
                child: ClipRect(child: _photoStack(photo, next)),
              ),
            ),
            const Positioned.fill(
              child: Viewfinder(color: Palette.ink, length: 22, stroke: 1.2),
            ),
          ],
        ),
      ),
    );

    final description = AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      // Prima esce la descrizione vecchia, poi entra la nuova: i due testi
      // non si sovrappongono.
      switchInCurve: const Interval(0.5, 1, curve: Curves.easeOut),
      switchOutCurve: const Interval(0.5, 1, curve: Curves.easeIn),
      child: Column(
        key: ValueKey(photo?.id),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (total > 1)
            Text(
              (_i + 1).toString().padLeft(2, '0'),
              style: display(34, color: context.accentInk, height: 1),
            ),
          const SizedBox(height: 10),
          Text(
            photo?.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: display(24, italic: true, height: 1.2),
          ),
          if ((photo?.caption ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              photo!.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: body(14.5, color: Palette.stone, height: 1.5),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              meta.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: label(9.5, color: Palette.stone),
            ),
          ],
        ],
      ),
    );

    final group = SizedBox(
      width: w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (phrase.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: g),
              child: Text(
                phrase.toUpperCase(),
                textAlign: TextAlign.center,
                style: label(10.5, color: Palette.stone),
              ),
            ),
            const SizedBox(height: 20),
          ],
          framed,
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: g),
            child: description,
          ),
        ],
      ),
    );

    final controls = total < 2
        ? const SizedBox.shrink()
        : Padding(
            padding: EdgeInsets.fromLTRB(g, 0, g, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Progress(index: _i, total: total),
                const SizedBox(height: 12),
                Row(
                  children: [
                    RoundIconButton(
                      Icons.chevron_left_rounded,
                      () => _go(_i - 1),
                      'Foto precedente',
                    ),
                    Expanded(
                      child: Text(
                        '${(_i + 1).toString().padLeft(2, '0')} / '
                        '${total.toString().padLeft(2, '0')}',
                        textAlign: TextAlign.center,
                        style: cameraText(10.5),
                      ),
                    ),
                    RoundIconButton(
                      Icons.chevron_right_rounded,
                      () => _go(_i + 1),
                      'Foto successiva',
                    ),
                  ],
                ),
              ],
            ),
          );

    return SizedBox(
      // Tutto lo schermo sotto la barra in alto.
      height: context.screenH - context.navH,
      child: Column(
        children: [
          Expanded(
            child: Center(
              // Su schermi molto bassi si rimpicciolisce invece di sforare.
              child: FittedBox(fit: BoxFit.scaleDown, child: group),
            ),
          ),
          controls,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = _shown;
    final photo = photos.isEmpty ? null : photos[_i % photos.length];
    final next = photos.length < 2 ? null : photos[(_i + 1) % photos.length];
    // Schermo in verticale (telefono, tablet in verticale): composizione a
    // tutta pagina con la foto al centro e la descrizione sotto.
    if (context.h > context.w) return _portrait(photos, photo, next);

    // In orizzontale la foto riempie tutto lo schermo sotto la barra, con
    // gli angoli del mirino che la racchiudono e la descrizione in basso.
    final g = context.gutter;
    final inset = g * 0.6;
    return SizedBox(
      height: context.screenH - context.navH,
      child: _swipe(
        ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Palette.linen),
              _photoStack(photo, next, fit: BoxFit.cover, zoom: true),
              // Solo in basso una velatura leggera, per leggere le scritte.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x8C000000),
                    ],
                    stops: [0, 0.62, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(inset),
                child: const Viewfinder(
                  color: Color(0xCCFFFAF0),
                  length: 30,
                  stroke: 1.2,
                ),
              ),
              Positioned(
                left: inset + 26,
                right: inset + 26,
                bottom: inset + 20,
                child: _HeroBar(
                  index: _i,
                  total: photos.length,
                  photo: photo,
                  phrase: widget.content.heroTitle,
                  onPrev: () => _go(_i - 1),
                  onNext: () => _go(_i + 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avanzamento: un segmento per foto, come i capitoli di un racconto (con
/// moltissime foto, una sola linea che avanza).
class _Progress extends StatelessWidget {
  const _Progress({
    required this.index,
    required this.total,
    this.color = Palette.ink,
    this.track = Palette.line,
  });
  final int index;
  final int total;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    if (total > 12) {
      return Container(
        height: 2,
        color: track,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: (index + 1) / total,
          child: Container(color: color),
        ),
      );
    }
    return Row(
      children: [
        for (var k = 0; k < total; k++) ...[
          if (k > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 2,
              color: k < index ? color : track,
              alignment: Alignment.centerLeft,
              child: k != index
                  ? null
                  : TweenAnimationBuilder<double>(
                      key: ValueKey('seg$index'),
                      tween: Tween(begin: 0, end: 1),
                      duration: HeroSlideshow.interval,
                      builder: (_, v, _) => FractionallySizedBox(
                        widthFactor: v,
                        child: Container(color: color),
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Descrizione e comandi sopra la foto a tutto schermo, in chiaro.
class _HeroBar extends StatelessWidget {
  const _HeroBar({
    required this.index,
    required this.total,
    required this.photo,
    required this.phrase,
    required this.onPrev,
    required this.onNext,
  });
  final int index;
  final int total;
  final GalleryPhoto? photo;
  final String phrase;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _light = Palette.paper;
  static const _soft = Color(0xD9FFFAF0);

  @override
  Widget build(BuildContext context) {
    final counter =
        '${(index + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}';
    final meta = photo == null
        ? ''
        : [
            photo!.category,
            photo!.location,
            photo!.year,
          ].where((e) => e.trim().isNotEmpty).join(' · ');
    final text = AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: const Interval(0.5, 1, curve: Curves.easeOut),
      switchOutCurve: const Interval(0.5, 1, curve: Curves.easeIn),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.bottomLeft,
        children: [...previous, ?current],
      ),
      child: Column(
        key: ValueKey(photo?.id),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            photo?.title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: display(
              context.fluid(22, 30),
              italic: true,
              color: _light,
              height: 1.2,
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meta.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: label(10, color: _soft),
            ),
          ],
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: text),
            if (total > 1) ...[
              const SizedBox(width: 16),
              Text(counter, style: cameraText(10.5, color: _soft)),
              const SizedBox(width: 12),
              RoundIconButton(
                Icons.chevron_left_rounded,
                onPrev,
                'Foto precedente',
                light: true,
              ),
              const SizedBox(width: 6),
              RoundIconButton(
                Icons.chevron_right_rounded,
                onNext,
                'Foto successiva',
                light: true,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (total > 1)
          _Progress(
            index: index,
            total: total,
            color: _light,
            track: const Color(0x4DFFFAF0),
          ),
        if (phrase.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            phrase.replaceAll('\n', ' ').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: label(10, color: _soft),
          ),
        ],
      ],
    );
  }
}

// ============================================================ MANIFESTO

/// Una frase sola, centrata, sotto l'apertura.
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
              const BrandMark(height: 34),
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
      color: Palette.linen,
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
