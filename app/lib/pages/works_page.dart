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

// I lavori dello studio, come sul sito: i filtri in alto e tutte le schede;
// ogni lavoro mostra solo le sue foto, una sotto l'altra.

const _maxW = 1240.0;

String _two(int n) => n.toString().padLeft(2, '0');

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
        if (options.isNotEmpty)
          _Wrap(
            top: context.fluid(14, 32),
            bottom: context.fluid(26, 44),
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
          top: options.isEmpty ? context.fluid(14, 32) : 0,
          bottom: context.fluid(70, 120),
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
              : WorkList(works: works),
        ),
      ],
    );
  }
}

/// Filtri discreti, come la didascalia di una mostra: una riga sola di
/// voci ("Evento · Tutti"), ognuna con il suo piccolo menu.
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
    final menus = Wrap(
      spacing: context.fluid(22, 44),
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (id, title, values, sel) in groups)
          _FilterMenu(
            title: title,
            values: values,
            selected: sel,
            onSelect: (v) => onSelect(id, v),
          ),
      ],
    );
    final result = filtering
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_two(shown)} ${shown == 1 ? 'TROVATO' : 'TROVATI'}',
                style: cameraText(10.5),
              ),
              const SizedBox(width: 16),
              HoverLink('AZZERA', style: label(10.5), onTap: onClear),
            ],
          )
        : null;
    if (context.isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          menus,
          if (result != null) ...[const SizedBox(height: 10), result],
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: menus),
        ?result,
      ],
    );
  }
}

/// Una voce del filtro: il nome piccolo e il valore scelto in corsivo, che
/// apre l'elenco delle scelte.
class _FilterMenu extends StatefulWidget {
  const _FilterMenu({
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
  State<_FilterMenu> createState() => _FilterMenuState();
}

class _FilterMenuState extends State<_FilterMenu> {
  bool _hover = false;

  /// "Tutti" nel menu (un valore nullo chiuderebbe il menu senza scelta).
  static const _all = '\u0000';

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final on = sel != null;
    bool isSel(String v) => sel != null && _key(sel) == _key(v);
    PopupMenuItem<String> item(String value, String text, bool active) =>
        PopupMenuItem(
          value: value,
          height: 42,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: display(
                    16,
                    italic: active,
                    color: active ? Palette.ink : Palette.stone,
                  ),
                ),
              ),
              if (active)
                const Icon(Icons.check_rounded, size: 16, color: Palette.ink),
            ],
          ),
        );

    final plain = Theme.of(context).copyWith(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      // Niente riquadri al tocco né fumetti: basta la sottolineatura.
      child: Theme(
        data: plain,
        child: TooltipVisibility(
          visible: false,
          child: PopupMenuButton<String>(
            key: ValueKey('filtro-${widget.title.toLowerCase()}'),
            tooltip: 'Filtra per ${widget.title.toLowerCase()}',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 6),
            color: Palette.ivory,
            surfaceTintColor: Colors.transparent,
            elevation: 3,
            shadowColor: const Color(0x331E1B17),
            constraints: const BoxConstraints(minWidth: 190),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Palette.line),
            ),
            onSelected: (v) => widget.onSelect(v == _all ? null : v),
            itemBuilder: (_) => [
              item(_all, 'Tutti', !on),
              for (final v in widget.values) item(v, v, isSel(v)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: label(10, color: Palette.stone),
                      ),
                      const SizedBox(width: 10),
                      // Larghezza fissa, quella della scelta più lunga: le
                      // voci accanto non si spostano cambiando la scelta.
                      ConstrainedBox(
                        // Nomi molto lunghi: si accorciano con i puntini.
                        constraints: BoxConstraints(
                          maxWidth: context.isPhone ? 150 : 220,
                        ),
                        child: Stack(
                          children: [
                            for (final v in ['Tutti', ...widget.values])
                              Visibility(
                                visible: on ? isSel(v) : v == 'Tutti',
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                child: Text(
                                  v,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: display(
                                    17,
                                    italic: true,
                                    color: on ? Palette.ink : Palette.stone,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: on ? Palette.ink : Palette.ash,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Sottolineatura sottile: piena se il filtro è attivo.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    height: 1,
                    width: on || _hover ? 40 : 0,
                    color: Palette.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================== DETTAGLIO

/// Un lavoro: solo le sue foto, intere, una sotto l'altra (orizzontali e
/// verticali). Toccandone una si apre a schermo intero.
class WorkPage extends StatefulWidget {
  const WorkPage({super.key, required this.id});
  final String id;

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  final _aspects = PhotoAspects.instance;

  @override
  void initState() {
    super.initState();
    _aspects.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _aspects.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final w = s.publishedWorks.where((w) => w.id == widget.id).firstOrNull;
    if (w == null || w.photos.isEmpty) {
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
                HoverLink(
                  '← TUTTI I LAVORI',
                  style: label(11, color: Palette.stone),
                  onTap: () => context.go('/lavori'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final urls = [for (final p in w.photos) p.url];
    _aspects.resolveAll(urls);
    final gap = context.fluid(10, 22);
    return SiteScaffold(
      location: '/lavori',
      children: [
        _Wrap(
          top: context.fluid(14, 32),
          bottom: context.fluid(70, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < w.photos.length; i++) ...[
                    if (i > 0) SizedBox(height: gap),
                    Reveal(
                      child: Semantics(
                        button: true,
                        image: true,
                        label: w.photos[i].caption.trim().isEmpty
                            ? 'Foto ${i + 1}'
                            : w.photos[i].caption,
                        child: GestureDetector(
                          onTap: () => showPhotoViewer(context, urls, i),
                          child: AspectRatio(
                            // Proporzioni vere, così la foto non si taglia.
                            aspectRatio: (_aspects.of(urls[i]) ?? 1.5).clamp(
                              0.4,
                              3.0,
                            ),
                            child: PhotoImage(urls[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
