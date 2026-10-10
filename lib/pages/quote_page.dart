import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/photo_ui.dart';
import '../widgets/site_scaffold.dart';

/// Larghezza massima del contenuto: la pagina resta raccolta e leggibile.
const _maxW = 1120.0;

class QuotePage extends StatefulWidget {
  const QuotePage({super.key, this.preService, this.prePackage});
  final String? preService;
  final String? prePackage;

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  final _formKey = GlobalKey<FormState>();
  final _formAnchor = GlobalKey();
  final _topAnchor = GlobalKey();

  // Selezione
  String? _packageId;
  final Set<String> _extra = {};
  bool _custom = false;

  // Modulo
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _other = TextEditingController();
  final _message = TextEditingController();
  String? _eventType;
  DateTime? _eventDate;
  bool _privacy = false;
  bool _privacyError = false;
  bool _sending = false;
  bool _formVisible = false;
  String? _selectionError;
  QuoteRequest? _sent;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    if (widget.prePackage != null && s.packageById(widget.prePackage) != null) {
      _packageId = widget.prePackage;
    } else if (widget.preService != null &&
        s.serviceById(widget.preService!) != null) {
      _extra.add(widget.preService!);
      _custom = true;
    } else {
      _custom = s.activePackages.isEmpty;
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _email, _other, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------- selezione

  List<String> _ids(AppState s) {
    final ids = <String>[];
    final p = s.packageById(_packageId);
    if (p != null) ids.addAll(p.serviceIds);
    ids.addAll(_extra.where((e) => !ids.contains(e)));
    return ids.where((id) => s.serviceById(id)?.active ?? false).toList();
  }

  void _choosePackage(ServicePackage p) => setState(() {
    _packageId = _packageId == p.id ? null : p.id;
    _extra.removeWhere((e) => p.serviceIds.contains(e));
    _selectionError = null;
  });

  /// Togliendo un servizio di un pacchetto, il pacchetto diventa "su misura".
  void _dissolvePackage(AppState s) {
    final p = s.packageById(_packageId);
    if (p == null) return;
    _extra.addAll(p.serviceIds);
    _packageId = null;
  }

  void _toggle(AppState s, String id) => setState(() {
    final p = s.packageById(_packageId);
    if (p != null && p.serviceIds.contains(id)) {
      _dissolvePackage(s);
      _extra.remove(id);
    } else if (!_extra.remove(id)) {
      _extra.add(id);
    }
    _selectionError = null;
  });

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        // Lascia spazio alla barra di navigazione in alto.
        alignment: 0.13,
      );
    }
  }

  // ----------------------------------------------------------------- invio

  Future<void> _submit(AppState s) async {
    final ids = _ids(s);
    final okForm = _formKey.currentState!.validate();
    setState(() {
      _privacyError = !_privacy;
      _selectionError = ids.isEmpty
          ? 'Scegli almeno un servizio o un pacchetto.'
          : null;
    });
    if (ids.isEmpty || !okForm || !_privacy) return;

    setState(() => _sending = true);
    final type = _eventType == 'Altro' && _other.text.trim().isNotEmpty
        ? 'Altro: ${_other.text.trim()}'
        : _eventType!;
    final q = QuoteRequest(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      eventType: type,
      eventDate: _eventDate,
      message: _message.text.trim(),
      serviceIds: ids,
      packageId: _packageId,
    );
    await s.addQuote(q);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = q;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_topAnchor));
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ids = _ids(s);
    final showBar = _sent == null && ids.isNotEmpty && !_formVisible;

    return SiteScaffold(
      location: '/preventivo',
      overlay: Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          offset: showBar ? Offset.zero : const Offset(0, 1.3),
          child: _SelectionBar(
            count: ids.length,
            packageName: s.packageById(_packageId)?.name,
            onNext: () => _scrollTo(_formAnchor),
          ),
        ),
      ),
      children: [
        SizedBox(key: _topAnchor, height: 0),
        _Page(
          child: _sent != null
              ? _Success(
                  quote: _sent!,
                  onNew: () => setState(() {
                    _sent = null;
                    _packageId = null;
                    _extra.clear();
                  }),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(step: _formVisible ? 2 : 1),
                    SizedBox(height: context.fluid(28, 44)),
                    _Card(
                      number: '1',
                      title: 'Cosa ti serve',
                      trailing: s.activePackages.isEmpty
                          ? null
                          : _Segmented(
                              custom: _custom,
                              onChanged: (v) => setState(() => _custom = v),
                            ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _custom || s.activePackages.isEmpty
                            ? _ServiceGrid(
                                key: const ValueKey('custom'),
                                state: s,
                                selected: ids.toSet(),
                                onTap: (id) => _toggle(s, id),
                              )
                            : _PackageGrid(
                                key: const ValueKey('packages'),
                                state: s,
                                selectedId: _packageId,
                                onTap: _choosePackage,
                                onCustom: () => setState(() => _custom = true),
                              ),
                      ),
                    ),
                    SizedBox(height: context.fluid(20, 28)),
                    VisibilityDetector(
                      key: const Key('quote-form'),
                      onVisibilityChanged: (i) {
                        final v = i.visibleFraction > 0.2;
                        if (v != _formVisible && mounted) {
                          setState(() => _formVisible = v);
                        }
                      },
                      child: _Card(
                        key: _formAnchor,
                        number: '2',
                        title: 'I tuoi contatti',
                        child: _buildContacts(s, ids),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildContacts(AppState s, List<String> ids) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Summary(
          state: s,
          ids: ids,
          package: s.packageById(_packageId),
          error: _selectionError,
          onRemove: (id) => _toggle(s, id),
        ),
        const SizedBox(height: 28),
        _buildForm(s),
      ],
    );
  }

  Widget _buildForm(AppState s) {
    final twoCols = context.w >= 720;
    String? req(String? v, String m) =>
        (v == null || v.trim().isEmpty) ? m : null;

    Widget pair(Widget a, Widget b) => twoCols
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 28),
              Expanded(child: b),
            ],
          )
        : Column(children: [a, const SizedBox(height: 16), b]);

    const gap = SizedBox(height: 18);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pair(
            TextFormField(
              controller: _first,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => req(v, 'Inserisci il nome'),
            ),
            TextFormField(
              controller: _last,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.familyName],
              decoration: const InputDecoration(labelText: 'Cognome'),
              validator: (v) => req(v, 'Inserisci il cognome'),
            ),
          ),
          gap,
          pair(
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(labelText: 'Telefono'),
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return d.length < 6 ? 'Inserisci un numero valido' : null;
              },
            ),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch((v ?? '').trim())
                  ? null
                  : 'Inserisci un indirizzo email valido',
            ),
          ),
          gap,
          pair(
            DropdownButtonFormField<String>(
              initialValue: _eventType,
              isExpanded: true,
              dropdownColor: Colors.white,
              decoration: const InputDecoration(labelText: 'Tipo di evento'),
              items: [
                for (final t in s.content.eventTypes)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _eventType = v),
              validator: (v) => v == null ? 'Scegli il tipo di evento' : null,
            ),
            _DateField(
              value: _eventDate,
              onChanged: (d) => setState(() => _eventDate = d),
            ),
          ),
          if (_eventType == 'Altro') ...[
            gap,
            TextFormField(
              controller: _other,
              decoration: const InputDecoration(
                labelText: 'Di che evento si tratta?',
              ),
            ),
          ],
          gap,
          TextFormField(
            controller: _message,
            minLines: 1,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Note (luogo, numero di invitati…)',
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              _privacy = !_privacy;
              _privacyError = false;
            }),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: _privacy,
                    onChanged: (v) => setState(() {
                      _privacy = v ?? false;
                      _privacyError = false;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Acconsento al trattamento dei miei dati per essere ricontattato.',
                      style: body(13.5, color: Palette.stone),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_privacyError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 38),
              child: Text(
                'Serve il consenso per inviare la richiesta.',
                style: body(13, color: const Color(0xFFB3261E)),
              ),
            ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PillButton(
                'Invia la richiesta',
                loading: _sending,
                icon: Icons.arrow_forward_rounded,
                onTap: () => _submit(s),
              ),
              Text(
                'Gratuito e senza impegno.',
                style: body(13.5, color: Palette.stone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- struttura

/// Contenuto centrato e raccolto, su fondo chiaro.
class _Page extends StatelessWidget {
  const _Page({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      context.gutter,
      context.fluid(32, 64),
      context.gutter,
      context.fluid(70, 120),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxW),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final steps = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepDot(n: 1, text: 'Scegli', active: step >= 1),
        Container(
          width: 36,
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: Palette.lineLight,
        ),
        _StepDot(n: 2, text: 'Contatti', active: step >= 2),
      ],
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Tag('Preventivo gratuito'),
        const SizedBox(height: 16),
        Text('Raccontaci il tuo evento', style: display(context.fluid(30, 44))),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Scegli cosa ti serve e lasciaci i tuoi contatti: ti richiamiamo '
            'noi con una proposta su misura.',
            style: body(context.fluid(15, 16.5), color: Palette.stone),
          ),
        ),
      ],
    );
    if (context.isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [text, const SizedBox(height: 22), steps],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        steps,
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.n, required this.text, required this.active});
  final int n;
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Palette.ink : Colors.transparent,
          border: Border.all(color: active ? Palette.ink : Palette.lineLight),
        ),
        child: Text(
          '$n',
          style: body(
            12,
            color: active ? Palette.paper : Palette.stone,
            weight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        text.toUpperCase(),
        style: label(10.5, color: active ? Palette.ink : Palette.stone),
      ),
    ],
  );
}

/// Scheda bianca con numero di passaggio e titolo.
class _Card extends StatelessWidget {
  const _Card({
    super.key,
    required this.number,
    required this.title,
    required this.child,
    this.trailing,
  });
  final String number;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final pad = context.fluid(18, 36);
    final heading = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: display(context.fluid(22, 28), color: Palette.stone),
        ),
        Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: Palette.lineLight,
        ),
        Flexible(
          child: Text(
            title.toUpperCase(),
            style: display(
              context.fluid(17, 21),
              weight: FontWeight.w400,
              spacing: 0.1,
            ),
          ),
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Palette.lineLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (trailing == null || context.isPhone) ...[
            heading,
            if (trailing != null) ...[const SizedBox(height: 16), trailing!],
          ] else
            Row(
              children: [
                Expanded(child: heading),
                trailing!,
              ],
            ),
          SizedBox(height: context.fluid(20, 30)),
          child,
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.custom, required this.onChanged});
  final bool custom;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget item(String text, bool active, VoidCallback onTap) => Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: text,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? Palette.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                text.toUpperCase(),
                style: label(10.5, color: active ? Palette.paper : Palette.ink),
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      width: 300,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: Palette.lineLight),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          item('Pacchetti', !custom, () => onChanged(false)),
          item('Su misura', custom, () => onChanged(true)),
        ],
      ),
    );
  }
}

/// Spunta circolare di selezione.
class _Check extends StatelessWidget {
  const _Check({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? Palette.ink : Colors.white.withValues(alpha: 0.85),
      border: Border.all(color: selected ? Palette.ink : Palette.lineLight),
    ),
    child: AnimatedOpacity(
      opacity: selected ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
    ),
  );
}

int _cols(
  BuildContext c, {
  required int phone,
  required int tablet,
  required int desk,
}) => c.isPhone ? phone : (c.isTablet ? tablet : desk);

/// Griglia di schede di uguale larghezza.
class _Grid extends StatelessWidget {
  const _Grid({required this.cols, required this.children, this.gap = 16});
  final int cols;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    },
  );
}

class _PackageGrid extends StatelessWidget {
  const _PackageGrid({
    super.key,
    required this.state,
    required this.selectedId,
    required this.onTap,
    required this.onCustom,
  });
  final AppState state;
  final String? selectedId;
  final ValueChanged<ServicePackage> onTap;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final pkgs = state.activePackages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Grid(
          cols: _cols(
            context,
            phone: 1,
            tablet: 2,
            desk: pkgs.length < 4 ? pkgs.length : 4,
          ),
          gap: context.fluid(12, 18),
          children: [
            for (final p in pkgs)
              _PackageCard(
                state: state,
                pkg: p,
                selected: p.id == selectedId,
                onTap: () => onTap(p),
              ),
          ],
        ),
        const SizedBox(height: 18),
        HoverLink(
          'Preferisci scegliere voce per voce? Componi su misura →',
          style: body(14, color: Palette.stone, weight: FontWeight.w500),
          onTap: onCustom,
        ),
      ],
    );
  }
}

class _PackageCard extends StatefulWidget {
  const _PackageCard({
    required this.state,
    required this.pkg,
    required this.selected,
    required this.onTap,
  });
  final AppState state;
  final ServicePackage pkg;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pkg;
    final sel = widget.selected;
    final names = [
      for (final id in p.serviceIds)
        if (widget.state.serviceById(id)?.active ?? false)
          widget.state.serviceById(id)!.name,
    ];
    return Semantics(
      button: true,
      selected: sel,
      label: 'Pacchetto ${p.name}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: sel
                    ? Palette.ink
                    : (_hover ? Palette.stone : Palette.lineLight),
                width: sel ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 3 / 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PhotoImage(p.image),
                      // Selezionare = "mettere a fuoco".
                      FocusFrame(
                        active: sel || _hover,
                        length: 16,
                        inset: 12,
                        focusPoint: sel,
                      ),
                      if (p.featured)
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            color: Palette.ink,
                            child: Text(
                              'PIÙ SCELTO',
                              style: label(9, color: Palette.paper),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: _Check(selected: sel),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name.toUpperCase(),
                        style: display(
                          19,
                          weight: FontWeight.w400,
                          spacing: 0.1,
                        ),
                      ),
                      if (p.tagline.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.tagline,
                          style: body(13.5, color: Palette.stone, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(height: 1, color: Palette.lineLight),
                      const SizedBox(height: 12),
                      for (final n in names)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Palette.stone,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(n, style: body(13.5, height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                    ],
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

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({
    super.key,
    required this.state,
    required this.selected,
    required this.onTap,
  });
  final AppState state;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final services = state.activeServices;
    final cats = <String>[];
    for (final s in services) {
      if (!cats.contains(s.category)) cats.add(s.category);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < cats.length; c++) ...[
          if (c > 0) const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              cats[c].toUpperCase(),
              style: label(10.5, color: Palette.stone),
            ),
          ),
          _Grid(
            cols: _cols(context, phone: 2, tablet: 3, desk: 4),
            gap: context.fluid(10, 16),
            children: [
              for (final s in services.where((e) => e.category == cats[c]))
                _ServiceTile(
                  service: s,
                  selected: selected.contains(s.id),
                  onTap: () => onTap(s.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ServiceTile extends StatefulWidget {
  const _ServiceTile({
    required this.service,
    required this.selected,
    required this.onTap,
  });
  final ServiceItem service;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final sel = widget.selected;
    return Semantics(
      button: true,
      selected: sel,
      label: s.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: sel
                    ? Palette.ink
                    : (_hover ? Palette.stone : Palette.lineLight),
                width: sel ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PhotoImage(s.image),
                      FocusFrame(
                        active: sel,
                        length: 12,
                        inset: 8,
                        focusPoint: true,
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: _Check(selected: sel),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
                  child: Text(
                    s.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: body(13.5, weight: FontWeight.w500, height: 1.35),
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

/// Riepilogo della selezione, in cima al modulo.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.state,
    required this.ids,
    required this.package,
    required this.error,
    required this.onRemove,
  });
  final AppState state;
  final List<String> ids;
  final ServicePackage? package;
  final String? error;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.paper,
        border: Border.all(
          color: error != null ? const Color(0xFFB3261E) : Palette.lineLight,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ids.isEmpty
                ? 'LA TUA SELEZIONE'
                : (package != null
                      ? 'PACCHETTO ${package!.name.toUpperCase()}'
                      : 'SU MISURA · ${ids.length} VOCI'),
            style: label(10.5, color: Palette.stone),
          ),
          const SizedBox(height: 10),
          if (ids.isEmpty)
            Text(
              'Non hai ancora scelto nulla: seleziona un pacchetto o dei servizi qui sopra.',
              style: body(14, color: Palette.stone),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in ids)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Palette.lineLight),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            state.serviceById(id)?.name ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: body(13, height: 1.2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkResponse(
                          onTap: () => onRemove(id),
                          radius: 14,
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: Palette.stone,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: body(13.5, color: const Color(0xFFB3261E))),
          ],
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.packageName,
    required this.onNext,
  });
  final int count;
  final String? packageName;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Palette.ink,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.gutter,
          10,
          context.gutter,
          10 + bottom,
        ),
        child: Row(
          children: [
            const BrandMark(height: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                packageName != null
                    ? 'Pacchetto $packageName'
                    : '$count ${count == 1 ? 'servizio scelto' : 'servizi scelti'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(14.5, color: Palette.paper),
              ),
            ),
            PillButton(
              'Avanti',
              onDark: true,
              icon: Icons.arrow_downward_rounded,
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onChanged});
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : DateFormat('d MMMM y', 'it_IT').format(value!);
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? now.add(const Duration(days: 30)),
          firstDate: now,
          lastDate: now.add(const Duration(days: 365 * 4)),
          locale: const Locale('it', 'IT'),
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: 'Data (facoltativa)',
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  tooltip: 'Rimuovi data',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(text, style: body(16)),
      ),
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
            color: Colors.white,
            border: Border.all(color: Palette.lineLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: Viewfinder(color: Palette.ink, length: 18, stroke: 1),
              ),
              Column(
                children: [
                  const BrandMark(height: 30, onDark: false),
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
                      PillButton(
                        'Torna alla home',
                        onTap: () => context.go('/'),
                      ),
                      HoverLink(
                        'Nuova richiesta',
                        style: body(14.5, weight: FontWeight.w500),
                        onTap: onNew,
                      ),
                    ],
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
