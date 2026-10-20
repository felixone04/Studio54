import 'dart:math' as math;

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

// I lavori dello studio: un elenco filtrabile (evento, stagione, location) e,
// per ognuno, solo le fotografie, composte in un collage.

const _maxW = 1240.0;

String _two(int n) => n.toString().padLeft(2, '0');

String _meta(Work w) =>
    [w.location, w.date].where((e) => e.trim().isNotEmpty).join(' · ');

/// Valori senza distinzione di maiuscole: "Mare" e "mare" sono lo stesso.
String _key(String v) => v.trim().toLowerCase();

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

/// Un criterio di filtro: come leggere il valore da un lavoro.
class _Facet {
  const _Facet(this.id, this.title, this.read, {this.order});
  final String id;
  final String title;
  final String Function(Work) read;

  /// Ordine fisso dei valori (es. le stagioni), altrimenti quello dei lavori.
  final List<String>? order;
}

final _facets = [
  _Facet('evento', 'Evento', (w) => w.category),
  _Facet('stagione', 'Stagione', (w) => w.seasonLabel, order: seasons),
  _Facet('location', 'Location', (w) => w.setting),
];

class WorksPage extends StatefulWidget {
  const WorksPage({super.key});

  @override
  State<WorksPage> createState() => _WorksPageState();
}

class _WorksPageState extends State<WorksPage> {
  /// Valore scelto per ogni criterio (assente = tutti).
  final _selected = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = s.publishedWorks;

    // Valori presenti per ogni criterio; si mostra solo se c'è da scegliere.
    final options = <_Facet, List<String>>{};
    for (final f in _facets) {
      final vals = <String>[];
      for (final w in all) {
        final v = f.read(w).trim();
        if (v.isNotEmpty && !vals.any((e) => _key(e) == _key(v))) vals.add(v);
      }
      if (f.order != null) {
        int pos(String v) {
          final i = f.order!.indexWhere((o) => _key(o) == _key(v));
          return i < 0 ? 99 : i;
        }

        vals.sort((a, b) => pos(a).compareTo(pos(b)));
      }
      if (vals.length > 1) options[f] = vals;
    }
    // Una scelta che non esiste più (lavoro nascosto o modificato) si toglie.
    String? chosen(_Facet f) {
      final v = _selected[f.id];
      final vals = options[f];
      if (v == null || vals == null) return null;
      return vals.any((e) => _key(e) == _key(v)) ? v : null;
    }

    final works = all.where((w) {
      for (final f in _facets) {
        final v = chosen(f);
        if (v != null && _key(f.read(w)) != _key(v)) return false;
      }
      return true;
    }).toList();
    final filtering = _facets.any((f) => chosen(f) != null);

    return SiteScaffold(
      location: '/lavori',
      children: [
        _Wrap(
          top: context.fluid(40, 90),
          bottom: context.fluid(28, 48),
          child: _Header(count: all.length),
        ),
        if (options.isNotEmpty)
          _Wrap(
            bottom: context.fluid(28, 48),
            child: _Filters(
              groups: [
                for (final f in _facets)
                  if (options[f] != null)
                    (f.id, f.title, options[f]!, chosen(f)),
              ],
              shown: works.length,
              filtering: filtering,
              onSelect: (id, v) => setState(() {
                if (v == null) {
                  _selected.remove(id);
                } else {
                  _selected[id] = v;
                }
              }),
              onClear: () => setState(_selected.clear),
            ),
          ),
        _Wrap(
          bottom: context.fluid(80, 140),
          child: works.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Text(
                    all.isEmpty
                        ? 'Presto qui i nostri lavori.'
                        : 'Nessun lavoro con questi filtri.',
                    style: display(22, color: Palette.stone, italic: true),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < works.length; i++) ...[
                      Container(height: 1, color: Palette.line),
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
                    Container(height: 1, color: Palette.line),
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
        const MaskReveal(child: Tag('Lavori')),
        SizedBox(height: context.fluid(14, 20)),
        MaskReveal(
          delay: 120,
          child: Text(
            'OGNI LAVORO,\nUNA STORIA',
            style: display(context.fluid(32, 60), spacing: 0.08, height: 1.08),
          ),
        ),
        SizedBox(height: context.fluid(14, 20)),
        MaskReveal(
          delay: 240,
          child: Text(
            'Matrimoni ed eventi raccontati dall\'inizio alla fine.',
            style: display(
              context.fluid(17, 21),
              color: Palette.stone,
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
      style: cameraText(11),
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

/// Filtri: per ogni criterio una fila di pulsanti a pillola.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.groups,
    required this.shown,
    required this.filtering,
    required this.onSelect,
    required this.onClear,
  });

  /// (id, titolo, valori, valore scelto)
  final List<(String, String, List<String>, String?)> groups;
  final int shown;
  final bool filtering;
  final void Function(String id, String? value) onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (final (id, title, values, sel) in groups)
        _FilterRow(
          title: title,
          values: values,
          selected: sel,
          onSelect: (v) => onSelect(id, v),
        ),
    ];
    return Container(
      padding: EdgeInsets.all(context.fluid(16, 26)),
      decoration: BoxDecoration(
        color: Palette.linen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: context.fluid(14, 18)),
            rows[i],
          ],
          SizedBox(height: context.fluid(14, 18)),
          Container(height: 1, color: Palette.line),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_two(shown)} ${shown == 1 ? 'LAVORO' : 'LAVORI'}'
                  '${filtering ? (shown == 1 ? ' TROVATO' : ' TROVATI') : ''}',
                  style: cameraText(10.5),
                ),
              ),
              if (filtering)
                HoverLink(
                  'AZZERA FILTRI',
                  style: label(10.5),
                  onTap: onClear,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelect,
  });
  final String title;
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill('Tutti', active: selected == null, onTap: () => onSelect(null)),
        for (final v in values)
          _Pill(
            v,
            active: selected != null && _key(selected!) == _key(v),
            // Un secondo tocco sul valore scelto lo toglie.
            onTap: () => onSelect(
              selected != null && _key(selected!) == _key(v) ? null : v,
            ),
          ),
      ],
    );
    final head = Text(title.toUpperCase(), style: label(10.5));
    if (context.isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [head, const SizedBox(height: 10), chips],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Padding(padding: const EdgeInsets.only(top: 9), child: head),
        ),
        Expanded(child: chips),
      ],
    );
  }
}

class _Pill extends StatefulWidget {
  const _Pill(this.text, {required this.active, required this.onTap});
  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active;
    return Semantics(
      button: true,
      selected: on,
      label: widget.text,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: on
                  ? Palette.ink
                  : (_hover ? Palette.ivory : Palette.paper),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: on || _hover ? Palette.ink : Palette.lineStrong,
              ),
            ),
            child: Text(
              widget.text.toUpperCase(),
              style: label(10.5, color: on ? Palette.paper : Palette.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un lavoro dell'elenco: copertina grande e presentazione, alternate a
/// destra e sinistra.
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
              child: PhotoImage(w.coverUrl),
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
    final tags = [
      w.setting,
      w.seasonLabel,
    ].where((e) => e.trim().isNotEmpty).toList();
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '${_two(widget.number)}A',
              style: cameraText(11, color: context.accentInk),
            ),
            if (w.category.trim().isNotEmpty) ...[
              Container(
                width: 22,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Palette.lineStrong,
              ),
              Flexible(
                child: Text(
                  w.category.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: label(10.5, color: Palette.stone),
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
          style: display(context.fluid(26, 40), spacing: 0.06, height: 1.12),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            meta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: display(17, color: Palette.stone, italic: true),
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.linen,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    t.toUpperCase(),
                    style: label(9.5, color: Palette.stone),
                  ),
                ),
            ],
          ),
        ],
        if (w.story.trim().isNotEmpty) ...[
          SizedBox(height: context.fluid(16, 22)),
          Text(
            w.story,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: body(15, color: Palette.stone, height: 1.65),
          ),
        ],
        SizedBox(height: context.fluid(20, 28)),
        Row(
          children: [
            Text('${_two(w.photos.length)} SCATTI', style: cameraText(10.5)),
            const SizedBox(width: 18),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: _hover ? 56 : 28,
              height: 1,
              color: Palette.ink,
            ),
            const SizedBox(width: 10),
            Text('GUARDA', style: label(10.5)),
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
        children: [
          _Wrap(
            top: 120,
            bottom: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questo lavoro non è più in mostra.',
                  style: display(context.fluid(24, 34), italic: true),
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
      children: [
        _Wrap(
          top: context.fluid(28, 56),
          bottom: context.fluid(24, 40),
          child: _DetailHeader(work: w),
        ),
        if (w.photos.isNotEmpty)
          _Wrap(
            bottom: context.fluid(70, 130),
            child: _Collage(work: w),
          ),
        _Wrap(
          bottom: context.fluid(70, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 1, color: Palette.line),
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

/// Solo il nome del lavoro e una riga di informazioni: il resto sono foto.
class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.work});
  final Work work;

  @override
  Widget build(BuildContext context) {
    final w = work;
    final info = [
      w.category,
      w.setting,
      w.seasonLabel,
      w.location,
      w.date,
    ].where((e) => e.trim().isNotEmpty).join('  ·  ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BackLink(),
        SizedBox(height: context.fluid(14, 22)),
        MaskReveal(
          child: Text(
            w.title.toUpperCase(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: display(context.fluid(30, 52), spacing: 0.08, height: 1.1),
          ),
        ),
        if (info.isNotEmpty) ...[
          const SizedBox(height: 10),
          MaskReveal(
            delay: 120,
            child: Text(
              info.toUpperCase(),
              style: label(10.5, color: Palette.stone),
            ),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------ collage

/// Composizione di una riga del collage.
sealed class _Row {
  const _Row();
}

/// Una foto sola a tutta larghezza (o, se verticale, centrata).
class _Single extends _Row {
  const _Single(this.i);
  final int i;
}

/// Foto affiancate alla stessa altezza.
class _Side extends _Row {
  const _Side(this.ids);
  final List<int> ids;
}

/// Una verticale accanto a due orizzontali una sopra l'altra.
class _Stack extends _Row {
  const _Stack(this.tall, this.top, this.bottom, {required this.tallLeft});
  final int tall;
  final int top;
  final int bottom;
  final bool tallLeft;
}

/// Sceglie la composizione delle righe dalle proporzioni delle foto, nel
/// loro ordine: la prima (orizzontale) grande, poi ritmi diversi che si
/// alternano — una verticale e due orizzontali, una orizzontale e due
/// verticali, coppie, foto singole.
List<_Row> _plan(List<bool> landscape) {
  final n = landscape.length;
  final rows = <_Row>[];
  if (n == 0) return rows;
  rows.add(const _Single(0));
  var k = 1;
  var variant = 0;
  bool? o(int d) => k + d < n ? landscape[k + d] : null;
  while (k < n) {
    final a = o(0)!, b = o(1), c = o(2);
    if (!a) {
      if (b == true && c == true) {
        rows.add(_Stack(k, k + 1, k + 2, tallLeft: true));
        k += 3;
      } else if (b == false && c != null) {
        rows.add(_Side([k, k + 1, k + 2]));
        k += 3;
      } else if (b != null) {
        rows.add(_Side([k, k + 1]));
        k += 2;
      } else {
        rows.add(_Single(k));
        k += 1;
      }
    } else {
      if (b == false && c == false) {
        rows.add(_Side([k, k + 1, k + 2]));
        k += 3;
      } else if (b == true && c == false) {
        rows.add(_Stack(k + 2, k, k + 1, tallLeft: false));
        k += 3;
      } else if (b == true && c == true && variant.isOdd) {
        rows.add(_Single(k));
        k += 1;
      } else if (b != null) {
        rows.add(_Side([k, k + 1]));
        k += 2;
      } else {
        rows.add(_Single(k));
        k += 1;
      }
    }
    variant++;
  }
  return rows;
}

class _Collage extends StatefulWidget {
  const _Collage({required this.work});
  final Work work;

  @override
  State<_Collage> createState() => _CollageState();
}

class _CollageState extends State<_Collage> {
  final _aspects = PhotoAspects.instance;

  @override
  void initState() {
    super.initState();
    _aspects.addListener(_changed);
    _aspects.resolveAll(widget.work.photos.map((p) => p.url));
  }

  @override
  void didUpdateWidget(_Collage old) {
    super.didUpdateWidget(old);
    _aspects.resolveAll(widget.work.photos.map((p) => p.url));
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _aspects.removeListener(_changed);
    super.dispose();
  }

  /// Proporzione nota, altrimenti si suppone una classica 3:2 orizzontale.
  double _ratio(WorkPhoto p) => (_aspects.of(p.url) ?? 1.5).clamp(0.4, 3.0);

  @override
  Widget build(BuildContext context) {
    final w = widget.work;
    // In apertura la prima foto orizzontale; le altre restano in ordine.
    final lead = w.photos.indexWhere((p) => _ratio(p) > 1);
    final photos = [
      if (lead > 0) w.photos[lead],
      for (var i = 0; i < w.photos.length; i++)
        if (i != lead || lead <= 0) w.photos[i],
    ];
    final lightbox = [
      for (final p in photos)
        GalleryPhoto(
          id: p.id,
          url: p.url,
          title: p.caption.trim().isEmpty ? w.title : p.caption,
          category: w.category,
          location: w.location,
          year: w.date,
        ),
    ];
    void open(int i) => showPhotoLightbox(context, lightbox, i);
    final ratios = [for (final p in photos) _ratio(p)];
    final gap = context.fluid(10, 22);
    final maxH = context.h * 0.9;

    Widget tile(int i, double width, double photoH) => _Plate(
      photo: photos[i],
      number: i + 1,
      width: width,
      photoHeight: photoH,
      onTap: () => open(i),
    );

    return LayoutBuilder(
      builder: (context, box) {
        // Un pixel di margine: le misure calcolate non sforano per gli
        // arrotondamenti.
        final full = box.maxWidth.floorToDouble() - 1;
        final rows = <Widget>[];

        // Telefono: una sotto l'altra, intere, facili da scorrere.
        if (context.isPhone) {
          for (var i = 0; i < photos.length; i++) {
            rows.add(tile(i, full, full / ratios[i]));
          }
        } else {
          for (final r in _plan([for (final a in ratios) a > 1])) {
            switch (r) {
              case _Single(:final i):
                var h = full / ratios[i];
                // Una verticale da sola non deve superare lo schermo.
                if (ratios[i] <= 1) h = math.min(h, maxH);
                rows.add(Center(child: tile(i, h * ratios[i], h)));
              case _Side(:final ids):
                final sum = ids.fold<double>(0, (s, i) => s + ratios[i]);
                final h = math.min(
                  (full - gap * (ids.length - 1)) / sum,
                  maxH,
                );
                rows.add(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var j = 0; j < ids.length; j++) ...[
                        if (j > 0) SizedBox(width: gap),
                        tile(ids[j], h * ratios[ids[j]], h),
                      ],
                    ],
                  ),
                );
              case _Stack(:final tall, :final top, :final bottom, :final tallLeft):
                // Larghezza della colonna delle due orizzontali, in modo che
                // la verticale e la colonna finiscano alla stessa altezza.
                final av = ratios[tall];
                final k = 1 / ratios[top] + 1 / ratios[bottom];
                const cap = _Plate.captionH;
                final c = (full - gap - av * (cap + gap)) / (av * k + 1);
                final hp = c * k + cap + gap;
                final tallTile = tile(tall, av * hp, hp);
                final column = Column(
                  children: [
                    tile(top, c, c / ratios[top]),
                    SizedBox(height: gap),
                    tile(bottom, c, c / ratios[bottom]),
                  ],
                );
                rows.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tallLeft
                        ? [tallTile, SizedBox(width: gap), column]
                        : [column, SizedBox(width: gap), tallTile],
                  ),
                );
            }
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: gap * 1.6),
              Reveal(child: rows[r]),
            ],
          ],
        );
      },
    );
  }
}

/// Una foto del collage con la sua piccola didascalia.
class _Plate extends StatefulWidget {
  const _Plate({
    required this.photo,
    required this.number,
    required this.width,
    required this.photoHeight,
    required this.onTap,
  });
  final WorkPhoto photo;
  final int number;
  final double width;
  final double photoHeight;
  final VoidCallback onTap;

  /// Spazio fisso della didascalia, per allineare le foto del collage.
  static const captionH = 36.0;

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
          ? 'Foto ${widget.number}'
          : 'Foto ${widget.number}: ${p.caption}',
      child: MouseRegion(
        cursor: SystemMouseCursors.zoomIn,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: widget.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: widget.photoHeight,
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedScale(
                          scale: _hover ? 1.02 : 1,
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          child: PhotoImage(p.url),
                        ),
                        FocusFrame(active: _hover, length: 18, inset: 14),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: _Plate.captionH,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TAV. ${_two(widget.number)}',
                          style: cameraText(10, color: context.accentInk),
                        ),
                        if (p.caption.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: display(
                                15,
                                color: Palette.stone,
                                italic: true,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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

/// Passaggio al lavoro successivo.
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
                    PhotoImage(w.coverUrl),
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
                      style: label(10, color: Palette.stone),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      w.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: display(context.fluid(20, 30), spacing: 0.06),
                    ),
                  ],
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: Offset(_hover ? 0.25 : 0, 0),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Palette.ink,
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
    style: label(11, color: Palette.stone),
    onTap: () => context.go('/lavori'),
  );
}
