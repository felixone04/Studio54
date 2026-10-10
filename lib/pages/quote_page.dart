import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/site_scaffold.dart';

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
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
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
          duration: const Duration(milliseconds: 400),
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
        if (_sent != null)
          _Success(
            quote: _sent!,
            onNew: () => setState(() {
              _sent = null;
              _packageId = null;
              _extra.clear();
            }),
          )
        else ...[
          const _Header(),
          Section(
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StepTitle('01', 'Scegli'),
                SizedBox(height: context.fluid(22, 36)),
                if (s.activePackages.isNotEmpty) ...[
                  _Segmented(
                    custom: _custom,
                    onChanged: (v) => setState(() => _custom = v),
                  ),
                  SizedBox(height: context.fluid(28, 48)),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
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
              ],
            ),
          ),
          Container(
            key: _formAnchor,
            color: Palette.paper2,
            child: VisibilityDetector(
              key: const Key('quote-form'),
              onVisibilityChanged: (i) {
                final v = i.visibleFraction > 0.25;
                if (v != _formVisible && mounted) {
                  setState(() => _formVisible = v);
                }
              },
              child: Section(child: _buildContacts(s, ids)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContacts(AppState s, List<String> ids) {
    final summary = _Summary(
      state: s,
      ids: ids,
      package: s.packageById(_packageId),
      error: _selectionError,
      onRemove: (id) => _toggle(s, id),
    );
    final form = _buildForm(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle('02', 'Contatti'),
        SizedBox(height: context.fluid(28, 56)),
        if (context.isTablet) ...[
          summary,
          SizedBox(height: context.fluid(32, 48)),
          form,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: form),
              SizedBox(width: context.fluid(40, 100)),
              Expanded(flex: 4, child: summary),
            ],
          ),
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
        : Column(children: [a, const SizedBox(height: 18), b]);

    const gap = SizedBox(height: 22);
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
              dropdownColor: Palette.paper,
              decoration: const InputDecoration(labelText: 'Tipo di festa'),
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
            decoration: const InputDecoration(labelText: 'Note (facoltativo)'),
          ),
          const SizedBox(height: 26),
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
          SizedBox(height: context.fluid(30, 44)),
          PillButton(
            'Invia la richiesta',
            big: true,
            loading: _sending,
            onTap: () => _submit(s),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- blocchi

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Section(
      top: context.fluid(40, 90),
      bottom: context.fluid(48, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Tag('Preventivo gratuito'),
          SizedBox(height: context.fluid(16, 28)),
          MaskRevealText(
            lines: const ['Il tuo', 'preventivo.'],
            size: context.fluid(60, 190),
          ),
          SizedBox(height: context.fluid(20, 32)),
          Text(
            'Scegli cosa ti serve. Ti richiamiamo noi.',
            style: body(context.fluid(16, 20), color: Palette.stone),
          ),
        ],
      ),
    );
  }
}

/// Titolo su più righe, le dispari in corsivo colorato.
class MaskRevealText extends StatelessWidget {
  const MaskRevealText({super.key, required this.lines, required this.size});
  final List<String> lines;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Reveal(
            delay: Duration(milliseconds: 120 * i),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                lines[i],
                maxLines: 1,
                style: display(
                  size,
                  italic: i.isOdd,
                  color: i.isOdd ? context.accentInk : Palette.ink,
                  height: 0.95,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.number, this.title);
  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          number,
          style: display(
            context.fluid(40, 84),
            italic: true,
            color: context.accentInk,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: Text(title, style: display(context.fluid(40, 84)))),
      ],
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
              duration: const Duration(milliseconds: 280),
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? Palette.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                text.toUpperCase(),
                style: label(11.5, color: active ? Palette.paper : Palette.ink),
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Palette.ink),
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

class _Check extends StatelessWidget {
  const _Check({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? context.accent : Colors.black.withValues(alpha: 0.25),
        border: Border.all(
          color: selected ? context.accent : Palette.paper,
          width: 1.4,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: const Icon(Icons.check_rounded, size: 20, color: Palette.ink),
      ),
    );
  }
}

int _cols(
  BuildContext c, {
  required int phone,
  required int tablet,
  required int desk,
}) => c.isPhone ? phone : (c.isTablet ? tablet : desk);

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
    final cols = _cols(
      context,
      phone: 1,
      tablet: 2,
      desk: pkgs.length < 4 ? pkgs.length : 4,
    );
    final gap = context.fluid(16, 28);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap * 1.6,
              children: [
                for (final p in pkgs)
                  SizedBox(
                    width: w,
                    child: _PackageCard(
                      state: state,
                      pkg: p,
                      selected: p.id == selectedId,
                      onTap: () => onTap(p),
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: context.fluid(24, 40)),
        HoverLink(
          'Preferisci scegliere tu? Crea il tuo →',
          style: body(15, color: Palette.ink, weight: FontWeight.w600),
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
    final names = [
      for (final id in p.serviceIds)
        if (widget.state.serviceById(id)?.active ?? false)
          widget.state.serviceById(id)!.name,
    ];
    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'Pacchetto ${p.name}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.all(widget.selected ? 6 : 0),
                color: widget.selected ? Palette.ink : Colors.transparent,
                child: AspectRatio(
                  aspectRatio: context.isPhone ? 4 / 3.4 : 3 / 4,
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedScale(
                          scale: _hover ? 1.05 : 1,
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          child: PhotoImage(p.image, dark: true),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x33000000),
                                Color(0x00000000),
                                Color(0xE0000000),
                              ],
                              stops: [0, 0.35, 1],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (p.featured)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.accent,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'PIÙ SCELTO',
                                        style: label(9.5, color: Palette.ink),
                                      ),
                                    ),
                                  const Spacer(),
                                  _Check(selected: widget.selected),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                p.name,
                                style: display(
                                  context.fluid(36, 52),
                                  color: Palette.paper,
                                ),
                              ),
                              if (p.tagline.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  p.tagline,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: display(
                                    17,
                                    color: context.accent,
                                    italic: true,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final n in names)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('— $n', style: body(14, color: Palette.stone)),
                ),
            ],
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
    final cols = _cols(context, phone: 2, tablet: 3, desk: 4);
    final gap = context.fluid(10, 22);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cat in cats) ...[
          Padding(padding: const EdgeInsets.only(bottom: 16), child: Tag(cat)),
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final s in services.where((e) => e.category == cat))
                    SizedBox(
                      width: w,
                      child: _ServiceTile(
                        service: s,
                        selected: selected.contains(s.id),
                        onTap: () => onTap(s.id),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: context.fluid(32, 52)),
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
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedScale(
                    scale: _hover ? 1.06 : 1,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    child: PhotoImage(s.image, dark: true),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: sel
                            ? const [Color(0x99000000), Color(0xE6000000)]
                            : const [Color(0x00000000), Color(0xD0000000)],
                      ),
                      border: Border.all(
                        color: sel ? context.accent : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(context.isPhone ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: _Check(selected: sel),
                        ),
                        const Spacer(),
                        Text(
                          s.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: display(
                            context.isPhone ? 19 : context.fluid(20, 28),
                            color: Palette.paper,
                            height: 1.05,
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
      ),
    );
  }
}

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
      padding: EdgeInsets.all(context.fluid(22, 34)),
      decoration: BoxDecoration(
        color: Palette.ink,
        border: error != null
            ? Border.all(color: const Color(0xFFE5735F), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LA TUA SELEZIONE', style: label(10.5, color: Palette.ash)),
          const SizedBox(height: 16),
          if (ids.isEmpty)
            Text(
              'Ancora nulla.',
              style: display(30, color: Palette.paper, italic: true),
            )
          else ...[
            Text(
              package?.name ?? 'Su misura',
              style: display(
                context.fluid(30, 44),
                color: Palette.paper,
                italic: true,
              ),
            ),
            const SizedBox(height: 14),
            for (final id in ids)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Palette.lineDark)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.serviceById(id)?.name ?? '—',
                        style: body(14.5, color: Palette.paper),
                      ),
                    ),
                    InkResponse(
                      onTap: () => onRemove(id),
                      radius: 18,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Palette.ash,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(error!, style: body(14, color: const Color(0xFFF0A08F))),
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
          12,
          context.gutter,
          12 + bottom,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: label(13, color: Palette.ink, spacing: 0),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                packageName ??
                    (count == 1 ? 'servizio scelto' : 'servizi scelti'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: display(22, color: Palette.paper, italic: true),
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
    return Section(
      top: context.fluid(60, 120),
      bottom: context.fluid(90, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Tag('Richiesta inviata'),
          SizedBox(height: context.fluid(18, 30)),
          MaskRevealText(
            lines: ['Grazie,', '${quote.firstName}.'],
            size: context.fluid(64, 200),
          ),
          SizedBox(height: context.fluid(22, 34)),
          Text(
            'Ti richiamiamo al ${quote.phone}.',
            style: body(context.fluid(17, 22), color: Palette.stone),
          ),
          SizedBox(height: context.fluid(34, 54)),
          Wrap(
            spacing: 20,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PillButton(
                'Torna alla home',
                big: true,
                onTap: () => context.go('/'),
              ),
              HoverLink(
                'Nuova richiesta',
                style: body(15, weight: FontWeight.w600),
                onTap: onNew,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
