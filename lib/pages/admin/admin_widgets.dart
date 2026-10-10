import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/models.dart';
import '../../widgets/common.dart';

void toast(BuildContext context, String message, {bool error = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error
          ? const Color(0xFF8E2F23)
          : const Color(0xFF2B2824),
      behavior: SnackBarBehavior.floating,
      width: 520,
      duration: Duration(seconds: error ? 6 : 3),
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context,
  String message, {
  String confirm = 'Elimina',
  String title = 'Conferma',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB3382A),
          ),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ------------------------------------------------------------------ layout

class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 14,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: t.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    subtitle!,
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (actions.isNotEmpty)
            Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: t.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                subtitle!,
                                style: t.textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Colors.black26),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- campi

/// Campo di testo collegato a una stringa: gestisce da solo il controller.
class BoundField extends StatefulWidget {
  const BoundField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.hint,
    this.helper,
    this.keyboardType,
    this.prefixIcon,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final int? minLines;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  @override
  State<BoundField> createState() => _BoundFieldState();
}

class _BoundFieldState extends State<BoundField> {
  late final _c = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      minLines: widget.minLines ?? (widget.maxLines > 1 ? 3 : null),
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        helperMaxLines: 3,
        alignLabelWithHint: widget.maxLines > 1,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, size: 20),
      ),
    );
  }
}

/// Anteprima + URL + caricamento da file.
class ImageField extends StatefulWidget {
  const ImageField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.aspect = 16 / 10,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final double aspect;

  @override
  State<ImageField> createState() => _ImageFieldState();
}

class _ImageFieldState extends State<ImageField> {
  late String _value = widget.value;
  late final _c = TextEditingController(
    text: _isData(widget.value) ? '' : widget.value,
  );
  bool _busy = false;

  static bool _isData(String v) => v.startsWith('data:');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _set(String v) {
    setState(() => _value = v);
    widget.onChanged(v);
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final f = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        imageQuality: 82,
      );
      if (f != null) {
        final bytes = await f.readAsBytes();
        final mime = (f.mimeType?.startsWith('image/') ?? false)
            ? f.mimeType!
            : 'image/jpeg';
        _c.text = '';
        _set('data:$mime;base64,${base64Encode(bytes)}');
      }
    } catch (e) {
      if (mounted)
        toast(context, 'Impossibile caricare l\'immagine: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isData = _isData(_value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 150 / widget.aspect,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD8D2C8)),
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: PhotoImage(_value),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _c,
                    onChanged: _set,
                    decoration: InputDecoration(
                      labelText: isData
                          ? 'Immagine caricata dal computer'
                          : 'Indirizzo (URL) dell\'immagine',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _pick,
                        icon: _busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_rounded, size: 18),
                        label: const Text('Carica foto'),
                      ),
                      if (_value.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _c.text = '';
                            _set('');
                          },
                          child: const Text('Rimuovi'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Elenco di righe di testo modificabile (es. tipi di evento).
class StringListEditor extends StatefulWidget {
  const StringListEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.addLabel = 'Aggiungi',
  });
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final String addLabel;

  @override
  State<StringListEditor> createState() => _StringListEditorState();
}

class _StringListEditorState extends State<StringListEditor> {
  late final List<String> _items = [...widget.items];
  final _c = TextEditingController();

  void _emit() => widget.onChanged([..._items]);

  void _add() {
    final v = _c.text.trim();
    if (v.isEmpty || _items.contains(v)) return;
    setState(() => _items.add(v));
    _c.clear();
    _emit();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _items)
              InputChip(
                label: Text(e),
                onDeleted: () {
                  setState(() => _items.remove(e));
                  _emit();
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _c,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  labelText: widget.addLabel,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Contenitore di una voce modificabile in una lista (con comandi sposta/elimina).
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.child,
    this.onUp,
    this.onDown,
    this.onDelete,
    this.title,
  });
  final Widget child;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback? onDelete;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F6),
        border: Border.all(color: const Color(0xFFE5DFD5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              else
                const Spacer(),
              if (onUp != null)
                IconButton(
                  onPressed: onUp,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  tooltip: 'Sposta su',
                ),
              if (onDown != null)
                IconButton(
                  onPressed: onDown,
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  tooltip: 'Sposta giù',
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'Elimina',
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

/// Barra di salvataggio fissa per gli editor di contenuto.
class SaveBar extends StatelessWidget {
  const SaveBar({
    super.key,
    required this.dirty,
    required this.onSave,
    required this.onDiscard,
  });
  final bool dirty;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: dirty ? 68 : 0,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5DFD5))),
        boxShadow: dirty
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, -4),
                ),
              ]
            : null,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.edit_note_rounded, size: 22),
                const SizedBox(width: 10),
                const Expanded(child: Text('Hai modifiche non salvate')),
                TextButton(
                  onPressed: onDiscard,
                  child: const Text('Annulla modifiche'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Salva'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatEuro(num v) {
  final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2).replaceAll('.', ',');
  return '€ $s';
}

String? serviceNames(List<ServiceItem> all, List<String> ids) {
  final n = [
    for (final id in ids)
      all.where((s) => s.id == id).map((s) => s.name).firstOrNull,
  ].whereType<String>().toList();
  return n.isEmpty ? null : n.join(' · ');
}
