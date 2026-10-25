// Apre ogni pagina (pubblica e riservata) su tutte le dimensioni di schermo,
// con i dati di esempio, con un archivio enorme e con un archivio vuoto.
// Qualsiasi errore di Flutter (overflow, assert, eccezioni) fa fallire il test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_fotografico/pages/admin/admin_widgets.dart';
import 'package:studio_fotografico/state/app_state.dart';

import 'support/data.dart';
import 'support/harness.dart';

const publicRoutes = [
  '/',
  '/preventivo',
  '/preventivo?s=svc-1',
  '/preventivo?p=pkg-1',
  '/preventivo?p=pkg-story',
  '/biografia',
  '/lavori',
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
  '/admin/clienti',
  '/admin/servizi',
  '/admin/pacchetti',
  '/admin/lavori',
  '/admin/galleria',
  '/admin/home',
  '/admin/biografia',
  '/admin/contatti',
  '/admin/impostazioni',
  '/admin/sezione-sconosciuta',
];

final datasets = <String, Map<String, Object?>? Function()>{
  'esempio': () => null,
  'enorme': hugeData,
  'vuoto': emptyData,
};

Future<AppState> _state(String dataset, {required bool admin}) async {
  final s = await loadState(datasets[dataset]!());
  if (admin) {
    await s.setAdminPassword('password-di-prova', remember: false);
  }
  return s;
}

void main() {
  setUpAll(setUpTestEnv);

  for (final dataset in datasets.keys) {
    for (final size in screenSizes) {
      group('$dataset ${sizeName(size)}', () {
        for (final route in publicRoutes) {
          testWidgets('pubblica $route', (tester) async {
            final s = await _state(dataset, admin: false);
            await pumpApp(tester, s, location: route, size: size);
            expect(find.byType(Scaffold), findsWidgets);
            // Scorre fino in fondo per far comparire tutte le sezioni.
            await tester.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, -100000),
            );
            await settle(tester, 800);
            await disposeApp(tester);
          });
        }

        testWidgets('admin login (primo accesso)', (tester) async {
          final s = await _state(dataset, admin: false);
          await pumpApp(tester, s, location: '/admin/richieste', size: size);
          expect(find.text('CREA E ENTRA'), findsOneWidget);
          await disposeApp(tester);
        });

        testWidgets('admin login (password già impostata)', (tester) async {
          final s = await _state(dataset, admin: true);
          await s.logout();
          await pumpApp(tester, s, location: '/admin', size: size);
          expect(find.text('ENTRA'), findsOneWidget);
          await disposeApp(tester);
        });

        testWidgets('lavoro: tavola aperta a tutto schermo', (tester) async {
          final s = await _state(dataset, admin: false);
          await pumpApp(
            tester,
            s,
            location: '/lavori/w-giulia-marco',
            size: size,
          );
          final plate = find.textContaining('TAV. 0');
          if (dataset == 'vuoto') {
            expect(plate, findsNothing);
          } else {
            // Al centro dello schermo, lontano dalla barra fissa.
            await Scrollable.ensureVisible(
              tester.element(plate.first),
              alignment: 0.5,
            );
            // Attende la fine della comparsa (Reveal dura 1,1 s).
            await settle(tester, 1600);
            await tester.tap(plate.first);
            await settle(tester, 800);
            expect(find.byTooltip('Chiudi'), findsOneWidget);
          }
          await disposeApp(tester);
        });

        testWidgets('admin lavori: finestra di modifica', (tester) async {
          final s = await _state(dataset, admin: true);
          await pumpApp(tester, s, location: '/admin/lavori', size: size);
          // Con dei lavori si apre il primo (il più carico), altrimenti uno
          // nuovo.
          final rows = find.byType(AdminListRow);
          if (rows.evaluate().isEmpty) {
            await tester.tap(find.text('Nuovo lavoro'));
          } else {
            await tester.tap(rows.first);
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
          testWidgets('admin $route', (tester) async {
            final s = await _state(dataset, admin: true);
            await pumpApp(tester, s, location: route, size: size);
            expect(find.text('CREA E ENTRA'), findsNothing);
            expect(find.text('ENTRA'), findsNothing);
            await disposeApp(tester);
          });
        }
      });
    }
  }
}
