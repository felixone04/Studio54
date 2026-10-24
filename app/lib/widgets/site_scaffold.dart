import 'package:flutter/foundation.dart' show kIsWeb;
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
];

/// Struttura comune delle pagine pubbliche: barra chiara con il logo in alto
/// a sinistra, contenuto e footer.
class SiteScaffold extends StatefulWidget {
  const SiteScaffold({
    super.key,
    required this.location,
    required this.children,
    this.overlay,
  });

  final String location;
  final List<Widget> children;

  /// Elemento fisso sopra al contenuto.
  final Widget? overlay;

  @override
  State<SiteScaffold> createState() => _SiteScaffoldState();
}

class _SiteScaffoldState extends State<SiteScaffold> {
  final _scroll = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_update);
  }

  void _update() {
    final scrolled = _scroll.offset > 10;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
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
    return Scaffold(
      backgroundColor: Palette.paper,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: navH),
                ...widget.children,
                SiteFooter(content: state.content),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // Niente sfocatura dello sfondo: è costosa da disegnare sul web e
            // rende lo scorrimento meno fluido. Basta un fondo pieno.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: navH,
              padding: EdgeInsets.symmetric(horizontal: context.gutter),
              decoration: BoxDecoration(
                color: Palette.paper.withValues(alpha: 0.97),
                border: Border(
                  bottom: BorderSide(
                    color: _scrolled ? Palette.line : Colors.transparent,
                  ),
                ),
              ),
              child: _NavBar(location: widget.location),
            ),
          ),
          if (widget.overlay != null) widget.overlay!,
        ],
      ),
    );
  }
}

/// Il logo in alto a sinistra, che riporta alla home.
class _HomeLogo extends StatelessWidget {
  const _HomeLogo({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Home',
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: BrandLogo(height: context.navH * 0.7),
      ),
    ),
  );
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final compact = context.w < 900;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _HomeLogo(onTap: () => context.go('/')),
          ),
        ),
        const SizedBox(width: 16),
        if (!compact) ...[
          for (var i = 0; i < _navItems.length; i++) ...[
            if (i > 0) const SizedBox(width: 34),
            HoverLink(
              _navItems[i].$1.toUpperCase(),
              active: location == _navItems[i].$2,
              style: label(11.5, color: Palette.ink),
              onTap: () => context.go(_navItems[i].$2),
            ),
          ],
        ] else
          _MenuButton(onTap: () => _openMenu(context, location)),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Menu',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('MENU', style: label(11.5)),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 26, height: 1.6, color: Palette.ink),
                  const SizedBox(height: 6),
                  Container(width: 16, height: 1.6, color: Palette.ink),
                ],
              ),
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
              // Nell'app il titolare entra nel gestionale direttamente da qui.
              if (!kIsWeb) ...[
                const SizedBox(height: 18),
                HoverLink(
                  'AREA RISERVATA',
                  style: label(10.5, color: Palette.ink),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/admin');
                  },
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

    return Container(
      color: Palette.linen,
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        context.fluid(64, 110),
        context.gutter,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            spacing: 20,
            children: [
              Text(
                '© ${DateTime.now().year} ${content.studioName}'
                '${c.vat.isEmpty ? '' : '  ·  ${c.vat}'}',
                style: body(12.5, color: Palette.stone),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: context.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  HoverLink(
                    'Area riservata',
                    style: body(12.5, color: Palette.stone),
                    onTap: () => context.go('/admin'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
