import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config.dart';
import '../../services/back_handlers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart' show openUrl;

bool isNarrow(BuildContext context) => MediaQuery.sizeOf(context).width < 600;

/// Larghezza del contenuto di una finestra di dialogo: [preferred] su
/// schermi ampi, tutto lo spazio disponibile su telefono.
double dialogWidth(BuildContext context, double preferred) =>
    math.min(preferred, MediaQuery.sizeOf(context).width - 112);

void toast(BuildContext context, String message, {bool error = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? const Color(0xFF8E2F23) : Palette.ink,
      behavior: SnackBarBehavior.floating,
      width: isNarrow(context) ? null : 520,
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

/// Per gli editor a bozza: con modifiche non salvate, il tasto indietro e il
/// cambio di sezione chiedono prima conferma (come sul computer).
mixin UnsavedGuard<T extends StatefulWidget> on State<T> {
  bool get dirty;
  void discardChanges();

  @override
  void initState() {
    super.initState();
    BackHandlers.add(_onBack);
    LeaveGuards.add(_canLeave);
  }

  @override
  void dispose() {
    BackHandlers.remove(_onBack);
    LeaveGuards.remove(_canLeave);
    super.dispose();
  }

  Future<bool> _canLeave() async {
    if (!dirty) return true;
    final ok = await confirmDialog(
      context,
      'Hai modifiche non salvate in questa sezione.',
      confirm: 'Esci senza salvare',
      title: 'Modifiche non salvate',
    );
    if (ok && mounted) discardChanges();
    return ok;
  }

  bool _onBack() {
    if (!dirty) return false;
    _canLeave().then((ok) {
      if (ok) BackHandlers.back?.call();
    });
    return true;
  }
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
    final narrow = isNarrow(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: display(narrow ? 34 : 46, height: 1.05)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(subtitle!, style: body(14.5, color: Palette.stone)),
          ),
        ],
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: narrow ? 20 : 28),
      child: narrow || actions.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: actions),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
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
    final narrow = isNarrow(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(title!, style: display(25, height: 1.1)),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle!, style: body(13, color: Palette.stone)),
          ),
      ],
    );
    return Card(
      child: Padding(
        padding: EdgeInsets.all(narrow ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: narrow || trailing == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heading,
                          if (trailing != null) ...[
                            const SizedBox(height: 8),
                            trailing!,
                          ],
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: heading),
                          trailing!,
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
      minLines:
          widget.minLines ??
          (widget.maxLines > 1 ? math.min(3, widget.maxLines) : null),
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
      if (mounted) {
        toast(context, 'Impossibile caricare l\'immagine: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isData = _isData(_value);
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _c,
          onChanged: _set,
          decoration: InputDecoration(
            labelText: isData
                ? 'Foto caricata dal dispositivo'
                : 'Oppure incolla l\'indirizzo (URL)',
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _pick,
              icon: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Palette.paper,
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
    );
    return LayoutBuilder(
      builder: (context, box) {
        final stacked = box.maxWidth < 440;
        final previewW = stacked ? box.maxWidth : 160.0;
        final preview = Container(
          width: previewW,
          height: stacked
              ? previewW / math.max(widget.aspect, 1.2)
              : 160 / widget.aspect,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD8D2C8)),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: PhotoImage(_value),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: label(10.5)),
            const SizedBox(height: 10),
            if (stacked) ...[
              preview,
              const SizedBox(height: 12),
              controls,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  preview,
                  const SizedBox(width: 16),
                  Expanded(child: controls),
                ],
              ),
          ],
        );
      },
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
    final narrow = isNarrow(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final h = 68.0 + bottom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: dirty ? h : 0,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: Palette.ink),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          height: h,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              narrow ? 16 : 28,
              0,
              narrow ? 12 : 28,
              bottom,
            ),
            child: Row(
              children: [
                if (!narrow) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    narrow
                        ? 'Modifiche non salvate'
                        : 'Hai modifiche non salvate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(14, color: Palette.paper),
                  ),
                ),
                TextButton(
                  onPressed: onDiscard,
                  style: TextButton.styleFrom(foregroundColor: Palette.ash),
                  child: Text(narrow ? 'Annulla' : 'Annulla modifiche'),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.brand,
                    foregroundColor: Palette.ink,
                  ),
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

/// Riga di un elenco ordinabile (lavori, foto). Su telefono le
/// azioni finiscono in un menu e si tocca la riga per modificare.
class AdminListRow extends StatelessWidget {
  const AdminListRow({
    super.key,
    required this.index,
    required this.image,
    required this.title,
    required this.onEdit,
    required this.onDelete,
    this.subtitle,
    this.dimmed = false,
    this.leadingExtra,
    this.trailing = const [],
  });
  final int index;
  final String image;
  final String title;
  final String? subtitle;
  final bool dimmed;
  final Widget? leadingExtra;
  final List<Widget> trailing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final thumbW = narrow ? 58.0 : 88.0;
    final row = Row(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.drag_indicator_rounded, color: Colors.black38),
          ),
        ),
        SizedBox(width: narrow ? 4 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: thumbW,
            height: thumbW * 0.72,
            child: Opacity(
              opacity: dimmed ? 0.45 : 1,
              child: PhotoImage(image),
            ),
          ),
        ),
        SizedBox(width: narrow ? 10 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(
                        15,
                        weight: FontWeight.w600,
                        color: dimmed ? Palette.stone : Palette.ink,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (leadingExtra != null) ...[
                    const SizedBox(width: 6),
                    leadingExtra!,
                  ],
                ],
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    maxLines: narrow ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: body(13, color: Palette.stone, height: 1.35),
                  ),
                ),
            ],
          ),
        ),
        if (!narrow) ...trailing,
        if (narrow)
          PopupMenuButton<String>(
            tooltip: 'Azioni',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifica')),
              PopupMenuItem(value: 'delete', child: Text('Elimina')),
            ],
          )
        else ...[
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Elimina',
          ),
        ],
      ],
    );
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEDE8DF))),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 6 : 12,
            vertical: 10,
          ),
          // Sul telefono le azioni su una seconda riga: il nome si legge intero.
          child: narrow && trailing.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    row,
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: trailing,
                      ),
                    ),
                  ],
                )
              : row,
        ),
      ),
    );
  }
}

/// Campi affiancati su schermi ampi, uno sotto l'altro su telefono.
/// Accetta gli stessi figli di una [Row] (Expanded + SizedBox di spaziatura).
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!isNarrow(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in children)
          if (c is Expanded)
            c.child
          else if (c is SizedBox && c.width != null && c.child == null)
            const SizedBox(height: 16)
          else
            c,
      ],
    );
  }
}

/// Apre il sito pubblico in una nuova scheda, lasciando aperta l'area
/// riservata in quella attuale. Dall'app apre il sito nel browser.
void openSiteInNewTab() => openUrl(
  kIsWeb ? Uri.base.replace(fragment: '/').toString() : AppConfig.siteUrl,
);
