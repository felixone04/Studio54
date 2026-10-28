import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/google_token.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final base = Uri.base;
    // "origin" esiste solo per indirizzi http/https (non nei test o in locale da file).
    final origin = base.isScheme('http') || base.isScheme('https')
        ? base.origin
        : base.toString();
    const gap = SizedBox(height: 20);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminHeader(
          title: 'Impostazioni',
          subtitle: 'Google Calendar, password e backup.',
        ),
        Panel(
          title: 'Google Calendar',
          subtitle:
              'Gli appuntamenti si salvano nel calendario principale del tuo account Google: li vedi su tutti i '
              'dispositivi in cui usi Google Calendar.',
          child: _GoogleSetup(origin: origin),
        ),
        gap,
        const Panel(title: 'Password area riservata', child: _PasswordForm()),
        gap,
        Panel(
          title: 'Dati e copie di sicurezza',
          subtitle: 'Per ora i dati (testi, foto, richieste, appuntamenti) sono salvati nel browser di questo computer.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: s.exportBackup()),
                      );
                      if (context.mounted) {
                        toast(
                          context,
                          'Copia di sicurezza negli appunti: incollala in un file di testo e conservala.',
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: const Text('Copia i dati (backup)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const _RestoreDialog(),
                    ),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Ripristina da backup'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (await confirmDialog(
                        context,
                        'Ripristinare testi, servizi, pacchetti e galleria ai contenuti di esempio? '
                        'Le richieste e gli appuntamenti non vengono toccati.',
                        confirm: 'Ripristina',
                        title: 'Contenuti di esempio',
                      )) {
                        await s.resetAll();
                        if (context.mounted) {
                          toast(context, 'Contenuti di esempio ripristinati.');
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB3382A),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Ripristina contenuti di esempio'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Foto caricate dal computer: ${(s.embeddedImageChars / (1024 * 1024)).toStringAsFixed(2)} MB '
                'di circa 5 MB disponibili nel browser.',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoogleSetup extends StatefulWidget {
  const _GoogleSetup({required this.origin});
  final String origin;

  @override
  State<_GoogleSetup> createState() => _GoogleSetupState();
}

class _GoogleSetupState extends State<_GoogleSetup> {
  late final _c = TextEditingController(
    text: context.read<AppState>().settings.googleClientId,
  );
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final s = context.read<AppState>();
    await s.saveGoogleClientId(_c.text);
    setState(() => _busy = true);
    try {
      await s.connectGoogle();
      if (mounted) {
        toast(
          context,
          'Collegato${s.calendar.calendarName != null ? ' a ${s.calendar.calendarName}' : ''}.',
        );
      }
    } on GoogleAuthException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final connected = s.calendar.connected;
    Widget step(int n, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.black12,
            child: Text('$n', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (connected)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D4F),
                ),
                const SizedBox(width: 10),
                Text(
                  'Collegato${s.calendar.calendarName != null ? ' · ${s.calendar.calendarName}' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        TextField(
          controller: _c,
          decoration: InputDecoration(
            labelText: 'Client ID Google',
            hintText: '1234567890-abc…apps.googleusercontent.com',
            helperText:
                s.googleClientId.isNotEmpty && s.settings.googleClientId.isEmpty
                ? 'In uso il valore impostato in fase di build.'
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _connect,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link_rounded, size: 18),
              label: Text(
                connected ? 'Ricollega' : 'Salva e collega Google Calendar',
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                await s.saveGoogleClientId(_c.text);
                if (context.mounted) toast(context, 'Client ID salvato.');
              },
              child: const Text('Solo salva'),
            ),
            if (connected)
              TextButton(
                onPressed: () => s.disconnectGoogle(),
                child: const Text('Scollega'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        // Istruzioni nascoste finché non servono.
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: const Text(
              'Come ottenere il Client ID (una sola volta)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              step(
                1,
                const Text(
                  'Apri console.cloud.google.com con il tuo account Google e crea un progetto (es. “Sito studio”).',
                ),
              ),
              step(
                2,
                const Text(
                  'Da “API e servizi” → “Libreria” cerca “Google Calendar API” e premi Abilita.',
                ),
              ),
              step(
                3,
                const Text(
                  'Da “Schermata consenso OAuth” scegli tipo Esterno, inserisci nome app e la tua email. '
                  'Tra gli “Utenti di prova” aggiungi il tuo indirizzo Gmail.',
                ),
              ),
              step(
                4,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Da “Credenziali” → “Crea credenziali” → “ID client OAuth” scegli “Applicazione web”. '
                      'In “Origini JavaScript autorizzate” aggiungi esattamente questo indirizzo:',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F2ED),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: SelectableText(
                              widget.origin,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copia',
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: widget.origin),
                            );
                            if (context.mounted) {
                              toast(context, 'Indirizzo copiato.');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Quando pubblicherai il sito aggiungi anche il suo indirizzo definitivo (https://…).',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              step(
                5,
                const Text(
                  'Copia il Client ID (finisce con .apps.googleusercontent.com), incollalo qui sopra e premi “Salva e collega”.',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Il collegamento dura circa un’ora: dopo, dal Calendario basta premere “Ricollega Google”. '
                'Gli appuntamenti già sincronizzati restano su Google Calendar.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm();

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _form = GlobalKey<FormState>();
  late final _user = TextEditingController(
    text: context.read<AppState>().settings.username,
  );
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _again = TextEditingController();

  @override
  void dispose() {
    _user.dispose();
    _old.dispose();
    _new.dispose();
    _again.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                TextFormField(
                  controller: _user,
                  decoration: const InputDecoration(labelText: 'Nome utente'),
                  validator: (v) {
                    final u = (v ?? '').trim();
                    if (u.length < 3 || u.contains(' ')) {
                      return 'Almeno 3 caratteri, senza spazi';
                    }
                    final mio = s.settings.username.trim().toLowerCase();
                    return u.toLowerCase() != mio && s.loginTaken(u)
                        ? 'È già usato da un cliente'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _old,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password attuale',
                  ),
                  validator: (v) =>
                      s.checkPassword(v ?? '') ? null : 'Password non corretta',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _new,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nuova password (almeno 8 caratteri)',
                  ),
                  validator: (v) =>
                      (v ?? '').length < 8 ? 'Almeno 8 caratteri' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _again,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Ripeti la nuova password',
                  ),
                  validator: (v) =>
                      v == _new.text ? null : 'Le password non coincidono',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              if (!_form.currentState!.validate()) return;
              // Mantiene la scelta "Ricordami" fatta all'accesso.
              await s.setAdminCredentials(
                _user.text,
                _new.text,
                remember: s.settings.sessionUntil != null,
              );
              _old.clear();
              _new.clear();
              _again.clear();
              if (context.mounted) toast(context, 'Password aggiornata.');
            },
            child: const Text(
              'Salva l'
              'accesso',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nome utente e password del titolare valgono nell'
            'Area clienti '
            'dell'
            'app e nel gestionale. Per ora restano su questo telefono: '
            'con il database varranno ovunque.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog();

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _c = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ripristina da backup'),
      content: SizedBox(
        width: dialogWidth(context, 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incolla qui il testo della copia di sicurezza. Sostituirà i dati attuali.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              minLines: 6,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: 'Backup',
                errorText: _error,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  setState(() {
                    _busy = true;
                    _error = null;
                  });
                  try {
                    await context.read<AppState>().importBackup(_c.text.trim());
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    toast(context, 'Dati ripristinati.');
                  } catch (e) {
                    if (!mounted) return;
                    setState(() {
                      _busy = false;
                      _error = e is FormatException
                          ? e.message
                          : 'Testo non valido.';
                    });
                  }
                },
          child: const Text('Ripristina'),
        ),
      ],
    );
  }
}
