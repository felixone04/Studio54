// Barre del telefono: nascoste sul carosello d'apertura e sulle foto a
// schermo intero, visibili (bianche) nel resto dell'app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/services/system_bars.dart';

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
}
