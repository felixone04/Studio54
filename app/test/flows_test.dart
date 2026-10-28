// Percorsi completi dell'app: preventivo a passi, modulo personalizzato dal
// gestionale, home, lavori (filtri e foto a schermo intero) e copia di
// sicurezza.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/models/models.dart';
import 'package:studio_fotografico/widgets/lightbox.dart';
import 'package:studio_fotografico/widgets/sections.dart';

import 'support/harness.dart';

const phone = Size(390, 844);

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  // Al centro dello schermo, lontano dalla barra in alto e da quella in basso.
  await Scrollable.ensureVisible(tester.element(f.first), alignment: 0.5);
  await tester.pump();
  await tester.tap(f.first);
  await settle(tester, 800);
}

Future<void> fill(WidgetTester tester, String label, String text) async {
  final f = find.widgetWithText(TextField, label);
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

Future<void> pickDate(WidgetTester tester) async {
  await tester.tap(
    find
        .ancestor(
          of: find.text('Data dell\'evento *'),
          matching: find.byType(InkWell),
        )
        .first,
  );
  await settle(tester, 800);
  await tester.tap(find.text('OK'));
  await settle(tester, 800);
}

void main() {
  setUpAll(setUpTestEnv);

  group('preventivo a passi', () {
    testWidgets('errori, avanti e indietro, riepilogo e invio', (tester) async {
      final s = await loadState();
      final before = s.quotes.length;
      await pumpApp(tester, s, location: '/preventivo', size: phone);

      // Passo 1: il matrimonio è già scelto (unico tipo acceso).
      expect(find.text('PASSO 1 DI 5'), findsOneWidget);
      expect(find.text('IL VOSTRO EVENTO'), findsOneWidget);
      await tapText(tester, 'AVANTI');
      expect(find.text('Scegliete la data dell\'evento'), findsOneWidget);
      expect(find.text('Indicate la città o la location'), findsOneWidget);
      expect(find.text('Scegliete il tipo di evento'), findsNothing);
      await pickDate(tester);
      await fill(tester, 'Luogo *', 'Masseria in Puglia');
      await tapText(tester, 'AVANTI');

      // Passo 2: le richieste (facoltative).
      expect(find.text('PASSO 2 DI 5'), findsOneWidget);
      await tapText(tester, 'Video del matrimonio');
      await tapText(tester, 'Album fine art');
      await tapText(tester, 'AVANTI');

      // Passo 3: contatti, con i controlli.
      await tapText(tester, 'AVANTI');
      expect(find.text('Inserite il nome'), findsOneWidget);
      expect(find.text('Inserite il numero di telefono'), findsOneWidget);
      await fill(tester, 'Nome *', 'Mario');
      await fill(tester, 'Cognome *', 'Rossi');
      await fill(tester, 'Telefono *', '12');
      await fill(tester, 'Email *', 'mario@');
      await tapText(tester, 'AVANTI');
      expect(
        find.text('Numero non valido: servono da 8 a 15 cifre'),
        findsOneWidget,
      );
      expect(find.text('Email non valida (es. nome@email.it)'), findsOneWidget);
      await fill(tester, 'Telefono *', '+39 333 123 4567');
      await fill(tester, 'Email *', 'mario@example.com');
      await tapText(tester, 'AVANTI');

      // Indietro e di nuovo avanti: i dati restano.
      await tapText(tester, 'INDIETRO');
      expect(find.text('Mario'), findsOneWidget);
      await tapText(tester, 'AVANTI');

      // Passo 4: il messaggio.
      expect(find.text('PASSO 4 DI 5'), findsOneWidget);
      await fill(tester, 'Messaggio (facoltativo)', 'Cerimonia al tramonto.');
      await tapText(tester, 'AVANTI');

      // Riepilogo: senza consenso non parte.
      expect(find.text('RIEPILOGO'), findsOneWidget);
      expect(find.textContaining('Masseria in Puglia'), findsOneWidget);
      expect(find.text('Video del matrimonio, Album fine art'), findsOneWidget);
      await tapText(tester, 'INVIA');
      expect(
        find.text('Serve il consenso per inviare la richiesta'),
        findsOneWidget,
      );
      expect(s.quotes.length, before);
      await tester.tap(find.byType(Checkbox));
      await settle(tester, 400);
      await tapText(tester, 'INVIA');

      expect(find.text('Grazie, Mario'), findsOneWidget);
      expect(s.quotes.length, before + 1);
      final q = s.quotes.first;
      expect(q.fullName, 'Mario Rossi');
      expect(q.eventType, 'Matrimonio');
      expect(q.eventDate, isNotNull);
      expect(q.location, 'Masseria in Puglia');
      expect(q.requests, ['Video del matrimonio', 'Album fine art']);
      expect(q.message, 'Cerimonia al tramonto.');
      expect(q.source, 'app');
      expect(q.status, QuoteStatus.nuova);

      // Nuova richiesta: si riparte da capo, campi vuoti.
      await tapText(tester, 'Nuova richiesta');
      expect(find.text('PASSO 1 DI 5'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('il modulo segue le scelte del gestionale', (tester) async {
      final s = await loadState();
      final f = s.quoteForm.copy()
        ..showDate = false
        ..showRequests = false
        ..showMessage = false
        ..askLastName = false
        ..askPhone = false;
      f.eventTypes.firstWhere((o) => o.label == 'Battesimo').active = true;
      await s.setQuoteForm(f);
      await pumpApp(tester, s, location: '/preventivo', size: phone);

      // Evento, contatti, riepilogo.
      expect(find.text('PASSO 1 DI 3'), findsOneWidget);
      expect(find.text('Data dell\'evento *'), findsNothing);
      // Con due tipi accesi bisogna sceglierne uno.
      await tapText(tester, 'AVANTI');
      expect(find.text('Scegliete il tipo di evento'), findsOneWidget);
      await tapText(tester, 'Battesimo');
      await fill(tester, 'Luogo *', 'Roma');
      await tapText(tester, 'AVANTI');
      expect(find.widgetWithText(TextField, 'Cognome *'), findsNothing);
      expect(find.widgetWithText(TextField, 'Telefono *'), findsNothing);
      await fill(tester, 'Nome *', 'Lucia');
      await fill(tester, 'Email *', 'lucia@example.com');
      await tapText(tester, 'AVANTI');
      await tester.tap(find.byType(Checkbox));
      await settle(tester, 400);
      await tapText(tester, 'INVIA');
      expect(
        find.text('Vi scriveremo a lucia@example.com per parlarne insieme.'),
        findsOneWidget,
      );
      expect(s.quotes.first.eventType, 'Battesimo');
      expect(s.quotes.first.phone, '');
      await disposeApp(tester);
    });

    test('serve sempre almeno un recapito', () {
      final f = QuoteForm(askPhone: false, askEmail: false);
      expect(f.phoneOn, isFalse);
      expect(f.emailOn, isTrue);
    });
  });

  group('home', () {
    testWidgets('carosello verticale e i quattro lavori in evidenza', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, size: phone);
      expect(find.byType(AppCarousel), findsOneWidget);
      // Nessuna freccia nel carosello dell'app.
      expect(find.byTooltip('Foto successiva'), findsNothing);
      expect(find.bySemanticsLabel('Foto 1 di 6'), findsOneWidget);
      await tester.pump(AppCarousel.interval);
      await settle(tester, 1600);
      expect(find.bySemanticsLabel('Foto 2 di 6'), findsOneWidget);
      expect(find.byType(WorkCard), findsNWidgets(4));
      expect(find.text('GIULIA & MARCO'), findsOneWidget);
      expect(find.text('SPERLONGA · MATRIMONIO'), findsOneWidget);
      expect(find.text('CHIARA & MATTEO'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('si vede solo quello che è acceso per l\'app', (tester) async {
      final s = await loadState();
      s.works.first.onApp = false;
      await s.setWorks([...s.works]);
      for (final p in s.carouselApp.skip(1)) {
        p.active = false;
      }
      await s.setCarouselApp([...s.carouselApp]);
      await pumpApp(tester, s, size: phone);
      expect(find.text('GIULIA & MARCO'), findsNothing);
      expect(find.byType(WorkCard), findsNWidgets(3));
      expect(find.bySemanticsLabel('Foto 1 di 1'), findsOneWidget);
      await disposeApp(tester);
    });

    test('al massimo quattro lavori in evidenza', () async {
      final s = await loadState();
      final w = s.works.firstWhere((w) => !w.featured);
      expect(await s.setFeatured(w, true), isFalse);
      expect(w.featured, isFalse);
      await s.setFeatured(s.works.first, false);
      expect(await s.setFeatured(w, true), isTrue);
      expect(s.featuredWorks, contains(w));
    });
  });

  group('orientamento', () {
    testWidgets('girato in orizzontale il carosello usa le foto del sito', (
      tester,
    ) async {
      final s = await loadState();
      // Una foto del sito spenta: il carosello orizzontale ne ha 5.
      s.carouselSite.first.active = false;
      await s.setCarouselSite([...s.carouselSite]);
      await pumpApp(tester, s, size: const Size(844, 390));
      expect(find.bySemanticsLabel('Foto 1 di 5'), findsOneWidget);
      await disposeApp(tester);

      await pumpApp(tester, s, size: phone);
      expect(find.bySemanticsLabel('Foto 1 di 6'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('menu in riga solo sul tablet in orizzontale', (tester) async {
      final s = await loadState();
      for (final (size, inline) in [
        (const Size(1180, 820), true),
        (const Size(1366, 1024), true),
        (const Size(820, 1180), false),
        (const Size(844, 390), false),
        (phone, false),
      ]) {
        await pumpApp(tester, s, location: '/lavori', size: size);
        expect(
          find.text('AREA CLIENTI'),
          inline ? findsWidgets : findsNothing,
          reason: '$size',
        );
        expect(
          find.bySemanticsLabel('Menu'),
          inline ? findsNothing : findsOneWidget,
          reason: '$size',
        );
        if (inline) {
          await tester.tap(find.text('BIOGRAFIA').first);
          await settle(tester, 800);
          expect(find.text('IL METODO'), findsOneWidget);
        }
        await disposeApp(tester);
      }
    });
    Future<(double, double)> tops(WidgetTester tester, Size size) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/lavori/w-anna-paolo', size: size);
      await settle(tester, 1600);
      // Anche fuori dallo schermo: si cerca il widget, non la semantica.
      Finder foto(String l) => find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == l,
      );
      final a = tester.getTopLeft(foto('Foto 2')).dy;
      final b = tester.getTopLeft(foto('Foto 3')).dy;
      await disposeApp(tester);
      return (a, b);
    }

    testWidgets('tablet in orizzontale: foto sparse, affiancate', (
      tester,
    ) async {
      final (a, b) = await tops(tester, const Size(1180, 820));
      expect(a, b);
    });

    testWidgets('telefono girato: una sotto l\'altra', (tester) async {
      final (a, b) = await tops(tester, const Size(844, 390));
      expect(b, greaterThan(a));
    });

    testWidgets('tablet in verticale: una sotto l\'altra', (tester) async {
      final (a, b) = await tops(tester, const Size(820, 1180));
      expect(b, greaterThan(a));
    });
  });
  group('lavori', () {
    testWidgets('filtri e dettaglio solo foto', (tester) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/lavori', size: phone);
      expect(find.byType(WorkCard), findsNWidgets(10));
      await tester.tap(find.byKey(const ValueKey('filtro-evento')));
      await settle(tester, 600);
      await tester.tap(find.text('Battesimo').last);
      await settle(tester, 800);
      expect(find.byType(WorkCard), findsOneWidget);
      await tester.tap(find.byType(WorkCard));
      await settle(tester, 1200);

      // Solo le foto: nessun titolo.
      expect(find.text('IL BATTESIMO DI LEO'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Foto 1'));
      await settle(tester, 800);
      expect(find.byType(PhotoViewer), findsOneWidget);
      expect(find.bySemanticsLabel('Foto successiva'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Chiudi').last);
      await settle(tester, 800);
      expect(find.byType(PhotoViewer), findsNothing);
      await disposeApp(tester);
    });
  });

  group('copia di sicurezza', () {
    test('andata e ritorno di tutti i dati', () async {
      final s = await loadState();
      s.works.first.featured = false;
      await s.setWorks([...s.works]);
      final backup = s.exportBackup();
      final other = await loadState({'works': [], 'clients': [], 'quotes': []});
      await other.importBackup(backup);
      expect(other.works.length, s.works.length);
      expect(other.works.first.featured, isFalse);
      expect(other.clients.length, s.clients.length);
      expect(other.quoteForm.toJson(), s.quoteForm.toJson());
      expect(jsonDecode(other.exportBackup()), jsonDecode(backup));
    });

    test('un testo rovinato non tocca i dati', () async {
      final s = await loadState();
      final n = s.works.length;
      await expectLater(s.importBackup('{rotto'), throwsFormatException);
      await expectLater(
        s.importBackup(
          jsonEncode({
            'content': {},
            'works': [1, 2],
          }),
        ),
        throwsFormatException,
      );
      expect(s.works.length, n);
    });

    test(
      'legge anche la copia scaricata dal gestionale sul computer',
      () async {
        final s = await loadState();
        final j = jsonDecode(s.exportBackup()) as Map<String, dynamic>;
        final pc = {
          'versione': 2,
          'pubblici': {
            for (final k in [
              'content',
              'carouselSite',
              'carouselApp',
              'works',
              'quoteForm',
            ])
              k: j[k],
          },
          'privati': {
            for (final k in ['quotes', 'appointments', 'clients']) k: j[k],
            'admin': {'username': 'titolare'},
          },
        };
        final other = await loadState({'works': [], 'clients': []});
        await other.importBackup(jsonEncode(pc));
        expect(other.works.length, s.works.length);
        expect(other.clients.length, s.clients.length);
      },
    );
  });
}
