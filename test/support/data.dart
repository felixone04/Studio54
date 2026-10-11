// Generatori di dati di prova: un archivio "enorme" pieno di casi limite e un
// archivio vuoto. Tutto è prodotto come JSON grezzo, come se arrivasse dal
// browser.

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

Map<String, Object?> hugeData({int seed = 42}) {
  final r = Random(seed);
  final now = DateTime.now();
  String pick(List<String> l) => l[r.nextInt(l.length)];

  // ------------------------------------------------------------- servizi
  final categories = [
    'Fotografia',
    'Video',
    'Prodotti',
    'Extra',
    'Stampa fine art e album rilegati a mano',
    unicode.trim(),
    'Categoria ${'molto ' * 8}lunga',
    'Drone',
    'Ritratti',
    'Eventi aziendali',
    '',
  ];
  final services = <Map<String, Object?>>[];
  for (var i = 0; i < 80; i++) {
    services.add({
      'id': 'svc-$i',
      'name': switch (i % 7) {
        0 => 'Servizio $i',
        1 => 'Servizio $i ${_cut(longText, 160)}',
        2 => '$unicode$i',
        3 => '$longWord$i',
        4 => 'S$i',
        5 => 'Reportage completo della giornata con due fotografi $i',
        _ => 'Voce $i',
      },
      'description': i % 3 == 0 ? '' : longText * (1 + i % 3),
      'category': categories[i % categories.length],
      'image': switch (i % 5) {
        0 => '',
        1 => tinyPng,
        2 => 'https://example.com/img/$i.jpg',
        3 => 'data:image/png;base64,@@@non-valido@@@',
        _ => unsplash('1537633552985-df8429e8048b', w: 900),
      },
      'internalPrice': switch (i % 4) {
        0 => null,
        1 => 99.5 + i,
        2 => 1200,
        _ => 0.01,
      },
      'active': i % 6 != 0,
    });
  }

  // ------------------------------------------------------------ pacchetti
  final packages = <Map<String, Object?>>[];
  for (var i = 0; i < 40; i++) {
    final ids = <String>{
      if (i % 5 != 0)
        for (var k = 0; k < 1 + r.nextInt(12); k++) 'svc-${r.nextInt(80)}',
      if (i % 7 == 0) 'svc-eliminato-$i',
    }.toList();
    packages.add({
      'id': 'pkg-$i',
      'name': switch (i % 4) {
        0 => 'Pacchetto $i',
        1 => 'Pacchetto $i ${_cut(longText, 120)}',
        2 => '$longWord$i',
        _ => '$unicode$i',
      },
      'tagline': i % 3 == 0 ? '' : _cut(longText, 40 + i * 5),
      'description': i % 2 == 0 ? '' : longText,
      'serviceIds': ids,
      'image': i % 3 == 0 ? '' : (i % 3 == 1 ? tinyPng : 'https://x.y/$i.jpg'),
      'featured': i % 4 == 1,
      'active': i % 5 != 4,
    });
  }

  // -------------------------------------------------------------- galleria
  final gallery = <Map<String, Object?>>[];
  for (var i = 0; i < 200; i++) {
    gallery.add({
      'id': 'ph-$i',
      'url': switch (i % 4) {
        0 => tinyPng,
        1 => 'https://example.com/photo/$i.jpg',
        2 => '',
        _ => 'data:image/jpeg;base64,', // vuoto: dati mancanti
      },
      'title': switch (i % 5) {
        0 => 'Foto $i',
        1 => 'Foto $i ${_cut(longText, 200)}',
        2 => '',
        3 => '$unicode$i',
        _ => '$longWord$i',
      },
      'caption': i % 2 == 0 ? '' : longText,
      'category': i % 3 == 0 ? '' : pick(['Matrimonio', 'Ritratto', unicode]),
      'location': i % 4 == 0 ? '' : 'Luogo $i ${_cut(longText, i % 60)}',
      'year': i % 5 == 0 ? '' : '${1990 + i % 40}',
      'inHero': i % 3 != 0,
    });
  }

  // ------------------------------------------------------------- richieste
  final statuses = ['nuova', 'contattata', 'confermata', 'archiviata'];
  final quotes = <Map<String, Object?>>[];
  for (var i = 0; i < 300; i++) {
    final created = now.subtract(Duration(hours: i * 7 + r.nextInt(5)));
    quotes.add({
      'id': 'q-$i',
      'createdAt': created.toIso8601String(),
      'firstName': switch (i % 6) {
        0 => '',
        1 => 'Maria Giovanna Antonietta',
        2 => unicode.trim(),
        3 => longWord,
        _ => 'Nome$i',
      },
      'lastName': i % 5 == 0 ? '' : 'Cognome$i ${i % 9 == 0 ? longWord : ''}',
      'phone': i % 8 == 0 ? '' : '+39 333 ${1000000 + i}',
      'email': i % 10 == 0
          ? ''
          : (i % 10 == 1
                ? 'indirizzo.email.lunghissimo.$i.$longWord@dominio-molto-lungo.example.com'
                : 'cliente$i@example.com'),
      'eventType': i % 7 == 0 ? '' : pick(['Matrimonio', 'Altro: $unicode']),
      'eventDate': i % 3 == 0
          ? null
          : now.add(Duration(days: i - 100)).toIso8601String(),
      'message': switch (i % 4) {
        0 => '',
        1 => longText * 6,
        2 => '$unicode\n\n${'riga\n' * 12}',
        _ => 'Breve nota $i',
      },
      'serviceIds': [
        for (var k = 0; k < r.nextInt(10); k++) 'svc-${r.nextInt(90)}',
      ],
      'packageId': i % 4 == 0 ? null : (i % 4 == 1 ? 'pkg-${i % 40}' : 'pkg-x'),
      'status': i % 25 == 0 ? 'stato-sconosciuto' : statuses[i % 4],
      'appointmentId': i % 10 == 0 ? 'a-${i ~/ 10}' : null,
    });
  }

  // --------------------------------------------------------- appuntamenti
  final appointments = <Map<String, Object?>>[];
  final today = DateTime(now.year, now.month, now.day);
  for (var i = 0; i < 150; i++) {
    final DateTime start;
    final DateTime end;
    final allDay = i % 6 == 0;
    if (i < 40) {
      // Molti appuntamenti nello stesso giorno (oggi).
      start = today.add(Duration(minutes: 8 * 60 + i * 15));
      end = start.add(const Duration(minutes: 45));
    } else if (i % 9 == 0) {
      // Termina a mezzanotte.
      final d = DateTime(today.year, today.month, today.day + (i - 80));
      start = DateTime(d.year, d.month, d.day, 21);
      end = DateTime(d.year, d.month, d.day + 1);
    } else {
      final d = DateTime(today.year, today.month, today.day + (i - 80) * 2);
      start = allDay
          ? d
          : DateTime(d.year, d.month, d.day, 9 + i % 10, (i * 7) % 60);
      end = allDay ? d : start.add(Duration(minutes: 30 + (i % 5) * 60));
    }
    appointments.add({
      'id': 'a-$i',
      'title': switch (i % 5) {
        0 => 'Incontro $i',
        1 => 'Incontro $i ${_cut(longText, 150)}',
        2 => '$unicode$i',
        3 => '$longWord$i',
        _ => 'A$i',
      },
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'allDay': allDay,
      'location': i % 3 == 0 ? '' : 'Via ${_cut(longText, 20 + i % 80)}',
      'notes': i % 2 == 0 ? '' : longText,
      'quoteId': i % 10 == 0
          ? 'q-${i * 10}'
          : (i % 13 == 0 ? 'q-eliminata' : null),
      'googleEventId': i % 11 == 0 ? 'gev-$i' : null,
    });
  }

  // --------------------------------------------------------------- contenuti
  final content = Seed.content().toJson()
    ..addAll({
      'studioName': 'Studio Lumen & Associati Fotografi',
      'heroKicker': 'Matrimoni · Ritratti · Eventi · ${_cut(longText, 60)}',
      'heroTitle': 'Ogni scatto,\nun\'opera.\n$unicode',
      'manifestoTitle': '${_cut(longText, 120)}\n$unicode\n$longWord',
      'galleryTitle': 'Opere $longWord',
      'servicesTitle': 'Cosa facciamo davvero, tutti i giorni',
      'bioTitle': 'Chi siamo $longWord',
      'bioIntro': '${_cut(longText, 140)}\n$unicode',
      'bioStory': [for (var i = 0; i < 12; i++) longText * (1 + i % 3)]
          .join('\n\n'),
      'bioImage': tinyPng,
      'teamTitle': 'Il team $longWord',
      'timeline': [
        for (var i = 0; i < 60; i++)
          {
            'year': i % 7 == 0
                ? ''
                : (i % 7 == 1 ? 'Primavera ${1960 + i}' : '${1960 + i}'),
            'title': i % 5 == 0 ? '' : 'Tappa $i ${_cut(longText, i * 3)}',
            'text': i % 2 == 0 ? '' : longText,
          },
      ],
      'team': [
        for (var i = 0; i < 45; i++)
          {
            'id': 't-$i',
            'name': i % 4 == 0
                ? ''
                : 'Persona $i ${i % 3 == 0 ? longWord : ''}',
            'role': i % 5 == 0 ? '' : 'Ruolo $i ${_cut(longText, i * 2)}',
            'bio': i % 2 == 0 ? '' : longText,
            'photo': i % 3 == 0
                ? ''
                : (i % 3 == 1 ? tinyPng : 'https://a.b/$i.jpg'),
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
      'eventTypes': [
        'Matrimonio',
        'Altro',
        unicode.trim(),
        'Tipo ${_cut(longText, 100)}',
        for (var i = 0; i < 30; i++) 'Evento $i',
      ],
    });

  return {
    'content': content,
    'services': services,
    'packages': packages,
    'gallery': gallery,
    'quotes': quotes,
    'appointments': appointments,
  };
}

/// Archivio senza galleria, servizi, pacchetti e con testi vuoti.
Map<String, Object?> emptyData() {
  final content = Seed.content().toJson();
  for (final k in content.keys.toList()) {
    if (content[k] is String) content[k] = '';
  }
  content
    ..['highlights'] = []
    ..['timeline'] = []
    ..['team'] = []
    ..['eventTypes'] = []
    ..['contacts'] = {};
  return {
    'content': content,
    'services': [],
    'packages': [],
    'gallery': [],
    'quotes': [],
    'appointments': [],
  };
}

/// Copia profonda via JSON (per confronti).
Object? roundTrip(Object? v) => jsonDecode(jsonEncode(v));
