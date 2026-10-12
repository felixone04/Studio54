import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/lightbox.dart';
import '../widgets/photo_ui.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

// I lavori dello studio, raccontati come piccole mostre: un elenco di "sale"
// e, per ognuna, la scheda e la sequenza completa delle fotografie.

const _maxW = 1240.0;
const _gold = Color(0xFFE8C27A);
const _soft = Color(0xD9F6F5F2); // testo chiaro, un filo attenuato

String _two(int n) => n.toString().padLeft(2, '0');

String _meta(Work w) =>
    [w.location, w.date].where((e) => e.trim().isNotEmpty).join(' · ');

/// Contenuto centrato a larghezza massima.
class _Wrap extends StatelessWidget {
  const _Wrap({required this.child, this.top = 0, this.bottom = 0});
  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(context.gutter, top, context.gutter, bottom),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxW),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

// ==================================================================== ELENCO

class WorksPage extends StatefulWidget {
  const WorksPage({super.key});

  @override
  State<WorksPage> createState() => _WorksPageState();
}

class _WorksPageState extends State<WorksPage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = s.publishedWorks;
    // Tipi senza distinzione di maiuscole: "Matrimonio" e "matrimonio" sono
    // la stessa sala (a video compaiono comunque in maiuscolo).
    String key(String c) => c.trim().toLowerCase();
    final cats = <String>[];
    for (final w in all) {
      final c = w.category.trim();
      if (c.isNotEmpty && !cats.any((e) => key(e) == key(c))) cats.add(c);
    }
    final cat = cats.contains(_category) ? _category : null;
    final works = cat == null
        ? all
        : all.where((w) => key(w.category) == key(cat)).toList();

    return SiteScaffold(
      location: '/lavori',
      darkHero: true,
      darkPage: true,
      grain: true,
      children: [
        _Wrap(
          top: context.fluid(66, 88) + context.fluid(48, 110),
          bottom: context.fluid(36, 64),
          child: _Header(count: all.length),
        ),
        if (cats.length > 1)
          _Wrap(
            bottom: context.fluid(28, 48),
            child: _Filters(
              categories: cats,
              selected: cat,
              onSelect: (c) => setState(() => _category = c),
            ),
          ),
        _Wrap(
          bottom: context.fluid(80, 140),
          child: works.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Text(
                    'Presto qui i nostri lavori.',
                    style: display(22, color: Palette.ash, italic: true),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < works.length; i++) ...[
                      Container(height: 1, color: Palette.lineDark),
                      SizedBox(height: context.fluid(28, 56)),
                      Reveal(
                        child: _WorkRow(
                          work: works[i],
                          number: i + 1,
                          flip: i.isOdd,
                        ),
                      ),
                      SizedBox(height: context.fluid(28, 56)),
                    ],
                    Container(height: 1, color: Palette.lineDark),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MaskReveal(child: Tag('Lavori', color: Palette.paper)),
        SizedBox(height: context.fluid(14, 20)),
        MaskReveal(
          delay: 120,
          child: Text(
            'OGNI LAVORO,\nUNA MOSTRA',
            style: display(
              context.fluid(32, 60),
              color: Palette.paper,
              spacing: 0.08,
              height: 1.08,
            ),
          ),
        ),
        SizedBox(height: context.fluid(14, 20)),
        MaskReveal(
          delay: 240,
          child: Text(
            'Matrimoni ed eventi raccontati dall\'inizio alla fine.',
            style: display(
              context.fluid(17, 21),
              color: Palette.ash,
              italic: true,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
    // Contatore come sul display di una fotocamera.
    final counter = Text(
      '${_two(count)} ${count == 1 ? 'LAVORO' : 'LAVORI'}',
      style: cameraText(11, color: Palette.ash),
    );
    if (context.isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [text, const SizedBox(height: 20), counter],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        counter,
      ],
    );
  }
}

/// Filtro per tipo, come le sale di una mostra.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget item(String text, bool active, VoidCallback onTap) => HoverLink(
      text.toUpperCase(),
      active: active,
      style: label(11, color: active ? Palette.paper : Palette.ash),
      onTap: onTap,
    );
    return Wrap(
      spacing: context.fluid(18, 30),
      runSpacing: 12,
      children: [
        item('Tutti', selected == null, () => onSelect(null)),
        for (final c in categories) item(c, selected == c, () => onSelect(c)),
      ],
    );
  }
}

/// Una "sala": copertina grande e scheda, alternate a destra e sinistra.
class _WorkRow extends StatefulWidget {
  const _WorkRow({
    required this.work,
    required this.number,
    required this.flip,
  });
  final Work work;
  final int number;
  final bool flip;

  @override
  State<_WorkRow> createState() => _WorkRowState();
}

class _WorkRowState extends State<_WorkRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.work;
    void open() => context.go('/lavori/${w.id}');
    final image = AspectRatio(
      aspectRatio: 3 / 2,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedScale(
              scale: _hover ? 1.04 : 1,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              child: PhotoImage(w.coverUrl, dark: true),
            ),
            AnimatedOpacity(
              opacity: _hover ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: const ThirdsGrid(opacity: 0.6),
            ),
            FocusFrame(active: _hover, length: 22, inset: 16),
          ],
        ),
      ),
    );
    final meta = _meta(w);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '${_two(widget.number)}A',
              style: cameraText(11, color: _gold),
            ),
            if (w.category.trim().isNotEmpty) ...[
              Container(
                width: 22,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Palette.lineDark,
              ),
              Flexible(
                child: Text(
                  w.category.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: label(10.5, color: Palette.ash),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: context.fluid(14, 20)),
        Text(
          w.title.toUpperCase(),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: display(
            context.fluid(26, 40),
            color: Palette.paper,
            spacing: 0.06,
            height: 1.12,
          ),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            meta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: display(17, color: Palette.ash, italic: true),
          ),
        ],
        if (w.story.trim().isNotEmpty) ...[
          SizedBox(height: context.fluid(16, 22)),
          Text(
            w.story,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: body(15, color: _soft, height: 1.65),
          ),
        ],
        SizedBox(height: context.fluid(20, 28)),
        Row(
          children: [
            Text(
              '${_two(w.photos.length)} SCATTI',
              style: cameraText(10.5, color: Palette.ash),
            ),
            const SizedBox(width: 18),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: _hover ? 56 : 28,
              height: 1,
              color: Palette.paper,
            ),
            const SizedBox(width: 10),
            Text('GUARDA', style: label(10.5, color: Palette.paper)),
          ],
        ),
      ],
    );

    final Widget content;
    if (context.isTablet) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [image, const SizedBox(height: 22), text],
      );
    } else {
      final gap = SizedBox(width: context.fluid(36, 72));
      final img = Expanded(flex: 7, child: image);
      final txt = Expanded(flex: 5, child: text);
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.flip ? [txt, gap, img] : [img, gap, txt],
      );
    }

    return Semantics(
      button: true,
      label: 'Lavoro ${w.title}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: open,
          child: content,
        ),
      ),
    );
  }
}

// =================================================================== DETTAGLIO

class WorkPage extends StatelessWidget {
  const WorkPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.publishedWorks;
    final i = list.indexWhere((w) => w.id == id);
    if (i < 0) {
      return SiteScaffold(
        location: '/lavori',
        darkHero: true,
        darkPage: true,
        grain: true,
        children: [
          _Wrap(
            top: context.fluid(66, 88) + 120,
            bottom: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questo lavoro non è più in mostra.',
                  style: display(
                    context.fluid(24, 34),
                    color: Palette.paper,
                    italic: true,
                  ),
                ),
                const SizedBox(height: 24),
                const _BackLink(),
              ],
            ),
          ),
        ],
      );
    }
    final w = list[i];
    final next = list.length > 1 ? list[(i + 1) % list.length] : null;

    return SiteScaffold(
      location: '/lavori',
      darkHero: true,
      darkPage: true,
      grain: true,
      children: [
        PageHero(
          image: w.coverUrl,
          title: w.title,
          subtitle: _meta(w),
          kicker: w.category.trim().isEmpty ? 'Lavoro' : w.category,
        ),
        _Wrap(
          top: context.fluid(56, 110),
          bottom: context.fluid(56, 100),
          child: _Label(work: w),
        ),
        if (w.photos.isNotEmpty)
          _Wrap(
            bottom: context.fluid(70, 130),
            child: _Plates(work: w),
          ),
        _Wrap(
          bottom: context.fluid(70, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 1, color: Palette.lineDark),
              const SizedBox(height: 28),
              if (next != null) ...[
                _NextWork(work: next),
                const SizedBox(height: 36),
              ],
              const _BackLink(),
            ],
          ),
        ),
      ],
    );
  }
}

/// La "didascalia da museo": racconto a sinistra, scheda tecnica a destra.
class _Label extends StatelessWidget {
  const _Label({required this.work});
  final Work work;

  @override
  Widget build(BuildContext context) {
    final w = work;
    final rows = <(String, String)>[
      if (w.category.trim().isNotEmpty) ('Tipo', w.category),
      if (w.location.trim().isNotEmpty) ('Luogo', w.location),
      if (w.date.trim().isNotEmpty) ('Data', w.date),
      if (w.credits.trim().isNotEmpty) ('Realizzato', w.credits),
      ('Scatti', _two(w.photos.length)),
    ];
    final sheet = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SCHEDA', style: cameraText(10.5, color: _gold)),
        const SizedBox(height: 14),
        for (final (k, v) in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Palette.lineDark)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104,
                  child: Text(
                    k.toUpperCase(),
                    style: label(10, color: Palette.ash),
                  ),
                ),
                Expanded(
                  child: Text(
                    v,
                    style: body(14.5, color: Palette.paper, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        Container(height: 1, color: Palette.lineDark),
      ],
    );
    final story = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Tag('Il racconto', color: Palette.paper),
        SizedBox(height: context.fluid(18, 26)),
        Text(
          w.story.trim().isEmpty ? w.title : w.story,
          style: display(context.fluid(19, 25), color: _soft, height: 1.55),
        ),
      ],
    );
    if (context.isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [story, const SizedBox(height: 40), sheet],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: story),
        SizedBox(width: context.fluid(48, 96)),
        Expanded(flex: 4, child: sheet),
      ],
    );
  }
}

/// Le fotografie, numerate come tavole di un catalogo. Ritmo: una grande,
/// poi due affiancate (su telefono tutte una sotto l'altra).
class _Plates extends StatelessWidget {
  const _Plates({required this.work});
  final Work work;

  @override
  Widget build(BuildContext context) {
    final photos = work.photos;
    final lightbox = [
      for (final p in photos)
        GalleryPhoto(
          id: p.id,
          url: p.url,
          title: p.caption.trim().isEmpty ? work.title : p.caption,
          category: work.category,
          location: work.location,
          year: work.date,
        ),
    ];
    void open(int i) => showPhotoLightbox(context, lightbox, i);
    final gap = context.fluid(14, 28);
    final rows = <Widget>[];
    var i = 0;
    while (i < photos.length) {
      final single = context.isPhone || i % 3 == 0 || i == photos.length - 1;
      if (single) {
        final idx = i;
        rows.add(
          _Plate(
            photo: photos[idx],
            number: idx + 1,
            aspect: context.isPhone ? 4 / 5 : 16 / 9,
            onTap: () => open(idx),
          ),
        );
        i++;
      } else {
        final a = i, b = i + 1;
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Plate(
                  photo: photos[a],
                  number: a + 1,
                  aspect: 4 / 5,
                  onTap: () => open(a),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _Plate(
                  photo: photos[b],
                  number: b + 1,
                  aspect: 4 / 5,
                  onTap: () => open(b),
                ),
              ),
            ],
          ),
        );
        i += 2;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: gap * 2),
          Reveal(child: rows[r]),
        ],
      ],
    );
  }
}

class _Plate extends StatefulWidget {
  const _Plate({
    required this.photo,
    required this.number,
    required this.aspect,
    required this.onTap,
  });
  final WorkPhoto photo;
  final int number;
  final double aspect;
  final VoidCallback onTap;

  @override
  State<_Plate> createState() => _PlateState();
}

class _PlateState extends State<_Plate> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.photo;
    return Semantics(
      button: true,
      label: p.caption.trim().isEmpty
          ? 'Tavola ${widget.number}'
          : 'Tavola ${widget.number}: ${p.caption}',
      child: MouseRegion(
        cursor: SystemMouseCursors.zoomIn,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: widget.aspect,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PhotoImage(p.url, dark: true),
                    FocusFrame(active: _hover, length: 18, inset: 14),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TAV. ${_two(widget.number)}',
                    style: cameraText(10, color: _gold),
                  ),
                  if (p.caption.trim().isNotEmpty) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        p.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: display(
                          15,
                          color: Palette.ash,
                          italic: true,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Passaggio alla "sala" successiva.
class _NextWork extends StatefulWidget {
  const _NextWork({required this.work});
  final Work work;

  @override
  State<_NextWork> createState() => _NextWorkState();
}

class _NextWorkState extends State<_NextWork> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.work;
    final thumb = context.isPhone ? 96.0 : 150.0;
    return Semantics(
      button: true,
      label: 'Lavoro successivo: ${w.title}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go('/lavori/${w.id}'),
          child: Row(
            children: [
              SizedBox(
                width: thumb,
                height: thumb * 2 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PhotoImage(w.coverUrl, dark: true),
                    FocusFrame(active: _hover, length: 12, inset: 8),
                  ],
                ),
              ),
              SizedBox(width: context.fluid(18, 32)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAVORO SUCCESSIVO',
                      style: label(10, color: Palette.ash),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      w.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: display(
                        context.fluid(20, 30),
                        color: Palette.paper,
                        spacing: 0.06,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: Offset(_hover ? 0.25 : 0, 0),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Palette.paper,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink();

  @override
  Widget build(BuildContext context) => HoverLink(
    '← TUTTI I LAVORI',
    style: label(11, color: Palette.ash),
    onTap: () => context.go('/lavori'),
  );
}
