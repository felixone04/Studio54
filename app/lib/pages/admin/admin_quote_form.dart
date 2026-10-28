import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_content.dart' show AdminPageScroll;
import 'admin_widgets.dart';

/// Il modulo "Preventivo", lo stesso sul sito e nell'app: ogni parte si
/// accende e si spegne, e si aggiungono tipi di evento e richieste. Le voci
/// spente restano qui, pronte per quando servono.
class AdminQuoteForm extends StatefulWidget {
  const AdminQuoteForm({super.key});

  @override
  State<AdminQuoteForm> createState() => _AdminQuoteFormState();
}

class _AdminQuoteFormState extends State<AdminQuoteForm> {
  late QuoteForm _f = context.read<AppState>().quoteForm.copy();
  bool _dirty = false;
  int _rev = 0;

  void _changed(VoidCallback fn) => setState(() {
    fn();
    _dirty = true;
  });

  Future<void> _save() async {
    final all = [..._f.eventTypes, ..._f.requests];
    if (all.any((o) => o.label.trim().isEmpty)) {
      toast(context, 'Dai un nome a tutte le voci (o eliminale).', error: true);
      return;
    }
    await context.read<AppState>().setQuoteForm(_f);
    if (!mounted) return;
    setState(() {
      _f = context.read<AppState>().quoteForm.copy();
      _dirty = false;
    });
    toast(context, 'Salvato: il modulo è aggiornato.');
  }

  void _discard() => setState(() {
    _f = context.read<AppState>().quoteForm.copy();
    _dirty = false;
    _rev++;
  });

  Widget _switch(
    String title,
    bool value,
    ValueChanged<bool>? onChanged, {
    String? sub,
  }) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: sub == null ? null : Text(sub),
    value: value,
    onChanged: onChanged,
  );

  void _contact(bool phone, bool on) {
    // Serve almeno un recapito: telefono o email.
    if (!on && !(phone ? _f.askEmail : _f.askPhone)) {
      toast(
        context,
        'Serve almeno un recapito: telefono o email.',
        error: true,
      );
      return;
    }
    _changed(() => phone ? _f.askPhone = on : _f.askEmail = on);
  }

  @override
  Widget build(BuildContext context) {
    final f = _f;
    return Column(
      children: [
        Expanded(
          child: AdminPageScroll(
            child: KeyedSubtree(
              key: ValueKey(_rev),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AdminHeader(
                    title: 'Preventivo',
                    subtitle:
                        'Il modulo è lo stesso sul sito e nell\'app. Accendi e '
                        'spegni ogni parte, aggiungi tipi di evento e richieste.',
                  ),
                  Panel(
                    title: 'Parti del modulo',
                    subtitle: 'Le parti spente non compaiono.',
                    child: Column(
                      children: [
                        _switch(
                          'Tipo di evento',
                          f.showEvent,
                          (v) => _changed(() => f.showEvent = v),
                          sub: 'Se c\'è un solo tipo acceso è già scelto.',
                        ),
                        _switch(
                          'Data',
                          f.showDate,
                          (v) => _changed(() => f.showDate = v),
                        ),
                        _switch(
                          'Luogo',
                          f.showLocation,
                          (v) => _changed(() => f.showLocation = v),
                        ),
                        _switch(
                          'Richieste',
                          f.showRequests,
                          (v) => _changed(() => f.showRequests = v),
                          sub: 'Le voci da toccare: video, album, drone…',
                        ),
                        _switch(
                          'Messaggio',
                          f.showMessage,
                          (v) => _changed(() => f.showMessage = v),
                          sub: 'Per chiedere qualsiasi altra informazione.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Panel(
                    title: 'Contatti chiesti',
                    subtitle:
                        'Il nome si chiede sempre; serve almeno un recapito.',
                    child: Column(
                      children: [
                        _switch('Nome', true, null, sub: 'Sempre richiesto.'),
                        _switch(
                          'Cognome',
                          f.askLastName,
                          (v) => _changed(() => f.askLastName = v),
                        ),
                        _switch(
                          'Telefono',
                          f.askPhone,
                          (v) => _contact(true, v),
                        ),
                        _switch('Email', f.askEmail, (v) => _contact(false, v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _OptionsPanel(
                    title: 'Tipi di evento',
                    subtitle: 'Per ora solo il matrimonio è acceso.',
                    hint: 'Es. Anniversario',
                    items: f.eventTypes,
                    onChanged: () => _changed(() {}),
                  ),
                  const SizedBox(height: 20),
                  _OptionsPanel(
                    title: 'Richieste',
                    subtitle: 'Le voci che il cliente può toccare.',
                    hint: 'Es. Video in 4K',
                    items: f.requests,
                    onChanged: () => _changed(() {}),
                  ),
                ],
              ),
            ),
          ),
        ),
        SaveBar(dirty: _dirty, onSave: _save, onDiscard: _discard),
      ],
    );
  }
}

/// Un elenco di voci con interruttore, nome, ordine ed eliminazione.
class _OptionsPanel extends StatefulWidget {
  const _OptionsPanel({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.items,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final String hint;
  final List<QuoteOption> items;
  final VoidCallback onChanged;

  @override
  State<_OptionsPanel> createState() => _OptionsPanelState();
}

class _OptionsPanelState extends State<_OptionsPanel> {
  final _new = TextEditingController();

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  void _edit(VoidCallback fn) {
    setState(fn);
    widget.onChanged();
  }

  void _add() {
    final t = _new.text.trim();
    if (t.isEmpty) return;
    _edit(() => widget.items.add(QuoteOption(label: t)));
    _new.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.items;
    return Panel(
      title: widget.title,
      subtitle: widget.subtitle,
      child: Column(
        children: [
          for (var i = 0; i < l.length; i++)
            Padding(
              key: ObjectKey(l[i]),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Switch(
                    value: l[i].active,
                    onChanged: (v) => _edit(() => l[i].active = v),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BoundField(
                      label: 'Voce',
                      value: l[i].label,
                      onChanged: (v) {
                        l[i].label = v;
                        widget.onChanged();
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sposta su',
                    onPressed: i == 0
                        ? null
                        : () => _edit(() => l.insert(i - 1, l.removeAt(i))),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Sposta giù',
                    onPressed: i == l.length - 1
                        ? null
                        : () => _edit(() => l.insert(i + 1, l.removeAt(i))),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Elimina',
                    onPressed: () => _edit(() => l.removeAt(i)),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _new,
                  onSubmitted: (_) => _add(),
                  decoration: InputDecoration(
                    labelText: 'Nuova voce',
                    hintText: widget.hint,
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
      ),
    );
  }
}
