// Esporta i contenuti d'esempio dell'app in un file JSON per il sito
// HTML/PHP, così sito e app mostrano gli stessi testi, foto e lavori.
// Quando ci sarà il database su Hostinger questo file non servirà più.
//
// Uso (dalla cartella app):  dart run tool/export_seed.dart ../sito/data/contenuti.json
import 'dart:convert';
import 'dart:io';

import 'package:studio_fotografico/data/seed.dart';
import 'package:studio_fotografico/models/models.dart';

void main(List<String> args) {
  final out = args.isNotEmpty ? args.first : '../sito/data/contenuti.json';
  final now = DateTime(2026, 10, 24, 10);

  // Qualche richiesta e appuntamento d'esempio, solo per mostrare la grafica
  // dell'area riservata.
  final quotes = [
    QuoteRequest(
      id: 'q1',
      createdAt: now.subtract(const Duration(hours: 3)),
      firstName: 'Martina',
      lastName: 'Esposito',
      phone: '+39 333 482 1190',
      email: 'martina.esposito@example.com',
      eventType: 'Matrimonio',
      eventDate: DateTime(2027, 6, 12),
      location: 'Masseria in Valle d\'Itria',
      message: 'Circa 120 invitati, cerimonia all\'aperto al tramonto.',
      serviceIds: ['svc-wedding', 'svc-second', 'svc-album'],
    ),
    QuoteRequest(
      id: 'q2',
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      firstName: 'Luca',
      lastName: 'Ferri',
      phone: '+39 347 220 9815',
      email: 'luca.ferri@example.com',
      eventType: 'Battesimo',
      eventDate: DateTime(2027, 3, 21),
      location: 'Roma',
      serviceIds: ['svc-ceremony', 'svc-prints'],
      status: QuoteStatus.contattata,
    ),
    QuoteRequest(
      id: 'q3',
      createdAt: now.subtract(const Duration(days: 4)),
      firstName: 'Giorgia',
      lastName: 'Conti',
      phone: '+39 320 771 4402',
      email: 'giorgia.conti@example.com',
      eventType: 'Compleanno / 18 anni',
      eventDate: DateTime(2026, 12, 5),
      location: 'Milano',
      message: 'Festa a sorpresa, ci piacerebbe il photo booth.',
      serviceIds: ['svc-party', 'svc-booth'],
      packageId: 'pkg-party',
      status: QuoteStatus.confermata,
    ),
    QuoteRequest(
      id: 'q4',
      createdAt: now.subtract(const Duration(days: 9)),
      firstName: 'Paolo',
      lastName: 'Marino',
      phone: '+39 06 4433 2211',
      email: 'paolo.marino@example.com',
      eventType: 'Evento aziendale',
      eventDate: DateTime(2027, 1, 30),
      location: 'Torino',
      serviceIds: ['svc-events', 'svc-video'],
    ),
  ];
  final appointments = [
    Appointment(
      id: 'a1',
      title: 'Incontro con Martina Esposito · Matrimonio',
      start: DateTime(2026, 10, 28, 10),
      end: DateTime(2026, 10, 28, 11),
      location: 'Studio',
      quoteId: 'q1',
    ),
    Appointment(
      id: 'a2',
      title: 'Sopralluogo masseria',
      start: DateTime(2026, 11, 3, 15),
      end: DateTime(2026, 11, 3, 17),
      location: 'Valle d\'Itria',
    ),
    Appointment(
      id: 'a3',
      title: 'Consegna album · Famiglia Ferri',
      start: DateTime(2026, 11, 12, 18),
      end: DateTime(2026, 11, 12, 18, 30),
      location: 'Studio',
    ),
    Appointment(
      id: 'a4',
      title: 'Festa di Giorgia',
      start: DateTime(2026, 12, 5),
      end: DateTime(2026, 12, 6),
      allDay: true,
      location: 'Milano',
      quoteId: 'q3',
    ),
  ];

  final data = {
    'content': Seed.content().toJson(),
    'services': Seed.services().map((e) => e.toJson()).toList(),
    'packages': Seed.packages().map((e) => e.toJson()).toList(),
    'gallery': Seed.gallery().map((e) => e.toJson()).toList(),
    'works': [
      for (final w in Seed.works()) {...w.toJson(), 'seasonLabel': w.seasonLabel},
    ],
    'quotes': quotes.map((e) => e.toJson()).toList(),
    'appointments': appointments.map((e) => e.toJson()).toList(),
    // Clienti d'esempio dell'area clienti (password: Seed.demoClientPassword).
    'clients': Seed.clients().map((e) => e.toJson()).toList(),
  };
  File(out)
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  stdout.writeln('Scritto $out');
}
