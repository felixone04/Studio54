import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../data/repository.dart';
import '../data/seed.dart';
import '../models/models.dart';
import '../services/google_calendar_service.dart';
import '../services/google_token.dart';

class AppState extends ChangeNotifier {
  AppState(this.repo);
  final Repository repo;

  bool loaded = false;
  bool adminAuthenticated = false;

  late SiteContent content;
  List<ServiceItem> services = [];
  List<ServicePackage> packages = [];
  List<GalleryPhoto> gallery = [];
  List<QuoteRequest> quotes = [];
  List<Appointment> appointments = [];
  AdminSettings settings = AdminSettings();

  final GoogleCalendarService calendar = GoogleCalendarService();

  // ---------------------------------------------------------------- load

  Future<void> load() async {
    final seed = Seed.content();
    final c = await repo.read('content');
    content = c is Map
        ? SiteContent.fromJson(Map<String, dynamic>.from(c), seed)
        : seed;

    services = await _list('services', ServiceItem.fromJson) ?? Seed.services();
    packages =
        await _list('packages', ServicePackage.fromJson) ?? Seed.packages();
    gallery = await _list('gallery', GalleryPhoto.fromJson) ?? Seed.gallery();
    quotes = await _list('quotes', QuoteRequest.fromJson) ?? [];
    appointments = await _list('appointments', Appointment.fromJson) ?? [];

    final s = await repo.read('settings');
    settings = s is Map
        ? AdminSettings.fromJson(Map<String, dynamic>.from(s))
        : AdminSettings();
    final until = settings.sessionUntil;
    adminAuthenticated = until != null && DateTime.now().isBefore(until);

    loaded = true;
    notifyListeners();
  }

  Future<List<T>?> _list<T>(
    String key,
    T Function(Map<String, dynamic>) f,
  ) async {
    final v = await repo.read(key);
    if (v is! List) return null;
    return v.map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> _persist(String key, Object json) async {
    await repo.write(key, json);
    notifyListeners();
  }

  // -------------------------------------------------------- public views

  List<ServiceItem> get activeServices =>
      services.where((s) => s.active).toList();
  List<ServicePackage> get activePackages =>
      packages.where((p) => p.active).toList();
  List<GalleryPhoto> get heroPhotos {
    final h = gallery.where((p) => p.inHero).toList();
    return h.isEmpty ? gallery : h;
  }

  ServiceItem? serviceById(String id) {
    for (final s in services) {
      if (s.id == id) return s;
    }
    return null;
  }

  ServicePackage? packageById(String? id) {
    if (id == null) return null;
    for (final p in packages) {
      if (p.id == id) return p;
    }
    return null;
  }

  QuoteRequest? quoteById(String? id) {
    if (id == null) return null;
    for (final q in quotes) {
      if (q.id == id) return q;
    }
    return null;
  }

  // ------------------------------------------------------------ mutations

  Future<void> updateContent(SiteContent c) {
    content = c;
    return _persist('content', c.toJson());
  }

  Future<void> setServices(List<ServiceItem> list) {
    services = list;
    return _persist('services', list.map((e) => e.toJson()).toList());
  }

  Future<void> deleteService(String id) async {
    for (final p in packages) {
      p.serviceIds.remove(id);
    }
    await _persist('packages', packages.map((e) => e.toJson()).toList());
    await setServices(services.where((s) => s.id != id).toList());
  }

  Future<void> setPackages(List<ServicePackage> list) {
    packages = list;
    return _persist('packages', list.map((e) => e.toJson()).toList());
  }

  Future<void> setGallery(List<GalleryPhoto> list) {
    gallery = list;
    return _persist('gallery', list.map((e) => e.toJson()).toList());
  }

  Future<void> addQuote(QuoteRequest q) {
    quotes = [q, ...quotes];
    return _persist('quotes', quotes.map((e) => e.toJson()).toList());
  }

  Future<void> updateQuote(QuoteRequest q) {
    quotes = [for (final e in quotes) e.id == q.id ? q : e];
    return _persist('quotes', quotes.map((e) => e.toJson()).toList());
  }

  Future<void> deleteQuote(String id) {
    quotes = quotes.where((e) => e.id != id).toList();
    return _persist('quotes', quotes.map((e) => e.toJson()).toList());
  }

  Future<void> _persistAppointments() =>
      _persist('appointments', appointments.map((e) => e.toJson()).toList());

  // ---------------------------------------------------------- appointments

  /// Salva l'appuntamento in locale e, se Google è collegato, anche su Google
  /// Calendar. Restituisce un avviso se la sincronizzazione non è riuscita.
  Future<String?> saveAppointment(Appointment a) async {
    String? warning;
    if (calendar.connected) {
      try {
        if (a.googleEventId == null) {
          a.googleEventId = await calendar.insert(a);
        } else {
          await calendar.update(a);
        }
      } on GoogleAuthException catch (e) {
        warning = e.message;
      } catch (e) {
        warning = 'Sincronizzazione con Google non riuscita: $e';
      }
    } else if (settings.googleWasConnected) {
      warning = 'Appuntamento salvato solo qui: ricollega Google Calendar per sincronizzarlo.';
    }
    final i = appointments.indexWhere((e) => e.id == a.id);
    if (i >= 0) {
      appointments[i] = a;
    } else {
      appointments = [...appointments, a];
    }
    await _persistAppointments();
    return warning;
  }

  Future<String?> deleteAppointment(Appointment a) async {
    String? warning;
    if (a.googleEventId != null && calendar.connected) {
      try {
        await calendar.delete(a.googleEventId!);
      } on GoogleAuthException catch (e) {
        warning = e.message;
      } catch (e) {
        warning = 'Impossibile eliminarlo anche da Google Calendar: $e';
      }
    } else if (a.googleEventId != null) {
      warning = 'Eliminato qui, ma resta su Google Calendar: ricollegalo per rimuoverlo anche lì.';
    }
    appointments = appointments.where((e) => e.id != a.id).toList();
    for (final q in quotes) {
      if (q.appointmentId == a.id) q.appointmentId = null;
    }
    await _persist('quotes', quotes.map((e) => e.toJson()).toList());
    await _persistAppointments();
    return warning;
  }

  /// Invia a Google gli appuntamenti locali non ancora sincronizzati.
  Future<int> pushUnsyncedToGoogle() async {
    var n = 0;
    try {
      for (final a in appointments.where((e) => e.googleEventId == null)) {
        a.googleEventId = await calendar.insert(a);
        n++;
      }
    } finally {
      // Anche se uno degli invii fallisce, quelli già riusciti vanno salvati:
      // altrimenti al prossimo tentativo finirebbero doppi su Google.
      if (n > 0) await _persistAppointments();
    }
    return n;
  }

  // ----------------------------------------------------- Google Calendar

  String get googleClientId => settings.googleClientId.trim().isNotEmpty
      ? settings.googleClientId.trim()
      : AppConfig.googleClientId;

  bool get googleConfigured => googleClientId.isNotEmpty;

  Future<void> connectGoogle() async {
    await calendar.connect(googleClientId);
    settings.googleWasConnected = true;
    await _persist('settings', settings.toJson());
  }

  Future<void> disconnectGoogle() async {
    calendar.disconnect();
    settings.googleWasConnected = false;
    await _persist('settings', settings.toJson());
  }

  Future<void> saveGoogleClientId(String id) {
    settings.googleClientId = id.trim();
    return _persist('settings', settings.toJson());
  }

  // ------------------------------------------------------------ admin auth

  bool get hasAdminPassword => settings.passwordHash.isNotEmpty;

  String _hash(String salt, String pw) =>
      sha256.convert(utf8.encode('$salt::$pw')).toString();

  Future<void> setAdminPassword(String pw, {bool remember = true}) async {
    final r = Random.secure();
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => r.nextInt(256)),
    );
    settings.passwordSalt = salt;
    settings.passwordHash = _hash(salt, pw);
    adminAuthenticated = true;
    if (remember) _rememberSession();
    await _persist('settings', settings.toJson());
  }

  /// Verifica la password senza modificare lo stato di accesso.
  bool checkPassword(String pw) =>
      hasAdminPassword &&
      _hash(settings.passwordSalt, pw) == settings.passwordHash;

  Future<bool> login(String pw, {bool remember = true}) async {
    if (!checkPassword(pw)) return false;
    adminAuthenticated = true;
    if (remember) {
      _rememberSession();
      await _persist('settings', settings.toJson());
    } else {
      notifyListeners();
    }
    return true;
  }

  void _rememberSession() =>
      settings.sessionUntil = DateTime.now().add(const Duration(days: 30));

  Future<void> logout() async {
    adminAuthenticated = false;
    settings.sessionUntil = null;
    await _persist('settings', settings.toJson());
  }

  /// Caratteri occupati dalle immagini incorporate (data URL) nell'archivio del
  /// browser, che ha un limite di circa 5 MB.
  int get embeddedImageChars {
    var n = 0;
    void add(String u) {
      if (u.startsWith('data:')) n += u.length;
    }

    for (final p in gallery) {
      add(p.url);
    }
    for (final s in services) {
      add(s.image);
    }
    for (final p in packages) {
      add(p.image);
    }
    for (final t in content.team) {
      add(t.photo);
    }
    add(content.bioImage);
    add(content.bannerImage);
    return n;
  }

  /// Copia di sicurezza di tutti i dati in un'unica stringa JSON.
  String exportBackup() => const JsonEncoder.withIndent(' ').convert({
    'version': 1,
    'content': content.toJson(),
    'services': services.map((e) => e.toJson()).toList(),
    'packages': packages.map((e) => e.toJson()).toList(),
    'gallery': gallery.map((e) => e.toJson()).toList(),
    'quotes': quotes.map((e) => e.toJson()).toList(),
    'appointments': appointments.map((e) => e.toJson()).toList(),
  });

  Future<void> importBackup(String raw) async {
    const invalid = FormatException(
      'Il testo incollato non è una copia di sicurezza valida.',
    );
    final Object? j;
    try {
      j = jsonDecode(raw);
    } on FormatException {
      throw invalid;
    }
    if (j is! Map || j['content'] is! Map) throw invalid;
    // Prima di sovrascrivere i dati attuali verifica che ogni sezione si possa
    // leggere: un backup rovinato renderebbe il sito inutilizzabile anche
    // dopo aver ricaricato la pagina.
    final parsers = <String, Object Function(Map<String, dynamic>)>{
      'services': ServiceItem.fromJson,
      'packages': ServicePackage.fromJson,
      'gallery': GalleryPhoto.fromJson,
      'quotes': QuoteRequest.fromJson,
      'appointments': Appointment.fromJson,
    };
    try {
      SiteContent.fromJson(
        Map<String, dynamic>.from(j['content'] as Map),
        Seed.content(),
      );
      for (final MapEntry(key: k, value: parse) in parsers.entries) {
        final v = j[k];
        if (v == null) continue;
        for (final e in v as List) {
          parse(Map<String, dynamic>.from(e as Map));
        }
      }
    } catch (_) {
      throw invalid;
    }
    for (final k in [
      'content',
      'services',
      'packages',
      'gallery',
      'quotes',
      'appointments',
    ]) {
      if (j[k] != null) await repo.write(k, j[k] as Object);
    }
    await load();
  }

  Future<void> resetAll() async {
    await repo.write('content', Seed.content().toJson());
    await repo.write(
      'services',
      Seed.services().map((e) => e.toJson()).toList(),
    );
    await repo.write(
      'packages',
      Seed.packages().map((e) => e.toJson()).toList(),
    );
    await repo.write('gallery', Seed.gallery().map((e) => e.toJson()).toList());
    await load();
  }
}
