import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart' show openUrl, digitsOf;
import 'admin_widgets.dart';

// I clienti con accesso alla propria area nell'app. Nessuno può registrarsi:
// gli account si creano solo da qui, con una password generata da mandare al
// cliente. In ogni area: foto e video della festa da scaricare, PDF e link.

/// PDF caricati qui: finché i dati stanno sul dispositivo meglio file piccoli.
const _maxPdfBytes = 3 * 1024 * 1024;

class AdminClients extends StatelessWidget {
  const AdminClients({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Clienti',
          subtitle:
              'Solo nell\'app: il cliente entra da menu → Area clienti con '
              'email o nome utente e password, guarda foto e video della '
              'festa e li scarica in alta qualità. Gli account li crei solo tu.',
          actions: [
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _ClientDialog(),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Nuovo cliente'),
            ),
          ],
        ),
        Card(
          child: s.clients.isEmpty
              ? const EmptyState(
                  icon: Icons.people_alt_outlined,
                  message: 'Nessun cliente ancora. Crea il primo account.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < s.clients.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _ClientRow(client: s.clients[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client});
  final ClientAccount client;

  @override
  Widget build(BuildContext context) {
    final c = client;
    final initials = c.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
    final meta = [
      c.email,
      c.eventTitle,
      '${c.photoCount} foto',
      if (c.videoCount > 0) '${c.videoCount} video',
      '${c.files.length} file',
    ].where((e) => e.trim().isNotEmpty).join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: Palette.linen,
        foregroundColor: const Color(0xFF7A6340),
        child: Text(
          initials,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              c.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          _Status(active: c.active),
        ],
      ),
      subtitle: Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showDialog(
        context: context,
        builder: (_) => _ClientDialog(existing: c),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF3F7D4E) : const Color(0xFF6B635A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Attivo' : 'Sospeso',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ modifica

class _ClientDialog extends StatefulWidget {
  const _ClientDialog({this.existing});
  final ClientAccount? existing;

  @override
  State<_ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<_ClientDialog> {
  final _form = GlobalKey<FormState>();
  late final ClientAccount _d = widget.existing == null
      ? ClientAccount(name: '', email: '')
      : ClientAccount.fromJson(widget.existing!.toJson());
  bool _busy = false;

  bool get _isNew => widget.existing == null;

  Future<void> _addPhotos() async {
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
        final data = 'data:$mime;base64,${base64Encode(bytes)}';
        _d.media.add(ClientMedia(url: data, original: data, name: f.name));
      }
    } catch (e) {
      if (mounted) toast(context, 'Caricamento non riuscito: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Copia nell'album le foto di un lavoro (es. il suo matrimonio).
  void _fromWork(Work w) => setState(() {
    for (final p in w.photos) {
      _d.media.add(ClientMedia(url: p.url, original: p.url));
    }
  });

  /// Un video della festa: l'indirizzo del file (mp4) e una foto d'anteprima.
  Future<void> _addVideo() async {
    var url = '', poster = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Aggiungi video'),
        content: SizedBox(
          width: dialogWidth(c, 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Indirizzo del video (mp4) *',
                  hintText: 'https://',
                ),
                onChanged: (v) => url = v.trim(),
              ),
              const SizedBox(height: 14),
              TextField(
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Foto di anteprima',
                  hintText: 'https://',
                ),
                onChanged: (v) => poster = v.trim(),
              ),
            ],
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
    final u = Uri.tryParse(url);
    if (ok != true || !mounted) return;
    if (u == null || !u.hasScheme || u.host.isEmpty) {
      toast(context, 'Indirizzo del video non valido.', error: true);
      return;
    }
    setState(
      () => _d.media.add(ClientMedia(url: url, isVideo: true, poster: poster)),
    );
  }

  Future<void> _addPdf() async {
    setState(() => _busy = true);
    try {
      final f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (bytes.length > _maxPdfBytes) {
        if (mounted) {
          toast(
            context,
            'Il PDF è troppo grande (max 3 MB per ora): caricalo su Google '
            'Drive e aggiungilo come link.',
            error: true,
          );
        }
        return;
      }
      final name = f.name.replaceAll(
        RegExp(r'\.pdf$', caseSensitive: false),
        '',
      );
      setState(() {
        _d.files.add(
          ClientFile(
            name: name,
            url: 'data:application/pdf;base64,${base64Encode(bytes)}',
          ),
        );
      });
    } catch (e) {
      if (mounted) toast(context, 'Caricamento non riuscito: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addLink() async {
    final f = await showDialog<ClientFile>(
      context: context,
      builder: (_) => const _LinkDialog(),
    );
    if (f != null) setState(() => _d.files.add(f));
  }

  Future<void> _newPassword() async {
    final s = context.read<AppState>();
    final ok = await confirmDialog(
      context,
      'Generare una nuova password per ${_d.name}? Quella attuale smetterà di funzionare.',
      confirm: 'Genera',
      title: 'Nuova password',
    );
    if (!ok || !mounted) return;
    final original = s.clientById(_d.id)!;
    final pw = await s.resetClientPassword(original);
    _d
      ..passwordHash = original.passwordHash
      ..passwordSalt = original.passwordSalt;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) =>
          CredentialsDialog(client: _d, password: pw, created: false),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    if (s.loginTaken(_d.email, exceptId: _d.id)) {
      toast(context, 'Esiste già un account con questa email.', error: true);
      return;
    }
    if (s.loginTaken(_d.username, exceptId: _d.id)) {
      toast(context, 'Questo nome utente è già usato.', error: true);
      return;
    }
    _d.email = _d.email.trim();
    _d.username = _d.username.trim();
    _d.name = _d.name.trim();
    final nav = Navigator.of(context);
    if (_isNew) {
      final pw = await s.createClient(_d);
      if (!mounted) return;
      nav.pop();
      await showDialog(
        context: context,
        builder: (_) =>
            CredentialsDialog(client: _d, password: pw, created: true),
      );
    } else {
      await s.saveClient(_d);
      if (!mounted) return;
      nav.pop();
      toast(context, 'Salvato.');
    }
  }

  Future<void> _delete() async {
    final s = context.read<AppState>();
    final nav = Navigator.of(context);
    if (await confirmDialog(
      context,
      'Eliminare ${_d.name}? Non potrà più accedere e il suo album, i '
      'documenti e i link verranno tolti.',
    )) {
      await s.deleteClient(_d.id);
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final works = context.read<AppState>().works;
    const gap = SizedBox(height: 14);
    Widget text(
      String label,
      String value,
      ValueChanged<String> set, {
      int maxLines = 1,
      String? helper,
      TextInputType? keyboard,
      String? Function(String?)? validator,
    }) => TextFormField(
      initialValue: value,
      minLines: maxLines > 1 ? 2 : null,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        alignLabelWithHint: maxLines > 1,
      ),
      onChanged: set,
      validator: validator,
    );
    final title = Theme.of(context).textTheme.titleMedium;

    return AlertDialog(
      title: Text(_isNew ? 'Nuovo cliente' : _d.name),
      content: SizedBox(
        width: dialogWidth(context, 720),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldRow(
                  children: [
                    Expanded(
                      child: text(
                        'Nome e cognome *',
                        _d.name,
                        (v) => _d.name = v,
                        validator: (v) => (v ?? '').trim().length < 2
                            ? 'Inserisci il nome'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: text(
                        'Email *',
                        _d.email,
                        (v) => _d.email = v,
                        keyboard: TextInputType.emailAddress,
                        helper: 'Serve al cliente per accedere.',
                        validator: (v) =>
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$')
                                .hasMatch((v ?? '').trim())
                            ? null
                            : 'Email non valida',
                      ),
                    ),
                  ],
                ),
                gap,
                FieldRow(
                  children: [
                    Expanded(
                      child: text(
                        'Nome utente (facoltativo)',
                        _d.username,
                        (v) => _d.username = v,
                        helper: 'In alternativa all\'email, es. anna.paolo.',
                        validator: (v) =>
                            (v ?? '').contains(' ') ? 'Senza spazi' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: text(
                        'Telefono (per WhatsApp)',
                        _d.phone,
                        (v) => _d.phone = v,
                        keyboard: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                gap,
                text(
                  'Evento',
                  _d.eventTitle,
                  (v) => _d.eventTitle = v,
                  helper: 'Es. "Il matrimonio di Anna e Paolo".',
                ),
                gap,
                FieldRow(
                  children: [
                    Expanded(
                      child: text(
                        'Data (es. 18 maggio 2024)',
                        _d.eventDate,
                        (v) => _d.eventDate = v,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: text('Luogo', _d.location, (v) => _d.location = v),
                    ),
                  ],
                ),
                gap,
                text(
                  'Benvenuto nella sua area',
                  _d.welcome,
                  (v) => _d.welcome = v,
                  maxLines: 3,
                ),
                if (!_isNew)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Accesso attivo'),
                    subtitle: const Text(
                      'Se lo spegni il cliente non può più entrare.',
                    ),
                    value: _d.active,
                    onChanged: (v) => setState(() => _d.active = v),
                  ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Foto e video (${_d.photoCount} foto, ${_d.videoCount} video)',
                        style: title,
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
                if (_d.media.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _d.media.length; i++)
                        Stack(
                          key: ObjectKey(_d.media[i]),
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                width: 76,
                                height: 56,
                                child: PhotoImage(_d.media[i].thumb),
                              ),
                            ),
                            if (_d.media[i].isVideo)
                              const Positioned.fill(
                                child: Center(
                                  child: Icon(
                                    Icons.play_circle_outline_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () =>
                                      setState(() => _d.media.removeAt(i)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(3),
                                    child: Icon(Icons.close_rounded, size: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _addPhotos,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 18,
                      ),
                      label: const Text('Carica foto'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _addVideo,
                      icon: const Icon(Icons.videocam_outlined, size: 18),
                      label: const Text('Aggiungi video'),
                    ),
                    if (works.isNotEmpty)
                      PopupMenuButton<Work>(
                        tooltip: 'Prendi le foto da un lavoro',
                        onSelected: _fromWork,
                        itemBuilder: (_) => [
                          for (final w in works)
                            PopupMenuItem(value: w, child: Text(w.title)),
                        ],
                        child: const IgnorePointer(
                          child: OutlinedButton(
                            onPressed: null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_stories_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Dalle foto di un lavoro'),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),
                Text('Documenti e link (${_d.files.length})', style: title),
                const SizedBox(height: 6),
                for (var i = 0; i < _d.files.length; i++)
                  _FileRow(
                    key: ObjectKey(_d.files[i]),
                    file: _d.files[i],
                    onDelete: () => setState(() => _d.files.removeAt(i)),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _addPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Carica PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addLink,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Aggiungi link'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!_isNew) ...[
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB3382A),
            ),
            child: const Text('Elimina'),
          ),
          TextButton(
            onPressed: _newPassword,
            child: const Text('Nuova password'),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_isNew ? 'Crea account' : 'Salva'),
        ),
      ],
    );
  }
}

/// Un documento o un link dell'area del cliente, con la sua nota.
class _FileRow extends StatelessWidget {
  const _FileRow({super.key, required this.file, required this.onDelete});
  final ClientFile file;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            file.isLink ? Icons.link_rounded : Icons.picture_as_pdf_outlined,
            color: const Color(0xFF7A6340),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: file.name,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    isDense: true,
                  ),
                  onChanged: (v) => file.name = v,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: file.note,
                  decoration: const InputDecoration(
                    labelText: 'Nota per il cliente',
                    isDense: true,
                  ),
                  onChanged: (v) => file.note = v,
                ),
              ],
            ),
          ),
          if (file.isLink || !file.url.startsWith('data:'))
            IconButton(
              tooltip: 'Apri',
              onPressed: () => openUrl(file.url),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
            ),
          IconButton(
            tooltip: 'Togli',
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final _form = GlobalKey<FormState>();
  String _name = '', _url = '', _note = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aggiungi link'),
      content: SizedBox(
        width: dialogWidth(context, 480),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  helperText:
                      'Es. "Galleria completa" o "Video del matrimonio".',
                ),
                onChanged: (v) => _name = v,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Inserisci un nome' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Indirizzo *',
                  hintText: 'https://',
                ),
                onChanged: (v) => _url = v,
                validator: (v) {
                  final u = Uri.tryParse((v ?? '').trim());
                  return u != null && u.hasScheme && u.host.isNotEmpty
                      ? null
                      : 'Indirizzo non valido (deve iniziare con https://)';
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nota per il cliente',
                ),
                onChanged: (v) => _note = v,
              ),
            ],
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
            Navigator.pop(
              context,
              ClientFile(
                name: _name.trim(),
                url: _url.trim(),
                isLink: true,
                note: _note.trim(),
              ),
            );
          },
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}

/// I dati di accesso da mandare al cliente: la password si vede solo qui,
/// poi resta salvata solo cifrata.
class CredentialsDialog extends StatelessWidget {
  const CredentialsDialog({
    super.key,
    required this.client,
    required this.password,
    required this.created,
  });
  final ClientAccount client;
  final String password;
  final bool created;

  String get message {
    final first = client.name.trim().split(' ').first;
    return 'Ciao $first,\n'
        'le foto e i video del vostro evento sono pronti nella vostra area '
        'riservata di Studio 54.\n\n'
        'Aprite l\'app Studio 54, toccate il menu e poi "Area clienti", ed '
        'entrate con:\n'
        'Email: ${client.email}\n'
        '${client.username.trim().isEmpty ? '' : 'oppure nome utente: ${client.username.trim()}\n'}'
        'Password: $password\n\n'
        'Da lì potete guardare e scaricare tutto in alta qualità.';
  }

  @override
  Widget build(BuildContext context) {
    final phone = digitsOf(client.phone).replaceAll('+', '');
    return AlertDialog(
      title: Text(created ? 'Account creato' : 'Nuova password'),
      content: SizedBox(
        width: dialogWidth(context, 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manda questi dati al cliente. La password non si potrà più '
              'rivedere: se la perde, ne generi una nuova.',
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Palette.paper,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD8D2C8)),
              ),
              child: SelectableText(
                message,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Chiudi'),
        ),
        if (phone.isNotEmpty)
          TextButton.icon(
            onPressed: () => openUrl(
              'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
            ),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('WhatsApp'),
          ),
        TextButton.icon(
          onPressed: () => openUrl(
            'mailto:${client.email}?subject=${Uri.encodeComponent('La tua area riservata di Studio 54')}'
            '&body=${Uri.encodeComponent(message)}',
          ),
          icon: const Icon(Icons.mail_outline_rounded, size: 18),
          label: const Text('Email'),
        ),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message));
            toast(context, 'Messaggio copiato.');
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copia'),
        ),
      ],
    );
  }
}
