import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app.dart';
import 'data/repository.dart';
import 'state/app_state.dart';
import 'widgets/common.dart';

Future<void> main() async {
  appStartedAt = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');
  VisibilityDetectorController.instance.updateInterval = const Duration(
    milliseconds: 100,
  );

  final state = AppState(await LocalRepository.open());
  await state.load();

  // Nell'app il logo d'apertura lo disegna Flutter (sul web è in index.html).
  introInApp = !kIsWeb;
  appStartedAt = DateTime.now();
  runApp(ChangeNotifierProvider.value(value: state, child: const StudioApp()));
}
