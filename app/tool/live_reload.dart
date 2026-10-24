// Avvia il sito in modalità sviluppo e, a ogni modifica salvata in `lib/`,
// esegue un riavvio a caldo: il browser collegato si aggiorna da solo.
//
// Uso:  dart run tool/live_reload.dart [porta] [host]   (predefiniti: 5173 localhost)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? args.first : '5173';
  // 0.0.0.0 rende il sito raggiungibile anche dagli altri dispositivi della
  // rete (es. il telefono sulla stessa Wi-Fi).
  final host = args.length > 1 ? args[1] : 'localhost';
  // dart.exe di Flutter sta in <flutter>/bin/cache/dart-sdk/bin/: risalgo a
  // <flutter>/bin, dove si trova flutter.bat.
  final flutterBin = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final flutter = Platform.isWindows ? '${flutterBin.path}\\flutter.bat' : 'flutter';

  stdout.writeln('[live] avvio del sito su http://localhost:$port ...');
  final proc = await Process.start(
    flutter,
    ['run', '-d', 'web-server', '--web-port', port, '--web-hostname', host],
    runInShell: true,
  );
  proc.stdout.transform(utf8.decoder).listen(stdout.write);
  proc.stderr.transform(utf8.decoder).listen(stderr.write);

  Timer? debounce;
  final changed = <String>{};
  Directory('lib').watch(recursive: true).listen((e) {
    if (!e.path.endsWith('.dart')) return;
    changed.add(e.path);
    debounce?.cancel();
    // Attende che le modifiche si fermino per un attimo prima di ricaricare.
    debounce = Timer(const Duration(seconds: 2), () {
      stdout.writeln('\n[live] ${changed.length} file modificati: aggiorno il sito...');
      changed.clear();
      proc.stdin.write('R');
    });
  });

  ProcessSignal.sigint.watch().listen((_) {
    proc.stdin.write('q');
  });
  exit(await proc.exitCode);
}
