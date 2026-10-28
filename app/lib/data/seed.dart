import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/models.dart';

/// Foto d'esempio da Unsplash: il titolare le sostituisce con le proprie dal
/// gestionale. Si chiedono alla larghezza che serve (vedi PhotoImage).
String unsplash(String id, {int? w}) =>
    'https://images.unsplash.com/photo-$id?auto=format&fit=crop'
    '${w == null ? '' : '&w=$w'}&q=80';

/// Il file originale, in alta qualità (per i download dei clienti).
String unsplashOriginal(String id) =>
    'https://images.unsplash.com/photo-$id?q=100&fm=jpg';

/// Foto orizzontali d'esempio.
const _l = <int, String>{
  0: '1520854221256-17451cc331bf',
  1: '1606800052052-a08af7148866',
  2: '1532712938310-34cb3982ef74',
  4: '1591604466107-ec97de577aff',
  5: '1519225421980-715cb0215aed',
  6: '1515934751635-c81c6bc9a2d8',
  7: '1529636798458-92182e662485',
  10: '1591700331354-f7eea65d1ce8',
  11: '1545232979-8bf68ee9b1af',
  12: '1595407753234-0882f1e77954',
  16: '1549488497-94b52bddac5d',
  17: '1542764824-4cdbd6c92dbe',
  18: '1550005809-91ad75fb315f',
  19: '1519379169146-d4b170447caa',
  20: '1523264114838-feca761983c4',
  22: '1595467959776-8acfb0dc313f',
  23: '1475721042966-f829c9b42aab',
  24: '1606217239582-d9f72323bcd7',
  25: '1551890946-3e5446d3a71b',
  26: '1473652502225-6b6af0664e32',
  29: '1529634597503-139d3726fed5',
  30: '1604017011826-d3b4c23f8914',
  33: '1600270237614-d20aef1c8b14',
  34: '1580824456266-c578703e13da',
  35: '1520886272478-69aed2b3685b',
  36: '1511795409834-ef04bbd61622',
  37: '1523521803700-b3bcaeab0150',
  38: '1524824267900-2fa9cbf7a506',
  39: '1612599542558-f3022089fb38',
  40: '1525441273400-056e9c7517b3',
  41: '1629219219925-ea8de62f2d68',
  42: '1522413452208-996ff3f3e740',
  43: '1587271407850-8d438ca9fdf2',
  44: '1510076857177-7470076d4098',
  45: '1541020230467-e33e4f96f7fc',
  46: '1513151233558-d860c5398176',
  47: '1527529482837-4698179dc6ce',
  50: '1504196606672-aef5c9cefc92',
  51: '1502035618526-6b2f1f5bca1b',
  52: '1530103862676-de8c9debad1d',
  53: '1566516171511-1c411a59c8ba',
  57: '1574957973698-418ac4c877af',
};

/// Foto verticali d'esempio.
const _p = <int, String>{
  0: '1606216794079-73f85bbd57d5',
  1: '1607190074257-dd4b7af0309f',
  2: '1599142296733-1c1f2073e6de',
  3: '1606216794074-735e91aa2c92',
  4: '1550784718-990c6de52adf',
  5: '1574871786514-46e1680ea587',
  7: '1525258946800-98cfd641d0de',
  8: '1548313093-370cf4ba3892',
  9: '1492175742197-ed20dc5a6bed',
  10: '1596457221755-b96bc3a6df18',
  12: '1583939003579-730e3918a45a',
  13: '1523438885200-e635ba2c371e',
  14: '1606490194859-07c18c9f0968',
  15: '1606490208247-b65be3d94cd1',
  16: '1507915977619-6ccfe8003ae6',
  17: '1631225893179-4d6e349189c2',
  18: '1474867985807-96ca17098cc9',
  19: '1613089347756-366a788dacf6',
  21: '1546032996-6dfacbacbf3f',
  22: '1561287495-a3fe1fd28504',
  24: '1563808599481-34a342e44508',
  25: '1618566864264-fb013f791da4',
  26: '1607357910286-1ff94ac13c24',
  27: '1606216836537-eea72a939072',
  28: '1544592732-83bbbfc46783',
  29: '1550713450-94c9b4fc9f25',
  30: '1537633552985-df8429e8048b',
  31: '1502635385003-ee1e6a1a742d',
  32: '1561593367-66c79c2294e6',
  33: '1607861884586-c7cfaed16290',
};

/// Una foto d'esempio: 'L4' = orizzontale n. 4, 'P12' = verticale n. 12,
/// altrimenti l'id di Unsplash.
String _photoId(String ref) {
  final n = int.tryParse(ref.substring(1));
  if (n != null && ref.startsWith('L')) return _l[n]!;
  if (n != null && ref.startsWith('P')) return _p[n]!;
  return ref;
}

/// Video d'esempio (libero da diritti) per l'area clienti.
const demoVideo =
    'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4';

class Seed {
  static const accentSand = 0xFFB89B72;

  static SiteContent content() => SiteContent(
    studioName: 'Studio 54',
    tagline: 'Fotografia di matrimoni ed eventi',
    bioTitle: 'Chi siamo',
    bioIntro: 'Uno sguardo discreto.\nUna sola ossessione: la luce.',
    bioStory:
        'Raccontiamo matrimoni ed eventi come se ogni giornata fosse una '
        'mostra da allestire: con calma, attenzione e rispetto.\n\n'
        'Prima ascoltiamo. Poi cerchiamo la luce. Infine stampiamo: perché '
        'una foto vera si tocca.',
    bioImage: unsplash(_p[10]!),
    timeline: [
      Milestone(
        year: '01',
        title: 'Ascoltiamo',
        text: 'Ci raccontate chi siete e come immaginate la giornata.',
      ),
      Milestone(
        year: '02',
        title: 'Progettiamo',
        text: 'Sopralluogo, luce, tempi: niente lasciato al caso.',
      ),
      Milestone(
        year: '03',
        title: 'Scattiamo',
        text: 'Discreti e presenti, senza mettere in posa le emozioni.',
      ),
      Milestone(
        year: '04',
        title: 'Consegniamo',
        text: 'Foto e video in alta qualità, album e stampe fine art.',
      ),
    ],
    contacts: Contacts(
      phone: '+39 06 1234 5678',
      whatsapp: '+39 333 123 4567',
      email: 'info@studio54.example',
      address: 'Via Roma 12, 00100 Roma',
      hours: 'Lun–Ven 10–19 · Sabato su appuntamento',
      instagram: 'https://instagram.com/',
      facebook: 'https://facebook.com/',
      vat: 'P.IVA 00000000000',
    ),
    accent: accentSand,
  );

  /// Carosello del sito: solo foto orizzontali.
  static List<CarouselPhoto> carouselSite() => [
    for (final (i, ref) in ['L2', 'L33', 'L30', 'L19', 'L35', 'L4'].indexed)
      CarouselPhoto(id: 'cs${i + 1}', url: unsplash(_photoId(ref))),
  ];

  /// Carosello dell'app: solo foto verticali.
  static List<CarouselPhoto> carouselApp() => [
    for (final (i, ref) in ['P1', 'P2', 'P14', 'P21', 'P29', 'P27'].indexed)
      CarouselPhoto(id: 'ca${i + 1}', url: unsplash(_photoId(ref))),
  ];

  static Work _work(
    String id,
    String title,
    String category,
    String location,
    String date,
    String setting,
    List<String> refs, {
    bool featured = false,
  }) => Work(
    id: id,
    title: title,
    category: category,
    location: location,
    date: date,
    setting: setting,
    featured: featured,
    photos: [
      for (final (i, r) in refs.indexed)
        WorkPhoto(id: '$id-${i + 1}', url: unsplash(_photoId(r))),
    ],
  );

  static List<Work> works() => [
    _work(
      'w-giulia-marco',
      'Giulia & Marco',
      'Matrimonio',
      'Sperlonga',
      'Giugno 2024',
      'Mare',
      ['L33', 'P30', 'L1', 'P0', 'L44', 'L26', 'P13'],
      featured: true,
    ),
    _work(
      'w-sofia-luca',
      'Sofia & Luca',
      'Matrimonio',
      'Val d\'Orcia',
      'Settembre 2023',
      'Campagna',
      ['L30', 'P17', 'L7', 'P10', 'L36', 'L23', 'P24'],
      featured: true,
    ),
    _work(
      'w-anna-paolo',
      'Anna & Paolo',
      'Matrimonio',
      'Valle d\'Itria',
      'Maggio 2024',
      'Masseria',
      ['L4', 'P3', 'L5', 'P15', 'L41', 'P12', 'L6', 'P5'],
      featured: true,
    ),
    _work(
      'w-elena-davide',
      'Elena & Davide',
      'Matrimonio',
      'Dolomiti',
      'Dicembre 2023',
      'Montagna',
      ['L2', 'P9', 'L10', 'P22', 'L37', 'L25', 'P26'],
      featured: true,
    ),
    _work(
      'w-chiara-matteo',
      'Chiara & Matteo',
      'Matrimonio',
      'Lago di Como',
      'Luglio 2024',
      'Lago',
      ['L19', 'P27', 'L11', 'P8', 'L38', 'L20', 'P4'],
    ),
    _work(
      'w-martina-andrea',
      'Martina & Andrea',
      'Matrimonio',
      'Roma',
      'Ottobre 2023',
      'Chiesa',
      ['L12', 'P18', 'L24', 'P16', 'L39', 'L17', 'P7'],
    ),
    _work(
      'w-francesca-simone',
      'Francesca & Simone',
      'Matrimonio',
      'Colli Euganei',
      'Aprile 2024',
      'Villa',
      ['L35', 'P25', 'L0', 'P28', 'L40', 'L18', 'P19', 'L22'],
    ),
    _work(
      'w-serena-fabio',
      'Serena & Fabio',
      'Matrimonio',
      'Costiera Amalfitana',
      'Settembre 2024',
      'Mare',
      ['L34', 'P33', 'L42', 'P32', 'L43', 'L16', 'P31', 'L29'],
    ),
    _work(
      'w-giorgia-18',
      'I 18 anni di Giorgia',
      '18 anni',
      'Milano',
      'Marzo 2024',
      'Città',
      ['L47', 'L51', 'L50', 'L46', 'L45', 'L52'],
    ),
    _work(
      'w-battesimo-leo',
      'Il battesimo di Leo',
      'Battesimo',
      'Roma',
      'Febbraio 2025',
      'Chiesa',
      [
        'L53',
        'L57',
        '1515488042361-ee00e0ddd4e4',
        '1469371670807-013ccf25f16a',
        '1452587925148-ce544e77e70d',
      ],
    ),
  ];

  /// Il modulo preventivo: per ora si chiedono informazioni solo per i
  /// matrimoni. Gli altri tipi restano pronti, spenti.
  static QuoteForm quoteForm() => QuoteForm(
    eventTypes: [
      QuoteOption(id: 'ev-matrimonio', label: 'Matrimonio'),
      QuoteOption(id: 'ev-battesimo', label: 'Battesimo', active: false),
      QuoteOption(
        id: 'ev-comunione',
        label: 'Comunione / Cresima',
        active: false,
      ),
      QuoteOption(id: 'ev-18', label: '18 anni', active: false),
      QuoteOption(id: 'ev-azienda', label: 'Evento aziendale', active: false),
    ],
    requests: [
      QuoteOption(id: 'rq-reportage', label: 'Reportage fotografico'),
      QuoteOption(id: 'rq-video', label: 'Video del matrimonio'),
      QuoteOption(id: 'rq-prematrimonio', label: 'Servizio pre-matrimonio'),
      QuoteOption(id: 'rq-album', label: 'Album fine art'),
      QuoteOption(id: 'rq-drone', label: 'Riprese con drone'),
      QuoteOption(id: 'rq-secondo', label: 'Secondo fotografo'),
      QuoteOption(id: 'rq-stampe', label: 'Stampe e cornici'),
      QuoteOption(id: 'rq-booth', label: 'Photo booth', active: false),
    ],
  );

  /// Documento PDF d'esempio, pubblicato con il sito.
  static const demoPdf =
      'https://felixone04.github.io/Studio54/assets/demo/scheda-servizio.pdf';

  /// Password dei clienti d'esempio e del titolare (solo per provare).
  static const demoClientPassword = 'studio54';
  static const demoAdminUser = 'titolare';
  static const demoAdminPassword = 'studio54';

  static String demoHash(String salt, String pw) =>
      sha256.convert(utf8.encode('$salt::$pw')).toString();

  /// Accesso d'esempio del titolare al gestionale.
  static AdminSettings admin() => AdminSettings(
    username: demoAdminUser,
    passwordSalt: 'demo-admin',
    passwordHash: demoHash('demo-admin', demoAdminPassword),
  );

  /// Clienti d'esempio: ognuno con le foto e un video della sua festa,
  /// documenti e link.
  static List<ClientAccount> clients() {
    final works = {for (final w in Seed.works()) w.id: w};
    List<ClientMedia> media(String id, String workId, String poster) => [
      for (final (i, p) in works[workId]!.photos.indexed)
        ClientMedia(
          id: '$id-m${i + 1}',
          url: p.url,
          original: unsplashOriginal(
            RegExp(r'photo-([0-9a-f-]+)').firstMatch(p.url)![1]!,
          ),
          name: '${id.substring(3)}-${(i + 1).toString().padLeft(3, '0')}.jpg',
        ),
      ClientMedia(
        id: '$id-v1',
        url: demoVideo,
        isVideo: true,
        poster: poster,
        name: '${id.substring(3)}-video.mp4',
      ),
    ];
    ClientAccount client({
      required String id,
      required String name,
      required String email,
      required String username,
      required String phone,
      required String workId,
      required String title,
      required String date,
      required String location,
      required String welcome,
      required List<ClientFile> files,
    }) => ClientAccount(
      id: id,
      name: name,
      email: email,
      username: username,
      phone: phone,
      passwordSalt: 'demo-$id',
      passwordHash: demoHash('demo-$id', demoClientPassword),
      eventTitle: title,
      eventDate: date,
      location: location,
      welcome: welcome,
      media: media(id, workId, works[workId]!.coverUrl),
      files: files,
      createdAt: DateTime(2024, 6, 2),
    );
    return [
      client(
        id: 'cl-anna',
        name: 'Anna Ricci',
        email: 'anna.ricci@example.com',
        username: 'anna.paolo',
        phone: '+39 333 555 0101',
        workId: 'w-anna-paolo',
        title: 'Il matrimonio di Anna e Paolo',
        date: '18 maggio 2024',
        location: 'Masseria in Valle d\'Itria',
        welcome:
            'Ecco le foto e il video del vostro giorno: scaricateli quando '
            'volete, in alta qualità.',
        files: [
          ClientFile(
            id: 'cl-anna-f1',
            name: 'Scheda del servizio',
            url: demoPdf,
            note: 'Riepilogo di servizi, tempi di consegna e album.',
            addedAt: DateTime(2024, 4, 2),
          ),
        ],
      ),
      client(
        id: 'cl-elena',
        name: 'Elena Bianchi',
        email: 'elena.bianchi@example.com',
        username: 'elena.davide',
        phone: '+39 347 555 0202',
        workId: 'w-elena-davide',
        title: 'Il matrimonio di Elena e Davide',
        date: '9 dicembre 2023',
        location: 'Dolomiti',
        welcome: 'Il vostro inverno in quota, foto dopo foto.',
        files: [],
      ),
    ];
  }

  /// Richieste d'esempio, per vedere il gestionale già in funzione.
  static List<QuoteRequest> quotes([DateTime? at]) {
    final now = at ?? DateTime.now();
    return [
      QuoteRequest(
        id: 'q1',
        createdAt: now.subtract(const Duration(hours: 3)),
        firstName: 'Martina',
        lastName: 'Esposito',
        phone: '+39 333 482 1190',
        email: 'martina.esposito@example.com',
        eventType: 'Matrimonio',
        eventDate: DateTime(now.year + 1, 6, 12),
        location: 'Masseria in Valle d\'Itria',
        requests: [
          'Reportage fotografico',
          'Secondo fotografo',
          'Album fine art',
        ],
        message: 'Circa 120 invitati, cerimonia all\'aperto al tramonto.',
      ),
      QuoteRequest(
        id: 'q2',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        firstName: 'Luca',
        lastName: 'Ferri',
        phone: '+39 347 220 9815',
        email: 'luca.ferri@example.com',
        eventType: 'Matrimonio',
        eventDate: DateTime(now.year + 1, 9, 21),
        location: 'Lago di Como',
        requests: ['Reportage fotografico', 'Video del matrimonio'],
        source: 'app',
        status: QuoteStatus.contattata,
      ),
      QuoteRequest(
        id: 'q3',
        createdAt: now.subtract(const Duration(days: 4)),
        firstName: 'Giorgia',
        lastName: 'Conti',
        phone: '+39 320 771 4402',
        email: 'giorgia.conti@example.com',
        eventType: 'Matrimonio',
        eventDate: DateTime(now.year + 1, 5, 5),
        location: 'Roma',
        requests: ['Servizio pre-matrimonio', 'Riprese con drone'],
        message: 'Vorremmo qualche informazione sui tempi di consegna.',
        status: QuoteStatus.confermata,
        appointmentId: 'a1',
      ),
    ];
  }

  static List<Appointment> appointments([DateTime? at]) {
    final n = at ?? DateTime.now();
    final d = DateTime(n.year, n.month, n.day);
    return [
      Appointment(
        id: 'a1',
        title: 'Incontro con Giorgia Conti · Matrimonio',
        start: d.add(const Duration(days: 2, hours: 10)),
        end: d.add(const Duration(days: 2, hours: 11)),
        location: 'Studio',
        quoteId: 'q3',
      ),
      Appointment(
        id: 'a2',
        title: 'Sopralluogo in masseria',
        start: d.add(const Duration(days: 6, hours: 15)),
        end: d.add(const Duration(days: 6, hours: 17)),
        location: 'Valle d\'Itria',
      ),
      Appointment(
        id: 'a3',
        title: 'Consegna album · Anna e Paolo',
        start: d.add(const Duration(days: 13, hours: 18)),
        end: d.add(const Duration(days: 13, hours: 18, minutes: 30)),
        location: 'Studio',
      ),
    ];
  }
}
