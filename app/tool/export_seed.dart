// Esporta i dati d'esempio dell'app in due file JSON per il sito HTML/PHP,
// così sito, app e gestionale partono dagli stessi lavori, foto e testi:
//   contenuti.json  → quello che vede chiunque (caroselli, lavori, modulo)
//   gestionale.json → solo per il gestionale (richieste, calendario, clienti)
// Quando ci sarà il database su Cloudflare questi file non serviranno più.
//
// Uso (dalla cartella app):  dart run tool/export_seed.dart ../sito/data
import 'dart:convert';
import 'dart:io';

import 'package:studio_fotografico/data/seed.dart';

void main(List<String> args) {
  final dir = args.isNotEmpty ? args.first : '../sito/data';
  const json = JsonEncoder.withIndent('  ');

  void write(String name, Object data) {
    final f = File('$dir/$name')..createSync(recursive: true);
    f.writeAsStringSync('${json.convert(data)}\n');
    stdout.writeln('Scritto ${f.path}');
  }

  write('contenuti.json', {
    'content': Seed.content().toJson(),
    'carouselSite': Seed.carouselSite().map((e) => e.toJson()).toList(),
    'carouselApp': Seed.carouselApp().map((e) => e.toJson()).toList(),
    'works': Seed.works().map((e) => e.toJson()).toList(),
    'quoteForm': Seed.quoteForm().toJson(),
  });

  // Date d'esempio vicine a oggi, così il gestionale sembra in funzione.
  final now = DateTime.now();
  write('gestionale.json', {
    'quotes': Seed.quotes(now).map((e) => e.toJson()).toList(),
    'appointments': Seed.appointments(now).map((e) => e.toJson()).toList(),
    // Clienti d'esempio (password: Seed.demoClientPassword).
    'clients': Seed.clients().map((e) => e.toJson()).toList(),
    // Accesso d'esempio del titolare (password: Seed.demoAdminPassword).
    'admin': Seed.admin().toJson(),
  });
}
