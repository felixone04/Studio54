import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'pages/admin/admin_page.dart';
import 'pages/bio_page.dart';
import 'pages/client_area_page.dart';
import 'pages/home_page.dart';
import 'pages/quote_page.dart';
import 'pages/works_page.dart';
import 'services/back_handlers.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

/// Permette il trascinamento con il mouse nei carousel (di default solo touch).
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  /// Nessuna barra di scorrimento visibile: si scorre lo stesso.
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// Sul telefono il sito sta tra la barra di stato (ora, batteria) e quella
/// dei gesti, su fondo crema: le pagine misurano solo lo spazio libero.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final top = mq.padding.top, bottom = mq.padding.bottom;
    final bars = AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Palette.paper,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: child,
    );
    // Sempre la stessa struttura, anche quando le barre sono nascoste
    // (spazio zero): se cambiasse, Flutter ricostruirebbe l'app da capo e
    // ripartirebbe il logo d'apertura.
    return ColoredBox(
      color: Palette.paper,
      child: Padding(
        padding: EdgeInsets.only(top: top, bottom: bottom),
        child: MediaQuery(
          data: mq.copyWith(
            size: Size(mq.size.width, mq.size.height - top - bottom),
            padding: mq.padding.copyWith(top: 0, bottom: 0),
            viewPadding: mq.viewPadding.copyWith(top: 0, bottom: 0),
          ),
          child: bars,
        ),
      ),
    );
  }
}

CustomTransitionPage<void> _fade(GoRouterState s, Widget child) =>
    CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, a, _, c) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: c,
      ),
    );

/// Il tasto indietro (telefono, tablet) ripercorre le pagine viste fino alla
/// home e lì si ferma: l'app non si chiude mai da sola. Finestre, menu e foto
/// a schermo intero si chiudono come sempre.
class _BackToHome extends RootBackButtonDispatcher {
  _BackToHome(this.router) {
    router.routerDelegate.addListener(_track);
    _track();
  }

  final GoRouter router;
  final List<String> _history = [];

  String get _here => router.routerDelegate.currentConfiguration.uri.toString();

  void _track() {
    final here = _here;
    if (here == '/') {
      _history
        ..clear()
        ..add(here);
      return;
    }
    // Una pagina già vista: si riparte da lì, senza giri a vuoto.
    final i = _history.indexOf(here);
    if (i >= 0) {
      _history.removeRange(i + 1, _history.length);
    } else {
      _history.add(here);
    }
  }

  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) async {
    Route<dynamic>? top;
    router.routerDelegate.navigatorKey.currentState?.popUntil((r) {
      top = r;
      return true;
    });
    final t = top;
    if (t != null && (t.settings is! Page || t.willHandlePopInternally)) {
      return super.invokeCallback(defaultValue);
    }
    // Una pagina che gestisce da sé il tasto (es. le cartelle dell'area
    // clienti).
    if (BackHandlers.handle()) return true;
    if (_history.length > 1) {
      _history.removeLast();
      router.go(_history.last);
    } else if (_here != '/') {
      router.go('/');
    }
    return true;
  }

  void dispose() => router.routerDelegate.removeListener(_track);
}

class StudioApp extends StatefulWidget {
  const StudioApp({super.key});

  @override
  State<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends State<StudioApp> {
  final _content = GlobalKey();
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', pageBuilder: (c, s) => _fade(s, const HomePage())),
      GoRoute(
        path: '/preventivo',
        pageBuilder: (c, s) => _fade(s, const QuotePage()),
      ),
      GoRoute(
        path: '/area-clienti',
        pageBuilder: (c, s) => _fade(s, const ClientAreaPage()),
      ),
      GoRoute(
        path: '/lavori',
        pageBuilder: (c, s) => _fade(s, const WorksPage()),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (c, s) => _fade(
              s,
              WorkPage(
                key: ValueKey(s.pathParameters['id']),
                id: s.pathParameters['id']!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/biografia',
        pageBuilder: (c, s) => _fade(s, const BioPage()),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (c, s) => NoTransitionPage(
          key: s.pageKey,
          child: const AdminPage(section: null),
        ),
        routes: [
          GoRoute(
            path: ':section',
            pageBuilder: (c, s) => NoTransitionPage(
              key: s.pageKey,
              child: AdminPage(section: s.pathParameters['section']),
            ),
          ),
        ],
      ),
    ],
    errorPageBuilder: (c, s) => _fade(s, const HomePage()),
  );
  late final _back = _BackToHome(_router);

  @override
  void dispose() {
    _back.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp.router(
      onGenerateTitle: (_) =>
          '${state.content.studioName} · ${state.content.tagline}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.site(Color(state.content.accent)),
      builder: (context, child) => ScreenScale(
        child: _SystemBars(
          // La chiave conserva l'app (pagine, scorrimento, logo d'apertura già
          // visto) anche quando cambia la cornice intorno: barre del telefono
          // che compaiono o spariscono, schermo che si gira.
          child: KeyedSubtree(
            key: _content,
            child: introInApp ? AppIntro(child: child!) : child!,
          ),
        ),
      ),
      scrollBehavior: _AppScrollBehavior(),
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerDelegate: _router.routerDelegate,
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _router.routeInformationProvider,
      backButtonDispatcher: _back,
    );
  }
}
