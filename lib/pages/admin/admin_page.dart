import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'admin_calendar.dart';
import 'admin_catalog.dart';
import 'admin_content.dart';
import 'admin_dashboard.dart';
import 'admin_quotes.dart';
import 'admin_settings.dart';

class _Section {
  const _Section(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

const _sections = <_Section>[
  _Section('panoramica', 'Panoramica', Icons.dashboard_outlined),
  _Section('richieste', 'Richieste preventivo', Icons.request_quote_outlined),
  _Section('calendario', 'Calendario', Icons.calendar_month_outlined),
  _Section('servizi', 'Servizi e prodotti', Icons.design_services_outlined),
  _Section('pacchetti', 'Pacchetti', Icons.card_giftcard_rounded),
  _Section('galleria', 'Galleria', Icons.photo_library_outlined),
  _Section('home', 'Pagina Home', Icons.web_outlined),
  _Section('biografia', 'Biografia e team', Icons.history_edu_outlined),
  _Section('contatti', 'Identità e contatti', Icons.contact_phone_outlined),
  _Section('impostazioni', 'Impostazioni', Icons.settings_outlined),
];

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
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    if (!s.hasAdminPassword) {
      if (_pw.text.length < 8) {
        setState(() => _error = 'La password deve avere almeno 8 caratteri.');
      } else if (_pw.text != _pw2.text) {
        setState(() => _error = 'Le due password non coincidono.');
      } else {
        await s.setAdminPassword(_pw.text);
      }
    } else if (!s.login(_pw.text)) {
      setState(() => _error = 'Password non corretta.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final create = !s.hasAdminPassword;
    final t = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 34,
                      color: t.colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      create ? 'Crea la password' : 'Area riservata',
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      create
                          ? 'È la prima volta: scegli una password per proteggere la gestione del sito.'
                          : s.content.studioName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 26),
                    TextField(
                      controller: _pw,
                      obscureText: !_show,
                      autofocus: true,
                      onSubmitted: (_) => create ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: create
                            ? 'Nuova password (almeno 8 caratteri)'
                            : 'Password',
                        suffixIcon: IconButton(
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
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Ripeti la password',
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFB3382A)),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(create ? 'Crea e accedi' : 'Entra'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('← Torna al sito'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================== SHELL

class _Shell extends StatelessWidget {
  const _Shell({required this.section});
  final String? section;

  String get _current =>
      _sections.any((e) => e.id == section) ? section! : 'panoramica';

  Widget _page() {
    final page = switch (_current) {
      'richieste' => const AdminPageScroll(child: AdminQuotes()),
      'calendario' => const AdminPageScroll(child: AdminCalendar()),
      'servizi' => const AdminPageScroll(child: AdminServices()),
      'pacchetti' => const AdminPageScroll(child: AdminPackages()),
      'galleria' => const AdminPageScroll(child: AdminGallery()),
      'home' => const AdminHomeEditor(),
      'biografia' => const AdminBioEditor(),
      'contatti' => const AdminIdentityEditor(),
      'impostazioni' => const AdminPageScroll(child: AdminSettingsPage()),
      _ => const AdminPageScroll(child: AdminDashboard()),
    };
    return KeyedSubtree(key: ValueKey(_current), child: page);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final nav = _NavList(
      current: _current,
      onSelect: (id) {
        if (!wide) Navigator.of(context).maybePop();
        context.go('/admin/$id');
      },
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 270,
              child: Material(
                color: Colors.white,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFE5DFD5))),
                  ),
                  child: nav,
                ),
              ),
            ),
            Expanded(child: _page()),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(_sections.firstWhere((e) => e.id == _current).label),
      ),
      drawer: Drawer(backgroundColor: Colors.white, child: nav),
      body: _page(),
    );
  }
}

class _NavList extends StatelessWidget {
  const _NavList({required this.current, required this.onSelect});
  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final newQuotes = s.quotes
        .where((q) => q.status == QuoteStatus.nuova)
        .length;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.content.studioName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Area riservata',
                        style: TextStyle(color: Colors.black54, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final sec in _sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      selected: sec.id == current,
                      selectedTileColor: primary.withValues(alpha: 0.12),
                      selectedColor: primary,
                      leading: Icon(sec.icon, size: 21),
                      title: Text(
                        sec.label,
                        style: TextStyle(
                          fontWeight: sec.id == current
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 14.5,
                        ),
                      ),
                      trailing: sec.id == 'richieste' && newQuotes > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC25B2E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$newQuotes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => onSelect(sec.id),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.open_in_new_rounded, size: 20),
                  title: const Text('Vedi il sito'),
                  onTap: () => context.go('/'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout_rounded, size: 20),
                  title: const Text('Esci'),
                  onTap: () {
                    context.read<AppState>().logout();
                    context.go('/admin');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
