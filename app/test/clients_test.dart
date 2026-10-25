// Area clienti (account creati dal gestionale) e stampe sul tavolo della home.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/data/seed.dart';
import 'package:studio_fotografico/models/models.dart';
import 'package:studio_fotografico/pages/admin/admin_clients.dart';
import 'package:studio_fotografico/state/app_state.dart';
import 'package:studio_fotografico/widgets/sections.dart';

import 'support/harness.dart';

void main() {
  setUpAll(setUpTestEnv);

  group('clienti', () {
    test('i clienti d\'esempio entrano con la password di prova', () async {
      final s = await loadState();
      expect(s.clients, isNotEmpty);
      final anna = s.checkClientLogin(
        ' Anna.Ricci@example.com ',
        Seed.demoClientPassword,
      );
      expect(anna?.id, 'cl-anna');
      expect(anna!.album, isNotEmpty);
      expect(s.checkClientLogin('anna.ricci@example.com', 'sbagliata'), isNull);
    });

    test('creare un cliente genera una password che funziona', () async {
      final s = await loadState();
      final c = ClientAccount(name: 'Marta Neri', email: 'marta@example.com');
      final pw = await s.createClient(c);
      expect(pw, hasLength(10));
      expect(pw, isNot(matches(RegExp('[lIO0]'))));
      expect(c.passwordHash, isNot(contains(pw)));
      expect(s.checkClientLogin('marta@example.com', pw)?.id, c.id);
      // Salvato cifrato nell'archivio.
      final raw = (s.repo as MemoryRepository).raw['clients']!;
      expect(raw, contains('marta@example.com'));
      expect(raw, isNot(contains(pw)));
    });

    test('nuova password, sospensione ed eliminazione', () async {
      final s = await loadState();
      final c = ClientAccount(name: 'Luca Blu', email: 'luca@example.com');
      final vecchia = await s.createClient(c);
      final nuova = await s.resetClientPassword(c);
      expect(nuova, isNot(vecchia));
      expect(s.checkClientLogin('luca@example.com', vecchia), isNull);
      expect(s.checkClientLogin('luca@example.com', nuova), isNotNull);

      c.active = false;
      await s.saveClient(c);
      expect(s.checkClientLogin('luca@example.com', nuova), isNull);

      await s.deleteClient(c.id);
      expect(s.clientById(c.id), isNull);
    });

    test('il backup comprende i clienti con album e file', () async {
      final s = await loadState();
      final backup = jsonDecode(s.exportBackup()) as Map;
      expect((backup['clients'] as List), hasLength(s.clients.length));
      final other = await loadState({'clients': []});
      expect(other.clients, isEmpty);
      await other.importBackup(s.exportBackup());
      expect(other.clientById('cl-anna')!.files, isNotEmpty);
      expect(other.clientById('cl-anna')!.album, isNotEmpty);
    });

    test('andata e ritorno in JSON di un cliente', () {
      final c = ClientAccount(
        id: 'x',
        name: 'A',
        email: 'a@b.it',
        album: [WorkPhoto(id: 'p', url: 'u', caption: 'c')],
        files: [
          ClientFile(id: 'f', name: 'Doc', url: 'https://x.it/d.pdf'),
          ClientFile(id: 'g', name: 'Link', url: 'https://x.it', isLink: true),
        ],
      );
      final back = ClientAccount.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
      );
      expect(back.toJson(), c.toJson());
      expect(ClientAccount.fromJson({}).active, isTrue);
    });

    testWidgets('gestionale: nuovo cliente e dati da mandare', (tester) async {
      final s = await loadState();
      await s.setAdminPassword('password-di-prova', remember: false);
      await pumpApp(tester, s, location: '/admin/clienti');
      expect(find.text('Anna Ricci'), findsOneWidget);

      await tester.tap(find.text('Nuovo cliente'));
      await settle(tester, 800);
      await tester.tap(find.text('Crea account'));
      await settle(tester, 600);
      expect(find.text('Inserisci il nome'), findsOneWidget);
      expect(find.text('Email non valida'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome e cognome *'),
        'Sara Verdi',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email *'),
        'anna.ricci@example.com',
      );
      await tester.tap(find.text('Crea account'));
      await settle(tester, 600);
      // Email già usata da un altro cliente.
      expect(s.clients.where((c) => c.name == 'Sara Verdi'), isEmpty);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email *'),
        'sara@example.com',
      );
      await tester.tap(find.text('Crea account'));
      await settle(tester, 800);
      expect(find.byType(CredentialsDialog), findsOneWidget);
      final dlg = tester.widget<CredentialsDialog>(
        find.byType(CredentialsDialog),
      );
      expect(dlg.message, contains('sara@example.com'));
      expect(dlg.message, contains(dlg.password));
      expect(s.checkClientLogin('sara@example.com', dlg.password), isNotNull);
      await tester.tap(find.text('Chiudi'));
      await settle(tester, 800);
      expect(find.text('Sara Verdi'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('home', () {
    testWidgets('stampe sul tavolo: si toccano e si spostano', (tester) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/');
      // L'ultima stampa è quella posata sopra le altre.
      final title = s.gallery[PrintsTable.slots.length - 1].title;
      final stampa = find.bySemanticsLabel(title);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -900),
      );
      await settle(tester, 800);
      expect(find.text('GLI SCATTI'), findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(stampa.first),
        alignment: 0.5,
      );
      await settle(tester, 800);

      // Trascinata: si sposta.
      final prima = tester.getTopLeft(stampa.first);
      await tester.drag(stampa.first, const Offset(80, 40));
      await settle(tester, 800);
      expect(tester.getTopLeft(stampa.first).dx, greaterThan(prima.dx + 20));

      // Toccata: si apre a schermo intero.
      await tester.tap(stampa.first);
      await settle(tester, 800);
      expect(find.byTooltip('Chiudi'), findsOneWidget);
      await disposeApp(tester);
    });

    test('lo stato espone il generatore di password', () {
      final a = AppState.generatePassword(), b = AppState.generatePassword();
      expect(a, isNot(b));
    });
  });
}
