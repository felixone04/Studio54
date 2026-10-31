import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/back_handlers.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/photo_ui.dart';
import '../../widgets/site_scaffold.dart';
import '../client_area_page.dart';
import 'admin_calendar.dart';
import 'admin_catalog.dart';
import 'admin_clients.dart';
import 'admin_content.dart';
import 'admin_dashboard.dart';
import 'admin_quote_form.dart';
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

/// Voci del menu, raggruppate per dove si vedono le modifiche (come nel
/// gestionale da computer).
const _groups = <(String, List<_Section>)>[
  (
    'Attività',
    [
      _Section('panoramica', 'Panoramica', Icons.space_dashboard_outlined),
      _Section('richieste', 'Richieste', Icons.mark_email_unread_outlined),
      _Section('calendario', 'Calendario', Icons.calendar_month_outlined),
    ],
  ),
  (
    'Sito e app',
    [
      _Section('lavori', 'Lavori', Icons.auto_stories_outlined),
      _Section('preventivo', 'Preventivo', Icons.edit_note_rounded),
      _Section('biografia', 'Biografia', Icons.history_edu_outlined),
      _Section('contatti', 'Contatti', Icons.badge_outlined),
      _Section(
        'carosello-sito',
        'Carosello orizzontale',
        Icons.photo_library_outlined,
      ),
      _Section(
        'carosello-app',
        'Carosello verticale',
        Icons.stay_current_portrait_rounded,
      ),
    ],
  ),
  (
    'Solo app',
    [_Section('clienti', 'Area clienti', Icons.people_alt_outlined)],
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
    // Senza accesso: si entra con le credenziali del titolare, come
    // dall'Area clienti.
    if (!s.adminAuthenticated) {
      return const SiteScaffold(
        location: '/area-clienti',
        children: [SignInView(adminOnly: true)],
      );
    }
    return Theme(
      data: AppTheme.admin(Color(s.content.accent)),
      child: _Shell(section: section),
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
  final _pageKeys = <String, GlobalKey>{};

  String get _current => _sections.any((e) => e.id == widget.section)
      ? widget.section!
      : 'panoramica';

  Widget _page() {
    final page = switch (_current) {
      'richieste' => const AdminPageScroll(child: AdminQuotes()),
      'calendario' => const AdminPageScroll(child: AdminCalendar()),
      'clienti' => const AdminPageScroll(child: AdminClients()),
      'lavori' => const AdminPageScroll(child: AdminWorks()),
      'preventivo' => const AdminQuoteForm(),
      'carosello-sito' => const AdminPageScroll(
        child: AdminCarousel(vertical: false),
      ),
      'carosello-app' => const AdminPageScroll(
        child: AdminCarousel(vertical: true),
      ),
      'biografia' => const AdminBioEditor(),
      'contatti' => const AdminIdentityEditor(),
      'impostazioni' => const AdminPageScroll(child: AdminSettingsPage()),
      _ => const AdminPageScroll(child: AdminDashboard()),
    };
    // Una chiave globale: girando il dispositivo il layout cambia, ma la pagina
    // e le sue modifiche non salvate restano.
    return KeyedSubtree(
      key: _pageKeys.putIfAbsent(_current, GlobalKey.new),
      child: page,
    );
  }

  Future<void> _select(String id) async {
    _scaffoldKey.currentState?.closeDrawer();
    if (id == _current || !await LeaveGuards.canLeave()) return;
    if (mounted) context.go('/admin/$id');
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
                    // Il titolo del gruppo dice dove si vedono le modifiche.
                    Padding(
                      padding: EdgeInsets.fromLTRB(12, g == 0 ? 2 : 16, 12, 6),
                      child: Text(
                        _groups[g].$1.toUpperCase(),
                        style: label(9.5, color: Palette.ash),
                      ),
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
                      if (!await LeaveGuards.canLeave() || !context.mounted) {
                        return;
                      }
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
