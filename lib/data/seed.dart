import '../models/models.dart';

/// Foto d'esempio da Unsplash: il titolare le sostituisce con le proprie
/// dall'area admin (Galleria).
String unsplash(String id, {int w = 1800}) =>
    'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=$w&q=80';

class Seed {
  static const accentSilver = 0xFFC9C5BC;

  static SiteContent content() => SiteContent(
    studioName: 'Liso Fotografi',
    tagline: 'Wedding & Events',
    heroKicker: 'Matrimoni · Eventi · Ritratti',
    heroTitle: 'Ogni scatto, un\'opera.',
    heroSubtitle: '',
    marquee: 'Matrimoni, Ritratti, Cerimonie, Eventi, Famiglie, Fine Art',
    manifestoTitle: 'Non fotografiamo momenti.\nFotografiamo emozioni.',
    manifestoText: '',
    highlights: [],
    galleryKicker: 'Portfolio',
    galleryTitle: 'Opere',
    galleryIntro: '',
    servicesTitle: 'Cosa facciamo',
    servicesIntro: '',
    bannerTitle: 'Parliamone.',
    bannerText: 'Ti richiamiamo noi.',
    bannerButton: 'Richiedi un preventivo',
    bannerImage: unsplash('1519741497674-611481863552', w: 2400),
    bioTitle: 'Chi siamo',
    bioIntro: 'Uno sguardo discreto.\nUna sola ossessione: la luce.',
    bioStory:
        'Raccontiamo matrimoni ed eventi come se ogni giornata fosse una '
        'mostra da allestire: con calma, attenzione e rispetto.\n\n'
        'Prima ascoltiamo. Poi cerchiamo la luce. Infine stampiamo: perché '
        'una foto vera si tocca.',
    bioImage: unsplash('1554048612-b6a482bc67e5', w: 1800),
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
        text: 'Galleria online, album e stampe fine art.',
      ),
    ],
    team: [
      TeamMember(
        name: 'Nome Cognome',
        role: 'Fondatore · Fotografo',
        bio: '',
        photo: unsplash('1507003211169-0a1dd7228f2d', w: 1000),
      ),
      TeamMember(
        name: 'Nome Cognome',
        role: 'Fotografa',
        bio: '',
        photo: unsplash('1544005313-94ddf0286df2', w: 1000),
      ),
      TeamMember(
        name: 'Nome Cognome',
        role: 'Album · Stampa',
        bio: '',
        photo: unsplash('1531746020798-e6953c6e8e04', w: 1000),
      ),
    ],
    teamTitle: 'Il team',
    contacts: Contacts(
      phone: '+39 06 1234 5678',
      whatsapp: '+39 333 123 4567',
      email: 'info@lisofotografi.example',
      address: 'Via Roma 12, 00100 Roma',
      hours: 'Lun–Ven 10–19 · Sabato su appuntamento',
      instagram: 'https://instagram.com/',
      facebook: 'https://facebook.com/',
      vat: 'P.IVA 00000000000',
    ),
    footerNote: '',
    accent: accentSilver,
    eventTypes: [
      'Matrimonio',
      'Battesimo',
      'Comunione / Cresima',
      'Compleanno / 18 anni',
      'Laurea',
      'Festa privata',
      'Evento aziendale',
      'Ritratti / famiglia',
      'Altro',
    ],
  );

  static List<ServiceItem> services() => [
    ServiceItem(
      id: 'svc-wedding',
      name: 'Reportage di matrimonio',
      description:
          'La giornata intera raccontata in modo naturale, dai '
          'preparativi al taglio della torta.',
      category: 'Fotografia',
      image: unsplash('1537633552985-df8429e8048b', w: 900),
      internalPrice: 1400,
    ),
    ServiceItem(
      id: 'svc-engagement',
      name: 'Servizio pre-matrimonio',
      description:
          'Una sessione rilassata a due, per sciogliere la tensione '
          'e avere le prime foto insieme.',
      category: 'Fotografia',
      image: unsplash('1516589178581-6cd7833ae3b2', w: 900),
      internalPrice: 250,
    ),
    ServiceItem(
      id: 'svc-ceremony',
      name: 'Cerimonie',
      description:
          'Battesimi, comunioni e cresime: i momenti in famiglia, '
          'senza perdere un sorriso.',
      category: 'Fotografia',
      image: unsplash('1469371670807-013ccf25f16a', w: 900),
      internalPrice: 450,
    ),
    ServiceItem(
      id: 'svc-party',
      name: 'Feste e compleanni',
      description:
          '18 anni, lauree, anniversari e feste a sorpresa: l\'energia '
          'della festa, catturata dal vivo.',
      category: 'Fotografia',
      image: unsplash('1530103862676-de8c9debad1d', w: 900),
      internalPrice: 380,
    ),
    ServiceItem(
      id: 'svc-portrait',
      name: 'Ritratti e book',
      description:
          'Sessioni in studio o in esterna, per te, per la famiglia o '
          'per il tuo lavoro.',
      category: 'Fotografia',
      image: unsplash('1531746020798-e6953c6e8e04', w: 900),
      internalPrice: 180,
    ),
    ServiceItem(
      id: 'svc-newborn',
      name: 'Neonati e famiglia',
      description:
          'Servizi dolci e senza fretta per i primi mesi, a casa o in '
          'studio.',
      category: 'Fotografia',
      image: unsplash('1515488042361-ee00e0ddd4e4', w: 900),
      internalPrice: 200,
    ),
    ServiceItem(
      id: 'svc-events',
      name: 'Eventi e concerti',
      description:
          'Eventi aziendali, serate e spettacoli: tutta l\'atmosfera, '
          'consegnata in tempi rapidi.',
      category: 'Fotografia',
      image: unsplash('1470229722913-7c0e2dbbafd3', w: 900),
      internalPrice: 500,
    ),
    ServiceItem(
      id: 'svc-video',
      name: 'Film dell\'evento',
      description:
          'Un montaggio cinematografico con le immagini e i suoni più '
          'belli della giornata.',
      category: 'Video',
      image: unsplash('1554048612-b6a482bc67e5', w: 900),
      internalPrice: 900,
    ),
    ServiceItem(
      id: 'svc-drone',
      name: 'Riprese con drone',
      description: 'Vedute dall\'alto di location, cerimonie e ricevimenti.',
      category: 'Video',
      image: unsplash('1492691527719-9d1e07e534b4', w: 900),
      internalPrice: 250,
    ),
    ServiceItem(
      id: 'svc-album',
      name: 'Album fine art',
      description:
          'Un libro cucito a mano, con carte pregiate e copertina '
          'personalizzata.',
      category: 'Prodotti',
      image: unsplash('1452587925148-ce544e77e70d', w: 900),
      internalPrice: 350,
    ),
    ServiceItem(
      id: 'svc-prints',
      name: 'Stampe e cornici',
      description:
          'Stampe su carta cotone, tele e cornici per dare spazio ai '
          'ricordi sulle vostre pareti.',
      category: 'Prodotti',
      image: unsplash('1519225421980-715cb0215aed', w: 900),
      internalPrice: 120,
    ),
    ServiceItem(
      id: 'svc-gallery',
      name: 'Galleria online privata',
      description:
          'Tutte le foto in alta risoluzione, da scaricare e condividere '
          'con parenti e amici.',
      category: 'Prodotti',
      image: unsplash('1511795409834-ef04bbd61622', w: 900),
      internalPrice: 60,
    ),
    ServiceItem(
      id: 'svc-second',
      name: 'Secondo fotografo',
      description:
          'Due punti di vista per non perdere nulla, soprattutto nelle '
          'cerimonie più affollate.',
      category: 'Extra',
      image: unsplash('1522673607200-164d1b6ce486', w: 900),
      internalPrice: 300,
    ),
    ServiceItem(
      id: 'svc-booth',
      name: 'Photo booth con stampa',
      description:
          'Divertimento per gli ospiti e un ricordo da portare a casa, '
          'stampato al momento.',
      category: 'Extra',
      image: unsplash('1492684223066-81342ee5ff30', w: 900),
      internalPrice: 350,
    ),
  ];

  static List<ServicePackage> packages() => [
    ServicePackage(
      id: 'pkg-essential',
      name: 'Essenziale',
      tagline: 'Per chi vuole l\'essenziale, fatto bene',
      description:
          'Il reportage della giornata con tutte le foto in galleria '
          'online privata.',
      serviceIds: ['svc-wedding', 'svc-gallery'],
      image: unsplash('1583939003579-730e3918a45a', w: 900),
    ),
    ServicePackage(
      id: 'pkg-story',
      name: 'Racconto',
      tagline: 'Il più scelto dalle coppie',
      description:
          'Dal servizio pre-matrimonio al libro finito: la storia '
          'completa, con due punti di vista.',
      serviceIds: [
        'svc-engagement',
        'svc-wedding',
        'svc-second',
        'svc-album',
        'svc-gallery',
      ],
      image: unsplash('1465495976277-4387d4b0b4c6', w: 900),
      featured: true,
    ),
    ServicePackage(
      id: 'pkg-cinema',
      name: 'Cinema',
      tagline: 'Foto, video e ricordi da toccare',
      description:
          'Un\'esperienza completa: fotografie, film con riprese '
          'aeree e stampe da incorniciare.',
      serviceIds: [
        'svc-wedding',
        'svc-video',
        'svc-drone',
        'svc-album',
        'svc-prints',
        'svc-gallery',
      ],
      image: unsplash('1511285560929-80b456fea0bc', w: 900),
    ),
    ServicePackage(
      id: 'pkg-party',
      name: 'Festa',
      tagline: 'Per compleanni, 18 anni e lauree',
      description:
          'La festa dal vivo con photo booth, per divertirvi e '
          'portarvi a casa i sorrisi.',
      serviceIds: ['svc-party', 'svc-booth', 'svc-gallery'],
      image: unsplash('1530103862676-de8c9debad1d', w: 900),
    ),
  ];

  static List<Work> works() => [
    Work(
      id: 'w-giulia-marco',
      title: 'Giulia & Marco',
      category: 'Matrimonio',
      location: 'Costa tirrenica',
      date: 'Giugno 2024',
      story:
          'Una giornata di vento e di sale. Dai preparativi in una casa '
          'affacciata sul mare fino all\'ultimo ballo sulla spiaggia, '
          'abbiamo seguito la luce senza mai interrompere la festa.',
      credits: 'Reportage · Secondo fotografo · Album fine art',
      photos: [
        WorkPhoto(
          url: unsplash('1537633552985-df8429e8048b', w: 2200),
          caption: 'Il velo e il mare',
        ),
        WorkPhoto(
          url: unsplash('1465495976277-4387d4b0b4c6', w: 2200),
          caption: 'Le fedi, poco prima della cerimonia',
        ),
        WorkPhoto(
          url: unsplash('1583939003579-730e3918a45a', w: 2200),
          caption: 'Pioggia di petali all\'uscita',
        ),
        WorkPhoto(
          url: unsplash('1460978812857-470ed1c77af0', w: 2200),
          caption: 'Un istante di silenzio',
        ),
        WorkPhoto(
          url: unsplash('1522673607200-164d1b6ce486', w: 2200),
          caption: 'Gli sposi tra gli invitati',
        ),
        WorkPhoto(
          url: unsplash('1519741497674-611481863552', w: 2200),
          caption: 'L\'ultima luce del giorno',
        ),
      ],
    ),
    Work(
      id: 'w-sofia-luca',
      title: 'Sofia & Luca',
      category: 'Matrimonio',
      location: 'Toscana',
      date: 'Settembre 2023',
      story:
          'Un casale tra le colline, cento palloncini e una promessa '
          'detta sottovoce. Un racconto tenero, fatto di sguardi e di '
          'piccoli gesti.',
      credits: 'Reportage · Film dell\'evento · Galleria online',
      photos: [
        WorkPhoto(
          url: unsplash('1511285560929-80b456fea0bc', w: 2200),
          caption: 'Il volo dei desideri',
        ),
        WorkPhoto(
          url: unsplash('1516589178581-6cd7833ae3b2', w: 2200),
          caption: 'Un cuore al tramonto',
        ),
        WorkPhoto(
          url: unsplash('1511795409834-ef04bbd61622', w: 2200),
          caption: 'La tavola apparecchiata',
        ),
        WorkPhoto(
          url: unsplash('1544005313-94ddf0286df2', w: 2200),
          caption: 'Luce d\'oro',
        ),
      ],
    ),
    Work(
      id: 'w-battesimo-leo',
      title: 'Il battesimo di Leo',
      category: 'Cerimonia',
      location: 'Roma',
      date: 'Aprile 2024',
      story:
          'Una mattina di primavera in famiglia: la chiesa piena di luce, '
          'i nonni emozionati e un piccolo protagonista che non ha mai '
          'smesso di sorridere.',
      credits: 'Reportage · Stampe e cornici',
      photos: [
        WorkPhoto(
          url: unsplash('1515488042361-ee00e0ddd4e4', w: 2200),
          caption: 'Primi giochi',
        ),
        WorkPhoto(
          url: unsplash('1469371670807-013ccf25f16a', w: 2200),
          caption: 'In famiglia',
        ),
        WorkPhoto(
          url: unsplash('1452587925148-ce544e77e70d', w: 2200),
          caption: 'L\'album, cucito a mano',
        ),
      ],
    ),
    Work(
      id: 'w-notte-estate',
      title: 'Notte d\'estate',
      category: 'Evento',
      location: 'Milano',
      date: 'Luglio 2023',
      story:
          'Una serata aziendale diventata concerto: luci, musica e mani '
          'al cielo. Foto consegnate la mattina dopo, pronte per i social.',
      credits: 'Eventi e concerti · Photo booth con stampa',
      photos: [
        WorkPhoto(
          url: unsplash('1470229722913-7c0e2dbbafd3', w: 2200),
          caption: 'La notte è nostra',
        ),
        WorkPhoto(
          url: unsplash('1492684223066-81342ee5ff30', w: 2200),
          caption: 'Il photo booth',
        ),
        WorkPhoto(
          url: unsplash('1530103862676-de8c9debad1d', w: 2200),
          caption: 'Colori di festa',
        ),
        WorkPhoto(
          url: unsplash('1492691527719-9d1e07e534b4', w: 2200),
          caption: 'Dietro le quinte',
        ),
      ],
    ),
  ];

  static List<GalleryPhoto> gallery() => [
    GalleryPhoto(
      id: 'g1',
      url: unsplash('1537633552985-df8429e8048b', w: 2200),
      title: 'Il velo e il mare',
      caption:
          'Il vento solleva il velo, loro non sentono altro che il '
          'rumore dell\'acqua.',
      category: 'Matrimonio',
      location: 'Costa tirrenica',
      year: '2023',
    ),
    GalleryPhoto(
      id: 'g2',
      url: unsplash('1583939003579-730e3918a45a', w: 2200),
      title: 'Pioggia di petali',
      caption: 'Il momento in cui tutta la festa respira insieme.',
      category: 'Matrimonio',
      location: 'Toscana',
      year: '2024',
    ),
    GalleryPhoto(
      id: 'g3',
      url: unsplash('1460978812857-470ed1c77af0', w: 2200),
      title: 'Sotto il velo',
      caption: 'Un istante di silenzio, in bianco e nero.',
      category: 'Matrimonio',
      location: 'Umbria',
      year: '2022',
    ),
    GalleryPhoto(
      id: 'g4',
      url: unsplash('1511285560929-80b456fea0bc', w: 2200),
      title: 'Il volo dei desideri',
      caption: 'Cento palloncini, cento desideri affidati al cielo.',
      category: 'Cerimonia',
      location: 'Lago di Bracciano',
      year: '2023',
    ),
    GalleryPhoto(
      id: 'g5',
      url: unsplash('1465495976277-4387d4b0b4c6', w: 2200),
      title: 'Due mani, una promessa',
      caption: 'Piccoli gesti che dicono tutto.',
      category: 'Dettagli',
      location: 'Roma',
      year: '2024',
    ),
    GalleryPhoto(
      id: 'g6',
      url: unsplash('1544005313-94ddf0286df2', w: 2200),
      title: 'Luce d\'oro',
      caption: 'L\'ultima ora del giorno regala i ritratti più sinceri.',
      category: 'Ritratto',
      location: 'Campagna romana',
      year: '2024',
    ),
    GalleryPhoto(
      id: 'g7',
      url: unsplash('1531746020798-e6953c6e8e04', w: 2200),
      title: 'Sguardo',
      caption: 'Uno sguardo che racconta più di mille pose.',
      category: 'Ritratto',
      location: 'Studio',
      year: '2023',
    ),
    GalleryPhoto(
      id: 'g8',
      url: unsplash('1515488042361-ee00e0ddd4e4', w: 2200),
      title: 'Primi giochi',
      caption: 'Il mondo visto da chi lo scopre per la prima volta.',
      category: 'Famiglia',
      location: 'A casa',
      year: '2024',
    ),
    GalleryPhoto(
      id: 'g9',
      url: unsplash('1470229722913-7c0e2dbbafd3', w: 2200),
      title: 'La notte è nostra',
      caption: 'Luci, voci e mani al cielo: l\'energia di una serata.',
      category: 'Eventi',
      location: 'Milano',
      year: '2023',
      inHero: false,
    ),
    GalleryPhoto(
      id: 'g10',
      url: unsplash('1516589178581-6cd7833ae3b2', w: 2200),
      title: 'Un cuore al tramonto',
      caption: 'Il sole ha scelto di stare in mezzo a noi.',
      category: 'Coppia',
      location: 'Puglia',
      year: '2022',
      inHero: false,
    ),
  ];
}
