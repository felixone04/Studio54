// I dispositivi veri, con i loro margini di sistema (notch, lineetta, barre):
// ogni pagina deve stare nello schermo, anche con il testo ingrandito e con la
// tastiera aperta, e le foto a schermo intero devono riempirlo davvero.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:studio_fotografico/data/seed.dart';
import 'package:studio_fotografico/services/system_bars.dart';
import 'package:studio_fotografico/widgets/sections.dart';

import 'support/harness.dart';

class Device {
  const Device(this.name, this.size, this.pad);
  final String name;
  final Size size;
  final FakeViewPadding pad;
}

const iphone15 = Device(
  'iPhone 15',
  Size(393, 852),
  FakeViewPadding(top: 59, bottom: 34),
);

// Dynamic Island: 59-62 pt in alto; con l'iPhone girato sta di lato.
const iphone16Pro = Device(
  'iPhone 16 Pro',
  Size(402, 874),
  FakeViewPadding(top: 62, bottom: 34),
);
const iphone16Girato = Device(
  'iPhone 16 Pro girato',
  Size(874, 402),
  FakeViewPadding(left: 62, right: 62, bottom: 21),
);

const devices = <Device>[
  iphone16Pro,
  iphone16Girato,
  Device(
    'iPhone 16 Pro Max',
    Size(440, 956),
    FakeViewPadding(top: 62, bottom: 34),
  ),
  Device('iPhone SE', Size(375, 667), FakeViewPadding(top: 20)),
  iphone15,
  Device(
    'iPhone Pro Max',
    Size(430, 932),
    FakeViewPadding(top: 59, bottom: 34),
  ),
  Device(
    'iPhone girato',
    Size(852, 393),
    FakeViewPadding(left: 59, right: 59, bottom: 21),
  ),
  Device(
    'Android piccolo',
    Size(360, 640),
    FakeViewPadding(top: 24, bottom: 48),
  ),
  Device(
    'Android grande',
    Size(412, 915),
    FakeViewPadding(top: 32, bottom: 24),
  ),
  Device('Android girato', Size(915, 412), FakeViewPadding(top: 24, right: 48)),
  Device('iPad mini', Size(744, 1133), FakeViewPadding(top: 24, bottom: 20)),
  Device('iPad', Size(820, 1180), FakeViewPadding(top: 24, bottom: 20)),
  Device('iPad girato', Size(1180, 820), FakeViewPadding(top: 24, bottom: 20)),
  Device('iPad Pro', Size(1024, 1366), FakeViewPadding(top: 24, bottom: 20)),
  Device(
    'iPad Pro girato',
    Size(1366, 1024),
    FakeViewPadding(top: 24, bottom: 20),
  ),
  Device('iPad a schermo diviso', Size(320, 1024), FakeViewPadding(top: 24)),
  Device('iPad a metà schermo', Size(507, 820), FakeViewPadding(top: 24)),
  Device(
    'Tablet Android',
    Size(800, 1280),
    FakeViewPadding(top: 24, bottom: 48),
  ),
  Device(
    'Tablet Android girato',
    Size(1280, 800),
    FakeViewPadding(top: 24, bottom: 48),
  ),
];

const publicRoutes = [
  '/',
  '/lavori',
  '/lavori/w-anna-paolo',
  '/biografia',
  '/preventivo',
  '/area-clienti',
];
const adminRoutes = [
  '/admin/panoramica',
  '/admin/richieste',
  '/admin/calendario',
  '/admin/lavori',
  '/admin/preventivo',
  '/admin/biografia',
  '/admin/contatti',
  '/admin/carosello-sito',
  '/admin/carosello-app',
  '/admin/clienti',
  '/admin/impostazioni',
];

Future<void> open(
  WidgetTester tester,
  Device d,
  String route, {
  String? login,
}) async {
  final s = await loadState();
  if (login != null) {
    await s.signIn(
      login,
      login == Seed.demoAdminUser
          ? Seed.demoAdminPassword
          : Seed.demoClientPassword,
    );
  }
  tester.view.padding = d.pad;
  await pumpApp(tester, s, location: route, size: d.size);
}

/// Fa scorrere la pagina fino in fondo e torna su: niente deve rompersi.
Future<void> walk(WidgetTester tester) async {
  final scroll = find.byType(Scrollable);
  if (scroll.evaluate().isEmpty) return;
  await tester.drag(
    scroll.first,
    const Offset(0, -100000),
    warnIfMissed: false,
  );
  await settle(tester, 400);
}

void main() {
  setUpAll(setUpTestEnv);

  for (final d in devices) {
    group(d.name, () {
      for (final r in publicRoutes) {
        testWidgets('pagina $r', (tester) async {
          await open(tester, d, r);
          await walk(tester);
          await disposeApp(tester);
        });
      }
      testWidgets('menu a schermo intero', (tester) async {
        await open(tester, d, '/biografia');
        final menu = find.bySemanticsLabel('Menu');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await settle(tester, 800);
          expect(find.bySemanticsLabel('Chiudi'), findsWidgets);
        }
        await disposeApp(tester);
      });
      testWidgets('foto a schermo intero', (tester) async {
        await open(tester, d, '/lavori/w-anna-paolo');
        await settle(tester, 1200);
        await tester.tap(find.bySemanticsLabel('Foto 1').first);
        await settle(tester, 800);
        final x = tester.getRect(find.bySemanticsLabel('Chiudi').last);
        expect(x.top, greaterThanOrEqualTo(d.pad.top));
        expect(x.right, lessThanOrEqualTo(d.size.width - d.pad.right));
        await disposeApp(tester);
      });
      testWidgets('area clienti con le cartelle', (tester) async {
        await open(tester, d, '/area-clienti', login: 'anna.paolo');
        await walk(tester);
        await disposeApp(tester);
      });
      for (final r in adminRoutes) {
        testWidgets('gestionale $r', (tester) async {
          await open(tester, d, r, login: Seed.demoAdminUser);
          await disposeApp(tester);
        });
      }
    });
  }

  group('testo di sistema al massimo', () {
    for (final d in [
      devices[3],
      devices[6],
      devices[7],
      devices[11],
      devices[15],
    ]) {
      for (final r in [...publicRoutes, ...adminRoutes]) {
        testWidgets('${d.name} $r', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 3.1;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await open(
            tester,
            d,
            r,
            login: r.startsWith('/admin') ? Seed.demoAdminUser : null,
          );
          await walk(tester);
          await disposeApp(tester);
        });
      }
    }
  });

  group('tastiera aperta', () {
    for (final d in [
      devices[0],
      devices[1],
      devices[3],
      devices[8],
      devices[9],
    ]) {
      for (final r in ['/preventivo', '/area-clienti', '/admin/contatti']) {
        testWidgets('${d.name} $r', (tester) async {
          await open(
            tester,
            d,
            r,
            login: r.startsWith('/admin') ? Seed.demoAdminUser : null,
          );
          tester.view.viewInsets = FakeViewPadding(
            bottom: d.size.width > d.size.height ? 200 : 320,
          );
          await settle(tester, 400);
          await disposeApp(tester);
        });
      }
    }
  });

  group('Dynamic Island', () {
    // In verticale l'isola occupa la parte alta al centro, in orizzontale un
    // lato: comandi e logo devono restarne fuori in ogni pagina.
    for (final r in ['/', '/biografia', '/lavori', '/preventivo']) {
      testWidgets('verticale, $r: barra sotto l\'isola', (tester) async {
        await open(tester, iphone16Pro, r);
        await settle(tester, 400);
        expect(
          tester.getRect(find.bySemanticsLabel('Menu')).top,
          greaterThanOrEqualTo(62),
        );
        expect(
          tester.getRect(find.bySemanticsLabel('Home').first).top,
          greaterThanOrEqualTo(62),
        );
        await disposeApp(tester);
      });
      testWidgets('girato, $r: logo e menu fuori dall\'isola', (tester) async {
        await open(tester, iphone16Girato, r);
        await settle(tester, 400);
        expect(
          tester.getRect(find.bySemanticsLabel('Home').first).left,
          greaterThanOrEqualTo(62),
        );
        expect(
          tester.getRect(find.bySemanticsLabel('Menu')).right,
          lessThanOrEqualTo(874 - 62),
        );
        await disposeApp(tester);
      });
    }

    testWidgets('sul carosello la foto riempie anche intorno all\'isola', (
      tester,
    ) async {
      for (final d in [iphone16Pro, iphone16Girato]) {
        await open(tester, d, '/');
        await settle(tester, 400);
        final r = tester.getRect(find.byType(AppCarousel));
        expect(r.top, 0, reason: d.name);
        expect(r.left, 0, reason: d.name);
        expect(r.width, d.size.width, reason: d.name);
        expect(r.height, d.size.height, reason: d.name);
        await disposeApp(tester);
      }
    });

    testWidgets('il menu aperto dal carosello resta fuori dall\'isola', (
      tester,
    ) async {
      for (final d in [iphone16Pro, iphone16Girato]) {
        await open(tester, d, '/');
        await settle(tester, 400);
        await tester.tap(find.bySemanticsLabel('Menu'));
        await settle(tester, 800);
        final x = tester.getRect(find.bySemanticsLabel('Chiudi').last);
        expect(x.top, greaterThanOrEqualTo(d.pad.top), reason: d.name);
        expect(
          x.right,
          lessThanOrEqualTo(d.size.width - d.pad.right),
          reason: d.name,
        );
        await disposeApp(tester);
      }
    });
  });

  group('iPhone con il notch', () {
    testWidgets('il carosello riempie anche notch e lineetta, la barra sta '
        'sotto il notch', (tester) async {
      await open(tester, iphone15, '/');
      await settle(tester, 400);
      final r = tester.getRect(find.byType(AppCarousel));
      expect(r.top, 0);
      expect(r.left, 0);
      expect(r.height, iphone15.size.height);
      expect(
        tester.getRect(find.bySemanticsLabel('Menu')).top,
        greaterThan(59),
      );
      await disposeApp(tester);
    });

    testWidgets('fuori dalla foto la pagina sta fra le barre', (tester) async {
      await open(tester, iphone15, '/biografia');
      await settle(tester, 400);
      expect(
        tester.getRect(find.bySemanticsLabel('Menu')).top,
        greaterThan(59),
      );
      final body = tester.getRect(find.byType(Scaffold).first);
      expect(body.top, 59);
      expect(body.bottom, iphone15.size.height - 34);
      await disposeApp(tester);
    });

    testWidgets('scorrendo oltre il carosello la pagina non fa salti', (
      tester,
    ) async {
      await open(tester, iphone15, '/');
      await settle(tester, 400);
      final scroll = tester
          .widget<SingleChildScrollView>(
            find.byType(SingleChildScrollView).first,
          )
          .controller!;
      final card = find.byType(WorkCard).first;
      // La barra finisce a 59 + altezza; il bordo della foto ci arriva qui.
      const navH = 72 + 28 * (393 - 360) / (1600 - 360);
      final soglia = iphone15.size.height - navH - 59;

      scroll.jumpTo(soglia - 10);
      // Finita l'animazione con cui la scheda compare.
      await settle(tester, 2400);
      expect(SystemBars.hidden, isTrue);
      final prima = tester.getRect(card).top;

      scroll.jumpTo(soglia + 10);
      await settle(tester, 400);
      expect(SystemBars.hidden, isFalse);
      // Si è scorso di 20: la scheda sale di 20, senza scatti in più.
      expect(tester.getRect(card).top, closeTo(prima - 20, 1));

      scroll.jumpTo(soglia - 80);
      await settle(tester, 400);
      expect(SystemBars.hidden, isTrue);
      expect(tester.getRect(card).top, closeTo(prima + 70, 1));
      await disposeApp(tester);
    });

    testWidgets('la X della foto a schermo intero è sotto il notch', (
      tester,
    ) async {
      await open(tester, iphone15, '/lavori/w-anna-paolo');
      await settle(tester, 1200);
      await tester.tap(find.bySemanticsLabel('Foto 1'));
      await settle(tester, 800);
      expect(
        tester.getRect(find.bySemanticsLabel('Chiudi').last).top,
        greaterThanOrEqualTo(59),
      );
      await disposeApp(tester);
    });

    testWidgets('ora e batteria hanno sempre il loro stile', (tester) async {
      for (final r in ['/', '/biografia']) {
        await open(tester, iphone15, r);
        final layer = tester.binding.renderViews.first.debugLayer!;
        final style = layer.find<SystemUiOverlayStyle>(
          const Offset(196, 59 / 2),
        );
        expect(style?.statusBarBrightness, Brightness.light, reason: r);
        expect(style?.statusBarIconBrightness, Brightness.dark, reason: r);
        await disposeApp(tester);
      }
    });
  });

  group('indietro su iPhone', () {
    String where(WidgetTester tester) =>
        GoRouter.of(tester.element(find.byType(Scaffold).first)).state.uri
            .toString();

    testWidgets('strisciando dal bordo sinistro si torna indietro', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await open(tester, iphone15, '/');
      await goTo(tester, '/lavori');
      await goTo(tester, '/biografia');
      await tester.dragFrom(const Offset(6, 400), const Offset(200, 0));
      await settle(tester, 800);
      expect(where(tester), '/lavori');
      await tester.dragFrom(const Offset(6, 400), const Offset(200, 0));
      await settle(tester, 800);
      expect(where(tester), '/');
      await disposeApp(tester);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('su Android il gesto non c\'è: c\'è il tasto', (tester) async {
      await open(tester, iphone15, '/');
      await goTo(tester, '/biografia');
      await tester.dragFrom(const Offset(6, 400), const Offset(200, 0));
      await settle(tester, 800);
      expect(where(tester), '/biografia');
      await disposeApp(tester);
    });
  });
}
