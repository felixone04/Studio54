import 'package:flutter/material.dart';

import '../widgets/line_icons.dart';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/back_handlers.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/photo_ui.dart';
import '../widgets/site_scaffold.dart';

// Il preventivo dell'app, a passi: una schermata per volta, con la barra
// dell'avanzamento in alto e Indietro / Avanti in basso, a portata di
// pollice. Le parti accese e le voci sono quelle scelte nel gestionale
// (le stesse del sito).

enum _Step { event, requests, contacts, message, summary }

extension on _Step {
  String get title => switch (this) {
    _Step.event => 'Il vostro evento',
    _Step.requests => 'Le vostre richieste',
    _Step.contacts => 'I vostri contatti',
    _Step.message => 'Il vostro messaggio',
    _Step.summary => 'Riepilogo',
  };
}

final _date = DateFormat('d MMMM y', 'it_IT');

// Come sul sito: nei nomi solo lettere, spazi, apostrofi e trattini; nel
// telefono solo cifre, spazi e il +.
final _onlyName = FilteringTextInputFormatter.allow(
  RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ' \-]"),
);
final _onlyPhone = TextInputFormatter.withFunction((old, v) {
  final t = v.text.replaceAll(RegExp(r'[^0-9+ ]'), '');
  final l = t.trimLeft(), plus = l.startsWith('+');
  final out =
      (plus ? '+' : '') + (plus ? l.substring(1) : l).replaceAll('+', '');
  return out == v.text
      ? v
      : TextEditingValue(
          text: out,
          selection: TextSelection.collapsed(offset: out.length),
        );
});
final _email = RegExp(
  r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$',
);

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  int _i = 0;
  String? _type;
  DateTime? _when;
  final _requests = <String>{};
  final _location = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _mail = TextEditingController();
  final _message = TextEditingController();
  bool _privacy = false;
  bool _tried =
      false; // errori visibili solo dopo aver provato ad andare avanti
  QuoteRequest? _sent;

  @override
  void initState() {
    super.initState();
    BackHandlers.add(_onBack);
  }

  @override
  void dispose() {
    BackHandlers.remove(_onBack);
    for (final c in [_location, _first, _last, _phone, _mail, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Il tasto indietro del telefono torna al passo precedente; dal primo
  /// passo lascia il modulo.
  bool _onBack() {
    if (_sent != null || _i == 0) return false;
    _back();
    return true;
  }

  List<_Step> _steps(QuoteForm f) => [
    if ((f.showEvent && f.activeEventTypes.isNotEmpty) ||
        f.showDate ||
        f.showLocation)
      _Step.event,
    if (f.showRequests && f.activeRequests.isNotEmpty) _Step.requests,
    _Step.contacts,
    if (f.showMessage) _Step.message,
    _Step.summary,
  ];

  // ------------------------------------------------------------ controlli

  String? _err(String field, QuoteForm f) {
    String name(String v, String what) {
      final t = v.trim();
      if (t.isEmpty) return 'Inserite il $what';
      return t.replaceAll(RegExp(r"['\s-]"), '').length < 2
          ? 'Il $what deve avere almeno 2 lettere'
          : '';
    }

    final r = switch (field) {
      'type' =>
        f.showEvent && f.activeEventTypes.isNotEmpty && _type == null
            ? 'Scegliete il tipo di evento'
            : '',
      'date' =>
        !f.showDate
            ? ''
            : _when == null
            ? 'Indicate la data dell\'evento'
            : '',
      'location' =>
        f.showLocation && _location.text.trim().length < 2
            ? 'Indicate la città o la location dell\'evento'
            : '',
      'first' => name(_first.text, 'nome'),
      'last' => f.askLastName ? name(_last.text, 'cognome') : '',
      'phone' => () {
        if (!f.phoneOn) return '';
        final n = _phone.text.replaceAll(RegExp(r'\D'), '').length;
        if (n == 0) return 'Inserite il numero di telefono';
        return n < 8 || n > 15
            ? 'Numero non valido: servono da 8 a 15 cifre'
            : '';
      }(),
      'email' => () {
        if (!f.emailOn) return '';
        final v = _mail.text.trim();
        if (v.isEmpty) return 'Inserite l\'indirizzo email';
        return _email.hasMatch(v) ? '' : 'Email non valida (es. nome@email.it)';
      }(),
      'requests' =>
        f.showRequests && f.activeRequests.isNotEmpty && _requests.isEmpty
            ? 'Scegliete almeno una richiesta'
            : '',
      'privacy' => _privacy ? '' : 'Serve il consenso per inviare la richiesta',
      _ => '',
    };
    return r.isEmpty ? null : r;
  }

  List<String> _fields(_Step s) => switch (s) {
    _Step.event => ['type', 'date', 'location'],
    _Step.requests => ['requests'],
    _Step.contacts => ['first', 'last', 'phone', 'email'],
    _Step.summary => ['privacy'],
    _ => [],
  };

  String? _shown(String field, QuoteForm f) => _tried ? _err(field, f) : null;

  // --------------------------------------------------------------- azioni

  void _next(QuoteForm f, List<_Step> steps) {
    final s = steps[_i];
    if (_fields(s).any((k) => _err(k, f) != null)) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    if (s == _Step.summary) {
      _send(f);
      return;
    }
    setState(() {
      _tried = false;
      _i++;
    });
  }

  void _back() {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = false;
      _i--;
    });
  }

  Future<void> _send(QuoteForm f) async {
    final q = QuoteRequest(
      firstName: _first.text.trim(),
      lastName: f.askLastName ? _last.text.trim() : '',
      phone: f.phoneOn ? _phone.text.trim() : '',
      email: f.emailOn ? _mail.text.trim() : '',
      eventType: _type ?? '',
      eventDate: _when,
      location: f.showLocation ? _location.text.trim() : '',
      requests: [
        for (final r in f.activeRequests)
          if (_requests.contains(r.label)) r.label,
      ],
      message: f.showMessage ? _message.text.trim() : '',
      source: 'app',
    );
    await context.read<AppState>().addQuote(q);
    if (mounted) setState(() => _sent = q);
  }

  void _restart() => setState(() {
    for (final c in [_location, _first, _last, _phone, _mail, _message]) {
      c.clear();
    }
    _requests.clear();
    _when = null;
    _type = null;
    _privacy = false;
    _tried = false;
    _sent = null;
    _i = 0;
  });

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _when ?? today.add(const Duration(days: 180)),
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
      locale: const Locale('it', 'IT'),
      helpText: 'Data dell\'evento',
    );
    if (d != null) setState(() => _when = d);
  }

  // ------------------------------------------------------------- disegno

  @override
  Widget build(BuildContext context) {
    final f = context.watch<AppState>().quoteForm;
    final types = f.activeEventTypes;
    // Un solo tipo di evento acceso: è già scelto.
    if (f.showEvent && types.length == 1) _type ??= types.first.label;
    if (_type != null && !types.any((t) => t.label == _type)) _type = null;

    if (_sent != null) {
      return SiteScaffold(
        location: '/preventivo',
        children: [_Thanks(quote: _sent!, onAgain: _restart)],
      );
    }
    final steps = _steps(f);
    _i = _i.clamp(0, steps.length - 1);
    final step = steps[_i];
    final last = step == _Step.summary;

    final bar = SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Palette.paper,
          border: Border(top: BorderSide(color: Palette.line)),
        ),
        padding: EdgeInsets.fromLTRB(context.gutter, 12, context.gutter, 14),
        // Sul tablet i due bottoni restano larghi quanto il modulo.
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Row(
              children: [
                if (_i > 0) ...[
                  Expanded(
                    child: PillButton(
                      'Indietro',
                      filled: false,
                      expand: true,
                      icon: Ico.arrowLeft,
                      onTap: _back,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: PillButton(
                    last ? 'Invia' : 'Avanti',
                    expand: true,
                    icon: last ? Ico.send : Ico.arrowRight,
                    onTap: () => _next(f, steps),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return SiteScaffold(
      location: '/preventivo',
      footer: false,
      bottomBar: bar,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            context.spaceTop,
            context.gutter,
            40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (var k = 0; k < steps.length; k++) ...[
                        if (k > 0) const SizedBox(width: 4),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            height: 2,
                            color: k <= _i ? Palette.ink : Palette.line,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'PASSO ${_i + 1} DI ${steps.length}',
                    style: label(10.5, color: Palette.stone),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.title.toUpperCase(),
                    style: display(24, spacing: 0.1, height: 1.2),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(a),
                        child: c,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(step),
                      child: _body(step, f, steps),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(_Step step, QuoteForm f, List<_Step> steps) {
    const gap = SizedBox(height: 16);
    switch (step) {
      case _Step.event:
        final types = f.activeEventTypes;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (f.showEvent && types.isNotEmpty) ...[
              _Hint('Tipo di evento'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in types)
                    _Choice(
                      t.label,
                      selected: _type == t.label,
                      onTap: () => setState(() => _type = t.label),
                    ),
                ],
              ),
              _Error(_shown('type', f)),
              gap,
            ],
            if (f.showDate) ...[
              _DateField(
                value: _when == null ? '' : _date.format(_when!),
                error: _shown('date', f),
                onTap: _pickDate,
              ),
              gap,
            ],
            if (f.showLocation)
              TextField(
                controller: _location,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _tried ? setState(() {}) : null,
                decoration: InputDecoration(
                  labelText: 'Luogo *',
                  hintText: 'Città o nome della location',
                  counterText: '',
                  errorText: _shown('location', f),
                ),
              ),
          ],
        );
      case _Step.requests:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hint('Toccate una o più voci. *'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in f.activeRequests)
                  _Choice(
                    r.label,
                    selected: _requests.contains(r.label),
                    onTap: () => setState(() {
                      if (!_requests.remove(r.label)) _requests.add(r.label);
                    }),
                  ),
              ],
            ),
            _Error(_shown('requests', f)),
          ],
        );
      case _Step.contacts:
        InputDecoration deco(String l, String k, {Ico? icon, String? hint}) =>
            InputDecoration(
              labelText: l,
              hintText: hint,
              counterText: '',
              prefixIcon: icon == null ? null : InputIcon(icon),
              errorText: _shown(k, f),
            );
        void refresh(String _) => _tried ? setState(() {}) : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _first,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [_onlyName],
              autofillHints: const [AutofillHints.givenName],
              onChanged: refresh,
              decoration: deco('Nome *', 'first'),
            ),
            if (f.askLastName) ...[
              gap,
              TextField(
                controller: _last,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [_onlyName],
                autofillHints: const [AutofillHints.familyName],
                onChanged: refresh,
                decoration: deco('Cognome *', 'last'),
              ),
            ],
            if (f.phoneOn) ...[
              gap,
              TextField(
                controller: _phone,
                maxLength: 20,
                keyboardType: TextInputType.phone,
                inputFormatters: [_onlyPhone],
                autofillHints: const [AutofillHints.telephoneNumber],
                onChanged: refresh,
                decoration: deco(
                  'Telefono *',
                  'phone',
                  icon: Ico.phone,
                  hint: '333 123 4567',
                ),
              ),
            ],
            if (f.emailOn) ...[
              gap,
              TextField(
                controller: _mail,
                maxLength: 80,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onChanged: refresh,
                decoration: deco(
                  'Email *',
                  'email',
                  icon: Ico.mail,
                  hint: 'nome@email.it',
                ),
              ),
            ],
          ],
        );
      case _Step.message:
        return TextField(
          controller: _message,
          maxLength: 500,
          minLines: 5,
          maxLines: 9,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Messaggio (facoltativo)',
            hintText: 'Scriveteci pure per qualsiasi altra informazione',
            alignLabelWithHint: true,
          ),
        );
      case _Step.summary:
        final rows = <(String, String, int)>[
          if (steps.contains(_Step.event))
            (
              'Evento',
              [
                _type ?? '',
                if (_when != null) _date.format(_when!),
                _location.text.trim(),
              ].where((e) => e.isNotEmpty).join(' · '),
              steps.indexOf(_Step.event),
            ),
          if (steps.contains(_Step.requests))
            (
              'Richieste',
              _requests.isEmpty
                  ? 'Nessuna in particolare'
                  : [
                      for (final r in f.activeRequests)
                        if (_requests.contains(r.label)) r.label,
                    ].join(', '),
              steps.indexOf(_Step.requests),
            ),
          (
            'Contatti',
            [
              '${_first.text.trim()} ${f.askLastName ? _last.text.trim() : ''}'
                  .trim(),
              if (f.phoneOn) _phone.text.trim(),
              if (f.emailOn) _mail.text.trim(),
            ].where((e) => e.isNotEmpty).join(' · '),
            steps.indexOf(_Step.contacts),
          ),
          if (steps.contains(_Step.message))
            (
              'Messaggio',
              _message.text.trim().isEmpty ? '—' : _message.text.trim(),
              steps.indexOf(_Step.message),
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (t, v, k) in rows)
              InkWell(
                onTap: () => setState(() {
                  _tried = false;
                  _i = k;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Palette.line)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          t.toUpperCase(),
                          style: label(9.5, color: Palette.stone),
                        ),
                      ),
                      Expanded(child: Text(v, style: body(15, height: 1.45))),
                      const LineIcon(Ico.edit, size: 16, color: Palette.ash),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 22),
            InkWell(
              onTap: () => setState(() => _privacy = !_privacy),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _privacy,
                    onChanged: (v) => setState(() => _privacy = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Acconsento al trattamento dei miei dati per essere '
                        'ricontattato. *',
                        style: body(14, color: Palette.stone),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Error(_shown('privacy', f)),
          ],
        );
    }
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: body(14, color: Palette.stone)),
  );
}

class _Error extends StatelessWidget {
  const _Error(this.text);
  final String? text;

  @override
  Widget build(BuildContext context) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(text!, style: body(12.5, color: Palette.error)),
        );
}

/// Una voce da toccare, a pillola come sul sito.
class _Choice extends StatelessWidget {
  const _Choice(this.text, {required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Palette.ink : Palette.paper,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: selected ? Palette.ink : Palette.lineStrong,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const LineIcon(Ico.check, size: 16, color: Palette.paper),
              const SizedBox(width: 6),
            ],
            // Una voce molto lunga va a capo invece di uscire dallo schermo.
            Flexible(
              child: Text(
                text,
                style: body(
                  14,
                  weight: FontWeight.w500,
                  color: selected ? Palette.paper : Palette.ink,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.error,
    required this.onTap,
  });
  final String value;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: InputDecorator(
      isEmpty: value.isEmpty,
      decoration: InputDecoration(
        labelText: 'Data dell\'evento *',
        errorText: error,
        suffixIcon: const InputIcon(Ico.calendar),
      ),
      // Stesso testo dei campi scritti, così il riquadro è alto uguale.
      child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    ),
  );
}

class _Thanks extends StatelessWidget {
  const _Thanks({required this.quote, required this.onAgain});
  final QuoteRequest quote;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final how = quote.phone.isNotEmpty
        ? 'Vi richiameremo al ${quote.phone} per parlarne insieme.'
        : 'Vi scriveremo a ${quote.email} per parlarne insieme.';
    return Padding(
      padding: EdgeInsets.fromLTRB(context.gutter, 70, context.gutter, 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              const BrandMark(height: 40),
              const SizedBox(height: 22),
              const Tag('Richiesta inviata'),
              const SizedBox(height: 16),
              Text(
                'Grazie, ${quote.firstName}',
                textAlign: TextAlign.center,
                style: display(32, height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                how,
                textAlign: TextAlign.center,
                style: body(15.5, color: Palette.stone),
              ),
              const SizedBox(height: 28),
              PillButton('Torna alla home', onTap: () => context.go('/')),
              const SizedBox(height: 12),
              HoverLink(
                'Nuova richiesta',
                style: body(14.5, weight: FontWeight.w500),
                onTap: onAgain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
