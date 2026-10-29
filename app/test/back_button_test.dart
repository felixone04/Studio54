// Tasto indietro di telefono e tablet: si torna fino alla home e lì si resta.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:studio_fotografico/data/seed.dart';

import 'flows_test.dart' show fill, tapText;
import 'support/harness.dart';

String _where(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).state.uri
        .toString();

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

  testWidgets('nel preventivo torna al passo precedente', (tester) async {
    final s = await loadState();
    final f = s.quoteForm.copy()
      ..showDate = false
      ..showRequests = false;
    await s.setQuoteForm(f);
    await pumpApp(tester, s, size: const Size(400, 860));
    await goTo(tester, '/preventivo');
    await fill(tester, 'Luogo *', 'Roma');
    await tapText(tester, 'AVANTI');
    expect(find.text('PASSO 2 DI 4'), findsOneWidget);

    await _back(tester);
    expect(find.text('PASSO 1 DI 4'), findsOneWidget);
    expect(_where(tester), '/preventivo');
    await _back(tester);
    expect(_where(tester), '/');
    expect(chiusure, isEmpty);
    await disposeApp(tester);
  });

  testWidgets('contatti del gestionale: gli stessi controlli del computer', (
    tester,
  ) async {
    final s = await loadState();
    await s.loginAdmin(
      Seed.demoAdminUser,
      Seed.demoAdminPassword,
      remember: false,
    );
    await pumpApp(tester, s, size: const Size(1280, 900));
    await goTo(tester, '/admin/contatti');
    final prima = s.content.contacts.email;
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'non-va');
    await settle(tester, 300);
    await tester.tap(find.text('Salva'));
    await settle(tester, 600);
    expect(find.text('Email non valida.'), findsOneWidget);
    expect(s.content.contacts.email, prima);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'a@b.it');
    await tester.enterText(
      find.widgetWithText(TextField, 'Instagram (link)'),
      'www.instagram.com/studio',
    );
    await settle(tester, 300);
    await tester.tap(find.text('Salva'));
    await settle(tester, 600);
    expect(s.content.contacts.email, 'a@b.it');
    expect(s.content.contacts.instagram, 'https://www.instagram.com/studio');
    await disposeApp(tester);
  });

  testWidgets('nel gestionale chiede prima di perdere le modifiche', (
    tester,
  ) async {
    final s = await loadState();
    await s.loginAdmin(
      Seed.demoAdminUser,
      Seed.demoAdminPassword,
      remember: false,
    );
    await pumpApp(tester, s, size: const Size(400, 860));
    await goTo(tester, '/admin/biografia');
    await tester.enterText(
      find.widgetWithText(TextField, 'Titolo della pagina'),
      'Nuovo titolo',
    );
    await settle(tester, 400);

    await _back(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Annulla'),
      ),
    );
    await settle(tester, 800);
    expect(_where(tester), '/admin/biografia');
    expect(find.text('Nuovo titolo'), findsOneWidget);

    await _back(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Esci senza salvare'),
      ),
    );
    await settle(tester, 800);
    expect(_where(tester), '/');
    expect(s.content.bioTitle, isNot('Nuovo titolo'));
    expect(chiusure, isEmpty);
    await disposeApp(tester);
  });
}
