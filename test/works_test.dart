// I lavori dello studio: modello, stato, pagine pubbliche (elenco e
// dettaglio) e gestione dall'area riservata. In coda alcuni percorsi del
// resto del sito (navigazione, menu su telefono, foto d'apertura).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/data/seed.dart';
import 'package:studio_fotografico/models/models.dart';
import 'package:studio_fotografico/state/app_state.dart';
import 'package:studio_fotografico/theme/app_theme.dart';
import 'package:studio_fotografico/widgets/common.dart';

import 'support/data.dart';
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

/// Sceglie [value] dal menu del filtro [group] ("evento", "stagione"...).
Future<void> pick(WidgetTester tester, String group, String value) async {
  await tapShown(tester, find.byKey(ValueKey('filtro-$group')));
  await tester.tap(find.text(value).last);
  await settle(tester, 800);
}

/// I lavori salvati nell'archivio, letti come farebbe il browser.
List<Map<String, dynamic>> storedWorks(AppState s) => [
  for (final e
      in jsonDecode((s.repo as MemoryRepository).raw['works']!) as List)
    Map<String, dynamic>.from(e as Map),
];

Work _work(
  String id,
  String title, {
  String category = 'Matrimonio',
  int photos = 3,
  bool published = true,
}) => Work(
  id: id,
  title: title,
  category: category,
  location: 'Luogo $id',
  date: 'Maggio 2025',
  story: 'Racconto di $title.',
  credits: 'Reportage',
  photos: [
    for (var i = 0; i < photos; i++)
      WorkPhoto(id: '$id-p$i', url: tinyPng, caption: 'Didascalia $id $i'),
  ],
  published: published,
);

Future<AppState> _withWorks(List<Work> works, {bool admin = false}) async {
  final s = await loadState({
    'works': [for (final w in works) w.toJson()],
  });
  if (admin) await s.setAdminPassword('password-di-prova', remember: false);
  return s;
}

/// Il link della barra di navigazione con il testo [text].
HoverLink navLink(WidgetTester tester, String text) => tester
    .widgetList<HoverLink>(find.byType(HoverLink))
    .firstWhere((l) => l.text == text);

void main() {
  setUpAll(setUpTestEnv);

  // ================================================================ MODELLO

  group('modello', () {
    test('andata e ritorno in JSON conserva ogni campo', () {
      final w = Work(
        id: 'w1',
        title: 'Titolo',
        category: 'Evento',
        location: 'Roma',
        date: 'Luglio 2024',
        story: 'Storia',
        credits: 'Reportage',
        cover: 'https://example.com/c.jpg',
        photos: [
          WorkPhoto(id: 'p1', url: 'https://example.com/1.jpg', caption: 'a'),
          WorkPhoto(id: 'p2', url: tinyPng),
        ],
        published: false,
      );
      final back = Work.fromJson(
        Map<String, dynamic>.from(roundTrip(w.toJson())! as Map),
      );
      expect(back.toJson(), w.toJson());
      expect(back.photos.map((p) => p.id), ['p1', 'p2']);
      expect(back.photos.last.caption, '');
      expect(back.published, isFalse);
    });

    test('lettura tollerante: campi mancanti e foto nulle', () {
      final w = Work.fromJson({'photos': null});
      expect(w.id, isNotEmpty);
      expect(w.title, '');
      expect(w.category, '');
      expect(w.photos, isEmpty);
      expect(w.published, isTrue);
      expect(w.coverUrl, '');

      final p = WorkPhoto.fromJson({});
      expect(p.id, isNotEmpty);
      expect(p.url, '');
      expect(p.caption, '');

      final minimal = Work.fromJson({
        'title': 'Solo titolo',
        'photos': [
          {'url': 'a.jpg'},
        ],
      });
      expect(minimal.photos.single.url, 'a.jpg');
      expect(minimal.photos.single.id, isNotEmpty);
    });

    test('dati del tipo sbagliato vengono rifiutati', () {
      expect(() => Work.fromJson({'title': 3}), throwsA(anything));
      expect(() => Work.fromJson({'photos': 'x'}), throwsA(anything));
      expect(() => Work.fromJson({'published': 'sì'}), throwsA(anything));
    });

    test('copertina: quella scelta, altrimenti la prima foto', () {
      final w = Work(
        title: 't',
        photos: [
          WorkPhoto(url: 'prima.jpg'),
          WorkPhoto(url: 'seconda.jpg'),
        ],
      );
      expect(w.coverUrl, 'prima.jpg');
      w.cover = '   ';
      expect(w.coverUrl, 'prima.jpg');
      w.cover = 'copertina.jpg';
      expect(w.coverUrl, 'copertina.jpg');
      expect(Work(title: 't').coverUrl, '');
    });

    test('stagione: scelta a mano, altrimenti dal mese della data', () {
      expect(seasonFromDate('Giugno 2024'), 'Estate');
      expect(seasonFromDate('12 dicembre 2023'), 'Inverno');
      expect(seasonFromDate('MARZO'), 'Primavera');
      expect(seasonFromDate('Ottobre'), 'Autunno');
      expect(seasonFromDate('2024'), '');
      final w = Work(title: 't', date: 'Agosto 2025');
      expect(w.seasonLabel, 'Estate');
      w.season = 'Autunno';
      expect(w.seasonLabel, 'Autunno');
      expect(Work.fromJson(w.toJson()).season, 'Autunno');
      // Lavori salvati prima dei filtri: campi vuoti.
      final old = Work.fromJson({'title': 'x'});
      expect(old.season, '');
      expect(old.setting, '');
    });

    test('ogni nuovo lavoro e ogni foto hanno un id diverso', () {
      final ids = {for (var i = 0; i < 200; i++) Work(title: '$i').id};
      expect(ids, hasLength(200));
      final photoIds = {for (var i = 0; i < 200; i++) WorkPhoto(url: '$i').id};
      expect(photoIds, hasLength(200));
    });

    test('i lavori d\'esempio sono completi e hanno id stabili', () {
      final a = Seed.works();
      final b = Seed.works();
      expect(a, isNotEmpty);
      expect(a.map((w) => w.id), b.map((w) => w.id));
      expect(a.map((w) => w.id).toSet(), hasLength(a.length));
      for (final w in a) {
        expect(w.title.trim(), isNotEmpty);
        expect(w.photos, isNotEmpty, reason: w.title);
        expect(w.coverUrl, isNotEmpty, reason: w.title);
        expect(w.published, isTrue);
        // Le foto dello stesso lavoro non devono avere id ripetuti: sono
        // usati come chiavi nell'editor.
        expect(w.photos.map((p) => p.id).toSet(), hasLength(w.photos.length));
      }
    });
  });

  // ================================================================== STATO

  group('stato', () {
    test('senza dati salvati si usano i lavori d\'esempio', () async {
      final s = await loadState();
      expect(s.works.map((w) => w.id), Seed.works().map((w) => w.id));
    });

    test('i dati salvati col vecchio marchio si aggiornano', () async {
      final old = Seed.content()
        ..studioName = 'Studio Lumen'
        ..tagline = 'Wedding & Events'
        ..accent = 0xFFC9C5BC
        ..manifestoTitle = 'Testo scritto dal titolare'
        ..team = [
          TeamMember(
            name: 'Nome Cognome',
            role: 'Fotografo',
            bio: '',
            photo: '',
          ),
        ];
      final oldWork = Work.fromJson(Seed.works().first.toJson())..setting = '';
      final s = await loadState({
        'content': old.toJson(),
        'works': [oldWork.toJson(), _work('mio', 'Mio').toJson()],
      });
      expect(s.content.studioName, 'Studio 54');
      expect(s.content.tagline, Seed.content().tagline);
      expect(s.content.accent, Seed.content().accent);
      expect(s.content.team, isEmpty);
      // I testi del titolare restano.
      expect(s.content.manifestoTitle, 'Testo scritto dal titolare');
      expect(s.works.first.setting, 'Mare');
      expect(s.works.last.setting, '');
      // E l'aggiornamento è salvato.
      expect(
        (s.repo as MemoryRepository).raw['content'],
        contains('Studio 54'),
      );
      expect(storedWorks(s).first['setting'], 'Mare');
    });

    test('un elenco salvato vuoto resta vuoto', () async {
      final s = await loadState({'works': []});
      expect(s.works, isEmpty);
      expect(s.publishedWorks, isEmpty);
    });

    test('publishedWorks nasconde i lavori non pubblicati', () async {
      final s = await _withWorks([
        _work('a', 'A'),
        _work('b', 'B', published: false),
        _work('c', 'C'),
      ]);
      expect(s.works, hasLength(3));
      expect(s.publishedWorks.map((w) => w.id), ['a', 'c']);
      expect(s.workById('b')!.title, 'B');
      expect(s.workById('zz'), isNull);
      expect(s.workById(null), isNull);
    });

    test('setWorks salva e avvisa chi ascolta', () async {
      final s = await _withWorks([_work('a', 'A')]);
      var notified = 0;
      s.addListener(() => notified++);
      await s.setWorks([...s.works, _work('b', 'B')]);
      expect(notified, 1);
      expect(storedWorks(s).map((e) => e['id']), ['a', 'b']);
      // Ricaricando dall'archivio si ritrova tutto.
      final again = AppState(s.repo);
      await again.load();
      expect(again.works.map((w) => w.title), ['A', 'B']);
      expect(again.works.last.photos, hasLength(3));
    });

    test('le foto caricate dei lavori contano nello spazio occupato', () async {
      final s = await loadState({
        'works': [],
        'gallery': [],
        'services': [],
        'packages': [],
      });
      final base = s.embeddedImageChars;
      await s.setWorks([
        Work(
          title: 't',
          cover: tinyPng,
          photos: [
            WorkPhoto(url: tinyPng),
            WorkPhoto(url: 'https://example.com/x.jpg'),
          ],
        ),
      ]);
      expect(s.embeddedImageChars - base, tinyPng.length * 2);
    });

    test('il backup comprende i lavori e li ripristina', () async {
      final s = await _withWorks([
        _work('a', 'A'),
        _work('b', 'B', published: false),
      ]);
      final backup = s.exportBackup();
      expect((jsonDecode(backup) as Map)['works'], hasLength(2));

      final other = await loadState();
      await other.importBackup(backup);
      expect(other.works.map((w) => w.id), ['a', 'b']);
      expect(other.works.last.published, isFalse);
      expect(other.works.first.photos.first.caption, 'Didascalia a 0');
    });

    test('un lavoro non valido nel backup non scrive nulla', () async {
      final s = await loadState();
      final repo = s.repo as MemoryRepository;
      final good = jsonDecode(s.exportBackup()) as Map<String, dynamic>;
      final before = Map.of(repo.raw);
      final writes = repo.writes;

      for (final bad in <Object>[
        'x',
        [1],
        [
          {'title': 3},
        ],
        [
          {'title': 'ok', 'photos': 'x'},
        ],
        [
          {
            'title': 'ok',
            'photos': [null],
          },
        ],
        [
          {
            'title': 'ok',
            'photos': [
              {'url': 5},
            ],
          },
        ],
      ]) {
        final raw = jsonEncode({...good, 'services': [], 'works': bad});
        await expectLater(
          s.importBackup(raw),
          throwsA(isA<FormatException>()),
          reason: '$bad',
        );
      }
      expect(repo.raw, before);
      expect(repo.writes, writes);
      expect(s.works, hasLength(Seed.works().length));
    });

    test('un backup senza lavori lascia quelli attuali', () async {
      final s = await _withWorks([_work('a', 'A')]);
      final b = jsonDecode(s.exportBackup()) as Map<String, dynamic>
        ..remove('works');
      await s.importBackup(jsonEncode(b));
      expect(s.works.single.id, 'a');
    });

    test('resetAll ripristina i lavori d\'esempio', () async {
      final s = await _withWorks([_work('a', 'A')]);
      await s.resetAll();
      expect(s.works.map((w) => w.id), Seed.works().map((w) => w.id));
      expect(storedWorks(s), hasLength(Seed.works().length));
    });
  });

  // ======================================================= PAGINE PUBBLICHE

  group('navigazione', () {
    testWidgets('"Lavori" è nella barra ed è attivo su elenco e dettaglio', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/');
      expect(navLink(tester, 'LAVORI').active, isFalse);
      expect(navLink(tester, 'HOME').active, isTrue);
      // Anche il piè di pagina porta ai lavori.
      expect(find.text('Lavori'), findsOneWidget);

      await tester.tap(find.text('LAVORI'));
      await settle(tester);
      expect(find.text('OGNI LAVORO,\nUNA STORIA'), findsOneWidget);
      expect(navLink(tester, 'LAVORI').active, isTrue);
      expect(navLink(tester, 'HOME').active, isFalse);

      await goTo(tester, '/lavori/w-sofia-luca');
      expect(find.text('SOFIA & LUCA'), findsOneWidget);
      expect(navLink(tester, 'LAVORI').active, isTrue);
      await disposeApp(tester);
    });

    testWidgets('menu su telefono: si apre, si chiude e porta ai lavori', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/', size: const Size(390, 844));
      // Su telefono i link sono nel menu.
      expect(find.text('LAVORI'), findsNothing);

      await tester.tap(find.text('MENU'));
      await settle(tester, 800);
      for (final t in ['HOME', 'LAVORI', 'BIOGRAFIA', 'PREVENTIVO']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tester.tap(find.byTooltip('Chiudi'));
      await settle(tester, 800);
      expect(find.text('BIOGRAFIA'), findsNothing);

      await tester.tap(find.text('MENU'));
      await settle(tester, 800);
      await tester.tap(find.text('LAVORI'));
      await settle(tester);
      expect(find.text('BIOGRAFIA'), findsNothing);
      expect(find.text('OGNI LAVORO,\nUNA STORIA'), findsOneWidget);

      // Nel menu aperto dai lavori la voce corrente è evidenziata.
      await tester.tap(find.text('MENU'));
      await settle(tester, 800);
      final current = tester.widget<Text>(find.text('BIOGRAFIA'));
      final active = tester.widget<Text>(
        find.descendant(
          of: find.byType(FittedBox),
          matching: find.text('LAVORI'),
        ),
      );
      expect(active.style!.color, Palette.ink);
      expect(current.style!.color, isNot(Palette.ink));
      await tester.tap(find.text('BIOGRAFIA'));
      await settle(tester);
      expect(find.text('MENU'), findsOneWidget);
      expect(find.text('OGNI LAVORO,\nUNA STORIA'), findsNothing);
      await disposeApp(tester);
    });
  });

  group('elenco lavori', () {
    testWidgets('mostra solo i lavori pubblicati, con il contatore', (
      tester,
    ) async {
      final s = await _withWorks([
        _work('a', 'Alfa'),
        _work('b', 'Beta', published: false),
        _work('c', 'Gamma'),
      ]);
      await pumpApp(tester, s, location: '/lavori');
      expect(find.text('ALFA'), findsOneWidget);
      expect(find.text('GAMMA'), findsOneWidget);
      expect(find.text('BETA'), findsNothing);
      expect(find.text('02 LAVORI'), findsOneWidget);
      expect(find.text('03 SCATTI'), findsNWidgets(2));
      await disposeApp(tester);
    });

    testWidgets('senza lavori pubblicati compare un messaggio', (tester) async {
      final s = await _withWorks([_work('b', 'Beta', published: false)]);
      await pumpApp(tester, s, location: '/lavori');
      expect(find.text('Presto qui i nostri lavori.'), findsOneWidget);
      expect(find.text('00 LAVORI'), findsOneWidget);
      expect(find.byKey(const ValueKey('filtro-evento')), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('un lavoro solo: "LAVORO" al singolare e niente filtri', (
      tester,
    ) async {
      final s = await _withWorks([_work('a', 'Alfa')]);
      await pumpApp(tester, s, location: '/lavori');
      expect(find.text('01 LAVORO'), findsOneWidget);
      expect(find.byKey(const ValueKey('filtro-evento')), findsNothing);
      await disposeApp(tester);
    });

    testWidgets(
      'il filtro per tipo mostra solo quel tipo; "Tutti" li rimette',
      (tester) async {
        final s = await loadState();
        await pumpApp(tester, s, location: '/lavori');
        final all = ['GIULIA & MARCO', 'SOFIA & LUCA', 'IL BATTESIMO DI LEO'];
        for (final t in all) {
          expect(find.text(t), findsOneWidget, reason: t);
        }
        // Una riga sola e discreta: tre voci con "Tutti".
        expect(find.text('Tutti'), findsNWidgets(3));

        await pick(tester, 'evento', 'Cerimonia');
        expect(find.text('IL BATTESIMO DI LEO'), findsOneWidget);
        expect(find.text('GIULIA & MARCO'), findsNothing);
        expect(find.text('SOFIA & LUCA'), findsNothing);
        expect(find.text('NOTTE D\'ESTATE'), findsNothing);
        expect(find.text('01 TROVATO'), findsOneWidget);
        // La voce mostra la scelta.
        expect(find.text('Cerimonia'), findsOneWidget);

        await pick(tester, 'evento', 'Matrimonio');
        expect(find.text('GIULIA & MARCO'), findsOneWidget);
        expect(find.text('SOFIA & LUCA'), findsOneWidget);
        expect(find.text('IL BATTESIMO DI LEO'), findsNothing);

        await pick(tester, 'evento', 'Tutti');
        for (final t in [...all, 'NOTTE D\'ESTATE']) {
          expect(find.text(t), findsOneWidget, reason: t);
        }
        expect(find.textContaining('TROVAT'), findsNothing);
        await disposeApp(tester);
      },
    );

    testWidgets('filtri per stagione e location, insieme e azzerati', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/lavori');
      // ("EVENTO" è anche il tipo di uno dei lavori.)
      expect(find.text('EVENTO'), findsWidgets);
      for (final g in ['STAGIONE', 'LOCATION']) {
        expect(find.text(g), findsOneWidget, reason: g);
      }
      // La stagione si ricava dal mese ("Dicembre 2023" → Inverno).
      await pick(tester, 'stagione', 'Inverno');
      expect(find.text('ELENA & DAVIDE'), findsOneWidget);
      expect(find.text('ANNA & PAOLO'), findsNothing);

      // Primavera: il battesimo (aprile) e la masseria (maggio).
      await pick(tester, 'stagione', 'Primavera');
      expect(find.text('IL BATTESIMO DI LEO'), findsOneWidget);
      expect(find.text('ANNA & PAOLO'), findsOneWidget);
      // + Masseria: resta solo quello in masseria.
      await pick(tester, 'location', 'Masseria');
      expect(find.text('ANNA & PAOLO'), findsOneWidget);
      expect(find.text('IL BATTESIMO DI LEO'), findsNothing);
      await pick(tester, 'location', 'Tutti');
      expect(find.text('IL BATTESIMO DI LEO'), findsOneWidget);

      // Nessun risultato, poi "Azzera".
      await pick(tester, 'location', 'Montagna');
      expect(find.text('Nessun lavoro con questi filtri.'), findsOneWidget);
      await tapShown(tester, find.text('AZZERA'));
      expect(find.text('AZZERA'), findsNothing);
      expect(find.text('Tutti'), findsNWidgets(3));
      expect(find.text('06 LAVORI'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('tipi scritti con maiuscole diverse sono un solo filtro', (
      tester,
    ) async {
      final s = await _withWorks([
        _work('a', 'Alfa', category: 'Matrimonio'),
        _work('b', 'Beta', category: ' matrimonio '),
        _work('c', 'Gamma', category: 'Evento'),
      ]);
      await pumpApp(tester, s, location: '/lavori');
      await tapShown(tester, find.byKey(const ValueKey('filtro-evento')));
      expect(find.text('Matrimonio'), findsOneWidget);
      expect(find.text('matrimonio'), findsNothing);
      await tester.tap(find.text('Matrimonio'));
      await settle(tester, 800);
      expect(find.text('ALFA'), findsOneWidget);
      expect(find.text('BETA'), findsOneWidget);
      expect(find.text('GAMMA'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('se il tipo scelto sparisce si torna a "Tutti"', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/lavori');
      await pick(tester, 'evento', 'Cerimonia');
      expect(find.text('SOFIA & LUCA'), findsNothing);

      // Il battesimo viene nascosto dall'area riservata.
      s.workById('w-battesimo-leo')!.published = false;
      await s.setWorks([...s.works]);
      await settle(tester);
      expect(find.text('SOFIA & LUCA'), findsOneWidget);
      expect(find.text('CERIMONIA'), findsNothing);
      expect(find.text('Tutti'), findsNWidgets(3));
      await disposeApp(tester);
    });

    testWidgets('toccando un lavoro si apre il suo dettaglio', (tester) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/lavori');
      await tapShown(tester, find.text('SOFIA & LUCA'));
      await settle(tester);
      expect(find.text('← TUTTI I LAVORI'), findsNWidgets(2));
      expect(find.textContaining('TOSCANA'), findsOneWidget);
      expect(find.text('OGNI LAVORO,\nUNA STORIA'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('su telefono il tocco sulla foto apre il dettaglio', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/lavori', size: const Size(360, 640));
      await tapShown(tester, find.text('03 SCATTI'));
      await settle(tester);
      expect(find.text('← TUTTI I LAVORI'), findsNWidgets(2));
      expect(find.text('Il battesimo di Leo'.toUpperCase()), findsWidgets);
      await disposeApp(tester);
    });
  });

  group('dettaglio lavoro', () {
    testWidgets('solo foto: titolo, una riga di dati, tavole e lightbox', (
      tester,
    ) async {
      final s = await loadState();
      final w = s.workById('w-giulia-marco')!;
      await pumpApp(tester, s, location: '/lavori/w-giulia-marco');

      expect(find.text('GIULIA & MARCO'), findsOneWidget);
      expect(
        find.text(
          'MATRIMONIO  ·  MARE  ·  ESTATE  ·  COSTA TIRRENICA  ·  GIUGNO 2024',
        ),
        findsOneWidget,
      );
      // Nessun testo lungo: il racconto resta nell'elenco.
      expect(find.text(w.story), findsNothing);
      expect(find.text('SCHEDA'), findsNothing);
      expect(find.textContaining('TAV. '), findsNWidgets(w.photos.length));
      expect(find.text('TAV. 06'), findsOneWidget);

      await tapShown(tester, find.text('TAV. 02'));
      expect(find.text('02 / 06'), findsOneWidget);
      expect(find.byTooltip('Chiudi'), findsOneWidget);
      // Il titolo nella vista a tutto schermo è la didascalia della tavola.
      expect(find.text(w.photos[1].caption), findsNWidgets(2));
      await tester.tap(find.byTooltip('Foto successiva'));
      await settle(tester, 800);
      expect(find.text('03 / 06'), findsOneWidget);
      await tester.tap(find.byTooltip('Chiudi'));
      await settle(tester, 800);
      expect(find.text('03 / 06'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('la tavola giusta si apre anche su telefono', (tester) async {
      final s = await loadState();
      await pumpApp(
        tester,
        s,
        location: '/lavori/w-giulia-marco',
        size: const Size(360, 640),
      );
      expect(find.textContaining('TAV. '), findsNWidgets(6));
      await tapShown(tester, find.text('TAV. 05'));
      expect(find.text('05 / 06'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('"Lavoro successivo" passa al seguente e ricomincia', (
      tester,
    ) async {
      final s = await loadState();
      final ids = s.publishedWorks.map((w) => w.id).toList();
      await pumpApp(tester, s, location: '/lavori/${ids.last}');
      expect(find.text('LAVORO SUCCESSIVO'), findsOneWidget);
      // Dall'ultimo si torna al primo.
      final first = s.workById(ids.first)!;
      expect(find.text(first.title.toUpperCase()), findsOneWidget);
      final second = s.workById(ids[1])!;
      final third = s.workById(ids[2])!;
      await tapShown(tester, find.text('LAVORO SUCCESSIVO'));
      await settle(tester);
      // Sul primo: il suo titolo in alto e il secondo come successivo.
      expect(find.text(first.title.toUpperCase()), findsOneWidget);
      expect(find.text(second.title.toUpperCase()), findsOneWidget);

      // E dal primo al secondo.
      await tapShown(tester, find.text('LAVORO SUCCESSIVO'));
      await settle(tester);
      expect(find.text(second.title.toUpperCase()), findsOneWidget);
      expect(find.text(third.title.toUpperCase()), findsOneWidget);
      expect(find.text(first.title.toUpperCase()), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('i lavori nascosti si saltano nel "successivo"', (
      tester,
    ) async {
      final s = await _withWorks([
        _work('a', 'Alfa'),
        _work('b', 'Beta', published: false),
        _work('c', 'Gamma'),
      ]);
      await pumpApp(tester, s, location: '/lavori/a');
      expect(find.text('GAMMA'), findsOneWidget);
      expect(find.text('BETA'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('con un solo lavoro non c\'è il "successivo"', (tester) async {
      final s = await _withWorks([_work('a', 'Alfa')]);
      await pumpApp(tester, s, location: '/lavori/a');
      expect(find.text('LAVORO SUCCESSIVO'), findsNothing);
      // In alto e in fondo alla pagina.
      expect(find.text('← TUTTI I LAVORI'), findsNWidgets(2));
      await disposeApp(tester);
    });

    testWidgets('un lavoro nascosto non è più in mostra', (tester) async {
      final s = await _withWorks([
        _work('a', 'Alfa'),
        _work('b', 'Beta', published: false),
      ]);
      await pumpApp(tester, s, location: '/lavori/b');
      expect(find.text('Questo lavoro non è più in mostra.'), findsOneWidget);
      expect(find.text('BETA'), findsNothing);
      expect(navLink(tester, 'LAVORI').active, isTrue);

      await tapShown(tester, find.text('← TUTTI I LAVORI'));
      await settle(tester);
      expect(find.text('ALFA'), findsOneWidget);
      expect(find.text('OGNI LAVORO,\nUNA STORIA'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('un lavoro inesistente non è più in mostra', (tester) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/lavori/non-esiste');
      expect(find.text('Questo lavoro non è più in mostra.'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('lavoro senza foto né dati: solo il titolo', (tester) async {
      final s = await _withWorks([
        Work(id: 'x', title: 'Solo titolo'),
        _work('y', 'Altro'),
      ]);
      await pumpApp(tester, s, location: '/lavori/x');
      expect(find.textContaining('TAV. '), findsNothing);
      expect(find.text('SOLO TITOLO'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('una modifica dall\'area riservata si vede subito', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/lavori/w-sofia-luca');
      final w = s.workById('w-sofia-luca')!;
      final edited = Work.fromJson(w.toJson())
        ..title = 'Titolo riscritto'
        ..photos.removeLast();
      await s.setWorks([for (final e in s.works) e.id == w.id ? edited : e]);
      await settle(tester);
      expect(find.text('TITOLO RISCRITTO'), findsOneWidget);
      expect(find.textContaining('TAV. '), findsNWidgets(3));
      await disposeApp(tester);
    });

    testWidgets('collage: verticali e orizzontali composte senza tagli', (
      tester,
    ) async {
      // Proporzioni note: 0 = orizzontale, poi verticale + due orizzontali,
      // poi orizzontale + due verticali.
      final ratios = [1.5, 0.67, 1.5, 1.5, 1.5, 0.67, 0.67];
      final w = Work(
        id: 'c',
        title: 'Collage',
        photos: [
          for (var i = 0; i < ratios.length; i++)
            WorkPhoto(id: 'c$i', url: 'https://example.com/c$i.jpg'),
        ],
      );
      for (var i = 0; i < ratios.length; i++) {
        PhotoAspects.instance.debugSet(w.photos[i].url, ratios[i]);
      }
      addTearDown(PhotoAspects.instance.debugClear);
      final s = await _withWorks([w, _work('y', 'Altro')]);
      await pumpApp(tester, s, location: '/lavori/c');

      Rect photo(int n) => tester.getRect(
        find.byWidgetPredicate(
          (e) => e is PhotoImage && e.url == w.photos[n - 1].url,
        ),
      );
      // Ogni foto conserva le sue proporzioni (nessun taglio).
      for (var i = 0; i < ratios.length; i++) {
        final r = photo(i + 1);
        expect(r.width / r.height, closeTo(ratios[i], 0.02), reason: '$i');
      }
      // La prima occupa tutta la larghezza.
      final full = photo(1).width;
      // Verticale a sinistra, alta quanto le due orizzontali accanto.
      expect(photo(2).left, lessThan(photo(3).left));
      expect(photo(3).left, closeTo(photo(4).left, 0.5));
      expect(photo(4).top, greaterThan(photo(3).bottom));
      expect(photo(2).width + photo(3).width, lessThan(full));
      // Orizzontale e due verticali sulla stessa riga, stessa altezza.
      expect(photo(5).top, closeTo(photo(6).top, 0.5));
      expect(photo(6).top, closeTo(photo(7).top, 0.5));
      expect(photo(5).height, closeTo(photo(7).height, 0.5));
      await disposeApp(tester);
    });

    testWidgets('su telefono le foto sono una sotto l\'altra', (tester) async {
      final s = await loadState();
      await pumpApp(
        tester,
        s,
        location: '/lavori/w-giulia-marco',
        size: const Size(390, 844),
      );
      final plates = find.textContaining('TAV. ');
      final xs = {
        for (final e in plates.evaluate())
          tester.getTopLeft(find.byWidget(e.widget)).dx.round(),
      };
      expect(xs, hasLength(1));
      await disposeApp(tester);
    });
  });

  // =========================================================== AREA RISERVATA

  group('area riservata', () {
    Future<void> openNewWork(WidgetTester tester) async {
      await tester.tap(find.text('Nuovo lavoro'));
      await settle(tester, 800);
      expect(find.text('Salva'), findsOneWidget);
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    Future<void> addByUrl(WidgetTester tester, String url) async {
      await tapShown(tester, find.text('Da indirizzo'));
      expect(find.text('Aggiungi foto'), findsOneWidget);
      await tester.enterText(
        find
            .widgetWithText(TextField, 'Oppure incolla l\'indirizzo (URL)')
            .last,
        url,
      );
      await tester.pump();
      await tester.tap(find.text('Aggiungi'));
      await settle(tester, 800);
    }

    testWidgets('nuovo lavoro: controlli, foto da indirizzo, ordine e salvo', (
      tester,
    ) async {
      final s = await _withWorks([_work('a', 'Alfa')], admin: true);
      await pumpApp(tester, s, location: '/admin/lavori');
      await openNewWork(tester);

      // Vuoto: titolo obbligatorio e almeno una foto.
      await tester.tap(find.text('Salva'));
      await settle(tester, 600);
      expect(find.text('Campo obbligatorio'), findsOneWidget);
      expect(find.text('Aggiungi almeno una foto.'), findsOneWidget);
      expect(s.works, hasLength(1));

      // Annullare la finestra dell'indirizzo non aggiunge nulla.
      await tapShown(tester, find.text('Da indirizzo'));
      await tester.tap(find.text('Annulla').last);
      await settle(tester, 800);
      expect(find.text('Foto (0)'), findsOneWidget);

      await addByUrl(tester, '  https://example.com/uno.jpg  ');
      expect(find.text('Foto (1)'), findsOneWidget);
      expect(find.text('Aggiungi almeno una foto.'), findsNothing);
      await addByUrl(tester, 'https://example.com/due.jpg');
      expect(find.text('Foto (2)'), findsOneWidget);

      // Didascalie e ordine: la seconda sale al primo posto.
      await tester.enterText(field('Didascalia').at(0), 'Prima');
      await tester.enterText(field('Didascalia').at(1), 'Seconda');
      await tapShown(tester, find.byTooltip('Sposta su').at(1));
      expect(field('Didascalia'), findsNWidgets(2));
      // Il primo campo in alto ora è la "Seconda".
      expect(
        find.descendant(
          of: field('Didascalia').at(0),
          matching: find.text('Seconda'),
        ),
        findsOneWidget,
      );

      // Il primo "su" e l'ultimo "giù" sono disattivati.
      IconButton btn(String t, int i) => tester.widget<IconButton>(
        find
            .widgetWithIcon(IconButton, switch (t) {
              'su' => Icons.arrow_upward_rounded,
              _ => Icons.arrow_downward_rounded,
            })
            .at(i),
      );
      expect(btn('su', 0).onPressed, isNull);
      expect(btn('giù', 1).onPressed, isNull);
      expect(btn('su', 1).onPressed, isNotNull);

      await tester.enterText(field('Titolo *'), 'Elena & Paolo');
      await tester.enterText(field('Evento (es. Matrimonio)'), 'Matrimonio');
      await tester.enterText(field('Data (es. Giugno 2024)'), 'Luglio 2025');
      await tester.enterText(field('Luogo'), 'Puglia');
      await tester.pump();
      // La stagione si propone dalla data; la location dai suggerimenti.
      expect(find.text('Dalla data: Estate'), findsOneWidget);
      await tapShown(tester, find.widgetWithText(ChoiceChip, 'Masseria'));
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Masseria'))
            .controller!
            .text,
        'Masseria',
      );
      await tester.tap(find.text('Salva'));
      await settle(tester, 800);

      expect(find.text('Salva'), findsNothing);
      expect(s.works, hasLength(2));
      final saved = storedWorks(s).first;
      expect(saved['title'], 'Elena & Paolo');
      expect(saved['category'], 'Matrimonio');
      expect(saved['location'], 'Puglia');
      expect(saved['setting'], 'Masseria');
      expect(saved['season'], '');
      expect(s.works.first.seasonLabel, 'Estate');
      expect(saved['published'], isTrue);
      final photos = (saved['photos'] as List).cast<Map>();
      expect(photos.map((p) => p['url']), [
        'https://example.com/due.jpg',
        'https://example.com/uno.jpg',
      ]);
      expect(photos.map((p) => p['caption']), ['Seconda', 'Prima']);
      // Il nuovo lavoro compare in cima all'elenco.
      expect(find.text('Elena & Paolo'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      'modifica: didascalia, foto tolta, nascosto; Annulla non salva',
      (tester) async {
        final s = await _withWorks([
          _work('a', 'Alfa'),
          _work('b', 'Beta'),
        ], admin: true);
        final writes = (s.repo as MemoryRepository).writes;
        await pumpApp(tester, s, location: '/admin/lavori');

        // Prima una modifica annullata: niente cambia.
        await tester.tap(find.text('Beta'));
        await settle(tester, 800);
        expect(find.text('Modifica lavoro'), findsOneWidget);
        await tester.enterText(field('Titolo *'), 'Non salvato');
        await tester.enterText(field('Didascalia').first, 'Non salvata');
        await tapShown(tester, find.byTooltip('Togli foto').first);
        await tester.tap(find.text('Annulla'));
        await settle(tester, 800);
        final b = s.workById('b')!;
        expect(b.title, 'Beta');
        expect(b.photos, hasLength(3));
        expect(b.photos.first.caption, 'Didascalia b 0');
        expect((s.repo as MemoryRepository).writes, writes);

        // Poi una modifica salvata.
        await tester.tap(find.text('Beta'));
        await settle(tester, 800);
        await tester.enterText(field('Didascalia').first, 'Nuova didascalia');
        await tapShown(tester, find.byTooltip('Togli foto').last);
        expect(find.text('Foto (2)'), findsOneWidget);
        await tapShown(tester, find.byType(SwitchListTile));
        await tester.tap(find.text('Salva'));
        await settle(tester, 800);

        final saved = storedWorks(s).firstWhere((e) => e['id'] == 'b');
        expect(saved['published'], isFalse);
        expect((saved['photos'] as List).map((p) => (p as Map)['caption']), [
          'Nuova didascalia',
          'Didascalia b 1',
        ]);
        expect(s.publishedWorks.map((w) => w.id), ['a']);
        // L'ordine dei lavori resta lo stesso.
        expect(s.works.map((w) => w.id), ['a', 'b']);
        await disposeApp(tester);
      },
    );

    testWidgets('togliere tutte le foto impedisce di salvare', (tester) async {
      final s = await _withWorks([_work('a', 'Alfa', photos: 1)], admin: true);
      await pumpApp(tester, s, location: '/admin/lavori');
      await tester.tap(find.text('Alfa'));
      await settle(tester, 800);
      await tapShown(tester, find.byTooltip('Togli foto'));
      await tester.tap(find.text('Salva'));
      await settle(tester, 600);
      expect(find.text('Aggiungi almeno una foto.'), findsOneWidget);
      expect(s.workById('a')!.photos, hasLength(1));
      await disposeApp(tester);
    });

    testWidgets('le foto senza indirizzo si scartano senza rompere l\'editor', (
      tester,
    ) async {
      final s = await _withWorks([
        Work(
          id: 'a',
          title: 'Alfa',
          photos: [
            WorkPhoto(id: 'p0', url: tinyPng),
            WorkPhoto(id: 'p1', url: ''),
            WorkPhoto(id: 'p2', url: tinyPng, caption: 'Terza'),
          ],
        ),
      ], admin: true);
      await pumpApp(tester, s, location: '/admin/lavori');
      await tester.tap(find.text('Alfa'));
      await settle(tester, 800);
      expect(find.text('Foto (3)'), findsOneWidget);

      // Un salvataggio respinto (titolo vuoto) toglie la foto vuota e
      // l'elenco mostrato deve seguirlo.
      await tester.enterText(field('Titolo *'), '');
      await tester.tap(find.text('Salva'));
      await settle(tester, 600);
      expect(find.text('Campo obbligatorio'), findsOneWidget);
      expect(find.text('Foto (2)'), findsOneWidget);
      expect(find.byTooltip('Togli foto'), findsNWidgets(2));
      await tapShown(tester, find.byTooltip('Togli foto').last);
      expect(find.text('Foto (1)'), findsOneWidget);

      await tester.enterText(field('Titolo *'), 'Alfa');
      await tester.tap(find.text('Salva'));
      await settle(tester, 800);
      expect(s.workById('a')!.photos.map((p) => p.id), ['p0']);
      await disposeApp(tester);
    });

    testWidgets('foto con id ripetuti (backup a mano): l\'editor regge', (
      tester,
    ) async {
      final s = await _withWorks([
        Work(
          id: 'a',
          title: 'Alfa',
          photos: [
            WorkPhoto(id: 'uguale', url: tinyPng, caption: 'Uno'),
            WorkPhoto(id: 'uguale', url: tinyPng, caption: 'Due'),
          ],
        ),
      ], admin: true);
      await pumpApp(tester, s, location: '/admin/lavori');
      await tester.tap(find.text('Alfa'));
      await settle(tester, 800);
      expect(tester.takeException(), isNull);
      expect(find.text('Foto (2)'), findsOneWidget);
      await tapShown(tester, find.byTooltip('Sposta giù').first);
      await tester.tap(find.text('Salva'));
      await settle(tester, 800);
      expect(s.workById('a')!.photos.map((p) => p.caption), ['Due', 'Uno']);
      await disposeApp(tester);
    });

    testWidgets('editor su telefono: pulsanti sotto la foto, senza overflow', (
      tester,
    ) async {
      final s = await _withWorks([_work('a', 'Alfa')], admin: true);
      await pumpApp(
        tester,
        s,
        location: '/admin/lavori',
        size: const Size(320, 568),
      );
      await tester.tap(find.text('Alfa'));
      await settle(tester, 800);
      final caption = find.widgetWithText(TextFormField, 'Didascalia').first;
      await show(tester, caption);
      // La didascalia ha spazio sufficiente per scrivere.
      expect(tester.getSize(caption).width, greaterThan(100));
      await tapShown(tester, find.byTooltip('Togli foto').first);
      expect(find.text('Foto (2)'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('visibilità dall\'elenco: nasconde e rimostra sul sito', (
      tester,
    ) async {
      final s = await _withWorks([
        _work('a', 'Alfa'),
        _work('b', 'Beta'),
      ], admin: true);
      await pumpApp(tester, s, location: '/admin/lavori');
      expect(find.byTooltip('Visibile sul sito'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Visibile sul sito').first);
      await settle(tester, 600);
      expect(s.workById('a')!.published, isFalse);
      expect(storedWorks(s).first['published'], isFalse);
      expect(find.byTooltip('Nascosto'), findsOneWidget);
      expect(s.publishedWorks.map((w) => w.id), ['b']);

      await tester.tap(find.byTooltip('Nascosto'));
      await settle(tester, 600);
      expect(storedWorks(s).first['published'], isTrue);
      expect(find.byTooltip('Nascosto'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('eliminare chiede conferma', (tester) async {
      final s = await _withWorks([
        _work('a', 'Alfa'),
        _work('b', 'Beta'),
      ], admin: true);
      await pumpApp(tester, s, location: '/admin/lavori');

      await tester.tap(find.byTooltip('Elimina').last);
      await settle(tester, 800);
      expect(find.text('Eliminare il lavoro “Beta”?'), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await settle(tester, 800);
      expect(s.works, hasLength(2));

      await tester.tap(find.byTooltip('Elimina').last);
      await settle(tester, 800);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Elimina'),
        ),
      );
      await settle(tester, 800);
      expect(s.works.map((w) => w.id), ['a']);
      expect(storedWorks(s).map((e) => e['id']), ['a']);
      expect(find.text('Beta'), findsNothing);

      await tester.tap(find.byTooltip('Elimina'));
      await settle(tester, 800);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Elimina'),
        ),
      );
      await settle(tester, 800);
      expect(storedWorks(s), isEmpty);
      expect(
        find.text('Nessun lavoro ancora. Aggiungi il primo.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('su telefono elimina dal menu delle azioni', (tester) async {
      final s = await _withWorks([
        _work('a', 'Alfa'),
        _work('b', 'Beta'),
      ], admin: true);
      await pumpApp(
        tester,
        s,
        location: '/admin/lavori',
        size: const Size(360, 640),
      );
      await tester.tap(find.byTooltip('Azioni').first);
      await settle(tester, 600);
      await tester.tap(find.text('Elimina').last);
      await settle(tester, 800);
      expect(find.text('Eliminare il lavoro “Alfa”?'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Elimina'),
        ),
      );
      await settle(tester, 800);
      expect(storedWorks(s).map((e) => e['id']), ['b']);
      await disposeApp(tester);
    });

    testWidgets('trascinando si riordinano i lavori', (tester) async {
      final s = await _withWorks([
        _work('a', 'Alfa'),
        _work('b', 'Beta'),
        _work('c', 'Gamma'),
      ], admin: true);
      await pumpApp(tester, s, location: '/admin/lavori');

      final handles = find.byIcon(Icons.drag_indicator_rounded);
      expect(handles, findsNWidgets(3));
      final rowH =
          tester.getCenter(handles.at(1)).dy -
          tester.getCenter(handles.at(0)).dy;
      final g = await tester.startGesture(tester.getCenter(handles.at(0)));
      await tester.pump(const Duration(milliseconds: 100));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(Offset(0, rowH * 0.25));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await g.up();
      await settle(tester, 800);

      expect(s.works.map((w) => w.id), ['b', 'c', 'a']);
      expect(storedWorks(s).map((e) => e['id']), ['b', 'c', 'a']);
      // Anche il sito segue il nuovo ordine.
      expect(s.publishedWorks.first.id, 'b');
      await disposeApp(tester);
    });
  });

  // ============================================================ ALTRI PERCORSI

  group('home', () {
    testWidgets(
      'la foto d\'apertura cambia ogni 4 secondi e le frecce girano',
      (tester) async {
        final s = await loadState();
        final n = s.heroPhotos.length.toString().padLeft(2, '0');
        expect(s.heroPhotos.length, greaterThan(2));
        await pumpApp(tester, s, location: '/');
        expect(find.text('01 / $n'), findsOneWidget);
        // pumpApp ha già fatto passare 1,6 s.
        await settle(tester, 2000);
        expect(find.text('01 / $n'), findsOneWidget);
        await settle(tester, 600);
        expect(find.text('02 / $n'), findsOneWidget);
        await settle(tester, 4000);
        expect(find.text('03 / $n'), findsOneWidget);

        Finder arrow(String label) => find.bySemanticsLabel(label);
        await tester.tap(arrow('Foto precedente'));
        await tester.pump();
        expect(find.text('02 / $n'), findsOneWidget);
        await tester.tap(arrow('Foto precedente'));
        await tester.pump();
        await tester.tap(arrow('Foto precedente'));
        await tester.pump();
        // Dalla prima si passa all'ultima.
        expect(find.text('$n / $n'), findsOneWidget);
        await tester.tap(arrow('Foto successiva'));
        await tester.pump();
        expect(find.text('01 / $n'), findsOneWidget);

        // Un tocco sulle frecce fa ripartire il conto dei 4 secondi.
        await settle(tester, 3400);
        expect(find.text('01 / $n'), findsOneWidget);
        await settle(tester, 800);
        expect(find.text('02 / $n'), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets('su telefono il carosello riempie lo schermo e si sfoglia', (
      tester,
    ) async {
      final s = await loadState();
      final n = s.heroPhotos.length.toString().padLeft(2, '0');
      await pumpApp(tester, s, location: '/', size: const Size(390, 844));
      final hero = s.heroPhotos.first;
      // Foto, titolo, descrizione e comandi stanno tutti nel primo schermo.
      // (Titolo e didascalia ricompaiono più giù, nella mostra.)
      for (final f in [
        find.text(hero.title).first,
        find.text(hero.caption).first,
        find.text('01 / $n'),
        find.bySemanticsLabel('Foto successiva'),
      ]) {
        expect(f, findsOneWidget);
        final r = tester.getRect(f);
        expect(r.bottom, lessThanOrEqualTo(844));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(390));
      }
      // La sezione successiva comincia sotto lo schermo.
      expect(tester.getTopLeft(find.text('MANIFESTO')).dy, greaterThan(844));

      // Un colpo di dito verso sinistra porta alla foto successiva.
      await tester.fling(
        find.bySemanticsLabel(hero.title).first,
        const Offset(-200, 0),
        800,
      );
      await settle(tester, 800);
      expect(find.text('02 / $n'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('nel carosello solo le foto orizzontali', (tester) async {
      final s = await loadState();
      final hero = s.heroPhotos;
      final total = hero.length;
      addTearDown(PhotoAspects.instance.debugClear);
      // Una foto risulta verticale: esce dal carosello.
      PhotoAspects.instance.debugSet(hero[1].url, 0.67);
      PhotoAspects.instance.debugSet(hero[0].url, 1.5);
      await pumpApp(tester, s, location: '/');
      final left = (total - 1).toString().padLeft(2, '0');
      expect(find.text('01 / $left'), findsOneWidget);
      expect(find.bySemanticsLabel(hero[0].title), findsWidgets);
      // Si scopre dopo, mentre gira: anche questa esce, e si resta sulla
      // foto che si stava guardando.
      PhotoAspects.instance.debugSet(hero[2].url, 0.8);
      await tester.pump();
      final fewer = (total - 2).toString().padLeft(2, '0');
      expect(find.text('01 / $fewer'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('biografia senza team, anche se ne restano i dati', (
      tester,
    ) async {
      final s = await loadState(hugeData());
      expect(s.content.team, isNotEmpty);
      await pumpApp(tester, s, location: '/biografia');
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -100000),
      );
      await settle(tester, 800);
      expect(find.textContaining('Il team'), findsNothing);
      expect(find.textContaining('PERSONA 1'), findsNothing);
      expect(find.text('IL METODO'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('niente sezione servizi né scritte della fotocamera', (
      tester,
    ) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/');
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -100000),
      );
      await settle(tester, 800);
      expect(find.textContaining('RAW'), findsNothing);
      expect(find.textContaining('AF-S'), findsNothing);
      expect(find.text(s.content.servicesTitle), findsNothing);
      expect(find.text('Reportage di matrimonio'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('con una sola foto non c\'è scorrimento automatico', (
      tester,
    ) async {
      final s = await loadState({
        'gallery': [
          GalleryPhoto(id: 'solo', url: tinyPng, title: 'Unica').toJson(),
        ],
      });
      await pumpApp(tester, s, location: '/');
      await settle(tester, 9000);
      // La foto resta, senza contatore né frecce.
      expect(find.text('Unica'), findsOneWidget);
      expect(find.text('01 / 01'), findsNothing);
      expect(find.bySemanticsLabel('Foto successiva'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('la barra con quattro voci sta nelle larghezze di confine', (
      tester,
    ) async {
      for (final w in [900.0, 960.0, 1023.0, 1100.0]) {
        final s = await loadState(hugeData());
        await pumpApp(tester, s, location: '/lavori', size: Size(w, 700));
        expect(find.text('PREVENTIVO'), findsOneWidget, reason: '$w');
        expect(find.text('MENU'), findsNothing, reason: '$w');
        await disposeApp(tester);
      }
    });

    testWidgets('dalla barra si raggiungono tutte le pagine', (tester) async {
      final s = await loadState();
      await pumpApp(tester, s, location: '/');
      for (final (link, check) in [
        ('BIOGRAFIA', 'BIOGRAFIA'),
        ('LAVORI', 'OGNI LAVORO,\nUNA STORIA'),
        ('PREVENTIVO', 'RACCONTACI\nIL TUO EVENTO'),
      ]) {
        await tester.tap(find.text(link).first);
        await settle(tester);
        expect(navLink(tester, link).active, isTrue, reason: link);
        expect(find.text(check), findsWidgets, reason: link);
      }
      await tester.tap(find.text('HOME'));
      await settle(tester);
      expect(navLink(tester, 'HOME').active, isTrue);
      await disposeApp(tester);
    });
  });
}
