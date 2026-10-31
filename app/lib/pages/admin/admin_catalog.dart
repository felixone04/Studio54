import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'admin_widgets.dart';

// I due caroselli d'apertura, per sito e app: si vede quello del verso dello
// schermo. Sono due elenchi separati: le modifiche a uno non toccano l'altro.

class AdminCarousel extends StatefulWidget {
  const AdminCarousel({super.key, required this.vertical});

  /// Vero: il carosello verticale; falso: quello orizzontale.
  final bool vertical;

  @override
  State<AdminCarousel> createState() => _AdminCarouselState();
}

class _AdminCarouselState extends State<AdminCarousel> {
  final _url = TextEditingController();
  final _aspects = PhotoAspects.instance;
  bool _busy = false;

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
    _url.dispose();
    super.dispose();
  }

  List<CarouselPhoto> _list(AppState s) =>
      widget.vertical ? s.carouselApp : s.carouselSite;

  Future<void> _set(AppState s, List<CarouselPhoto> l) =>
      widget.vertical ? s.setCarouselApp(l) : s.setCarouselSite(l);

  Future<void> _upload(AppState s) async {
    setState(() => _busy = true);
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2200,
        imageQuality: 84,
      );
      final added = <CarouselPhoto>[];
      for (final f in files) {
        final bytes = await f.readAsBytes();
        final mime = (f.mimeType?.startsWith('image/') ?? false)
            ? f.mimeType!
            : 'image/jpeg';
        added.add(
          CarouselPhoto(url: 'data:$mime;base64,${base64Encode(bytes)}'),
        );
      }
      if (added.isNotEmpty) await _set(s, [..._list(s), ...added]);
    } catch (e) {
      if (mounted) toast(context, 'Caricamento non riuscito: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addUrl(AppState s) {
    final u = _url.text.trim();
    final uri = Uri.tryParse(u);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      toast(
        context,
        'Incolla un indirizzo che inizi con https://',
        error: true,
      );
      return;
    }
    _set(s, [..._list(s), CarouselPhoto(url: u)]);
    _url.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = _list(s);
    final v = widget.vertical;
    _aspects.resolveAll(l.map((p) => p.url));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: v ? 'Carosello verticale' : 'Carosello orizzontale',
          subtitle: v
              ? 'Sito e app, schermo in verticale (telefono, tablet o monitor '
                    'girato): le foto riempiono lo schermo all\'apertura e '
                    'scorrono da sole, 4 secondi l\'una. Usa foto verticali.'
              : 'Sito e app, schermo in orizzontale (computer, tablet o '
                    'telefono girato): le foto scorrono a tutto schermo nella '
                    'home, 4 secondi l\'una, con dissolvenza. Usa foto orizzontali.',
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (l.isEmpty)
                const EmptyState(
                  icon: Icons.photo_library_outlined,
                  message: 'Nessuna foto: aggiungi la prima.',
                )
              else
                LayoutBuilder(
                  builder: (context, box) {
                    final min = v ? 130.0 : 190.0;
                    final cols = (box.maxWidth / min).floor().clamp(2, 6);
                    const gap = 12.0;
                    final w = (box.maxWidth - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var i = 0; i < l.length; i++)
                          SizedBox(
                            width: w,
                            child: _PhotoCard(
                              key: ValueKey(l[i].id),
                              photo: l[i],
                              vertical: v,
                              aspect: _aspects.of(l[i].url),
                              onToggle: (on) {
                                l[i].active = on;
                                _set(s, [...l]);
                              },
                              onLeft: i == 0
                                  ? null
                                  : () => _set(
                                      s,
                                      [...l]
                                        ..insert(i - 1, l[i])
                                        ..removeAt(i + 1),
                                    ),
                              onRight: i == l.length - 1
                                  ? null
                                  : () => _set(
                                      s,
                                      [...l]
                                        ..insert(i + 2, l[i])
                                        ..removeAt(i),
                                    ),
                              onDelete: () async {
                                if (await confirmDialog(
                                  context,
                                  'Togliere questa foto dal carosello?',
                                  confirm: 'Togli',
                                )) {
                                  _set(s, [...l]..removeAt(i));
                                }
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _upload(s),
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Carica foto'),
                  ),
                  SizedBox(
                    width: 360,
                    child: TextField(
                      controller: _url,
                      onSubmitted: (_) => _addUrl(s),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Oppure incolla l\'indirizzo (https://…)',
                        suffixIcon: IconButton(
                          tooltip: 'Aggiungi',
                          onPressed: () => _addUrl(s),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    super.key,
    required this.photo,
    required this.vertical,
    required this.aspect,
    required this.onToggle,
    required this.onLeft,
    required this.onRight,
    required this.onDelete,
  });
  final CarouselPhoto photo;
  final bool vertical;
  final double? aspect;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final a = aspect;
    // Avviso se la foto ha l'orientamento sbagliato per questo carosello.
    final wrong = a == null
        ? null
        : (vertical && a > 1
              ? 'Orizzontale: verrà tagliata'
              : (!vertical && a <= 1 ? 'Verticale: si salta' : null));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E2DD)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: vertical ? 9 / 16 : 3 / 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: photo.active ? 1 : 0.4,
                  child: PhotoImage(photo.url),
                ),
                if (wrong != null)
                  Positioned(
                    left: 6,
                    top: 6,
                    right: 6,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1E0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          wrong,
                          style: body(
                            11,
                            weight: FontWeight.w600,
                            color: const Color(0xFF8A4B08),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            // Su schede strette i pulsanti vanno sotto l'interruttore.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Switch(value: photo.active, onChanged: onToggle),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Sposta prima',
                        visualDensity: VisualDensity.compact,
                        onPressed: onLeft,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        tooltip: 'Sposta dopo',
                        visualDensity: VisualDensity.compact,
                        onPressed: onRight,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                      IconButton(
                        tooltip: 'Togli',
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
