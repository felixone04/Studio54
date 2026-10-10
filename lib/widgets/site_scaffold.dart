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
  final u = Uri.tryParse(url.trim());
  if (u == null) return;
  await launchUrl(u, webOnlyWindowName: '_blank');
}

String digitsOf(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

const _navItems = <(String, String)>[
  ('Home', '/'),
  ('Biografia', '/biografia'),
  ('Preventivo', '/preventivo'),
];

/// Struttura comune delle pagine pubbliche.
class SiteScaffold extends StatefulWidget {
  const SiteScaffold({
    super.key,
    required this.location,
    required this.children,
    this.darkHero = false,
    this.logoHero = false,
    this.overlay,
  });

  final String location;
  final List<Widget> children;

  /// La prima sezione è un'immagine scura a tutto schermo: la barra resta
  /// trasparente con testo chiaro finché la si scorre.
  final bool darkHero;

  /// La prima sezione mostra già il logo grande (home).
  final bool logoHero;

  /// Elemento fisso sopra al contenuto (es. barra del preventivo).
  final Widget? overlay;

  @override
  State<SiteScaffold> createState() => _SiteScaffoldState();
}

class _SiteScaffoldState extends State<SiteScaffold> {
  final _scroll = ScrollController();
  bool _onDark = true;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _onDark = widget.darkHero;
    _scroll.addListener(_update);
  }

  void _update() {
    final o = _scroll.offset;
    final onDark = widget.darkHero && o < context.screenH - _navH(context);
    final scrolled = o > 10;
    if (onDark != _onDark || scrolled != _scrolled) {
      setState(() {
        _onDark = onDark;
        _scrolled = scrolled;
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static double _navH(BuildContext c) => c.fluid(66, 88);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final navH = _navH(context);
    final dark = _onDark;
    final fg = dark ? Palette.paper : Palette.ink;
    return Scaffold(
      backgroundColor: Palette.paper,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.darkHero) SizedBox(height: navH),
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
                gradient: dark && !_scrolled
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x80000000), Color(0x00000000)],
                      )
                    : null,
                color: dark
                    ? (_scrolled ? Palette.ink.withValues(alpha: 0.92) : null)
                    : Palette.paper.withValues(alpha: 0.97),
                border: Border(
                  bottom: BorderSide(
                    color: !dark && _scrolled
                        ? Palette.lineLight
                        : Colors.transparent,
                  ),
                ),
              ),
              child: _NavBar(
                name: state.content.studioName,
                location: widget.location,
                fg: fg,
                onDark: dark,
                // Sopra la foto d'apertura c'è già il logo grande: qui solo l'icona.
                showName: !(widget.logoHero && !_scrolled),
              ),
            ),
          ),
          if (widget.overlay != null) widget.overlay!,
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.name,
    required this.location,
    required this.fg,
    required this.onDark,
    this.showName = true,
  });
  final String name;
  final String location;
  final Color fg;
  final bool onDark;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final compact = context.w < 900;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/'),
                child: BrandWordmark(
                  name: name,
                  height: context.fluid(20, 24),
                  onDark: onDark,
                  showName: showName,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (!compact) ...[
          for (var i = 0; i < _navItems.length; i++) ...[
            if (i > 0) const SizedBox(width: 34),
            HoverLink(
              _navItems[i].$1.toUpperCase(),
              active: location == _navItems[i].$2,
              style: label(11.5, color: fg),
              onTap: () => context.go(_navItems[i].$2),
            ),
          ],
        ] else
          _MenuButton(color: fg, onTap: () => _openMenu(context, location)),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.color, required this.onTap});
  final Color color;
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
              Text('MENU', style: label(11.5, color: color)),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 26, height: 1.6, color: color),
                  const SizedBox(height: 6),
                  Container(width: 16, height: 1.6, color: color),
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
    final accent = Theme.of(context).colorScheme.primary;
    final c = content.contacts;
    return Material(
      color: Palette.ink,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: context.fluid(66, 88),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: BrandWordmark(
                          name: content.studioName,
                          height: context.fluid(20, 24),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Chiudi',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Palette.paper,
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 16),
                          child: Text(
                            '0${i + 1}',
                            style: label(10.5, color: accent),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _navItems[i].$1.toUpperCase(),
                              style: display(
                                30,
                                spacing: 0.12,
                                color: location == _navItems[i].$2
                                    ? Palette.paper
                                    : Palette.paper.withValues(alpha: 0.5),
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
                  child: Text(c.phone, style: body(14.5, color: Palette.ash)),
                ),
              if (c.email.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => openUrl('mailto:${c.email}'),
                  child: Text(c.email, style: body(14.5, color: Palette.ash)),
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
    final accent = Theme.of(context).colorScheme.primary;
    final cols = context.isPhone ? 1 : (context.isTablet ? 2 : 4);

    Widget link(String text, String? url) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: url == null
          ? Text(text, style: body(15, color: Palette.paper))
          : HoverLink(
              text,
              style: body(15, color: Palette.paper),
              onTap: () => openUrl(url),
            ),
    );

    Widget col(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: label(10.5, color: Palette.ash)),
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
          Text(c.hours, style: body(14, color: Palette.ash)),
      ]),
      col('Social', [
        if (c.instagram.isNotEmpty) link('Instagram', c.instagram),
        if (c.facebook.isNotEmpty) link('Facebook', c.facebook),
      ]),
      col('Esplora', [
        for (final (t, p) in _navItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HoverLink(
              t,
              style: body(15, color: Palette.paper),
              onTap: () => context.go(p),
            ),
          ),
      ]),
    ];

    return Container(
      color: Palette.ink,
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
          Center(child: BrandLogo(width: context.fluid(220, 300))),
          SizedBox(height: context.fluid(36, 56)),
          Container(height: 1, color: Palette.lineDark),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            spacing: 20,
            children: [
              Text(
                '© ${DateTime.now().year} ${content.studioName}'
                '${c.vat.isEmpty ? '' : '  ·  ${c.vat}'}',
                style: body(12.5, color: Palette.ash),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  HoverLink(
                    'Area riservata',
                    style: body(12.5, color: Palette.ash),
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
