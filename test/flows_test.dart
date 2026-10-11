// Percorsi completi: preventivo dal lato cliente, stato delle richieste
// nell'area riservata e ripristino da backup.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/data/seed.dart';
import 'package:studio_fotografico/models/models.dart';

import 'support/harness.dart';

/// Porta [f] al centro dello schermo (lontano da barra e menu fissi).
Future<void> show(WidgetTester tester, Finder f) async {
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
  await settle(tester, 800);
}

Future<void> tapShown(WidgetTester tester, Finder f) async {
  await show(tester, f);
  await tester.tap(f);
  await settle(tester, 800);
}

Future<void> fill(WidgetTester tester, String label, String text) async {
  final f = find.widgetWithText(TextFormField, label);
  await show(tester, f);
  await tester.enterText(f, text);
  await tester.pump();
}

QuoteRequest _quote(String id, String name) => QuoteRequest(
  id: id,
  firstName: name,
  lastName: 'Rossi',
  phone: '333 1234567',
  email: '$id@example.com',
  eventType: 'Matrimonio',
  serviceIds: ['svc-wedding'],
);

void main() {
  setUpAll(setUpTestEnv);

  group('preventivo', () {
    testWidgets('pacchetto: si sceglie e si toglie con un secondo tocco', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/preventivo');
      expect(find.text('LA TUA SELEZIONE'), findsOneWidget);

      final card = find.text('RACCONTO');
      await tapShown(tester, card);
      expect(find.text('PACCHETTO RACCONTO'), findsOneWidget);

      await tapShown(tester, card);
      expect(find.text('PACCHETTO RACCONTO'), findsNothing);
      expect(find.text('LA TUA SELEZIONE'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('togliere un servizio del pacchetto lo rende su misura', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/preventivo?p=pkg-essential');
      expect(find.text('PACCHETTO ESSENZIALE'), findsOneWidget);

      await tapShown(
        tester,
        find.bySemanticsLabel('Rimuovi Galleria online privata'),
      );
      expect(find.text('PACCHETTO ESSENZIALE'), findsNothing);
      expect(find.text('SU MISURA · 1 VOCI'), findsOneWidget);
      expect(find.text('Reportage di matrimonio'), findsWidgets);
      await disposeApp(tester);
    });

    testWidgets('un pacchetto nascosto non viene preselezionato', (
      tester,
    ) async {
      final s = await loadState();
      s.packageById('pkg-essential')!.active = false;
      await pumpApp(tester, s, location: '/preventivo?p=pkg-essential');
      expect(find.text('PACCHETTO ESSENZIALE'), findsNothing);
      expect(find.text('LA TUA SELEZIONE'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('invio: errori se mancano dati, poi la richiesta è salvata', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/preventivo?p=pkg-essential');

      final send = find.text('INVIA LA RICHIESTA');
      await tapShown(tester, send);
      for (final e in [
        'Inserisci il nome',
        'Inserisci il cognome',
        'Inserisci un numero valido',
        'Inserisci un indirizzo email valido',
        'Scegli il tipo di evento',
        'Serve il consenso per inviare la richiesta.',
      ]) {
        expect(find.text(e), findsOneWidget, reason: e);
      }
      expect(s.quotes, isEmpty);

      await fill(tester, 'Nome', ' Mario ');
      await fill(tester, 'Cognome', 'Rossi');
      await fill(tester, 'Telefono', '+39 333 123 4567');
      await fill(tester, 'Email', 'mario@example.com');
      await fill(tester, 'Note (luogo, numero di invitati…)', 'Villa al mare');

      await tapShown(tester, find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.text('Matrimonio').last);
      await settle(tester, 800);

      await tapShown(tester, find.byType(Checkbox));
      await tapShown(tester, send);

      expect(s.quotes, hasLength(1));
      final q = s.quotes.single;
      expect(q.firstName, 'Mario');
      expect(q.lastName, 'Rossi');
      expect(q.eventType, 'Matrimonio');
      expect(q.message, 'Villa al mare');
      expect(q.packageId, 'pkg-essential');
      expect(q.serviceIds, ['svc-wedding', 'svc-gallery']);
      expect(q.status, QuoteStatus.nuova);
      final repo = s.repo as MemoryRepository;
      expect(repo.raw['quotes'], contains('mario@example.com'));
      expect(find.text('Grazie, Mario'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('senza tipi di evento il modulo resta inviabile', (
      tester,
    ) async {
      final s = await loadState();
      s.content.eventTypes = [];
      await pumpApp(tester, s, location: '/preventivo?s=svc-portrait');

      await fill(tester, 'Nome', 'Anna');
      await fill(tester, 'Cognome', 'Bianchi');
      await fill(tester, 'Telefono', '06 1234567');
      await fill(tester, 'Email', 'anna@example.com');
      await tapShown(tester, find.byType(Checkbox));
      await tapShown(tester, find.text('INVIA LA RICHIESTA'));

      expect(s.quotes, hasLength(1));
      expect(s.quotes.single.serviceIds, ['svc-portrait']);
      expect(s.quotes.single.packageId, isNull);
      await disposeApp(tester);
    });
  });

  group('area riservata', () {
    testWidgets('cambiare stato aggiorna la richiesta giusta', (tester) async {
      final s = await loadState({
        'quotes': [
          _quote('q-a', 'Aldo').toJson(),
          _quote('q-b', 'Bice').toJson(),
        ],
      });
      await s.setAdminPassword('password-di-prova', remember: false);
      await pumpApp(tester, s, location: '/admin/richieste');

      await tester.tap(find.text('Nuova (2)'));
      await settle(tester, 600);

      await tester.tap(find.byType(DropdownButtonFormField<QuoteStatus>).first);
      await settle(tester, 600);
      await tester.tap(find.text('Contattata').last);
      await settle(tester, 800);

      expect(s.quoteById('q-a')!.status, QuoteStatus.contattata);
      expect(s.quoteById('q-b')!.status, QuoteStatus.nuova);
      expect(
        (s.repo as MemoryRepository).raw['quotes'],
        contains('contattata'),
      );

      // Con il filtro "Nuova" resta solo Bice, e il suo menu dice "Nuova".
      expect(find.text('Aldo Rossi'), findsNothing);
      expect(find.text('Bice Rossi'), findsOneWidget);
      final menu = tester.widget<DropdownButton<QuoteStatus>>(
        find.byType(DropdownButton<QuoteStatus>),
      );
      expect(menu.value, QuoteStatus.nuova);
      await disposeApp(tester);
    });
  });

  group('backup', () {
    test('un backup non valido non tocca i dati attuali', () async {
      final s = await loadState();
      final repo = s.repo as MemoryRepository;
      final before = Map.of(repo.raw);
      final services = s.services.length;

      for (final raw in [
        'non è json',
        '{"content": {}, "services": [1, 2]}',
        '{"content": {}, "quotes": "x"}',
        '{"content": {"studioName": 3}}',
      ]) {
        await expectLater(
          s.importBackup(raw),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('copia di sicurezza'),
            ),
          ),
          reason: raw,
        );
      }
      expect(repo.raw, before);
      expect(s.services, hasLength(services));
    });

    test('un backup valido sostituisce i dati', () async {
      final s = await loadState();
      final other = await loadState({
        'services': [ServiceItem(id: 'solo', name: 'Unico').toJson()],
        'content': (Seed.content()..studioName = 'Altro studio').toJson(),
      });
      await s.importBackup(other.exportBackup());
      expect(s.services.single.id, 'solo');
      expect(s.content.studioName, 'Altro studio');
    });
  });
}
