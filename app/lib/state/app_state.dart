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
  List<CarouselPhoto> carouselSite = [];
  List<CarouselPhoto> carouselApp = [];
  List<Work> works = [];
  QuoteForm quoteForm = QuoteForm();
  List<QuoteRequest> quotes = [];
  List<Appointment> appointments = [];
  List<ClientAccount> clients = [];
  AdminSettings settings = AdminSettings();

  /// Il cliente entrato nella sua area da questo dispositivo.
  String? clientId;

  final GoogleCalendarService calendar = GoogleCalendarService();

  // ---------------------------------------------------------------- load

  Future<void> load() async {
    final seed = Seed.content();
    final c = await repo.read('content');
    content = c is Map
        ? SiteContent.fromJson(Map<String, dynamic>.from(c), seed)
        : seed;

    carouselSite =
        await _list('carouselSite', CarouselPhoto.fromJson) ??
        Seed.carouselSite();
    carouselApp =
        await _list('carouselApp', CarouselPhoto.fromJson) ??
        Seed.carouselApp();
    works = await _list('works', Work.fromJson) ?? Seed.works();
    final f = await repo.read('quoteForm');
    quoteForm = f is Map
        ? QuoteForm.fromJson(Map<String, dynamic>.from(f))
        : Seed.quoteForm();
    quotes = await _list('quotes', QuoteRequest.fromJson) ?? Seed.quotes();
    appointments =
        await _list('appointments', Appointment.fromJson) ??
        Seed.appointments();
    clients = await _list('clients', ClientAccount.fromJson) ?? Seed.clients();

    final s = await repo.read('settings');
    settings = s is Map
        ? AdminSettings.fromJson(Map<String, dynamic>.from(s))
        : AdminSettings();
    // Senza credenziali scelte vale l'accesso d'esempio del titolare.
    if (settings.passwordHash.isEmpty) {
      final d = Seed.admin();
      settings
        ..passwordHash = d.passwordHash
        ..passwordSalt = d.passwordSalt;
    }
    if (settings.username.trim().isEmpty) {
      settings.username = Seed.demoAdminUser;
    }
    final until = settings.sessionUntil;
    adminAuthenticated = until != null && DateTime.now().isBefore(until);

    final session = await repo.read('clientSession');
    clientId = session is String && clientById(session)?.active == true
        ? session
        : null;

    loaded = true;
    notifyListeners();
  }

  Future<List<T>?> _list<T>(
    String key,
    T Function(Map<String, dynamic>) f,
  ) async {
    final v = await repo.read(key);
    if (v is! List) return null;
    return [
      for (final e in v)
        if (e is Map) f(Map<String, dynamic>.from(e)),
    ];
  }

  Future<void> _persist(String key, Object json) async {
    await repo.write(key, json);
    notifyListeners();
  }

  // -------------------------------------------------------- public views

  List<String> _activeUrls(List<CarouselPhoto> l) => [
    for (final p in l)
      if (p.active && p.url.trim().isNotEmpty) p.url,
  ];

  /// Foto del carosello d'apertura per lo schermo in verticale.
  List<String> get appCarousel => _activeUrls(carouselApp);

  /// Foto del carosello d'apertura per lo schermo in orizzontale.
  List<String> get siteCarousel => _activeUrls(carouselSite);

  /// I lavori visibili nell'app.
  List<Work> get publishedWorks =>
      works.where((w) => w.published && w.onApp).toList();

  /// I lavori in evidenza nella home dell'app (al massimo quattro).
  List<Work> get featuredWorks =>
      publishedWorks.where((w) => w.featured).take(maxFeatured).toList();

  /// Contano solo i lavori in evidenza che si vedono (sul sito o nell'app).
  int get featuredCount => works
      .where((w) => w.featured && w.published && (w.onSite || w.onApp))
      .length;

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

  Future<void> setCarouselSite(List<CarouselPhoto> list) {
    carouselSite = list;
    return _persist('carouselSite', list.map((e) => e.toJson()).toList());
  }

  Future<void> setCarouselApp(List<CarouselPhoto> list) {
    carouselApp = list;
    return _persist('carouselApp', list.map((e) => e.toJson()).toList());
  }

  Future<void> setWorks(List<Work> list) {
    works = list;
    return _persist('works', list.map((e) => e.toJson()).toList());
  }

  /// Mette o toglie un lavoro dalla home. Falso se ce ne sono già quattro.
  Future<bool> setFeatured(Work w, bool on) async {
    if (on && !w.featured && featuredCount >= maxFeatured) return false;
    w.featured = on;
    await setWorks([...works]);
    return true;
  }

  Future<void> setQuoteForm(QuoteForm f) {
    quoteForm = f;
    return _persist('quoteForm', f.toJson());
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

  // -------------------------------------------------------------- clienti

  ClientAccount? clientById(String? id) {
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Il cliente collegato in questo momento, se l'account è ancora attivo.
  ClientAccount? get currentClient {
    final c = clientById(clientId);
    return c != null && c.active ? c : null;
  }

  Future<void> _persistClients() =>
      _persist('clients', clients.map((e) => e.toJson()).toList());

  /// Password facile da dettare: niente lettere che si confondono (l, I, O, 0).
  static String generatePassword([int length = 10]) {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  void _setClientPassword(ClientAccount c, String pw) {
    final r = Random.secure();
    c.passwordSalt = base64Url.encode(
      List<int>.generate(16, (_) => r.nextInt(256)),
    );
    c.passwordHash = _hash(c.passwordSalt, pw);
  }

  /// Crea l'account e restituisce la password generata, da mandare al
  /// cliente (resta salvata solo cifrata).
  Future<String> createClient(ClientAccount c) async {
    final pw = generatePassword();
    _setClientPassword(c, pw);
    clients = [c, ...clients];
    await _persistClients();
    return pw;
  }

  /// Nuova password per un cliente (ad esempio se l'ha dimenticata).
  Future<String> resetClientPassword(ClientAccount c) async {
    final pw = generatePassword();
    _setClientPassword(c, pw);
    await _persistClients();
    return pw;
  }

  Future<void> saveClient(ClientAccount c) {
    clients = [for (final e in clients) e.id == c.id ? c : e];
    return _persistClients();
  }

  Future<void> deleteClient(String id) async {
    clients = clients.where((e) => e.id != id).toList();
    if (clientId == id) await logoutClient();
    return _persistClients();
  }

  /// Vero se [login] (email o nome utente) è già usato da un altro account.
  bool loginTaken(String login, {String? exceptId}) {
    final l = login.trim().toLowerCase();
    if (l.isEmpty) return false;
    if (l == settings.username.trim().toLowerCase()) return true;
    return clients.any(
      (c) =>
          c.id != exceptId &&
          (c.email.trim().toLowerCase() == l ||
              c.username.trim().toLowerCase() == l),
    );
  }

  /// Verifica email (o nome utente) e password di un cliente.
  ClientAccount? checkClientLogin(String login, String pw) {
    final l = login.trim().toLowerCase();
    if (l.isEmpty) return null;
    for (final c in clients) {
      final match =
          c.email.trim().toLowerCase() == l ||
          (c.username.trim().isNotEmpty &&
              c.username.trim().toLowerCase() == l);
      if (c.active &&
          match &&
          c.passwordHash.isNotEmpty &&
          _hash(c.passwordSalt, pw) == c.passwordHash) {
        return c;
      }
    }
    return null;
  }

  /// Accesso dall'area clienti: un cliente entra nella sua area, il titolare
  /// (con le sue credenziali) nel gestionale.
  Future<SignIn> signIn(String login, String pw, {bool remember = true}) async {
    if (await loginAdmin(login, pw, remember: remember)) return SignIn.admin;
    final c = checkClientLogin(login, pw);
    if (c == null) return SignIn.wrong;
    c.lastLogin = DateTime.now();
    clientId = c.id;
    await repo.write('clientSession', c.id);
    await _persistClients();
    return SignIn.client;
  }

  Future<void> logoutClient() async {
    clientId = null;
    await _persist('clientSession', '');
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

  String _hash(String salt, String pw) =>
      sha256.convert(utf8.encode('$salt::$pw')).toString();

  /// Nuove credenziali del titolare (dalle Impostazioni).
  Future<void> setAdminCredentials(
    String username,
    String pw, {
    bool remember = true,
  }) async {
    final r = Random.secure();
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => r.nextInt(256)),
    );
    if (username.trim().isNotEmpty) settings.username = username.trim();
    // Password vuota: si cambia solo il nome utente.
    if (pw.isNotEmpty) {
      settings.passwordSalt = salt;
      settings.passwordHash = _hash(salt, pw);
    }
    adminAuthenticated = true;
    if (remember) _rememberSession();
    await _persist('settings', settings.toJson());
  }

  /// Verifica la password senza modificare lo stato di accesso.
  bool checkPassword(String pw) =>
      settings.passwordHash.isNotEmpty &&
      _hash(settings.passwordSalt, pw) == settings.passwordHash;

  Future<bool> loginAdmin(
    String username,
    String pw, {
    bool remember = true,
  }) async {
    final u = username.trim().toLowerCase();
    if (u != settings.username.trim().toLowerCase() || !checkPassword(pw)) {
      return false;
    }
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

  /// Caratteri occupati dalle immagini incorporate (data URL) nell'archivio
  /// del dispositivo.
  int get embeddedImageChars {
    var n = 0;
    void add(String u) {
      if (u.startsWith('data:')) n += u.length;
    }

    for (final p in [...carouselSite, ...carouselApp]) {
      add(p.url);
    }
    for (final w in works) {
      add(w.cover);
      for (final p in w.photos) {
        add(p.url);
      }
    }
    for (final c in clients) {
      for (final m in c.media) {
        add(m.url);
        add(m.original);
        add(m.poster);
      }
      for (final f in c.files) {
        add(f.url);
      }
    }
    add(content.bioImage);
    return n;
  }

  /// Copia di sicurezza di tutti i dati in un'unica stringa JSON.
  String exportBackup() => const JsonEncoder.withIndent(' ').convert({
    'version': 2,
    'content': content.toJson(),
    'carouselSite': carouselSite.map((e) => e.toJson()).toList(),
    'carouselApp': carouselApp.map((e) => e.toJson()).toList(),
    'works': works.map((e) => e.toJson()).toList(),
    'quoteForm': quoteForm.toJson(),
    'quotes': quotes.map((e) => e.toJson()).toList(),
    'appointments': appointments.map((e) => e.toJson()).toList(),
    'clients': clients.map((e) => e.toJson()).toList(),
  });

  static const _backupKeys = [
    'content',
    'carouselSite',
    'carouselApp',
    'works',
    'quoteForm',
    'quotes',
    'appointments',
    'clients',
  ];

  Future<void> importBackup(String raw) async {
    const invalid = FormatException(
      'Il testo incollato non è una copia di sicurezza valida.',
    );
    Object? j;
    try {
      j = jsonDecode(raw);
    } on FormatException {
      throw invalid;
    }
    // La copia scaricata dal gestionale sul computer divide i dati in
    // "pubblici" e "privati": qui si leggono tutti allo stesso livello.
    if (j is Map && j['pubblici'] is Map && j['privati'] is Map) {
      j = {...j['pubblici'] as Map, ...j['privati'] as Map};
    }
    if (j is! Map || j['content'] is! Map) throw invalid;
    // Prima di sovrascrivere i dati attuali verifica che ogni sezione si possa
    // leggere: un backup rovinato renderebbe l'app inutilizzabile.
    final parsers = <String, Object Function(Map<String, dynamic>)>{
      'carouselSite': CarouselPhoto.fromJson,
      'carouselApp': CarouselPhoto.fromJson,
      'works': Work.fromJson,
      'quotes': QuoteRequest.fromJson,
      'appointments': Appointment.fromJson,
      'clients': ClientAccount.fromJson,
    };
    try {
      SiteContent.fromJson(
        Map<String, dynamic>.from(j['content'] as Map),
        Seed.content(),
      );
      if (j['quoteForm'] != null) {
        QuoteForm.fromJson(Map<String, dynamic>.from(j['quoteForm'] as Map));
      }
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
    for (final k in _backupKeys) {
      if (j[k] != null) await repo.write(k, j[k] as Object);
    }
    await load();
  }

  /// Riporta testi, caroselli, lavori e modulo preventivo agli esempi.
  Future<void> resetAll() async {
    await repo.write('content', Seed.content().toJson());
    await repo.write(
      'carouselSite',
      Seed.carouselSite().map((e) => e.toJson()).toList(),
    );
    await repo.write(
      'carouselApp',
      Seed.carouselApp().map((e) => e.toJson()).toList(),
    );
    await repo.write('works', Seed.works().map((e) => e.toJson()).toList());
    await repo.write('quoteForm', Seed.quoteForm().toJson());
    await load();
  }
}

/// Esito di un accesso dall'area clienti.
enum SignIn { client, admin, wrong }
