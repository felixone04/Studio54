import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'pages/admin/admin_page.dart';
import 'pages/bio_page.dart';
import 'pages/home_page.dart';
import 'pages/quote_page.dart';
import 'pages/works_page.dart';
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
    if (top == 0 && bottom == 0) return bars;
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

class StudioApp extends StatefulWidget {
  const StudioApp({super.key});

  @override
  State<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends State<StudioApp> {
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', pageBuilder: (c, s) => _fade(s, const HomePage())),
      GoRoute(
        path: '/preventivo',
        pageBuilder: (c, s) => _fade(
          s,
          QuotePage(
            key: ValueKey(s.uri.toString()),
            preService: s.uri.queryParameters['s'],
            prePackage: s.uri.queryParameters['p'],
          ),
        ),
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
          child: introInApp ? AppIntro(child: child!) : child!,
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
      routerConfig: _router,
    );
  }
}
