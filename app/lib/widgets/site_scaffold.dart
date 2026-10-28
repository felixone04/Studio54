import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'photo_ui.dart';

Future<void> openUrl(String url) async {
  final t = url.trim();
  var u = Uri.tryParse(t);
  if (u == null || t.isEmpty) return;
  // Link social inseriti senza "https://" (es. instagram.com/studio): senza
  // schema il browser li tratterebbe come percorsi interni al sito.
  if (!u.hasScheme) u = Uri.tryParse('https://$t');
  if (u == null) return;
  await launchUrl(u, webOnlyWindowName: '_blank');
}

String digitsOf(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

const _navItems = <(String, String)>[
  ('Home', '/'),
  ('Lavori', '/lavori'),
  ('Biografia', '/biografia'),
  ('Preventivo', '/preventivo'),
  ('Area clienti', '/area-clienti'),
];

/// Segna una parte della pagina con il suo colore di fondo: quando la barra
/// in alto ci passa sopra prende quel colore, così non si vede mai uno stacco.
class NavTint extends StatefulWidget {
  const NavTint({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  State<NavTint> createState() => _NavTintState();
}

class _NavTintState extends State<NavTint> {
  _NavTints? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.getInheritedWidgetOfExactType<_NavTints>();
    if (s != _scope) {
      _scope?.tints.remove(this);
      _scope = s?..tints.add(this);
    }
  }

  @override
  void dispose() {
    _scope?.tints.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NavTints extends InheritedWidget {
  const _NavTints({required this.tints, required super.child});
  final Set<_NavTintState> tints;

  @override
  bool updateShouldNotify(_NavTints old) => false;
}

/// Struttura comune delle pagine pubbliche: barra fissa in alto con il logo
/// a sinistra (senza uno sfondo suo: prende quello della pagina), contenuto
/// e footer.
class SiteScaffold extends StatefulWidget {
  const SiteScaffold({
    super.key,
    required this.location,
    required this.children,
    this.overlay,
    this.photoUnderNav,
    this.footer = true,
    this.bottomBar,
  });

  final String location;
  final List<Widget> children;

  /// Falso nelle pagine a passi (preventivo), che non hanno il footer.
  final bool footer;

  /// Comandi fissi in basso (es. Indietro e Avanti del preventivo).
  final Widget? bottomBar;

  /// Elemento fisso sopra al contenuto.
  final Widget? overlay;

  /// Altezza della foto d'apertura che parte dal bordo in alto, sotto la
  /// barra trasparente (home in orizzontale); null = nessuna.
  final double? photoUnderNav;

  @override
  State<SiteScaffold> createState() => _SiteScaffoldState();
}

class _SiteScaffoldState extends State<SiteScaffold> {
  final _scroll = ScrollController();
  final _tints = <_NavTintState>{};
  Color _under = Palette.paper;
  bool _overPhoto = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(SiteScaffold old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  /// Colore della parte di pagina appena sotto la barra.
  void _update() {
    if (!mounted) return;
    final navH = context.navH;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final photo = widget.photoUnderNav;
    final overPhoto = photo != null && offset < photo - navH;
    var under = Palette.paper;
    for (final t in _tints) {
      final box = t.context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= navH && top + box.size.height > navH) under = t.widget.color;
    }
    if (under != _under || overPhoto != _overPhoto) {
      setState(() {
        _under = under;
        _overPhoto = overPhoto;
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final navH = context.navH;
    final light = _overPhoto;
    return Scaffold(
      backgroundColor: Palette.paper,
      bottomNavigationBar: widget.bottomBar,
      body: _NavTints(
        tints: _tints,
        child: Stack(
          children: [
            NotificationListener<ScrollMetricsNotification>(
              onNotification: (_) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _update());
                return false;
              },
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.photoUnderNav == null) SizedBox(height: navH),
                    ...widget.children,
                    if (widget.footer) SiteFooter(content: state.content),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // Come un vetro: bianco appena trasparente e sfocato, così si
              // intravede la pagina che scorre sotto ma logo e menu si leggono
              // sempre. Sopra la foto d'apertura è del tutto trasparente, con
              // una velatura leggera.
              child: ClipRect(
                child: BackdropFilter(
                  enabled: !light,
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    height: navH,
                    padding: EdgeInsets.symmetric(horizontal: context.gutter),
                    decoration: BoxDecoration(
                      color: light
                          ? Colors.transparent
                          : _under.withValues(alpha: 0.72),
                      gradient: light
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x61000000), Color(0x00000000)],
                            )
                          : null,
                    ),
                    child: _NavBar(location: widget.location, light: light),
                  ),
                ),
              ),
            ),
            if (widget.overlay != null) widget.overlay!,
          ],
        ),
      ),
    );
  }
}

/// Il logo in alto a sinistra, che riporta alla home.
class _HomeLogo extends StatelessWidget {
  const _HomeLogo({required this.onTap, this.light = false});
  final VoidCallback onTap;
  final bool light;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Home',
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: BrandLogo(height: context.navH * 0.7, light: light),
      ),
    ),
  );
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.location, this.light = false});
  final String location;

  /// Chiara sopra la foto d'apertura.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final fg = light ? Palette.paper : Palette.ink;
    // Nell'app: il logo a sinistra e i tre trattini del menu a destra.
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _HomeLogo(onTap: () => context.go('/'), light: light),
          ),
        ),
        const SizedBox(width: 16),
        _MenuButton(color: fg, onTap: () => _openMenu(context, location)),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap, this.color = Palette.ink});
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(width: 24, height: 1.6, color: color);
    return Semantics(
      button: true,
      label: 'Menu',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              line(),
              const SizedBox(height: 6),
              line(),
              const SizedBox(height: 6),
              line(),
            ],
          ),
        ),
      ),
    );
  }
}

void _openMenu(BuildContext context, String location) {
  final c = context.read<AppState>().content;
  showGeneralDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierLabel: 'Chiudi menu',
    transitionDuration: const Duration(milliseconds: 450),
    transitionBuilder: (_, a, _, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutQuart);
      return ClipPath(clipper: _RevealClipper(curved.value), child: child);
    },
    pageBuilder: (ctx, _, _) => _FullMenu(location: location, content: c),
  );
}

class _RevealClipper extends CustomClipper<Path> {
  _RevealClipper(this.t);
  final double t;
  @override
  Path getClip(Size size) =>
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height * t));
  @override
  bool shouldReclip(_RevealClipper old) => old.t != t;
}

class _FullMenu extends StatelessWidget {
  const _FullMenu({required this.location, required this.content});
  final String location;
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final c = content.contacts;
    return Material(
      color: Palette.paper,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: context.navH,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _HomeLogo(
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/');
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Chiudi',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Palette.ink,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              for (var i = 0; i < _navItems.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(_navItems[i].$2);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3, right: 12),
                          child: Text(
                            '0${i + 1}',
                            style: label(7.5, color: context.accentInk),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _navItems[i].$1.toUpperCase(),
                              // Il 30% più piccole della prima versione (30).
                              style: display(
                                21,
                                spacing: 0.12,
                                color: location == _navItems[i].$2
                                    ? Palette.ink
                                    : Palette.ash,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              if (c.phone.isNotEmpty)
                GestureDetector(
                  onTap: () => openUrl('tel:${digitsOf(c.phone)}'),
                  child: Text(c.phone, style: body(14.5, color: Palette.stone)),
                ),
              if (c.email.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => openUrl('mailto:${c.email}'),
                  child: Text(c.email, style: body(14.5, color: Palette.stone)),
                ),
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- footer

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final c = content.contacts;
    final cols = context.isPhone ? 1 : (context.isTablet ? 2 : 4);

    Widget link(String text, String? url) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: url == null
          ? Text(text, style: body(15))
          : HoverLink(text, style: body(15), onTap: () => openUrl(url)),
    );

    Widget col(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: label(10.5, color: Palette.stone)),
        const SizedBox(height: 16),
        ...children,
      ],
    );

    final columns = <Widget>[
      col('Scrivici', [
        if (c.email.isNotEmpty) link(c.email, 'mailto:${c.email}'),
        if (c.phone.isNotEmpty) link(c.phone, 'tel:${digitsOf(c.phone)}'),
        if (c.whatsapp.isNotEmpty)
          link(
            'WhatsApp',
            'https://wa.me/${digitsOf(c.whatsapp).replaceAll('+', '')}',
          ),
      ]),
      col('Studio', [
        if (c.address.isNotEmpty)
          link(
            c.address,
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(c.address)}',
          ),
        if (c.hours.isNotEmpty)
          Text(c.hours, style: body(14, color: Palette.stone)),
      ]),
      col('Social', [
        if (c.instagram.isNotEmpty) link('Instagram', c.instagram),
        if (c.facebook.isNotEmpty) link('Facebook', c.facebook),
      ]),
      col('Esplora', [
        for (final (t, p) in _navItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HoverLink(t, style: body(15), onTap: () => context.go(p)),
          ),
      ]),
    ];

    // Una linea sottile lo separa dalla pagina, come quella in fondo.
    return Container(
      color: Palette.paper,
      padding: EdgeInsets.fromLTRB(context.gutter, 0, context.gutter, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 1, color: Palette.line),
          SizedBox(height: context.fluid(56, 100)),
          LayoutBuilder(
            builder: (context, box) {
              const gap = 32.0;
              final wdt = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: 40,
                children: [
                  for (final w in columns) SizedBox(width: wdt, child: w),
                ],
              );
            },
          ),
          SizedBox(height: context.fluid(56, 90)),
          // Firma: il logo al centro.
          Center(child: BrandLogo(width: context.fluid(150, 200))),
          SizedBox(height: context.fluid(36, 56)),
          Container(height: 1, color: Palette.line),
          const SizedBox(height: 18),
          Text(
            '© ${DateTime.now().year} ${content.studioName}'
            '${c.vat.isEmpty ? '' : '  ·  ${c.vat}'}',
            style: body(12.5, color: Palette.stone),
          ),
        ],
      ),
    );
  }
}
