// Area clienti dell'app (account creati dal gestionale, foto e video da
// scaricare) e accesso del titolare al gestionale dalla stessa schermata.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/data/seed.dart';
import 'package:studio_fotografico/models/models.dart';
import 'package:studio_fotografico/pages/admin/admin_clients.dart';
import 'package:studio_fotografico/services/media_saver.dart';
import 'package:studio_fotografico/state/app_state.dart';

import 'support/harness.dart';

const phone = Size(390, 844);

/// Salvataggio finto: ricorda cosa è stato scaricato.
class FakeSaver implements MediaSaver {
  final saved = <String>[];
  String? failOn;

  @override
  Future<void> save(ClientMedia m) async {
    if (m.id == failOn) {
      throw const SaveException('Spazio sul telefono esaurito.');
    }
    saved.add(m.id);
  }
}

Future<void> signIn(WidgetTester tester, String login, String pw) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Email o nome utente'),
    login,
  );
  await tester.enterText(find.widgetWithText(TextField, 'Password'), pw);
  await tester.tap(find.text('ENTRA'));
  await settle(tester, 1200);
}

void main() {
  setUpAll(setUpTestEnv);

  group('accessi', () {
    test('i clienti d\'esempio entrano con email o nome utente', () async {
      final s = await loadState();
      expect(
        s
            .checkClientLogin(
              ' Anna.Ricci@example.com ',
              Seed.demoClientPassword,
            )
            ?.id,
        'cl-anna',
      );
      expect(
        s.checkClientLogin('ANNA.PAOLO', Seed.demoClientPassword)?.id,
        'cl-anna',
      );
      expect(s.checkClientLogin('anna.ricci@example.com', 'sbagliata'), isNull);
      expect(s.checkClientLogin('', Seed.demoClientPassword), isNull);
    });

    test(
      'il titolare entra nel gestionale, il cliente nella sua area',
      () async {
        final s = await loadState();
        expect(
          await s.signIn('Titolare', Seed.demoAdminPassword),
          SignIn.admin,
        );
        expect(s.adminAuthenticated, isTrue);
        await s.logout();
        expect(
          await s.signIn('elena.davide', Seed.demoClientPassword),
          SignIn.client,
        );
        expect(s.currentClient?.id, 'cl-elena');
        expect(s.currentClient!.lastLogin, isNotNull);
        expect(await s.signIn('elena.davide', 'no'), SignIn.wrong);
      },
    );

    test('l\'accesso del cliente resta sul telefono', () async {
      final s = await loadState();
      await s.signIn('anna.ricci@example.com', Seed.demoClientPassword);
      final again = AppState(s.repo);
      await again.load();
      expect(again.currentClient?.id, 'cl-anna');
      // Sospeso: non entra più, nemmeno con la sessione salvata.
      again.clientById('cl-anna')!.active = false;
      await again.saveClient(again.clientById('cl-anna')!);
      final third = AppState(s.repo);
      await third.load();
      expect(third.currentClient, isNull);
    });

    test('nuove credenziali del titolare', () async {
      final s = await loadState();
      await s.setAdminCredentials(
        'studio',
        'nuova-password-1',
        remember: false,
      );
      await s.logout();
      expect(
        await s.loginAdmin(Seed.demoAdminUser, Seed.demoAdminPassword),
        isFalse,
      );
      expect(await s.loginAdmin('STUDIO', 'nuova-password-1'), isTrue);
      expect(s.loginTaken('studio'), isTrue);
    });
  });

  group('account', () {
    test('creare un cliente genera una password che funziona', () async {
      final s = await loadState();
      final c = ClientAccount(
        name: 'Marta Neri',
        email: 'marta@example.com',
        username: 'marta',
      );
      final pw = await s.createClient(c);
      expect(pw, hasLength(10));
      expect(pw, isNot(matches(RegExp('[lIO0]'))));
      expect(s.checkClientLogin('marta', pw)?.id, c.id);
      // Salvato cifrato nell'archivio.
      final raw = (s.repo as MemoryRepository).raw['clients']!;
      expect(raw, contains('marta@example.com'));
      expect(raw, isNot(contains(pw)));
      expect(s.loginTaken('MARTA@example.com'), isTrue);
      expect(s.loginTaken('marta@example.com', exceptId: c.id), isFalse);
    });

    test('nuova password, sospensione ed eliminazione', () async {
      final s = await loadState();
      final c = ClientAccount(name: 'Luca Blu', email: 'luca@example.com');
      final vecchia = await s.createClient(c);
      final nuova = await s.resetClientPassword(c);
      expect(s.checkClientLogin('luca@example.com', vecchia), isNull);
      expect(s.checkClientLogin('luca@example.com', nuova), isNotNull);
      c.active = false;
      await s.saveClient(c);
      expect(s.checkClientLogin('luca@example.com', nuova), isNull);
      await s.deleteClient(c.id);
      expect(s.clientById(c.id), isNull);
    });

    test('andata e ritorno in JSON di un cliente con foto e video', () {
      final c = ClientAccount(
        id: 'x',
        name: 'A',
        email: 'a@b.it',
        username: 'a',
        media: [
          ClientMedia(
            id: 'p',
            url: 'https://x.it/p.jpg',
            original: 'https://x.it/p-orig.jpg',
          ),
          ClientMedia(
            id: 'v',
            url: 'https://x.it/v.mp4',
            isVideo: true,
            poster: 'https://x.it/v.jpg',
          ),
        ],
        files: [ClientFile(id: 'f', name: 'Doc', url: 'https://x.it/d.pdf')],
      );
      final back = ClientAccount.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
      );
      expect(back.toJson(), c.toJson());
      expect(back.photoCount, 1);
      expect(back.videoCount, 1);
      expect(back.media.first.downloadUrl, 'https://x.it/p-orig.jpg');
      expect(back.media.last.downloadUrl, 'https://x.it/v.mp4');
      expect(back.media.last.thumb, 'https://x.it/v.jpg');
    });
  });

  group('app', () {
    late FakeSaver saver;
    setUp(() => mediaSaver = saver = FakeSaver());
    tearDown(() => mediaSaver = GalleryMediaSaver());

    testWidgets('il cliente entra, vede foto e video e scarica tutto', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/area-clienti', size: phone);
      await signIn(tester, 'anna.ricci@example.com', 'sbagliata');
      expect(
        find.text('Email, nome utente o password non corretti.'),
        findsOneWidget,
      );

      await signIn(tester, 'anna.paolo', Seed.demoClientPassword);
      expect(find.text('IL MATRIMONIO DI ANNA E PAOLO'), findsOneWidget);
      expect(find.text('8 FOTO · 1 VIDEO'), findsOneWidget);
      expect(find.bySemanticsLabel('Video 9'), findsOneWidget);

      await tester.tap(find.text('SCARICA TUTTO'));
      await settle(tester, 1600);
      expect(saver.saved, hasLength(9));
      expect(
        find.text(
          'Tutto salvato nella galleria del telefono (album Studio 54).',
        ),
        findsOneWidget,
      );

      // Una foto aperta a schermo intero si scarica da sola.
      await tester.tap(find.bySemanticsLabel('Foto 2'));
      await settle(tester, 800);
      await tester.tap(find.text('SCARICA').last);
      await settle(tester, 800);
      expect(saver.saved.last, 'cl-anna-m2');
      await tester.tap(find.bySemanticsLabel('Chiudi').last);
      await settle(tester, 800);

      // Esce: torna l'accesso.
      await Scrollable.ensureVisible(
        tester.element(find.text('ESCI')),
        alignment: 0.5,
      );
      await settle(tester, 400);
      await tester.tap(find.text('ESCI'));
      await settle(tester, 800);
      expect(find.text('Le vostre foto.'), findsOneWidget);
      expect(s.currentClient, isNull);
      await disposeApp(tester);
    });

    testWidgets('un download non riuscito lo dice', (tester) async {
      final s = await loadState();
      saver.failOn = 'cl-elena-m1';
      await s.signIn('elena.bianchi@example.com', Seed.demoClientPassword);
      await pumpApp(tester, s, location: '/area-clienti', size: phone);
      await tester.tap(find.text('SCARICA TUTTO'));
      await settle(tester, 1600);
      expect(saver.saved, isEmpty);
      expect(find.text('Spazio sul telefono esaurito.'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('il titolare entra nel gestionale dall\'area clienti', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/area-clienti', size: phone);
      await signIn(tester, Seed.demoAdminUser, Seed.demoAdminPassword);
      expect(s.adminAuthenticated, isTrue);
      expect(find.text('Panoramica'), findsWidgets);
      await disposeApp(tester);
    });

    testWidgets('gestionale: nuovo cliente e dati da mandare', (tester) async {
      final s = await loadState();
      await s.loginAdmin(
        Seed.demoAdminUser,
        Seed.demoAdminPassword,
        remember: false,
      );
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
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome utente (facoltativo)'),
        'sara.verdi',
      );
      await tester.tap(find.text('Crea account'));
      await settle(tester, 800);
      final dlg = tester.widget<CredentialsDialog>(
        find.byType(CredentialsDialog),
      );
      expect(dlg.message, contains('Area clienti'));
      expect(dlg.message, contains('sara.verdi'));
      expect(dlg.message, contains(dlg.password));
      expect(s.checkClientLogin('sara.verdi', dlg.password), isNotNull);
      await tester.tap(find.text('Chiudi'));
      await settle(tester, 800);
      expect(find.text('Sara Verdi'), findsOneWidget);
      await disposeApp(tester);
    });
  });
}
