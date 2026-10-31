import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/system_bars.dart';
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
  // I link web si aprono fuori dall'app (browser, Instagram, WhatsApp...).
  final web = u.isScheme('http') || u.isScheme('https');
  try {
    await launchUrl(
      u,
      mode: web ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    // Nessuna app per aprirlo (es. telefonare da un tablet): non si fa nulla.
  }
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

  /// Da 0 (barra trasparente sopra la foto d'apertura) a 1 (vetro bianco):
  /// segue lo scorrimento, così il passaggio è fluido e senza scatti.
  double _glass = 1;

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
    // A tutto schermo la barra sta sotto il notch: finisce più in basso.
    final navH = context.navH + MediaQuery.paddingOf(context).top;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final photo = widget.photoUnderNav;
    final overPhoto = photo != null && offset < photo - navH;
    // Mentre il bordo della foto sale verso la barra il vetro si riempie piano
    // piano, ed è pieno quando la foto è passata tutta sotto.
    final glass = photo == null
        ? 1.0
        : ((1 - (photo - offset - navH) / (navH * 1.5)).clamp(0.0, 1.0) * 100)
                  .roundToDouble() /
              100;
    var under = Palette.paper;
    for (final t in _tints) {
      final box = t.context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= navH && top + box.size.height > navH) under = t.widget.color;
    }
    // Sul carosello d'apertura le barre del telefono si nascondono.
    SystemBars.hide(this, overPhoto);
    if (under != _under || glass != _glass) {
      setState(() {
        _under = under;
        _glass = glass;
      });
    }
  }

  @override
  void dispose() {
    SystemBars.hide(this, false);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final navH = context.navH;
    final inset = MediaQuery.paddingOf(context);
    final g = _glass;
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                  enabled: g > 0,
                  // mirror: ai bordi la sfocatura non pesca il grigio da fuori.
                  filter: ImageFilter.blur(
                    sigmaX: 14 * g,
                    sigmaY: 14 * g,
                    tileMode: TileMode.mirror,
                  ),
                  child: Container(
                    height: navH + inset.top,
                    padding: EdgeInsets.fromLTRB(
                      context.gutter + inset.left,
                      inset.top,
                      context.gutter + inset.right,
                      0,
                    ),
                    decoration: BoxDecoration(
                      color: _under.withValues(alpha: 0.72 * g),
                      gradient: g < 1
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                // Sparisce insieme al testo chiaro.
                                Color.fromRGBO(0, 0, 0, 0.38 * (1 - _inkOf(g))),
                                const Color(0x00000000),
                              ],
                            )
                          : null,
                    ),
                    child: _NavBar(location: widget.location, glass: g),
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

/// Testo e logo della barra cambiano prima e più in fretta del vetro: così
/// restano grigi su grigio solo per un breve tratto (come sul sito).
double _inkOf(double glass) => ((glass - 0.15) / 0.3).clamp(0.0, 1.0);

/// Il logo in alto a sinistra, che riporta alla home.
class _HomeLogo extends StatelessWidget {
  const _HomeLogo({required this.onTap, this.glass = 1});
  final VoidCallback onTap;

  /// Il vetro della barra: 0 logo chiaro (sopra la foto), poi logo scuro; in
  /// mezzo si sfumano.
  final double glass;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Home',
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: _inkOf(glass) >= 1
            ? BrandLogo(height: context.navH * 0.7)
            : Stack(
                children: [
                  Opacity(
                    opacity: _inkOf(glass),
                    child: BrandLogo(height: context.navH * 0.7),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 1 - _inkOf(glass),
                      child: BrandLogo(height: context.navH * 0.7, light: true),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.location, this.glass = 1});
  final String location;

  /// 0: chiara sopra la foto d'apertura, 1: scura sul vetro bianco.
  final double glass;

  /// Voci in riga, come sul sito: solo su un tablet in orizzontale, dove
  /// stanno comode. Sui telefoni (anche girati) e sul tablet in verticale i
  /// tre trattini del menu.
  static bool inline(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 &&
        size.width > size.height &&
        size.width >= 900;
  }

  @override
  Widget build(BuildContext context) {
    final fg = Color.lerp(Palette.paper, Palette.ink, _inkOf(glass))!;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _HomeLogo(onTap: () => context.go('/'), glass: glass),
          ),
        ),
        const SizedBox(width: 16),
        if (inline(context))
          for (var i = 0; i < _navItems.length; i++) ...[
            if (i > 0) SizedBox(width: context.fluid(22, 34)),
            HoverLink(
              _navItems[i].$1.toUpperCase(),
              active: location == _navItems[i].$2,
              style: label(11.5, color: fg),
              onTap: () => context.go(_navItems[i].$2),
            ),
          ]
        else
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
          // Area da toccare larga, ma i trattini finiscono sul margine.
          padding: const EdgeInsets.fromLTRB(12, 14, 0, 14),
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

/// La X del menu: tratti sottili come i tre trattini, e nello stesso punto.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget line(double turn) => Transform.rotate(
      angle: turn * math.pi,
      child: Container(width: 26, height: 1.6, color: Palette.ink),
    );
    return Semantics(
      button: true,
      label: 'Chiudi',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
          child: SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [line(0.25), line(-0.25)],
            ),
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
    final wide = context.w > context.h;
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
                    _CloseButton(onTap: () => Navigator.pop(context)),
                  ],
                ),
              ),
              // Le voci al centro, i contatti in fondo; sul telefono girato i
              // contatti a destra. Se lo spazio non basta (testo grande) si
              // scorre invece di uscire dallo schermo.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final voci = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                    padding: const EdgeInsets.only(
                                      top: 3,
                                      right: 12,
                                    ),
                                    child: Text(
                                      '0${i + 1}',
                                      style: label(
                                        10,
                                        color: context.accentInk,
                                      ),
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
                                              : Palette.stone,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                    final contatti = Column(
                      crossAxisAlignment: wide
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.phone.isNotEmpty)
                          GestureDetector(
                            onTap: () => openUrl('tel:${digitsOf(c.phone)}'),
                            child: Text(
                              c.phone,
                              style: body(14.5, color: Palette.stone),
                            ),
                          ),
                        if (c.email.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => openUrl('mailto:${c.email}'),
                            child: Text(
                              c.email,
                              style: body(14.5, color: Palette.stone),
                            ),
                          ),
                        ],
                      ],
                    );
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(child: voci),
                                    const SizedBox(width: 24),
                                    contatti,
                                  ],
                                )
                              : IntrinsicHeight(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Spacer(),
                                      voci,
                                      const Spacer(),
                                      const SizedBox(height: 16),
                                      contatti,
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- footer

/// Un link social, come sul sito: solo indirizzi web veri (http/https),
/// con `www.` completato in `https://www.`.
String? profileUrl(String raw) {
  var u = raw.trim();
  if (u.toLowerCase().startsWith('www.')) u = 'https://$u';
  return RegExp(r'^https?://\S+$', caseSensitive: false).hasMatch(u) ? u : null;
}

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final c = content.contacts;
    // Telefono: due colonne compatte (metà altezza rispetto a una sola).
    final cols = context.isTablet ? 2 : 4;
    final gap = context.isPhone ? 20.0 : 32.0;

    // Sul telefono le voci stanno più vicine.
    final under = context.isPhone ? 0.0 : 8.0;
    final size = context.isPhone ? 14.0 : 15.0;
    Widget link(String text, String? url) => Padding(
      padding: EdgeInsets.only(bottom: under),
      child: url == null
          ? Text(text, style: body(size))
          : HoverLink(text, style: body(size), onTap: () => openUrl(url)),
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
      col('Scriveteci', [
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
        if (profileUrl(c.instagram) case final u?) link('Instagram', u),
        if (profileUrl(c.facebook) case final u?) link('Facebook', u),
      ]),
      col('Esplora', [
        for (final (t, p) in _navItems)
          Padding(
            padding: EdgeInsets.only(bottom: under),
            child: HoverLink(t, style: body(size), onTap: () => context.go(p)),
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
          SizedBox(height: context.spaceSection),
          LayoutBuilder(
            builder: (context, box) {
              final wdt = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: context.isPhone ? 30 : 40,
                children: [
                  for (final w in columns) SizedBox(width: wdt, child: w),
                ],
              );
            },
          ),
          SizedBox(height: context.spaceSection),
          // Firma: il logo al centro.
          Center(child: BrandLogo(width: context.fluid(150, 200))),
          SizedBox(height: context.spaceBlock),
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
