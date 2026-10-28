import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'admin_widgets.dart';

// ================================================================== LAVORI

class AdminWorks extends StatelessWidget {
  const AdminWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Lavori',
          subtitle:
              'Gli stessi sul sito e nell\'app. La stella mette un lavoro in '
              'evidenza nella home (al massimo ${maxFeatured.toString()}); Sito e '
              'App scelgono dove si vede. Trascina per riordinare.',
          actions: [
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _WorkDialog(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuovo lavoro'),
            ),
          ],
        ),
        Card(
          child: s.works.isEmpty
              ? const EmptyState(
                  icon: Icons.auto_stories_outlined,
                  message: 'Nessun lavoro ancora. Aggiungi il primo.',
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: s.works.length,
                  onReorderItem: (o, n) {
                    final l = [...s.works];
                    l.insert(n, l.removeAt(o));
                    s.setWorks(l);
                  },
                  itemBuilder: (context, i) {
                    final w = s.works[i];
                    final meta = [
                      w.category,
                      w.date,
                      '${w.photos.length} foto',
                      if (!w.onSite) 'non sul sito',
                      if (!w.onApp) 'non nell\'app',
                    ].where((e) => e.trim().isNotEmpty).join(' · ');
                    return AdminListRow(
                      key: ValueKey(w.id),
                      index: i,
                      image: w.coverUrl,
                      title: w.title,
                      subtitle: meta,
                      dimmed: !w.published,
                      trailing: [
                        IconButton(
                          tooltip: 'In evidenza nella home',
                          onPressed: () async {
                            if (!await s.setFeatured(w, !w.featured) &&
                                context.mounted) {
                              toast(
                                context,
                                'Ci sono già 4 lavori in evidenza: togli la '
                                'stella a uno prima.',
                                error: true,
                              );
                            }
                          },
                          icon: Icon(
                            w.featured
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: w.featured
                                ? const Color(0xFFB38A2E)
                                : Colors.black38,
                          ),
                        ),
                        // Su telefono Sito e App si scelgono nella scheda del lavoro.
                        if (!isNarrow(context))
                          for (final (where, on) in [
                            ('Sito', w.onSite),
                            ('App', w.onApp),
                          ])
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: FilterChip(
                                label: Text(where),
                                selected: on,
                                showCheckmark: false,
                                visualDensity: VisualDensity.compact,
                                tooltip: on
                                    ? 'Si vede ${where == 'Sito' ? 'sul sito' : 'nell\'app'}'
                                    : 'Non si vede ${where == 'Sito' ? 'sul sito' : 'nell\'app'}',
                                onSelected: (v) {
                                  if (where == 'Sito') {
                                    w.onSite = v;
                                  } else {
                                    w.onApp = v;
                                  }
                                  s.setWorks([...s.works]);
                                },
                              ),
                            ),
                        Tooltip(
                          message: w.published ? 'Pubblicato' : 'Nascosto',
                          child: IconButton(
                            onPressed: () {
                              w.published = !w.published;
                              s.setWorks([...s.works]);
                            },
                            icon: Icon(
                              w.published
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: w.published
                                  ? Colors.black87
                                  : Colors.black38,
                            ),
                          ),
                        ),
                      ],
                      onEdit: () => showDialog(
                        context: context,
                        builder: (_) => _WorkDialog(existing: w),
                      ),
                      onDelete: () async {
                        if (await confirmDialog(
                          context,
                          'Eliminare il lavoro “${w.title}”?',
                        )) {
                          s.setWorks(
                            s.works.where((e) => e.id != w.id).toList(),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _WorkDialog extends StatefulWidget {
  const _WorkDialog({this.existing});
  final Work? existing;

  @override
  State<_WorkDialog> createState() => _WorkDialogState();
}

class _WorkDialogState extends State<_WorkDialog> {
  final _form = GlobalKey<FormState>();
  late final Work _d = widget.existing == null
      ? Work(title: '')
      : Work.fromJson(widget.existing!.toJson());
  late final _setting = TextEditingController(text: _d.setting);
  bool _busy = false;
  String? _photosError;

  @override
  void dispose() {
    _setting.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 1800,
        imageQuality: 82,
      );
      for (final f in files) {
        final bytes = await f.readAsBytes();
        final mime = (f.mimeType?.startsWith('image/') ?? false)
            ? f.mimeType!
            : 'image/jpeg';
        _d.photos.add(
          WorkPhoto(url: 'data:$mime;base64,${base64Encode(bytes)}'),
        );
      }
      if (files.isNotEmpty) _photosError = null;
    } catch (e) {
      if (mounted) toast(context, 'Caricamento non riuscito: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addByUrl() async {
    var url = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Aggiungi foto'),
        content: SizedBox(
          width: dialogWidth(c, 480),
          child: ImageField(
            label: 'Fotografia',
            value: '',
            onChanged: (v) => url = v,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
    if (ok == true && url.trim().isNotEmpty && mounted) {
      setState(() {
        _d.photos.add(WorkPhoto(url: url.trim()));
        _photosError = null;
      });
    }
  }

  void _move(int i, int delta) => setState(() {
    final j = i + delta;
    if (j < 0 || j >= _d.photos.length) return;
    _d.photos.insert(j, _d.photos.removeAt(i));
  });

  void _save() {
    final ok = _form.currentState!.validate();
    // Le foto senza indirizzo si scartano anche dall'elenco mostrato:
    // altrimenti, se il salvataggio viene respinto, i pulsanti delle righe
    // agirebbero sulla foto sbagliata (o fuori dall'elenco).
    setState(() {
      _d.photos.removeWhere((p) => p.url.trim().isEmpty);
      if (_d.photos.isEmpty) _photosError = 'Aggiungi almeno una foto.';
    });
    if (_d.photos.isEmpty || !ok) return;
    final s = context.read<AppState>();
    final others = s.works.where((w) => w.id != _d.id && w.featured).length;
    if (_d.featured && others >= maxFeatured) {
      toast(
        context,
        'Ci sono già 4 lavori in evidenza: togli la stella a uno prima.',
        error: true,
      );
      return;
    }
    final list = [...s.works];
    if (widget.existing == null) {
      list.insert(0, _d);
    } else {
      final i = list.indexWhere((e) => e.id == _d.id);
      if (i >= 0) list[i] = _d;
    }
    s.setWorks(list);
    Navigator.pop(context);
    toast(context, 'Salvato.');
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    Widget text(
      String label,
      String value,
      ValueChanged<String> set, {
      int maxLines = 1,
      String? helper,
      bool required = false,
    }) => TextFormField(
      initialValue: value,
      minLines: maxLines > 1 ? 3 : null,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        helperText: helper,
        alignLabelWithHint: maxLines > 1,
      ),
      onChanged: set,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null
          : null,
    );
    final narrow = isNarrow(context);

    return AlertDialog(
      title: Text(widget.existing == null ? 'Nuovo lavoro' : 'Modifica lavoro'),
      content: SizedBox(
        width: dialogWidth(context, 720),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  'Nome dei festeggiati',
                  _d.title,
                  (v) => _d.title = v,
                  required: true,
                  helper: 'Es. "Giulia & Marco" o "Il battesimo di Leo".',
                ),
                gap,
                FieldRow(
                  children: [
                    Expanded(
                      child: text(
                        'Tipologia (es. Matrimonio)',
                        _d.category,
                        (v) => _d.category = v,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: text(
                        'Data (es. Giugno 2024)',
                        _d.date,
                        // Aggiorna la stagione suggerita qui sotto.
                        (v) => setState(() => _d.date = v),
                      ),
                    ),
                  ],
                ),
                gap,
                text('Location', _d.location, (v) => _d.location = v),
                gap,
                // Stagione e tipo di location servono ai filtri del sito.
                FieldRow(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: seasons.contains(_d.season)
                            ? _d.season
                            : '',
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Stagione',
                          helperText: _d.season.isEmpty
                              ? (seasonFromDate(_d.date).isEmpty
                                    ? 'Scrivi il mese nella data o scegli qui.'
                                    : 'Dalla data: ${seasonFromDate(_d.date)}')
                              : null,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Automatica (dalla data)'),
                          ),
                          for (final s in seasons)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) => setState(() => _d.season = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _setting,
                        decoration: const InputDecoration(
                          labelText: 'Tipo di location',
                          helperText: 'Es. Masseria, Mare, Montagna, Natura…',
                        ),
                        onChanged: (v) => setState(() => _d.setting = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in settingSuggestions)
                      ChoiceChip(
                        label: Text(s),
                        selected:
                            _d.setting.trim().toLowerCase() == s.toLowerCase(),
                        onSelected: (_) => setState(() {
                          _d.setting = s;
                          _setting.text = s;
                        }),
                      ),
                  ],
                ),
                gap,
                ImageField(
                  label: 'Copertina (se vuota si usa la prima foto)',
                  aspect: 3 / 2,
                  value: _d.cover,
                  onChanged: (v) => _d.cover = v,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Foto (${_d.photos.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (_busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _upload,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Carica dal dispositivo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _addByUrl,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Da indirizzo'),
                    ),
                  ],
                ),
                if (_photosError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _photosError!,
                      style: const TextStyle(
                        color: Color(0xFFB3382A),
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                for (var i = 0; i < _d.photos.length; i++)
                  _PhotoRow(
                    // Chiave per oggetto: regge anche id ripetuti in un
                    // backup modificato a mano.
                    key: ObjectKey(_d.photos[i]),
                    photo: _d.photos[i],
                    number: i + 1,
                    narrow: narrow,
                    onUp: i > 0 ? () => _move(i, -1) : null,
                    onDown: i < _d.photos.length - 1 ? () => _move(i, 1) : null,
                    onDelete: () => setState(() => _d.photos.removeAt(i)),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Dove si vede',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pubblicato'),
                  subtitle: const Text(
                    'Spento: resta qui ma non si vede da nessuna parte.',
                  ),
                  value: _d.published,
                  onChanged: (v) => setState(() => _d.published = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('In evidenza nella home'),
                  subtitle: const Text(
                    'Al massimo 4 lavori, sul sito e nell\'app.',
                  ),
                  value: _d.featured,
                  onChanged: (v) => setState(() => _d.featured = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sul sito'),
                  value: _d.onSite,
                  onChanged: (v) => setState(() => _d.onSite = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nell\'app'),
                  value: _d.onApp,
                  onChanged: (v) => setState(() => _d.onApp = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

/// Una foto del lavoro: anteprima, didascalia e ordine.
class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    super.key,
    required this.photo,
    required this.number,
    required this.narrow,
    required this.onUp,
    required this.onDown,
    required this.onDelete,
  });
  final WorkPhoto photo;
  final int number;
  final bool narrow;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final thumb = narrow ? 56.0 : 80.0;
    final index = SizedBox(
      width: 26,
      child: Text(
        '$number',
        style: const TextStyle(color: Colors.black45, fontSize: 13),
      ),
    );
    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: thumb,
        height: thumb * 0.72,
        child: PhotoImage(photo.url),
      ),
    );
    final caption = TextFormField(
      initialValue: photo.caption,
      decoration: const InputDecoration(labelText: 'Didascalia', isDense: true),
      onChanged: (v) => photo.caption = v,
    );
    final buttons = [
      IconButton(
        tooltip: 'Sposta su',
        onPressed: onUp,
        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
      ),
      IconButton(
        tooltip: 'Sposta giù',
        onPressed: onDown,
        icon: const Icon(Icons.arrow_downward_rounded, size: 18),
      ),
      IconButton(
        tooltip: 'Togli foto',
        onPressed: onDelete,
        icon: const Icon(Icons.close_rounded, size: 18),
      ),
    ];
    // Su telefono la finestra è stretta: i pulsanti vanno sotto la foto,
    // altrimenti la riga non ci sta e la didascalia resta senza spazio.
    if (narrow) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          children: [
            Row(
              children: [
                preview,
                const SizedBox(width: 12),
                Expanded(child: caption),
              ],
            ),
            Row(children: [index, const Spacer(), ...buttons]),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          index,
          preview,
          const SizedBox(width: 12),
          Expanded(child: caption),
          ...buttons,
        ],
      ),
    );
  }
}
