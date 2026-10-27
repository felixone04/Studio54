// Tasto indietro di telefono e tablet: si torna fino alla home e lì si resta.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/harness.dart';

String _where(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).state.uri.toString();

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await settle(tester, 800);
}

void main() {
  setUpAll(setUpTestEnv);

  late List<String> chiusure;
  setUp(() {
    chiusure = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemNavigator.pop') chiusure.add(call.method);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('ripercorre le pagine fino alla home e non chiude l\'app', (
    tester,
  ) async {
    final s = await loadState();
    final id = s.publishedWorks.first.id;
    await pumpApp(tester, s, size: const Size(400, 860));
    await goTo(tester, '/lavori');
    await goTo(tester, '/lavori/$id');
    await goTo(tester, '/biografia');

    await _back(tester);
    expect(_where(tester), '/lavori/$id');
    await _back(tester);
    expect(_where(tester), '/lavori');
    await _back(tester);
    expect(_where(tester), '/');
    await _back(tester);
    await _back(tester);
    expect(_where(tester), '/');
    expect(chiusure, isEmpty);
    await disposeApp(tester);
  });

  testWidgets('una pagina già vista non fa giri a vuoto', (tester) async {
    final s = await loadState();
    await pumpApp(tester, s, size: const Size(400, 860));
    await goTo(tester, '/lavori');
    await goTo(tester, '/biografia');
    await goTo(tester, '/lavori');

    await _back(tester);
    expect(_where(tester), '/');
    expect(chiusure, isEmpty);
    await disposeApp(tester);
  });

  testWidgets('aperta da un\'altra pagina, indietro porta alla home', (
    tester,
  ) async {
    final s = await loadState();
    await pumpApp(tester, s, location: '/preventivo');
    await _back(tester);
    expect(_where(tester), '/');
    expect(chiusure, isEmpty);
    await disposeApp(tester);
  });

  testWidgets('prima chiude finestre e menu, poi cambia pagina', (
    tester,
  ) async {
    final s = await loadState();
    await pumpApp(tester, s, size: const Size(400, 860));
    await goTo(tester, '/biografia');
    showDialog<void>(
      context: tester.element(find.byType(Scaffold).first),
      builder: (_) => const AlertDialog(content: Text('Finestra di prova')),
    );
    await settle(tester, 800);
    expect(find.text('Finestra di prova'), findsOneWidget);

    await _back(tester);
    expect(find.text('Finestra di prova'), findsNothing);
    expect(_where(tester), '/biografia');

    await _back(tester);
    expect(_where(tester), '/');
    expect(chiusure, isEmpty);
    await disposeApp(tester);
  });
}
