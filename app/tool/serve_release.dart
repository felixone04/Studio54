// Serve la versione ottimizzata (`build/web`) su tutta la rete locale, così
// si può aprire il sito dal telefono collegato alla stessa Wi-Fi.
//
// Uso:  dart run tool/serve_release.dart [porta]      (predefinita 8080)
import 'dart:io';

const _types = <String, String>{
  'html': 'text/html; charset=utf-8',
  'js': 'application/javascript',
  'mjs': 'application/javascript',
  'json': 'application/json',
  'css': 'text/css',
  'wasm': 'application/wasm',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'svg': 'image/svg+xml',
  'ico': 'image/x-icon',
  'ttf': 'font/ttf',
  'otf': 'font/otf',
  'woff2': 'font/woff2',
  'bin': 'application/octet-stream',
  'frag': 'application/octet-stream',
};

Future<void> main(List<String> args) async {
  final port = int.tryParse(args.isNotEmpty ? args.first : '') ?? 8080;
  final root = Directory('build/web');
  if (!root.existsSync()) {
    stderr.writeln('Manca build/web: esegui prima "flutter build web --release".');
    exit(1);
  }
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('[release] sito servito su http://0.0.0.0:$port (tutta la rete locale)');
  await for (final req in server) {
    var path = Uri.decodeComponent(req.uri.path);
    if (path.endsWith('/')) path += 'index.html';
    var file = File('${root.path}$path');
    // Percorsi sconosciuti → index.html (il sito usa il routing con #).
    if (path.contains('..') || !file.existsSync()) {
      file = File('${root.path}/index.html');
    }
    final ext = file.path.split('.').last.toLowerCase();
    req.response.headers
      ..contentType = ContentType.parse(_types[ext] ?? 'application/octet-stream')
      ..set('Cache-Control', 'no-cache');
    await req.response.addStream(file.openRead());
    await req.response.close();
  }
}
