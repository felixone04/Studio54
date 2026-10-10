import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'dart:convert';

import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

List<T> _move<T>(List<T> list, int oldIndex, int newIndex) {
  final l = [...list];
  l.insert(newIndex, l.removeAt(oldIndex));
  return l;
}

Widget _storageWarning(AppState s) {
  final mb = s.embeddedImageChars / (1024 * 1024);
  if (mb < 2.5) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Card(
      color: const Color(0xFFFFF4E0),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFB36A00)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Le foto caricate dal computer occupano circa ${mb.toStringAsFixed(1)} MB di circa 5 MB '
                'disponibili nel browser. Per molte foto usa gli indirizzi (URL) di immagini già online '
                'oppure collega un archivio online (vedi Impostazioni).',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ================================================================== SERVIZI

class AdminServices extends StatelessWidget {
  const AdminServices({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Servizi e prodotti',
          subtitle:
              'Le voci del preventivo. Il prezzo resta visibile solo a te.',
          actions: [
            FilledButton.icon(
              onPressed: () => _editService(context, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuovo servizio / prodotto'),
            ),
          ],
        ),
        _storageWarning(s),
        Card(
          child: s.services.isEmpty
              ? const EmptyState(
                  icon: Icons.photo_camera_back_outlined,
                  message: 'Nessun servizio inserito.',
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: s.services.length,
                  onReorderItem: (o, n) =>
                      s.setServices(_move(s.services, o, n)),
                  itemBuilder: (context, i) {
                    final it = s.services[i];
                    return AdminListRow(
                      key: ValueKey(it.id),
                      index: i,
                      image: it.image,
                      title: it.name,
                      dimmed: !it.active,
                      subtitle:
                          '${it.category}${it.internalPrice != null ? '  ·  ${formatEuro(it.internalPrice!)} (interno)' : ''}',
                      trailing: [
                        Tooltip(
                          message: it.active ? 'Visibile sul sito' : 'Nascosto',
                          child: Switch(
                            value: it.active,
                            onChanged: (v) {
                              it.active = v;
                              s.setServices([...s.services]);
                            },
                          ),
                        ),
                      ],
                      onEdit: () => _editService(context, it),
                      onDelete: () async {
                        if (await confirmDialog(
                          context,
                          'Eliminare “${it.name}”? Verrà tolto anche dai pacchetti che lo contengono.',
                        )) {
                          s.deleteService(it.id);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _editService(BuildContext context, ServiceItem? existing) {
    return showDialog(
      context: context,
      builder: (_) => _ServiceDialog(existing: existing),
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({this.existing});
  final ServiceItem? existing;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _form = GlobalKey<FormState>();
  late final ServiceItem _d = widget.existing == null
      ? ServiceItem(name: '')
      : ServiceItem.fromJson(widget.existing!.toJson());
  late final _cat = TextEditingController(text: _d.category);
  late final _price = TextEditingController(
    text: _d.internalPrice == null
        ? ''
        : _d.internalPrice!.toStringAsFixed(_d.internalPrice! % 1 == 0 ? 0 : 2),
  );

  @override
  void dispose() {
    _cat.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final cats = {
      for (final e in s.services) e.category,
      'Fotografia',
      'Video',
      'Prodotti',
      'Extra',
    }.toList();
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Nuovo servizio / prodotto' : 'Modifica',
      ),
      content: SizedBox(
        width: dialogWidth(context, 560),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _d.name,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                  onChanged: (v) => _d.name = v,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci il nome'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _d.description,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => _d.description = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cat,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    helperText: 'Serve a raggruppare le voci nel preventivo (es. Fotografia, Video, Prodotti).',
                  ),
                  onChanged: (v) => _d.category = v,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in cats)
                      ActionChip(
                        label: Text(c),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          _cat.text = c;
                          _d.category = c;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                ImageField(
                  label: 'Immagine',
                  value: _d.image,
                  aspect: 4 / 3,
                  onChanged: (v) => _d.image = v,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Prezzo indicativo (solo per te)',
                    prefixText: '€ ',
                    helperText: 'Non viene mostrato ai clienti. Serve per stimare il totale di ogni richiesta.',
                    helperMaxLines: 2,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    return double.tryParse(v.replaceAll(',', '.')) == null
                        ? 'Numero non valido'
                        : null;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visibile sul sito'),
                  value: _d.active,
                  onChanged: (v) => setState(() => _d.active = v),
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
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            final p = _price.text.trim();
            _d.internalPrice = p.isEmpty
                ? null
                : double.parse(p.replaceAll(',', '.'));
            _d.name = _d.name.trim();
            _d.category = _d.category.trim().isEmpty
                ? 'Servizi'
                : _d.category.trim();
            final list = [...s.services];
            if (widget.existing == null) {
              list.add(_d);
            } else {
              final i = list.indexWhere((e) => e.id == _d.id);
              if (i >= 0) list[i] = _d;
            }
            s.setServices(list);
            Navigator.pop(context);
            toast(context, 'Salvato.');
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

// ================================================================ PACCHETTI

class AdminPackages extends StatelessWidget {
  const AdminPackages({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Pacchetti',
          subtitle: 'Combinazioni pronte di servizi.',
          actions: [
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _PackageDialog(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuovo pacchetto'),
            ),
          ],
        ),
        Card(
          child: s.packages.isEmpty
              ? const EmptyState(
                  icon: Icons.card_giftcard_rounded,
                  message: 'Nessun pacchetto: i clienti potranno solo creare il preventivo su misura.',
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: s.packages.length,
                  onReorderItem: (o, n) =>
                      s.setPackages(_move(s.packages, o, n)),
                  itemBuilder: (context, i) {
                    final p = s.packages[i];
                    return AdminListRow(
                      key: ValueKey(p.id),
                      index: i,
                      image: p.image,
                      title: p.name,
                      dimmed: !p.active,
                      leadingExtra: p.featured
                          ? const Icon(
                              Icons.star_rounded,
                              size: 17,
                              color: Color(0xFFC8A04A),
                            )
                          : null,
                      subtitle:
                          serviceNames(s.services, p.serviceIds) ??
                          'Nessun servizio incluso',
                      trailing: [
                        Switch(
                          value: p.active,
                          onChanged: (v) {
                            p.active = v;
                            s.setPackages([...s.packages]);
                          },
                        ),
                      ],
                      onEdit: () => showDialog(
                        context: context,
                        builder: (_) => _PackageDialog(existing: p),
                      ),
                      onDelete: () async {
                        if (await confirmDialog(
                          context,
                          'Eliminare il pacchetto “${p.name}”?',
                        )) {
                          s.setPackages(
                            s.packages.where((e) => e.id != p.id).toList(),
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

class _PackageDialog extends StatefulWidget {
  const _PackageDialog({this.existing});
  final ServicePackage? existing;

  @override
  State<_PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends State<_PackageDialog> {
  final _form = GlobalKey<FormState>();
  late final ServicePackage _d = widget.existing == null
      ? ServicePackage(name: '')
      : ServicePackage.fromJson(widget.existing!.toJson());

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final cats = <String>[];
    for (final e in s.services) {
      if (!cats.contains(e.category)) cats.add(e.category);
    }
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Nuovo pacchetto' : 'Modifica pacchetto',
      ),
      content: SizedBox(
        width: dialogWidth(context, 600),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _d.name,
                  decoration: const InputDecoration(
                    labelText: 'Nome del pacchetto *',
                  ),
                  onChanged: (v) => _d.name = v,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci il nome'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _d.tagline,
                  decoration: const InputDecoration(
                    labelText: 'Frase breve (sotto il nome)',
                  ),
                  onChanged: (v) => _d.tagline = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _d.description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => _d.description = v,
                ),
                const SizedBox(height: 18),
                ImageField(
                  label: 'Immagine',
                  value: _d.image,
                  aspect: 16 / 8,
                  onChanged: (v) => _d.image = v,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Servizi inclusi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                for (final c in cats) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Text(
                      c.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 1.6,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  for (final sv in s.services.where((e) => e.category == c))
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(sv.name),
                      value: _d.serviceIds.contains(sv.id),
                      onChanged: (v) => setState(() {
                        if (v ?? false) {
                          _d.serviceIds.add(sv.id);
                        } else {
                          _d.serviceIds.remove(sv.id);
                        }
                      }),
                    ),
                ],
                const Divider(height: 28),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Evidenzia come “Più scelto”'),
                  value: _d.featured,
                  onChanged: (v) => setState(() => _d.featured = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visibile sul sito'),
                  value: _d.active,
                  onChanged: (v) => setState(() => _d.active = v),
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
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            _d.name = _d.name.trim();
            final list = [...s.packages];
            if (widget.existing == null) {
              list.add(_d);
            } else {
              final i = list.indexWhere((e) => e.id == _d.id);
              if (i >= 0) list[i] = _d;
            }
            s.setPackages(list);
            Navigator.pop(context);
            toast(context, 'Salvato.');
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

// ================================================================== GALLERIA

class AdminGallery extends StatefulWidget {
  const AdminGallery({super.key});

  @override
  State<AdminGallery> createState() => _AdminGalleryState();
}

class _AdminGalleryState extends State<AdminGallery> {
  bool _busy = false;

  Future<void> _addMany() async {
    final s = context.read<AppState>();
    setState(() => _busy = true);
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 1800,
        imageQuality: 82,
      );
      final added = <GalleryPhoto>[];
      for (final f in files) {
        final bytes = await f.readAsBytes();
        final mime = (f.mimeType?.startsWith('image/') ?? false)
            ? f.mimeType!
            : 'image/jpeg';
        final name = f.name
            .replaceAll(RegExp(r'\.[^.]+$'), '')
            .replaceAll(RegExp(r'[_-]+'), ' ')
            .trim();
        added.add(
          GalleryPhoto(
            url: 'data:$mime;base64,${base64Encode(bytes)}',
            title: name.isEmpty ? 'Senza titolo' : name,
          ),
        );
      }
      if (added.isNotEmpty) {
        await s.setGallery([...s.gallery, ...added]);
        if (mounted)
          toast(
            context,
            '${added.length} foto aggiunte. Dai un titolo a ciascuna con “Modifica”.',
          );
      }
    } catch (e) {
      if (mounted) toast(context, 'Caricamento non riuscito: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Galleria',
          subtitle:
              'La stella mette la foto in apertura. Trascina per riordinare.',
          actions: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _addMany,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Carica più foto'),
            ),
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _PhotoDialog(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuova foto'),
            ),
          ],
        ),
        _storageWarning(s),
        Card(
          child: s.gallery.isEmpty
              ? const EmptyState(
                  icon: Icons.photo_library_outlined,
                  message: 'Nessuna foto in galleria.',
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: s.gallery.length,
                  onReorderItem: (o, n) => s.setGallery(_move(s.gallery, o, n)),
                  itemBuilder: (context, i) {
                    final p = s.gallery[i];
                    final meta = [
                      p.category,
                      p.location,
                      p.year,
                    ].where((e) => e.isNotEmpty).join(' · ');
                    return AdminListRow(
                      key: ValueKey(p.id),
                      index: i,
                      image: p.url,
                      title: p.title,
                      subtitle: meta,
                      trailing: [
                        Tooltip(
                          message: p.inHero
                              ? 'Nella prima schermata'
                              : 'Solo nella mostra',
                          child: IconButton(
                            onPressed: () {
                              p.inHero = !p.inHero;
                              s.setGallery([...s.gallery]);
                            },
                            icon: Icon(
                              p.inHero
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: p.inHero
                                  ? const Color(0xFFC8A04A)
                                  : Colors.black38,
                            ),
                          ),
                        ),
                      ],
                      onEdit: () => showDialog(
                        context: context,
                        builder: (_) => _PhotoDialog(existing: p),
                      ),
                      onDelete: () async {
                        if (await confirmDialog(
                          context,
                          'Eliminare “${p.title}” dalla galleria?',
                        )) {
                          s.setGallery(
                            s.gallery.where((e) => e.id != p.id).toList(),
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

class _PhotoDialog extends StatefulWidget {
  const _PhotoDialog({this.existing});
  final GalleryPhoto? existing;

  @override
  State<_PhotoDialog> createState() => _PhotoDialogState();
}

class _PhotoDialogState extends State<_PhotoDialog> {
  final _form = GlobalKey<FormState>();
  late final GalleryPhoto _d = widget.existing == null
      ? GalleryPhoto(url: '', title: '')
      : GalleryPhoto.fromJson(widget.existing!.toJson());
  String? _imageError;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nuova foto' : 'Modifica foto'),
      content: SizedBox(
        width: dialogWidth(context, 560),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageField(
                  label: 'Fotografia *',
                  value: _d.url,
                  onChanged: (v) => setState(() {
                    _d.url = v;
                    _imageError = null;
                  }),
                ),
                if (_imageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _imageError!,
                      style: const TextStyle(
                        color: Color(0xFFB3382A),
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                TextFormField(
                  initialValue: _d.title,
                  decoration: const InputDecoration(
                    labelText: 'Titolo *',
                    helperText: 'Come il titolo di un\'opera.',
                  ),
                  onChanged: (v) => _d.title = v,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci un titolo'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _d.caption,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Didascalia',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => _d.caption = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _d.category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria (es. Matrimonio)',
                  ),
                  onChanged: (v) => _d.category = v,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _d.location,
                        decoration: const InputDecoration(labelText: 'Luogo'),
                        onChanged: (v) => _d.location = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        initialValue: _d.year,
                        decoration: const InputDecoration(labelText: 'Anno'),
                        onChanged: (v) => _d.year = v,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mostra anche nella prima schermata'),
                  value: _d.inHero,
                  onChanged: (v) => setState(() => _d.inHero = v),
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
          onPressed: () {
            final ok = _form.currentState!.validate();
            if (_d.url.trim().isEmpty) {
              setState(
                () => _imageError = 'Carica una foto o incolla un indirizzo.',
              );
              return;
            }
            if (!ok) return;
            final list = [...s.gallery];
            if (widget.existing == null) {
              list.add(_d);
            } else {
              final i = list.indexWhere((e) => e.id == _d.id);
              if (i >= 0) list[i] = _d;
            }
            s.setGallery(list);
            Navigator.pop(context);
            toast(context, 'Salvato.');
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
