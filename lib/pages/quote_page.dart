import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/photo_ui.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

/// Larghezza massima del modulo: resta raccolto e facile da compilare.
const _formW = 820.0;

final _dateFmt = DateFormat('dd/MM/yyyy', 'it_IT');

// ------------------------------------------------------------ controlli

/// Data come gg/mm/aaaa: solo cifre, le barre si inseriscono da sole.
class DateMaskFormatter extends TextInputFormatter {
  const DateMaskFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 8) d = d.substring(0, 8);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 4) b.write('/');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Il "+" del prefisso internazionale è ammesso solo come primo carattere;
/// gli altri (es. in un numero incollato) si tolgono.
class _PlusOnlyFirst extends TextInputFormatter {
  const _PlusOnlyFirst();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lead = newValue.text.trimLeft();
    final plus = lead.startsWith('+');
    final out =
        (plus ? '+' : '') + (plus ? lead.substring(1) : lead).replaceAll('+', '');
    if (out == newValue.text) return newValue;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

final _phoneFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
  const _PlusOnlyFirst(),
  LengthLimitingTextInputFormatter(20),
];

final _nameFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ' \-]")),
  LengthLimitingTextInputFormatter(40),
];

final _emailFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.deny(RegExp(r'\s')),
  LengthLimitingTextInputFormatter(80),
];

final _emailRe = RegExp(
  r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$',
);

/// Controlli dei campi (usati sia dal modulo sia dai test).
abstract final class QuoteRules {
  static String? name(String? v, String what) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Inserisci il $what';
    if (t.replaceAll(RegExp(r"[' \-]"), '').length < 2) {
      return 'Il $what deve avere almeno 2 lettere';
    }
    return null;
  }

  static String? phone(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Inserisci il numero di telefono';
    final d = t.replaceAll(RegExp(r'\D'), '');
    if (d.length < 8 || d.length > 15) {
      return 'Numero non valido: servono da 8 a 15 cifre';
    }
    return null;
  }

  static String? email(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Inserisci l\'indirizzo email';
    return _emailRe.hasMatch(t) ? null : 'Email non valida (es. nome@email.it)';
  }

  static String? place(String? v) => (v ?? '').trim().length < 2
      ? 'Indica la città o la location dell\'evento'
      : null;

  /// Data dell'evento come gg/mm/aaaa, da oggi a 5 anni.
  static String? date(String? v, {DateTime? today}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Inserisci la data dell\'evento';
    final d = parseDate(t);
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(t)) {
      return 'Scrivi la data come gg/mm/aaaa';
    }
    if (d == null) return 'Questa data non esiste';
    final now = today ?? DateTime.now();
    final day0 = DateTime(now.year, now.month, now.day);
    if (d.isBefore(day0)) return 'La data è già passata';
    if (d.isAfter(DateTime(now.year + 5, now.month, now.day))) {
      return 'Scegli una data entro 5 anni';
    }
    return null;
  }

  /// gg/mm/aaaa → data, oppure null se non esiste (es. 31/02/2026).
  static DateTime? parseDate(String t) {
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(t.trim());
    if (m == null) return null;
    final d = int.parse(m[1]!), mo = int.parse(m[2]!), y = int.parse(m[3]!);
    final r = DateTime(y, mo, d);
    return r.year == y && r.month == mo && r.day == d ? r : null;
  }
}

// ------------------------------------------------------------------ pagina

class QuotePage extends StatefulWidget {
  const QuotePage({super.key, this.preService, this.prePackage});
  final String? preService;
  final String? prePackage;

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  final _formKey = GlobalKey<FormState>();
  final _topAnchor = GlobalKey();
  final _eventKey = GlobalKey();
  final _servicesKey = GlobalKey();
  final _contactsKey = GlobalKey();
  final _privacyKey = GlobalKey();

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _date = TextEditingController();
  final _place = TextEditingController();
  final _other = TextEditingController();
  final _message = TextEditingController();

  String? _eventType;
  final Set<String> _services = {};

  /// Pacchetto arrivato dal link (?p=), finché la scelta resta quella.
  String? _packageId;
  bool _privacy = false;
  bool _tried = false;
  bool _sending = false;
  String? _sendError;
  QuoteRequest? _sent;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    // Si preselezionano solo voci visibili sul sito.
    final p = s.packageById(widget.prePackage);
    if (p != null && p.active) {
      _packageId = p.id;
      _services.addAll(
        p.serviceIds.where((id) => s.serviceById(id)?.active ?? false),
      );
    } else if (widget.preService != null &&
        (s.serviceById(widget.preService!)?.active ?? false)) {
      _services.add(widget.preService!);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _first,
      _last,
      _phone,
      _email,
      _date,
      _place,
      _other,
      _message,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _selected(AppState s) => [
    for (final sv in s.activeServices)
      if (_services.contains(sv.id)) sv.id,
  ];

  void _toggle(String id) => setState(() {
    if (!_services.remove(id)) _services.add(id);
    _packageId = null;
  });

  String? _typeError(AppState s) =>
      _eventType == null && s.content.eventTypes.isNotEmpty
      ? 'Scegli il tipo di evento'
      : null;

  String? _otherError() => _eventType == 'Altro' && _other.text.trim().isEmpty
      ? 'Scrivi di che evento si tratta'
      : null;

  String? _servicesError(AppState s) =>
      s.activeServices.isNotEmpty && _selected(s).isEmpty
      ? 'Scegli almeno una voce'
      : null;

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      // Lascia spazio alla barra di navigazione in alto.
      alignment: 0.1,
    );
  }

  /// La prima parte del modulo con un errore, per portarci il visitatore.
  GlobalKey? _firstError(AppState s) {
    if (_typeError(s) != null ||
        _otherError() != null ||
        QuoteRules.date(_date.text) != null ||
        QuoteRules.place(_place.text) != null) {
      return _eventKey;
    }
    if (_servicesError(s) != null) return _servicesKey;
    if (QuoteRules.name(_first.text, 'nome') != null ||
        QuoteRules.name(_last.text, 'cognome') != null ||
        QuoteRules.phone(_phone.text) != null ||
        QuoteRules.email(_email.text) != null) {
      return _contactsKey;
    }
    if (!_privacy) return _privacyKey;
    return null;
  }

  Future<void> _submit(AppState s) async {
    setState(() => _tried = true);
    final okForm = _formKey.currentState!.validate();
    final err = _firstError(s);
    if (!okForm || err != null) {
      if (err != null) _scrollTo(err);
      return;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    final type = _eventType == 'Altro'
        ? 'Altro: ${_other.text.trim()}'
        : (_eventType ?? '');
    final q = QuoteRequest(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      eventType: type,
      eventDate: QuoteRules.parseDate(_date.text),
      location: _place.text.trim(),
      message: _message.text.trim(),
      serviceIds: _selected(s),
      packageId: _packageId,
    );
    try {
      await s.addQuote(q);
    } catch (_) {
      // Es. archivio del browser pieno: il pulsante non resta in attesa.
      if (mounted) {
        setState(() {
          _sending = false;
          _sendError = 'Invio non riuscito. Riprova tra qualche istante.';
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = q;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_topAnchor));
  }

  void _reset() => setState(() {
    _sent = null;
    _tried = false;
    _services.clear();
    _packageId = null;
    _eventType = null;
    for (final c in [_date, _place, _other, _message]) {
      c.clear();
    }
    // Il consenso va dato di nuovo per ogni richiesta.
    _privacy = false;
  });

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final image = s.content.bannerImage.trim().isNotEmpty
        ? s.content.bannerImage
        : (s.heroPhotos.isEmpty ? '' : s.heroPhotos.first.url);

    return SiteScaffold(
      location: '/preventivo',
      children: [
        SizedBox(key: _topAnchor, height: 0),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            context.fluid(36, 80),
            context.gutter,
            context.fluid(70, 120),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: _sent != null
                  ? _Success(quote: _sent!, onNew: _reset)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(image: image),
                        SizedBox(height: context.fluid(28, 48)),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _formW,
                            ),
                            child: _buildForm(s),
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

  Widget _buildForm(AppState s) {
    final twoCols = context.w >= 720;
    Widget pair(Widget a, Widget b) => twoCols
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 16),
              Expanded(child: b),
            ],
          )
        : Column(children: [a, const SizedBox(height: 16), b]);
    const gap = SizedBox(height: 16);
    final types = s.content.eventTypes.toSet().toList();
    final live = AutovalidateMode.onUserInteraction;
    final servicesError = _tried ? _servicesError(s) : null;

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(context.fluid(20, 44)),
        decoration: BoxDecoration(
          color: Palette.ivory,
          border: Border.all(color: Palette.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Step(
              key: _eventKey,
              number: 1,
              title: 'Il tuo evento',
              child: Column(
                children: [
                  pair(
                    DropdownButtonFormField<String>(
                      initialValue: types.contains(_eventType)
                          ? _eventType
                          : null,
                      isExpanded: true,
                      autovalidateMode: live,
                      dropdownColor: Palette.ivory,
                      decoration: const InputDecoration(
                        labelText: 'Tipo di evento *',
                      ),
                      items: [
                        for (final t in types)
                          DropdownMenuItem(value: t, child: Text(t)),
                      ],
                      onChanged: (v) => setState(() => _eventType = v),
                      validator: (_) => _typeError(s),
                    ),
                    TextFormField(
                      controller: _date,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: const [DateMaskFormatter()],
                      autovalidateMode: live,
                      decoration: InputDecoration(
                        labelText: 'Data dell\'evento *',
                        hintText: 'gg/mm/aaaa',
                        suffixIcon: IconButton(
                          tooltip: 'Scegli dal calendario',
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 19,
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      validator: (v) => QuoteRules.date(v),
                    ),
                  ),
                  if (_eventType == 'Altro') ...[
                    gap,
                    TextFormField(
                      controller: _other,
                      autovalidateMode: live,
                      inputFormatters: [LengthLimitingTextInputFormatter(60)],
                      decoration: const InputDecoration(
                        labelText: 'Di che evento si tratta? *',
                      ),
                      validator: (_) => _otherError(),
                    ),
                  ],
                  gap,
                  TextFormField(
                    controller: _place,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: live,
                    inputFormatters: [LengthLimitingTextInputFormatter(80)],
                    decoration: const InputDecoration(
                      labelText: 'Luogo *',
                      hintText: 'Città o nome della location',
                    ),
                    validator: QuoteRules.place,
                  ),
                ],
              ),
            ),
            if (s.activeServices.isNotEmpty) ...[
              const _Divider(),
              _Step(
                key: _servicesKey,
                number: 2,
                title: 'Cosa ti serve',
                hint: 'Tocca una o più voci.',
                child: _ServicePicker(
                  services: s.activeServices,
                  selected: _services,
                  error: servicesError,
                  onToggle: _toggle,
                ),
              ),
            ],
            const _Divider(),
            _Step(
              key: _contactsKey,
              number: s.activeServices.isEmpty ? 2 : 3,
              title: 'I tuoi contatti',
              child: AutofillGroup(
                child: Column(
                  children: [
                    pair(
                      TextFormField(
                        controller: _first,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.givenName],
                        inputFormatters: _nameFormatters,
                        autovalidateMode: live,
                        decoration: const InputDecoration(
                          labelText: 'Nome *',
                        ),
                        validator: (v) => QuoteRules.name(v, 'nome'),
                      ),
                      TextFormField(
                        controller: _last,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.familyName],
                        inputFormatters: _nameFormatters,
                        autovalidateMode: live,
                        decoration: const InputDecoration(
                          labelText: 'Cognome *',
                        ),
                        validator: (v) => QuoteRules.name(v, 'cognome'),
                      ),
                    ),
                    gap,
                    pair(
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: _phoneFormatters,
                        autovalidateMode: live,
                        decoration: const InputDecoration(
                          labelText: 'Telefono *',
                          hintText: 'Es. 333 123 4567',
                          prefixIcon: Icon(Icons.phone_outlined, size: 19),
                        ),
                        validator: QuoteRules.phone,
                      ),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        inputFormatters: _emailFormatters,
                        autovalidateMode: live,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          hintText: 'nome@email.it',
                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            size: 19,
                          ),
                        ),
                        validator: QuoteRules.email,
                      ),
                    ),
                    gap,
                    TextFormField(
                      controller: _message,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Note (facoltative)',
                        hintText: 'Numero di invitati, orari, idee…',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _Privacy(
              key: _privacyKey,
              value: _privacy,
              error: _tried && !_privacy,
              onChanged: (v) => setState(() => _privacy = v),
            ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 18,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PillButton(
                  'Invia la richiesta',
                  big: true,
                  loading: _sending,
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => _submit(s),
                ),
                Text(
                  '* campi obbligatori',
                  style: body(13, color: Palette.stone),
                ),
              ],
            ),
            if (_sendError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _sendError!,
                  style: body(13.5, color: Palette.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = QuoteRules.parseDate(_date.text);
    final last = DateTime(now.year + 5, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(today)
          ? (current.isAfter(last) ? last : current)
          : today.add(const Duration(days: 30)),
      firstDate: today,
      lastDate: last,
      locale: const Locale('it', 'IT'),
    );
    if (d != null && mounted) setState(() => _date.text = _dateFmt.format(d));
  }
}

// ---------------------------------------------------------------- struttura

/// Titolo e invito, con una foto accanto su schermi larghi.
class _Header extends StatelessWidget {
  const _Header({required this.image});
  final String image;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MaskReveal(child: Tag('Preventivo gratuito')),
        SizedBox(height: context.fluid(14, 20)),
        MaskReveal(
          delay: 120,
          child: Text(
            'RACCONTACI\nIL TUO EVENTO',
            style: display(context.fluid(30, 54), spacing: 0.08, height: 1.08),
          ),
        ),
        SizedBox(height: context.fluid(12, 18)),
        MaskReveal(
          delay: 240,
          child: Text(
            'Bastano due minuti: compila i campi e ti richiamiamo noi con una '
            'proposta su misura. Gratuito e senza impegno.',
            style: display(
              context.fluid(17, 20),
              color: Palette.stone,
              italic: true,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
    if (context.isTablet || image.trim().isEmpty) return text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 6, child: text),
        SizedBox(width: context.fluid(40, 80)),
        Expanded(
          flex: 5,
          child: Reveal(
            child: AspectRatio(aspectRatio: 3 / 2, child: PhotoImage(image)),
          ),
        ),
      ],
    );
  }
}

/// Una parte del modulo, con il suo numero.
class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.number,
    required this.title,
    required this.child,
    this.hint,
  });
  final int number;
  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Palette.ink,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: body(
                  13,
                  color: Palette.paper,
                  weight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: display(
                  context.fluid(17, 20),
                  weight: FontWeight.w400,
                  spacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(hint!, style: body(13.5, color: Palette.stone)),
          ),
        ],
        SizedBox(height: context.fluid(16, 22)),
        child,
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.fluid(22, 32)),
    child: Container(height: 1, color: Palette.line),
  );
}

/// Servizi come pulsanti a pillola, raggruppati per categoria.
class _ServicePicker extends StatelessWidget {
  const _ServicePicker({
    required this.services,
    required this.selected,
    required this.error,
    required this.onToggle,
  });
  final List<ServiceItem> services;
  final Set<String> selected;
  final String? error;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final cats = <String>[];
    for (final s in services) {
      if (!cats.contains(s.category)) cats.add(s.category);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < cats.length; c++) ...[
          if (c > 0) const SizedBox(height: 18),
          if (cats.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                cats[c].toUpperCase(),
                style: label(10, color: Palette.stone),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in services.where((e) => e.category == cats[c]))
                _Choice(
                  text: s.name,
                  selected: selected.contains(s.id),
                  onTap: () => onToggle(s.id),
                ),
            ],
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: body(13, color: Palette.error)),
        ],
      ],
    );
  }
}

class _Choice extends StatefulWidget {
  const _Choice({
    required this.text,
    required this.selected,
    required this.onTap,
  });
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Choice> createState() => _ChoiceState();
}

class _ChoiceState extends State<_Choice> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return Semantics(
      button: true,
      selected: sel,
      label: widget.text,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.fromLTRB(sel ? 12 : 16, 10, 16, 10),
            decoration: BoxDecoration(
              color: sel ? Palette.ink : Palette.paper,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: sel || _hover ? Palette.ink : Palette.lineStrong,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sel) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Palette.paper,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    widget.text,
                    style: body(
                      14,
                      color: sel ? Palette.paper : Palette.ink,
                      weight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Privacy extends StatelessWidget {
  const _Privacy({
    super.key,
    required this.value,
    required this.error,
    required this.onChanged,
  });
  final bool value;
  final bool error;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: value,
                  side: BorderSide(
                    color: error ? Palette.error : Palette.ink,
                    width: 1.4,
                  ),
                  onChanged: (v) => onChanged(v ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
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
        if (error)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 38),
            child: Text(
              'Serve il consenso per inviare la richiesta.',
              style: body(13, color: Palette.error),
            ),
          ),
      ],
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.quote, required this.onNew});
  final QuoteRequest quote;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: EdgeInsets.all(context.fluid(26, 48)),
          decoration: BoxDecoration(
            color: Palette.ivory,
            border: Border.all(color: Palette.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const BrandMark(height: 40),
              const SizedBox(height: 22),
              const Tag('Richiesta inviata'),
              const SizedBox(height: 16),
              Text(
                'Grazie, ${quote.firstName}',
                textAlign: TextAlign.center,
                style: display(context.fluid(28, 38)),
              ),
              const SizedBox(height: 12),
              Text(
                'Ti richiameremo al ${quote.phone} per parlarne insieme.',
                textAlign: TextAlign.center,
                style: body(15.5, color: Palette.stone),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 18,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PillButton('Torna alla home', onTap: () => context.go('/')),
                  HoverLink(
                    'Nuova richiesta',
                    style: body(14.5, weight: FontWeight.w500),
                    onTap: onNew,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
