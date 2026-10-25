// Percorsi completi: preventivo dal lato cliente, stato delle richieste
// nell'area riservata e ripristino da backup.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:studio_fotografico/data/seed.dart';
import 'package:studio_fotografico/models/models.dart';
import 'package:studio_fotografico/pages/quote_page.dart';

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
    // Una data valida qualsiasi: fra due mesi.
    final inTwoMonths = DateFormat('dd/MM/yyyy')
        .format(DateTime.now().add(const Duration(days: 60)));

    /// Compila tutti i campi obbligatori tranne i servizi.
    Future<void> fillAll(WidgetTester tester, {bool type = true}) async {
      if (type) {
        await tapShown(tester, find.byType(DropdownButtonFormField<String>));
        await tester.tap(find.text('Matrimonio').last);
        await settle(tester, 800);
      }
      await fill(tester, 'Data dell\'evento *', inTwoMonths);
      await fill(tester, 'Luogo *', 'Masseria in Puglia');
      await fill(tester, 'Nome *', ' Mario ');
      await fill(tester, 'Cognome *', 'Rossi');
      await fill(tester, 'Telefono *', '+39 333 123 4567');
      await fill(tester, 'Email *', 'mario@example.com');
      await tapShown(tester, find.byType(Checkbox));
    }

    testWidgets('invio: errori se mancano dati, poi la richiesta è salvata', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/preventivo');

      final send = find.text('INVIA LA RICHIESTA');
      await tapShown(tester, send);
      for (final e in [
        'Scegli il tipo di evento',
        'Inserisci la data dell\'evento',
        'Indica la città o la location dell\'evento',
        'Scegli almeno una voce',
        'Inserisci il nome',
        'Inserisci il cognome',
        'Inserisci il numero di telefono',
        'Inserisci l\'indirizzo email',
        'Serve il consenso per inviare la richiesta.',
      ]) {
        expect(find.text(e), findsOneWidget, reason: e);
      }
      expect(s.quotes, isEmpty);

      await fillAll(tester);
      await fill(tester, 'Note (facoltative)', 'Circa 120 invitati');
      await tapShown(tester, find.text('Reportage di matrimonio'));
      await tapShown(tester, find.text('Album fine art'));
      await tapShown(tester, send);

      expect(s.quotes, hasLength(1));
      final q = s.quotes.single;
      expect(q.firstName, 'Mario');
      expect(q.lastName, 'Rossi');
      expect(q.eventType, 'Matrimonio');
      expect(q.eventDate, DateFormat('dd/MM/yyyy').parse(inTwoMonths));
      expect(q.location, 'Masseria in Puglia');
      expect(q.message, 'Circa 120 invitati');
      expect(q.serviceIds, ['svc-wedding', 'svc-album']);
      expect(q.packageId, isNull);
      expect(q.status, QuoteStatus.nuova);
      final repo = s.repo as MemoryRepository;
      expect(repo.raw['quotes'], contains('mario@example.com'));
      expect(find.text('Grazie, Mario'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('dal link di un pacchetto: servizi già scelti', (tester) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/preventivo?p=pkg-essential');
      await fillAll(tester);
      await tapShown(tester, find.text('INVIA LA RICHIESTA'));

      final q = s.quotes.single;
      expect(q.packageId, 'pkg-essential');
      expect(q.serviceIds, ['svc-wedding', 'svc-gallery']);
      await disposeApp(tester);
    });

    testWidgets('togliere un servizio del pacchetto lo rende su misura', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/preventivo?p=pkg-essential');
      await tapShown(tester, find.text('Galleria online privata'));
      await fillAll(tester);
      await tapShown(tester, find.text('INVIA LA RICHIESTA'));

      final q = s.quotes.single;
      expect(q.packageId, isNull);
      expect(q.serviceIds, ['svc-wedding']);
      await disposeApp(tester);
    });

    testWidgets('un pacchetto nascosto non viene preselezionato', (
      tester,
    ) async {
      final s = await loadState();
      s.packageById('pkg-essential')!.active = false;
      await pumpApp(tester, s, location: '/preventivo?p=pkg-essential');
      await fillAll(tester);
      await tapShown(tester, find.text('INVIA LA RICHIESTA'));
      expect(find.text('Scegli almeno una voce'), findsOneWidget);
      expect(s.quotes, isEmpty);
      await disposeApp(tester);
    });

    testWidgets('senza tipi di evento il modulo resta inviabile', (
      tester,
    ) async {
      final s = await loadState();
      s.content.eventTypes = [];
      await pumpApp(tester, s, location: '/preventivo?s=svc-portrait');
      await fillAll(tester, type: false);
      await tapShown(tester, find.text('INVIA LA RICHIESTA'));

      expect(s.quotes, hasLength(1));
      expect(s.quotes.single.serviceIds, ['svc-portrait']);
      expect(s.quotes.single.packageId, isNull);
      await disposeApp(tester);
    });

    testWidgets('"Altro" chiede di specificare l\'evento', (tester) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/preventivo?s=svc-portrait');
      await tapShown(tester, find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.text('Altro').last);
      await settle(tester, 800);
      await fillAll(tester, type: false);
      await tapShown(tester, find.text('INVIA LA RICHIESTA'));
      expect(find.text('Scrivi di che evento si tratta'), findsOneWidget);
      expect(s.quotes, isEmpty);

      await fill(tester, 'Di che evento si tratta? *', 'Anniversario');
      await tapShown(tester, find.text('INVIA LA RICHIESTA'));
      expect(s.quotes.single.eventType, 'Altro: Anniversario');
      await disposeApp(tester);
    });

    testWidgets('i campi accettano solo i caratteri giusti', (tester) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/preventivo');
      String text(String label) => tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, label))
          .controller!
          .text;

      await fill(tester, 'Telefono *', 'tel. +39 333-12+34');
      expect(text('Telefono *'), '+39 3331234');
      await fill(tester, 'Nome *', 'Mario99 D\'Amico-Rossi!');
      expect(text('Nome *'), 'Mario D\'Amico-Rossi');
      await fill(tester, 'Email *', ' mario @ example.com ');
      expect(text('Email *'), 'mario@example.com');
      await fill(tester, 'Data dell\'evento *', '1506203099');
      expect(text('Data dell\'evento *'), '15/06/2030');
      await disposeApp(tester);
    });
  });

  group('regole del preventivo', () {
    final today = DateTime(2026, 10, 20);
    test('data', () {
      String? d(String v) => QuoteRules.date(v, today: today);
      expect(d(''), 'Inserisci la data dell\'evento');
      expect(d('15/06'), 'Scrivi la data come gg/mm/aaaa');
      expect(d('31/02/2027'), 'Questa data non esiste');
      expect(d('19/10/2026'), 'La data è già passata');
      expect(d('20/10/2026'), isNull);
      expect(d('29/02/2028'), isNull);
      expect(d('21/10/2031'), 'Scegli una data entro 5 anni');
      expect(QuoteRules.parseDate('05/07/2027'), DateTime(2027, 7, 5));
    });

    test('telefono, email, nome e luogo', () {
      expect(QuoteRules.phone('333 123 4567'), isNull);
      expect(QuoteRules.phone('+39 06 1234567'), isNull);
      expect(QuoteRules.phone('1234567'), isNotNull);
      expect(QuoteRules.phone('1234567890123456'), isNotNull);
      expect(QuoteRules.email('a.b+c@studio-54.it'), isNull);
      for (final e in ['a@b', 'a@b.c', '@x.it', 'a@@x.it', 'a@x.it.']) {
        expect(QuoteRules.email(e), isNotNull, reason: e);
      }
      expect(QuoteRules.name('A', 'nome'), contains('almeno 2'));
      expect(QuoteRules.name('Al', 'nome'), isNull);
      expect(QuoteRules.place(' '), isNotNull);
      expect(QuoteRules.place('Bari'), isNull);
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
