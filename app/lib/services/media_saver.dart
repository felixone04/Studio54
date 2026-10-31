import 'dart:convert';
import 'dart:io';

import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

/// Un download non riuscito, con un messaggio da mostrare al cliente.
class SaveException implements Exception {
  const SaveException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Salva foto e video dell'area clienti nella galleria del telefono, nel
/// formato originale e in alta qualità (album "Studio 54").
abstract class MediaSaver {
  Future<void> save(ClientMedia m);
}

class GalleryMediaSaver implements MediaSaver {
  static const album = 'Studio 54';

  @override
  Future<void> save(ClientMedia m) async {
    if (!await Gal.hasAccess(toAlbum: true) &&
        !await Gal.requestAccess(toAlbum: true)) {
      throw const SaveException(
        'Per salvare le foto serve il permesso di accedere alla galleria.',
      );
    }
    final dir = await getTemporaryDirectory();
    // Con l'id: due file con lo stesso nome possono scaricarsi insieme.
    final file = File('${dir.path}/${m.id}-${_fileName(m)}');
    try {
      await _download(m.downloadUrl, file);
      if (m.isVideo) {
        await Gal.putVideo(file.path, album: album);
      } else {
        await Gal.putImage(file.path, album: album);
      }
    } on GalException catch (e) {
      throw SaveException(switch (e.type) {
        GalExceptionType.accessDenied => 'Permesso per la galleria negato.',
        GalExceptionType.notEnoughSpace => 'Spazio sul telefono esaurito.',
        _ => 'Il telefono non ha accettato il file.',
      });
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  /// Scrive il file a pezzi mentre arriva: un video di qualche GB non passa
  /// mai tutto dalla memoria del telefono.
  Future<void> _download(String url, File file) async {
    if (url.startsWith('data:')) {
      await file.writeAsBytes(
        base64Decode(url.substring(url.indexOf(',') + 1)),
        flush: true,
      );
      return;
    }
    final client = http.Client();
    try {
      final http.StreamedResponse r;
      try {
        r = await client.send(http.Request('GET', Uri.parse(url)));
      } catch (_) {
        throw const SaveException('Nessuna connessione: riprovate tra poco.');
      }
      if (r.statusCode != 200) {
        throw const SaveException(
          'Il file non è disponibile, riprovate più tardi.',
        );
      }
      final out = file.openWrite();
      try {
        await out.addStream(r.stream);
      } on FileSystemException {
        throw const SaveException('Spazio sul telefono esaurito.');
      } catch (_) {
        throw const SaveException('Download interrotto: riprovate tra poco.');
      } finally {
        await out.close().catchError((_) {});
      }
    } finally {
      client.close();
    }
  }

  String _fileName(ClientMedia m) {
    final ext = m.isVideo ? 'mp4' : 'jpg';
    final base = m.name.trim().isNotEmpty
        ? m.name.trim().replaceAll(RegExp(r'[^\w.\-]'), '_')
        : 'studio54-${m.id}';
    return base.contains('.') ? base : '$base.$ext';
  }
}

/// Il salvataggio usato dall'app (i test lo sostituiscono).
MediaSaver mediaSaver = GalleryMediaSaver();
