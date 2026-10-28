// Generatori di dati di prova: un archivio "enorme" pieno di casi limite e un
// archivio vuoto. Tutto è prodotto come JSON grezzo, come se arrivasse dal
// dispositivo o dal database.

import 'dart:convert';
import 'dart:math';

import 'package:studio_fotografico/data/seed.dart';

/// Un PNG 1x1 valido, come quelli caricati dal dispositivo.
const tinyPng =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

const longText =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim '
    'veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea '
    'commodo consequat. Duis aute irure dolor in reprehenderit in voluptate '
    'velit esse cillum dolore eu fugiat nulla pariatur. ';

const unicode = 'Àçcèntí ✨📸 Ñandú — 日本語のテキスト «citazione» ';

const longWord =
    'Supercalifragilistichespiralidosoeancorapiùlungosenzaspazialcunoperdavvero';

String _cut(String s, int n) => s.length <= n ? s : s.substring(0, n);

String _url(int i) => switch (i % 4) {
  0 => tinyPng,
  1 => 'https://example.com/foto/$i.jpg',
  2 => '',
  _ => 'data:image/png;base64,@@@non-valido@@@',
};

Map<String, Object?> hugeData({int seed = 42}) {
  final r = Random(seed);
  final now = DateTime.now();
  String pick(List<String> l) => l[r.nextInt(l.length)];

  final carousel = [
    for (var i = 0; i < 60; i++)
      {'id': 'c$i', 'url': _url(i), 'active': i % 5 != 0},
  ];

  final works = <Map<String, Object?>>[
    // Tutto lungo e moltissime foto (stesso id di un lavoro d'esempio, così
    // la stessa rotta vale per entrambi gli archivi).
    {
      'id': 'w-giulia-marco',
      'title': 'Giulia & Marco ${_cut(longText, 180)} $longWord',
      'category': 'Matrimonio ${_cut(longText, 90)}',
      'location': 'Luogo ${_cut(longText, 160)} $unicode',
      'date': 'Giugno 2024 · ${_cut(longText, 70)}',
      'setting': longWord,
      'cover': tinyPng,
      'featured': true,
      'photos': [
        for (var k = 0; k < 61; k++)
          {'id': 'wp-$k', 'url': _url(k), 'caption': k.isOdd ? longText : ''},
      ],
    },
    // Nessuna foto e nessuna copertina.
    {'id': 'work-nofoto', 'title': longWord, 'photos': [], 'featured': true},
    // Campi mancanti e foto nulle: deve leggersi lo stesso.
    {'id': 'work-minimo', 'title': 'Minimo', 'photos': null},
    for (var i = 0; i < 40; i++)
      {
        'id': 'work-$i',
        'title': switch (i % 5) {
          0 => 'Lavoro $i',
          1 => 'Lavoro $i ${_cut(longText, 120)}',
          2 => '$unicode$i',
          3 => '$longWord$i',
          _ => '',
        },
        'category': i % 4 == 0
            ? ''
            : pick([
                'Matrimonio',
                'Battesimo',
                unicode.trim(),
                'Tipo $longWord',
              ]),
        'location': i % 3 == 0 ? '' : 'Luogo $i',
        'date': i % 2 == 0
            ? ''
            : '${pick(['Maggio', 'Agosto', 'Dicembre'])} ${1990 + i}',
        'setting': i % 3 == 0 ? '' : pick(['Mare', 'Montagna', longWord]),
        'cover': i % 3 == 0 ? '' : _url(i),
        'photos': [
          for (var k = 0; k < i % 6; k++)
            {'id': 'w$i-p$k', 'url': _url(k + i), 'caption': ''},
        ],
        'published': i % 4 != 3,
        'featured': i % 7 == 0,
        'onSite': i % 5 != 1,
        'onApp': i % 5 != 2,
      },
  ];

  final quoteForm = {
    'eventTypes': [
      for (var i = 0; i < 25; i++)
        {
          'id': 'ev$i',
          'label': i == 3
              ? ''
              : (i % 4 == 0
                    ? '$longWord$i'
                    : 'Evento $i ${_cut(longText, i * 3)}'),
          'active': i % 3 != 2,
        },
    ],
    'requests': [
      for (var i = 0; i < 40; i++)
        {
          'id': 'rq$i',
          'label': i % 6 == 0
              ? '$unicode$i'
              : 'Richiesta $i ${_cut(longText, i * 2)}',
          'active': i % 4 != 3,
        },
    ],
  };

  final statuses = ['nuova', 'contattata', 'confermata', 'archiviata'];
  final quotes = [
    for (var i = 0; i < 300; i++)
      {
        'id': 'q-$i',
        'createdAt': now.subtract(Duration(hours: i * 7)).toIso8601String(),
        'firstName': switch (i % 6) {
          0 => '',
          1 => 'Maria Giovanna Antonietta',
          2 => unicode.trim(),
          3 => longWord,
          _ => 'Nome$i',
        },
        'lastName': i % 5 == 0 ? '' : 'Cognome$i ${i % 9 == 0 ? longWord : ''}',
        'phone': i % 8 == 0 ? '' : '+39 333 ${1000000 + i}',
        'email': i % 10 == 0 ? '' : 'cliente$i@example.com',
        'eventType': i % 7 == 0 ? '' : pick(['Matrimonio', 'Altro: $unicode']),
        'eventDate': i % 3 == 0
            ? null
            : now.add(Duration(days: i - 100)).toIso8601String(),
        'location': i % 4 == 0 ? '' : 'Luogo ${_cut(longText, i % 90)}',
        'requests': [
          for (var k = 0; k < i % 9; k++)
            'Richiesta $k ${k == 3 ? longWord : ''}',
        ],
        'message': switch (i % 4) {
          0 => '',
          1 => longText * 6,
          2 => '$unicode\n\n${'riga\n' * 12}',
          _ => 'Breve nota $i',
        },
        'source': i.isEven ? 'sito' : 'app',
        'status': i % 25 == 0 ? 'stato-sconosciuto' : statuses[i % 4],
        'appointmentId': i % 10 == 0 ? 'a-${i ~/ 10}' : null,
      },
  ];

  final today = DateTime(now.year, now.month, now.day);
  final appointments = [
    for (var i = 0; i < 150; i++)
      () {
        final allDay = i % 6 == 0;
        final DateTime start = i < 40
            ? today.add(Duration(minutes: 8 * 60 + i * 15))
            : DateTime(
                today.year,
                today.month,
                today.day + (i - 80) * 2,
                9 + i % 10,
              );
        return {
          'id': 'a-$i',
          'title': switch (i % 4) {
            0 => 'Incontro $i',
            1 => 'Incontro $i ${_cut(longText, 150)}',
            2 => '$unicode$i',
            _ => '$longWord$i',
          },
          'start': start.toIso8601String(),
          'end': start
              .add(Duration(minutes: allDay ? 0 : 45))
              .toIso8601String(),
          'allDay': allDay,
          'location': i % 3 == 0 ? '' : 'Via ${_cut(longText, 20 + i % 80)}',
          'notes': i.isEven ? '' : longText,
          'quoteId': i % 10 == 0 ? 'q-${i * 10}' : null,
        };
      }(),
  ];

  final clients = [
    for (var i = 0; i < 30; i++)
      {
        'id': 'cl-$i',
        'name': i % 4 == 0 ? longWord : 'Cliente $i ${_cut(longText, i * 3)}',
        'email': 'cliente$i@example.com',
        'username': i.isEven ? 'utente$i' : '',
        'phone': i % 3 == 0 ? '' : '+39 333 ${2000000 + i}',
        'passwordSalt': 'demo-cl-$i',
        'passwordHash': Seed.demoHash('demo-cl-$i', Seed.demoClientPassword),
        'active': i % 5 != 4,
        'eventTitle': i % 3 == 0
            ? ''
            : 'Il matrimonio $i ${_cut(longText, i * 4)} $unicode',
        'eventDate': i.isOdd ? '' : '$i giugno 2024',
        'location': i % 4 == 1 ? '' : 'Luogo $i ${_cut(longText, i * 2)}',
        'welcome': i % 2 == 0 ? '' : longText * 2,
        'media': [
          for (var k = 0; k < (i == 0 ? 120 : i % 7); k++)
            {
              'id': 'm$i-$k',
              'url': k % 5 == 4 ? 'https://example.com/v$k.mp4' : _url(k),
              'original': k.isEven ? '' : _url(k + 1),
              'isVideo': k % 5 == 4,
              'poster': k % 10 == 4 ? _url(k) : '',
              'name': k % 3 == 0 ? '' : 'file $k $longWord.jpg',
            },
        ],
        'files': [
          for (var k = 0; k < i % 4; k++)
            {
              'id': 'f$i-$k',
              'name': k == 1 ? longText : 'Documento $k',
              'url': 'https://example.com/d$k.pdf',
              'isLink': k.isOdd,
              'note': k == 2 ? longText : '',
            },
        ],
      },
  ];

  final content = Seed.content().toJson()
    ..addAll({
      'studioName': 'Studio Lumen & Associati Fotografi',
      'bioTitle': 'Chi siamo $longWord',
      'bioIntro': '${_cut(longText, 140)}\n$unicode',
      'bioStory': [for (var i = 0; i < 12; i++) longText * (1 + i % 3)]
          .join('\n\n'),
      'bioImage': tinyPng,
      'timeline': [
        for (var i = 0; i < 60; i++)
          {
            'year': i % 7 == 0 ? '' : '${1960 + i}',
            'title': i % 5 == 0 ? '' : 'Tappa $i ${_cut(longText, i * 3)}',
            'text': i.isEven ? '' : longText,
          },
      ],
      'contacts': {
        'phone': '+39 06 1234 5678 / +39 333 000 0000 / +39 340 111 2222',
        'whatsapp': '+39 333 123 4567',
        'email': 'indirizzo.email.molto.lungo.dello.studio@dominio-lunghissimo.example.com',
        'address': 'Via ${_cut(longText, 140)} 12, 00100 Roma',
        'hours': 'Lun–Ven 10–19 · Sabato su appuntamento · $unicode',
        'instagram': 'https://instagram.com/',
        'facebook': '',
        'vat': 'P.IVA 00000000000 · ${_cut(longText, 80)}',
      },
    });

  return {
    'content': content,
    'carouselSite': carousel,
    'carouselApp': carousel,
    'works': works,
    'quoteForm': quoteForm,
    'quotes': quotes,
    'appointments': appointments,
    'clients': clients,
  };
}

/// Archivio senza foto, lavori, clienti e con testi vuoti; nel modulo restano
/// solo nome e un recapito.
Map<String, Object?> emptyData() {
  final content = Seed.content().toJson();
  for (final k in content.keys.toList()) {
    if (content[k] is String) content[k] = '';
  }
  content
    ..['timeline'] = []
    ..['contacts'] = {};
  return {
    'content': content,
    'carouselSite': [],
    'carouselApp': [],
    'works': [],
    'quoteForm': {
      'showEvent': false,
      'showDate': false,
      'showLocation': false,
      'showRequests': false,
      'showMessage': false,
      'askLastName': false,
      'askPhone': false,
      'askEmail': false,
      'eventTypes': [],
      'requests': [],
    },
    'quotes': [],
    'appointments': [],
    'clients': [],
  };
}

/// Copia profonda via JSON (per confronti).
Object? roundTrip(Object? v) => jsonDecode(jsonEncode(v));
