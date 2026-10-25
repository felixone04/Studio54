import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  setUpAll(setUpTestEnv);

  testWidgets('la home si apre con i dati di esempio', (tester) async {
    final s = await loadState();
    await pumpApp(tester, s);
    expect(find.bySemanticsLabel(RegExp('Studio 54')), findsWidgets);
    await disposeApp(tester);
  });
}
