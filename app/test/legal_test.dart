// Privacy e cookie: la pagina si raggiunge dal footer (lo chiedono anche gli
// store), mostra i testi del gestionale con i dati dello studio e si
// modifica dal gestionale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/data/seed.dart';
import 'package:studio_fotografico/models/models.dart';
import 'package:studio_fotografico/pages/legal_page.dart';

import 'support/harness.dart';

void main() {
  setUpAll(setUpTestEnv);

  const phone = Size(390, 844);

  testWidgets('dal footer si apre la pagina, con i dati dello studio', (
    tester,
  ) async {
    final s = await loadState();
    await pumpApp(tester, s, location: '/biografia', size: phone);
    final link = find.text('Privacy e cookie');
    await tester.scrollUntilVisible(
      link,
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(link);
    await settle(tester);
    expect(find.byType(LegalPage), findsOneWidget);
    expect(find.text('PRIVACY E COOKIE'), findsOneWidget);
    for (final t in ['INFORMATIVA PRIVACY', 'COOKIE', 'NOTE LEGALI']) {
      expect(find.text(t), findsOneWidget);
    }
    // I segnaposto diventano i contatti veri; nessuna graffa resta.
    expect(
      find.textContaining(
        'Titolare del trattamento è Studio 54, '
        '${s.content.contacts.address} (${s.content.contacts.vat})',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('{'), findsNothing);
    // Titoli e voci di elenco.
    expect(find.text('PER QUANTO TEMPO'), findsOneWidget);
    expect(
      find.textContaining('Dati di fatturazione: 10 anni'),
      findsOneWidget,
    );
    await disposeApp(tester);
  });

  test('i dati salvati prima della privacy prendono i testi d\'esempio', () {
    final old = Seed.content().toJson()
      ..remove('privacyText')
      ..remove('cookieText')
      ..remove('legalText');
    final c = SiteContent.fromJson(old, Seed.content());
    expect(c.privacyText, Seed.privacyText);
    expect(c.cookieText, Seed.cookieText);
    expect(c.legalText, Seed.legalText);
  });

  test('un testo vuoto non compare nella pagina', () {
    final c = Seed.content()..legalText = '  ';
    expect(legalParts(c).map((p) => p.$1), ['privacy', 'cookie']);
  });

  testWidgets('si modifica dal gestionale, per sito e app', (tester) async {
    final s = await loadState();
    await s.loginAdmin(
      Seed.demoAdminUser,
      Seed.demoAdminPassword,
      remember: false,
    );
    await pumpApp(tester, s, size: const Size(1280, 900));
    await goTo(tester, '/admin/privacy');
    expect(find.text('Informativa privacy'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Testo').last,
      'Studio di {studio}.',
    );
    await settle(tester, 300);
    await tester.tap(find.text('Salva'));
    await settle(tester, 600);
    expect(s.content.legalText, 'Studio di {studio}.');

    await goTo(tester, '/privacy');
    expect(find.text('Studio di Studio 54.'), findsOneWidget);
    await disposeApp(tester);
  });
}
