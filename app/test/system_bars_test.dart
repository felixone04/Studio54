// Barre del telefono: nascoste sul carosello d'apertura e sulle foto a
// schermo intero, visibili (bianche) nel resto dell'app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/services/system_bars.dart';
import 'package:studio_fotografico/widgets/common.dart';

import 'support/harness.dart';

void main() {
  setUpAll(setUpTestEnv);

  late List<String> modes;
  setUp(() {
    modes = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
            modes.add('${call.arguments}');
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('nascoste sul carosello, di nuovo visibili scorrendo e nelle '
      'altre pagine, nascoste sulle foto a schermo intero', (tester) async {
    final s = await loadState();
    await pumpApp(tester, s, size: const Size(390, 844));
    expect(SystemBars.hidden, isTrue);
    expect(modes.last, 'SystemUiMode.immersiveSticky');

    // Scorrendo oltre il carosello le barre tornano.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -1200),
    );
    await settle(tester, 800);
    expect(SystemBars.hidden, isFalse);
    expect(modes.last, 'SystemUiMode.edgeToEdge');

    // Le foto di un lavoro: visibili sulla pagina, nascoste a schermo intero.
    await goTo(tester, '/lavori/w-anna-paolo');
    expect(SystemBars.hidden, isFalse);
    await tester.tap(find.bySemanticsLabel('Foto 1'));
    await settle(tester, 800);
    expect(SystemBars.hidden, isTrue);
    await tester.tap(find.bySemanticsLabel('Chiudi').last);
    await settle(tester, 800);
    expect(SystemBars.hidden, isFalse);
    expect(modes.last, 'SystemUiMode.edgeToEdge');
    await disposeApp(tester);
  });

  testWidgets('quando le barre compaiono o spariscono l\'app non riparte', (
    tester,
  ) async {
    introInApp = true;
    appStartedAt = DateTime.now();
    addTearDown(() => introInApp = false);
    final s = await loadState();
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    await pumpApp(tester, s, size: const Size(390, 844));
    await settle(tester, 3200); // il logo d'apertura è sparito
    final intro = tester.state(find.byType(AppIntro));
    final nav = tester.state(find.byType(Navigator).first);

    // Barre nascoste (nessuno spazio riservato), poi di nuovo visibili.
    tester.view.padding = FakeViewPadding.zero;
    await settle(tester, 400);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    await settle(tester, 400);

    expect(tester.state(find.byType(AppIntro)), same(intro));
    expect(tester.state(find.byType(Navigator).first), same(nav));
    // Il logo d'apertura non è ricomparso.
    expect(find.bySemanticsLabel('Studio 54').evaluate().length, lessThan(3));
    await disposeApp(tester);
  });
}
