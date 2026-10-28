// Apre ogni pagina (pubblica, area clienti e gestionale) su tutte le
// dimensioni di schermo, con i dati di esempio, con un archivio enorme e con
// un archivio vuoto. Qualsiasi errore di Flutter (overflow, assert,
// eccezioni) fa fallire il test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/data/seed.dart';
import 'package:studio_fotografico/pages/admin/admin_widgets.dart';
import 'package:studio_fotografico/state/app_state.dart';

import 'support/data.dart';
import 'support/harness.dart';

const publicRoutes = [
  '/',
  '/preventivo',
  '/biografia',
  '/lavori',
  '/area-clienti',
  // Esiste sia nei dati d'esempio sia nell'archivio enorme (lì con testi
  // lunghissimi e 61 foto); nell'archivio vuoto non esiste.
  '/lavori/w-giulia-marco',
  // Solo nell'archivio enorme: senza foto e senza copertina.
  '/lavori/work-nofoto',
  // Nascosto nell'archivio enorme.
  '/lavori/work-3',
  '/lavori/inesistente',
  '/pagina-inesistente',
];

const adminRoutes = [
  '/admin',
  '/admin/panoramica',
  '/admin/richieste',
  '/admin/calendario',
  '/admin/lavori',
  '/admin/preventivo',
  '/admin/biografia',
  '/admin/contatti',
  '/admin/carosello-sito',
  '/admin/carosello-app',
  '/admin/clienti',
  '/admin/impostazioni',
  '/admin/sezione-sconosciuta',
];

final datasets = <String, Map<String, Object?>? Function()>{
  'esempio': () => null,
  'enorme': hugeData,
  'vuoto': emptyData,
};

Future<AppState> _state(String dataset, {bool admin = false}) async {
  final s = await loadState(datasets[dataset]!());
  if (admin) {
    await s.loginAdmin(
      Seed.demoAdminUser,
      Seed.demoAdminPassword,
      remember: false,
    );
  }
  return s;
}

Future<void> _scrollToEnd(WidgetTester tester) async {
  final scroll = find.byType(SingleChildScrollView);
  if (scroll.evaluate().isEmpty) return;
  await tester.drag(scroll.first, const Offset(0, -100000));
  await settle(tester, 800);
}

void main() {
  setUpAll(setUpTestEnv);

  for (final dataset in datasets.keys) {
    for (final size in screenSizes) {
      group('$dataset ${sizeName(size)}', () {
        for (final route in publicRoutes) {
          testWidgets('pubblica $route', (tester) async {
            final s = await _state(dataset);
            await pumpApp(tester, s, location: route, size: size);
            expect(find.byType(Scaffold), findsWidgets);
            await _scrollToEnd(tester);
            await disposeApp(tester);
          });
        }

        testWidgets('area di un cliente', (tester) async {
          final s = await _state(dataset);
          final c = s.clients.firstOrNull;
          if (c != null) {
            s.clientId = c.id;
            c.active = true;
          }
          await pumpApp(tester, s, location: '/area-clienti', size: size);
          await _scrollToEnd(tester);
          await disposeApp(tester);
        });

        testWidgets('gestionale senza accesso', (tester) async {
          final s = await _state(dataset);
          await pumpApp(tester, s, location: '/admin/richieste', size: size);
          expect(find.text('Bentornato.'), findsOneWidget);
          await disposeApp(tester);
        });

        testWidgets('gestionale lavori: finestra di modifica', (tester) async {
          final s = await _state(dataset, admin: true);
          await pumpApp(tester, s, location: '/admin/lavori', size: size);
          final rows = find.byType(AdminListRow);
          if (rows.evaluate().isEmpty) {
            await tester.tap(find.text('Nuovo lavoro'));
          } else {
            // Il nome del lavoro: lontano da stella e occhio.
            await tester.tap(
              find
                  .descendant(of: rows.first, matching: find.byType(Text))
                  .first,
            );
          }
          await settle(tester, 800);
          expect(find.text('Salva'), findsOneWidget);
          await tester.drag(
            find
                .descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(Scrollable),
                )
                .first,
            const Offset(0, -100000),
          );
          await settle(tester, 800);
          await disposeApp(tester);
        });

        for (final route in adminRoutes) {
          testWidgets('gestionale $route', (tester) async {
            final s = await _state(dataset, admin: true);
            await pumpApp(tester, s, location: route, size: size);
            expect(find.text('Bentornato.'), findsNothing);
            await disposeApp(tester);
          });
        }
      });
    }
  }
}
