import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_ui.dart';
import 'admin_calendar.dart';
import 'admin_catalog.dart';
import 'admin_clients.dart';
import 'admin_content.dart';
import 'admin_dashboard.dart';
import 'admin_quotes.dart';
import 'admin_settings.dart';
import 'admin_widgets.dart';
import 'admin_works.dart';

class _Section {
  const _Section(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

/// Voci del menu, raggruppate.
const _groups = <(String, List<_Section>)>[
  (
    'Attività',
    [
      _Section('panoramica', 'Panoramica', Icons.space_dashboard_outlined),
      _Section('richieste', 'Richieste', Icons.mark_email_unread_outlined),
      _Section('calendario', 'Calendario', Icons.calendar_month_outlined),
      _Section('clienti', 'Clienti', Icons.people_alt_outlined),
    ],
  ),
  (
    'Catalogo',
    [
      _Section('servizi', 'Servizi e prodotti', Icons.design_services_outlined),
      _Section('pacchetti', 'Pacchetti', Icons.card_giftcard_rounded),
      _Section('lavori', 'Lavori', Icons.auto_stories_outlined),
      _Section('galleria', 'Galleria', Icons.photo_library_outlined),
    ],
  ),
  (
    'Sito',
    [
      _Section('home', 'Pagina Home', Icons.web_outlined),
      _Section('biografia', 'Biografia', Icons.history_edu_outlined),
      _Section('contatti', 'Identità e contatti', Icons.badge_outlined),
    ],
  ),
  ('Sistema', [_Section('impostazioni', 'Impostazioni', Icons.tune_rounded)]),
];

final _sections = [for (final g in _groups) ...g.$2];

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.section});
  final String? section;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Theme(
      data: AppTheme.admin(Color(s.content.accent)),
      child: s.adminAuthenticated ? _Shell(section: section) : const _Login(),
    );
  }
}

// ======================================================================= LOGIN

class _Login extends StatefulWidget {
  const _Login();

  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _show = false;
  bool _remember = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    setState(() => _error = null);
    if (!s.hasAdminPassword) {
      if (_pw.text.length < 8) {
        setState(() => _error = 'La password deve avere almeno 8 caratteri.');
        return;
      }
      if (_pw.text != _pw2.text) {
        setState(() => _error = 'Le due password non coincidono.');
        return;
      }
      setState(() => _busy = true);
      await s.setAdminPassword(_pw.text, remember: _remember);
    } else {
      setState(() => _busy = true);
      final ok = await s.login(_pw.text, remember: _remember);
      if (!ok && mounted) {
        setState(() {
          _busy = false;
          _error = 'Password non corretta.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final create = !s.hasAdminPassword;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final photo = s.heroPhotos.isNotEmpty ? s.heroPhotos.first.url : '';

    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Tag(create ? 'Primo accesso' : 'Area riservata'),
            const SizedBox(height: 18),
            Text(
              create ? 'Scegli la\npassword.' : 'Bentornato.',
              style: display(wide ? 54 : 44, height: 1.0),
            ),
            const SizedBox(height: 12),
            Text(
              create
                  ? 'Servirà per entrare nella gestione del sito.'
                  : 'Inserisci la password per gestire il sito.',
              style: body(14.5, color: Palette.stone),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _pw,
              obscureText: !_show,
              autofocus: true,
              autofillHints: [
                create ? AutofillHints.newPassword : AutofillHints.password,
              ],
              onSubmitted: (_) => create ? null : _submit(),
              decoration: InputDecoration(
                labelText: create
                    ? 'Nuova password (min. 8 caratteri)'
                    : 'Password',
                suffixIcon: IconButton(
                  tooltip: _show ? 'Nascondi' : 'Mostra',
                  onPressed: () => setState(() => _show = !_show),
                  icon: Icon(
                    _show
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
              ),
            ),
            if (create) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _pw2,
                obscureText: !_show,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Ripeti la password',
                ),
              ),
            ],
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('Ricordami su questo dispositivo', style: body(14)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: body(14, color: const Color(0xFFB3261E))),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const StadiumBorder(),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Palette.paper,
                      ),
                    )
                  : Text(
                      create ? 'CREA E ENTRA' : 'ENTRA',
                      style: label(12, color: Palette.paper),
                    ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Torna al sito'),
              ),
            ),
          ],
        ),
      ),
    );

    final poster = Stack(
      fit: StackFit.expand,
      children: [
        PhotoImage(photo),
        Padding(
          padding: EdgeInsets.all(wide ? 32 : 18),
          child: const Viewfinder(
            color: Color(0xCCFFFAF0),
            length: 24,
            stroke: 1,
          ),
        ),
        // Il logo su un cartoncino chiaro, leggibile su qualsiasi foto.
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 40 : 24,
              vertical: wide ? 28 : 16,
            ),
            decoration: BoxDecoration(
              color: Palette.paper.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandLogo(width: wide ? 220 : 130),
                SizedBox(height: wide ? 18 : 10),
                Text('AREA RISERVATA', style: label(10.5)),
              ],
            ),
          ),
        ),
      ],
    );

    if (wide) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 6, child: poster),
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: form,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 220, child: poster),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 40),
              child: Center(child: form),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================== SHELL

class _Shell extends StatefulWidget {
  const _Shell({required this.section});
  final String? section;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _current => _sections.any((e) => e.id == widget.section)
      ? widget.section!
      : 'panoramica';

  Widget _page() {
    final page = switch (_current) {
      'richieste' => const AdminPageScroll(child: AdminQuotes()),
      'calendario' => const AdminPageScroll(child: AdminCalendar()),
      'clienti' => const AdminPageScroll(child: AdminClients()),
      'servizi' => const AdminPageScroll(child: AdminServices()),
      'pacchetti' => const AdminPageScroll(child: AdminPackages()),
      'lavori' => const AdminPageScroll(child: AdminWorks()),
      'galleria' => const AdminPageScroll(child: AdminGallery()),
      'home' => const AdminHomeEditor(),
      'biografia' => const AdminBioEditor(),
      'contatti' => const AdminIdentityEditor(),
      'impostazioni' => const AdminPageScroll(child: AdminSettingsPage()),
      _ => const AdminPageScroll(child: AdminDashboard()),
    };
    return KeyedSubtree(key: ValueKey(_current), child: page);
  }

  void _select(String id) {
    _scaffoldKey.currentState?.closeDrawer();
    if (id != _current) context.go('/admin/$id');
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final nav = _NavPanel(current: _current, onSelect: _select);

    if (wide) {
      return Scaffold(
        key: _scaffoldKey,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 264, child: nav),
            Expanded(child: _page()),
          ],
        ),
      );
    }
    final current = _sections.firstWhere((e) => e.id == _current);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Palette.linen,
        foregroundColor: Palette.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Text(current.label, style: display(24, italic: true)),
        actions: [
          IconButton(
            tooltip: 'Vedi il sito',
            onPressed: openSiteInNewTab,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        width: 290,
        backgroundColor: Palette.linen,
        shape: const RoundedRectangleBorder(),
        child: nav,
      ),
      body: _page(),
    );
  }
}

class _NavPanel extends StatelessWidget {
  const _NavPanel({required this.current, required this.onSelect});
  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final newQuotes = s.quotes
        .where((q) => q.status == QuoteStatus.nuova)
        .length;
    return Material(
      color: Palette.linen,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandLogo(width: 120),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var g = 0; g < _groups.length; g++) ...[
                    // Gruppi separati da una linea sottile, senza titoli.
                    if (g > 0)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        color: Palette.line,
                      ),
                    for (final sec in _groups[g].$2)
                      _NavItem(
                        section: sec,
                        selected: sec.id == current,
                        badge: sec.id == 'richieste' && newQuotes > 0
                            ? newQuotes
                            : null,
                        onTap: () => onSelect(sec.id),
                      ),
                  ],
                ],
              ),
            ),
            Container(height: 1, color: Palette.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Column(
                children: [
                  _NavAction(
                    icon: Icons.open_in_new_rounded,
                    text: 'Vedi il sito',
                    onTap: openSiteInNewTab,
                  ),
                  _NavAction(
                    icon: Icons.logout_rounded,
                    text: 'Esci',
                    onTap: () async {
                      await context.read<AppState>().logout();
                      if (context.mounted) context.go('/admin');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final _Section section;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final fg = sel || _hover ? Palette.ink : Palette.stone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: sel
                  ? Palette.ink.withValues(alpha: 0.07)
                  : (_hover ? Palette.ink.withValues(alpha: 0.04) : null),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: sel ? 18 : 0,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: context.brand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(widget.section.icon, size: 19, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.section.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(
                      14,
                      color: fg,
                      weight: sel ? FontWeight.w600 : FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ),
                if (widget.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.brand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.badge}',
                      style: body(
                        12,
                        color: Palette.ink,
                        weight: FontWeight.w700,
                        height: 1.3,
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

class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.icon,
    required this.text,
    required this.onTap,
  });
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Palette.stone),
            const SizedBox(width: 12),
            Text(text, style: body(14, color: Palette.stone, height: 1.2)),
          ],
        ),
      ),
    );
  }
}
