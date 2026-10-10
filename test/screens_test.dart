// Apre ogni pagina (pubblica e riservata) su tutte le dimensioni di schermo,
// con i dati di esempio, con un archivio enorme e con un archivio vuoto.
// Qualsiasi errore di Flutter (overflow, assert, eccezioni) fa fallire il test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  '/pagina-inesistente',
];

const adminRoutes = [
  '/admin',
  '/admin/panoramica',
  '/admin/richieste',
  '/admin/calendario',
  '/admin/servizi',
  '/admin/pacchetti',
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
