import 'dart:math';

// I dati di Studio 54, gli stessi per sito, app e gestionale: oggi vivono nel
// dispositivo (o nel browser), domani nel database. I nomi dei campi JSON
// sono quelli letti anche dal sito (sito/assets/js).

int _idSeq = 0;

/// Genera un id univoco leggero (niente dipendenze extra). Il contatore
/// evita doppioni anche quando se ne creano molti nello stesso istante.
String newId() {
  final r = Random();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${(_idSeq++).toRadixString(36)}'
      '${r.nextInt(1 << 20).toRadixString(36)}';
}

List<T> _listOf<T>(Object? v, T Function(Map<String, dynamic>) f) => [
  if (v is List)
    for (final e in v)
      if (e is Map) f(Map<String, dynamic>.from(e)),
];

class Milestone {
  String year;
  String title;
  String text;
  Milestone({required this.year, required this.title, required this.text});

  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
    year: j['year'] ?? '',
    title: j['title'] ?? '',
    text: j['text'] ?? '',
  );
  Map<String, dynamic> toJson() => {'year': year, 'title': title, 'text': text};
}

class Contacts {
  String phone;
  String whatsapp;
  String email;
  String address;
  String hours;
  String instagram;
  String facebook;
  String vat;
  Contacts({
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.address = '',
    this.hours = '',
    this.instagram = '',
    this.facebook = '',
    this.vat = '',
  });

  factory Contacts.fromJson(Map<String, dynamic> j) => Contacts(
    phone: j['phone'] ?? '',
    whatsapp: j['whatsapp'] ?? '',
    email: j['email'] ?? '',
    address: j['address'] ?? '',
    hours: j['hours'] ?? '',
    instagram: j['instagram'] ?? '',
    facebook: j['facebook'] ?? '',
    vat: j['vat'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'phone': phone,
    'whatsapp': whatsapp,
    'email': email,
    'address': address,
    'hours': hours,
    'instagram': instagram,
    'facebook': facebook,
    'vat': vat,
  };
}

/// Testi e dati generali, uguali su sito e app: nome, biografia, contatti.
class SiteContent {
  String studioName;
  String tagline;

  // Biografia
  String bioTitle;
  String bioIntro;
  String bioStory; // paragrafi separati da riga vuota
  String bioImage;
  List<Milestone> timeline;

  Contacts contacts;
  int accent; // colore ARGB

  SiteContent({
    required this.studioName,
    required this.tagline,
    required this.bioTitle,
    required this.bioIntro,
    required this.bioStory,
    required this.bioImage,
    required this.timeline,
    required this.contacts,
    required this.accent,
  });

  factory SiteContent.fromJson(Map<String, dynamic> j, SiteContent fallback) {
    String s(String k, String d) => (j[k] as String?) ?? d;
    return SiteContent(
      studioName: s('studioName', fallback.studioName),
      tagline: s('tagline', fallback.tagline),
      bioTitle: s('bioTitle', fallback.bioTitle),
      bioIntro: s('bioIntro', fallback.bioIntro),
      bioStory: s('bioStory', fallback.bioStory),
      bioImage: s('bioImage', fallback.bioImage),
      timeline: j['timeline'] is List
          ? _listOf(j['timeline'], Milestone.fromJson)
          : fallback.timeline,
      contacts: j['contacts'] is Map
          ? Contacts.fromJson(Map<String, dynamic>.from(j['contacts']))
          : fallback.contacts,
      accent: (j['accent'] as int?) ?? fallback.accent,
    );
  }

  Map<String, dynamic> toJson() => {
    'studioName': studioName,
    'tagline': tagline,
    'bioTitle': bioTitle,
    'bioIntro': bioIntro,
    'bioStory': bioStory,
    'bioImage': bioImage,
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'contacts': contacts.toJson(),
    'accent': accent,
  };

  /// Copia profonda, usata dagli editor del gestionale per lavorare su una bozza.
  SiteContent copy() => SiteContent.fromJson(toJson(), this);
}

/// Una foto del carosello d'apertura: orizzontali per il sito, verticali per
/// l'app (sono due elenchi separati).
class CarouselPhoto {
  String id;
  String url;
  bool active;
  CarouselPhoto({String? id, required this.url, this.active = true})
    : id = id ?? newId();

  factory CarouselPhoto.fromJson(Map<String, dynamic> j) => CarouselPhoto(
    id: j['id'],
    url: j['url'] ?? '',
    active: j['active'] ?? true,
  );
  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'active': active};
}

/// Una foto all'interno di un lavoro (orizzontale o verticale).
class WorkPhoto {
  String id;
  String url;
  String caption; // solo per il gestionale e l'accessibilità: non si mostra
  WorkPhoto({String? id, required this.url, this.caption = ''})
    : id = id ?? newId();

  factory WorkPhoto.fromJson(Map<String, dynamic> j) =>
      WorkPhoto(id: j['id'], url: j['url'] ?? '', caption: j['caption'] ?? '');
  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'caption': caption};
}

/// Stagioni proposte nel filtro dei lavori.
const seasons = ['Primavera', 'Estate', 'Autunno', 'Inverno'];

/// Tipi di location suggeriti nel gestionale (se ne possono scrivere altri).
const settingSuggestions = [
  'Masseria',
  'Mare',
  'Montagna',
  'Natura',
  'Lago',
  'Campagna',
  'Villa',
  'Città',
  'Chiesa',
];

const _monthSeason = {
  'gennaio': 'Inverno',
  'febbraio': 'Inverno',
  'marzo': 'Primavera',
  'aprile': 'Primavera',
  'maggio': 'Primavera',
  'giugno': 'Estate',
  'luglio': 'Estate',
  'agosto': 'Estate',
  'settembre': 'Autunno',
  'ottobre': 'Autunno',
  'novembre': 'Autunno',
  'dicembre': 'Inverno',
};

/// Stagione ricavata dal mese scritto nella data ("Giugno 2024" → Estate).
String seasonFromDate(String date) {
  final d = date.toLowerCase();
  for (final e in _monthSeason.entries) {
    if (d.contains(e.key)) return e.value;
  }
  return '';
}

/// Al massimo quattro lavori in evidenza nella home.
const maxFeatured = 4;

/// Un lavoro realizzato (un matrimonio, un evento…): copertina, poche
/// informazioni e la sequenza delle foto.
class Work {
  String id;
  String title; // il nome dei festeggiati, es. "Giulia & Marco"
  String category; // tipologia, es. "Matrimonio"
  String location;
  String date; // testo libero, es. "Giugno 2024"
  String season; // vuota = ricavata dalla data
  String setting; // tipo di location, es. "Masseria", "Mare"
  String cover;
  List<WorkPhoto> photos;
  bool published;
  bool featured; // in evidenza nella home
  bool onSite;
  bool onApp;
  Work({
    String? id,
    required this.title,
    this.category = '',
    this.location = '',
    this.date = '',
    this.season = '',
    this.setting = '',
    this.cover = '',
    List<WorkPhoto>? photos,
    this.published = true,
    this.featured = false,
    this.onSite = true,
    this.onApp = true,
  }) : id = id ?? newId(),
       photos = photos ?? [];

  /// Copertina: quella scelta, altrimenti la prima foto.
  String get coverUrl => cover.trim().isNotEmpty
      ? cover
      : (photos.isEmpty ? '' : photos.first.url);

  /// Stagione scelta, altrimenti quella del mese indicato nella data.
  String get seasonLabel =>
      season.trim().isNotEmpty ? season.trim() : seasonFromDate(date);

  factory Work.fromJson(Map<String, dynamic> j) => Work(
    id: j['id'],
    title: j['title'] ?? '',
    category: j['category'] ?? '',
    location: j['location'] ?? '',
    date: j['date'] ?? '',
    season: j['season'] ?? '',
    setting: j['setting'] ?? '',
    cover: j['cover'] ?? '',
    photos: _listOf(j['photos'], WorkPhoto.fromJson),
    published: j['published'] ?? true,
    featured: j['featured'] ?? false,
    onSite: j['onSite'] ?? true,
    onApp: j['onApp'] ?? true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'location': location,
    'date': date,
    'season': season,
    'setting': setting,
    'cover': cover,
    'photos': photos.map((e) => e.toJson()).toList(),
    'published': published,
    'featured': featured,
    'onSite': onSite,
    'onApp': onApp,
  };
}

// ---------------------------------------------------------------- preventivo

/// Una voce del modulo preventivo (un tipo di evento o una richiesta) che il
/// titolare può aggiungere, rinominare, spegnere e riaccendere.
class QuoteOption {
  String id;
  String label;
  bool active;
  QuoteOption({String? id, required this.label, this.active = true})
    : id = id ?? newId();

  factory QuoteOption.fromJson(Map<String, dynamic> j) => QuoteOption(
    id: j['id'],
    label: j['label'] ?? '',
    active: j['active'] ?? true,
  );
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'active': active};
}

/// Il modulo "Preventivo", uguale su sito e app: ogni parte si accende e si
/// spegne dal gestionale. Nome, almeno un recapito e il consenso restano
/// sempre: senza non si potrebbe ricontattare nessuno.
class QuoteForm {
  bool showEvent;
  bool showDate;
  bool showLocation;
  bool showRequests;
  bool showMessage;
  bool askLastName;
  bool askPhone;
  bool askEmail;
  List<QuoteOption> eventTypes;
  List<QuoteOption> requests;
  QuoteForm({
    this.showEvent = true,
    this.showDate = true,
    this.showLocation = true,
    this.showRequests = true,
    this.showMessage = true,
    this.askLastName = true,
    this.askPhone = true,
    this.askEmail = true,
    List<QuoteOption>? eventTypes,
    List<QuoteOption>? requests,
  }) : eventTypes = eventTypes ?? [],
       requests = requests ?? [];

  List<QuoteOption> get activeEventTypes =>
      eventTypes.where((e) => e.active && e.label.trim().isNotEmpty).toList();
  List<QuoteOption> get activeRequests =>
      requests.where((e) => e.active && e.label.trim().isNotEmpty).toList();

  /// Almeno un recapito: se il titolare li spegne entrambi resta l'email.
  bool get phoneOn => askPhone;
  bool get emailOn => askEmail || !askPhone;

  factory QuoteForm.fromJson(Map<String, dynamic> j) => QuoteForm(
    showEvent: j['showEvent'] ?? true,
    showDate: j['showDate'] ?? true,
    showLocation: j['showLocation'] ?? true,
    showRequests: j['showRequests'] ?? true,
    showMessage: j['showMessage'] ?? true,
    askLastName: j['askLastName'] ?? true,
    askPhone: j['askPhone'] ?? true,
    askEmail: j['askEmail'] ?? true,
    eventTypes: _listOf(j['eventTypes'], QuoteOption.fromJson),
    requests: _listOf(j['requests'], QuoteOption.fromJson),
  );
  Map<String, dynamic> toJson() => {
    'showEvent': showEvent,
    'showDate': showDate,
    'showLocation': showLocation,
    'showRequests': showRequests,
    'showMessage': showMessage,
    'askLastName': askLastName,
    'askPhone': askPhone,
    'askEmail': askEmail,
    'eventTypes': eventTypes.map((e) => e.toJson()).toList(),
    'requests': requests.map((e) => e.toJson()).toList(),
  };

  QuoteForm copy() => QuoteForm.fromJson(toJson());
}

enum QuoteStatus { nuova, contattata, confermata, archiviata }

extension QuoteStatusLabel on QuoteStatus {
  String get label => switch (this) {
    QuoteStatus.nuova => 'Nuova',
    QuoteStatus.contattata => 'Contattata',
    QuoteStatus.confermata => 'Confermata',
    QuoteStatus.archiviata => 'Archiviata',
  };
}

class QuoteRequest {
  String id;
  DateTime createdAt;
  String firstName;
  String lastName;
  String phone;
  String email;
  String eventType;
  DateTime? eventDate;
  String location; // dove si svolge l'evento
  List<String> requests; // le voci scelte, con il loro nome
  String message;
  String source; // "sito" o "app"
  QuoteStatus status;
  String? appointmentId;

  QuoteRequest({
    String? id,
    DateTime? createdAt,
    required this.firstName,
    this.lastName = '',
    this.phone = '',
    this.email = '',
    this.eventType = '',
    this.eventDate,
    this.location = '',
    List<String>? requests,
    this.message = '',
    this.source = 'sito',
    this.status = QuoteStatus.nuova,
    this.appointmentId,
  }) : id = id ?? newId(),
       createdAt = createdAt ?? DateTime.now(),
       requests = requests ?? [];

  String get fullName => '$firstName $lastName'.trim();

  factory QuoteRequest.fromJson(Map<String, dynamic> j) => QuoteRequest(
    id: j['id'],
    createdAt: DateTime.tryParse(j['createdAt'] ?? ''),
    firstName: j['firstName'] ?? '',
    lastName: j['lastName'] ?? '',
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
    eventType: j['eventType'] ?? '',
    eventDate: DateTime.tryParse(j['eventDate'] ?? ''),
    location: j['location'] ?? '',
    requests: [
      for (final r in (j['requests'] as List? ?? const []))
        if (r is String) r,
    ],
    message: j['message'] ?? '',
    source: j['source'] ?? 'sito',
    status: QuoteStatus.values.firstWhere(
      (e) => e.name == j['status'],
      orElse: () => QuoteStatus.nuova,
    ),
    appointmentId: j['appointmentId'],
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'email': email,
    'eventType': eventType,
    'eventDate': eventDate?.toIso8601String(),
    'location': location,
    'requests': requests,
    'message': message,
    'source': source,
    'status': status.name,
    'appointmentId': appointmentId,
  };
}

// ------------------------------------------------------------------- clienti

/// Una foto o un video della festa nell'area di un cliente. [url] è la
/// versione da guardare, [original] il file in alta qualità da scaricare.
class ClientMedia {
  String id;
  String url;
  String original;
  bool isVideo;
  String poster; // anteprima dei video
  String name; // nome del file scaricato
  ClientMedia({
    String? id,
    required this.url,
    this.original = '',
    this.isVideo = false,
    this.poster = '',
    this.name = '',
  }) : id = id ?? newId();

  /// Il file da scaricare: l'originale, se c'è.
  String get downloadUrl => original.trim().isNotEmpty ? original : url;

  /// L'immagine da mostrare nella griglia.
  String get thumb => isVideo ? poster : url;

  factory ClientMedia.fromJson(Map<String, dynamic> j) => ClientMedia(
    id: j['id'],
    url: j['url'] ?? '',
    original: j['original'] ?? '',
    isVideo: j['isVideo'] ?? false,
    poster: j['poster'] ?? '',
    name: j['name'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'original': original,
    'isVideo': isVideo,
    'poster': poster,
    'name': name,
  };
}

/// Un file nell'area di un cliente: un PDF da scaricare o un link (es. una
/// galleria su Google Drive), con una nota.
class ClientFile {
  String id;
  String name;
  String url; // indirizzo web o file caricato (data URL)
  bool isLink; // vero = link da aprire, falso = documento da scaricare
  String note;
  DateTime addedAt;
  ClientFile({
    String? id,
    required this.name,
    required this.url,
    this.isLink = false,
    this.note = '',
    DateTime? addedAt,
  }) : id = id ?? newId(),
       addedAt = addedAt ?? DateTime.now();

  factory ClientFile.fromJson(Map<String, dynamic> j) => ClientFile(
    id: j['id'],
    name: j['name'] ?? '',
    url: j['url'] ?? '',
    isLink: j['isLink'] ?? false,
    note: j['note'] ?? '',
    addedAt: DateTime.tryParse(j['addedAt'] ?? ''),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'isLink': isLink,
    'note': note,
    'addedAt': addedAt.toIso8601String(),
  };
}

/// Un cliente con accesso alla propria area nell'app. Nessuno si registra da
/// solo: gli account li crea il titolare dal gestionale. Si entra con email
/// (o nome utente) e password.
class ClientAccount {
  String id;
  String name;
  String email;
  String username; // facoltativo, in alternativa all'email
  String phone;
  String passwordHash;
  String passwordSalt;
  bool active; // falso = accesso sospeso
  String eventTitle; // es. "Il matrimonio di Anna e Paolo"
  String eventDate; // testo libero, es. "18 maggio 2024"
  String location;
  String welcome; // due righe di benvenuto nell'area del cliente
  List<ClientMedia> media;
  List<ClientFile> files;
  DateTime createdAt;
  DateTime? lastLogin;
  ClientAccount({
    String? id,
    required this.name,
    required this.email,
    this.username = '',
    this.phone = '',
    this.passwordHash = '',
    this.passwordSalt = '',
    this.active = true,
    this.eventTitle = '',
    this.eventDate = '',
    this.location = '',
    this.welcome = '',
    List<ClientMedia>? media,
    List<ClientFile>? files,
    DateTime? createdAt,
    this.lastLogin,
  }) : id = id ?? newId(),
       media = media ?? [],
       files = files ?? [],
       createdAt = createdAt ?? DateTime.now();

  int get photoCount => media.where((m) => !m.isVideo).length;
  int get videoCount => media.where((m) => m.isVideo).length;

  factory ClientAccount.fromJson(Map<String, dynamic> j) => ClientAccount(
    id: j['id'],
    name: j['name'] ?? '',
    email: j['email'] ?? '',
    username: j['username'] ?? '',
    phone: j['phone'] ?? '',
    passwordHash: j['passwordHash'] ?? '',
    passwordSalt: j['passwordSalt'] ?? '',
    active: j['active'] ?? true,
    eventTitle: j['eventTitle'] ?? '',
    eventDate: j['eventDate'] ?? '',
    location: j['location'] ?? '',
    welcome: j['welcome'] ?? '',
    media: _listOf(j['media'], ClientMedia.fromJson),
    files: _listOf(j['files'], ClientFile.fromJson),
    createdAt: DateTime.tryParse(j['createdAt'] ?? ''),
    lastLogin: DateTime.tryParse(j['lastLogin'] ?? ''),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'username': username,
    'phone': phone,
    'passwordHash': passwordHash,
    'passwordSalt': passwordSalt,
    'active': active,
    'eventTitle': eventTitle,
    'eventDate': eventDate,
    'location': location,
    'welcome': welcome,
    'media': media.map((e) => e.toJson()).toList(),
    'files': files.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
  };
}

class Appointment {
  String id;
  String title;
  DateTime start;
  DateTime end;
  bool allDay;
  String location;
  String notes;
  String? quoteId;
  String? googleEventId;

  Appointment({
    String? id,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.location = '',
    this.notes = '',
    this.quoteId,
    this.googleEventId,
  }) : id = id ?? newId();

  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
    id: j['id'],
    title: j['title'] ?? '',
    start: DateTime.tryParse(j['start'] ?? '') ?? DateTime.now(),
    end: DateTime.tryParse(j['end'] ?? '') ?? DateTime.now(),
    allDay: j['allDay'] ?? false,
    location: j['location'] ?? '',
    notes: j['notes'] ?? '',
    quoteId: j['quoteId'],
    googleEventId: j['googleEventId'],
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'allDay': allDay,
    'location': location,
    'notes': notes,
    'quoteId': quoteId,
    'googleEventId': googleEventId,
  };
}

/// Impostazioni riservate al titolare (non pubbliche).
class AdminSettings {
  String username;
  String passwordHash;
  String passwordSalt;
  String googleClientId;
  bool googleWasConnected;

  /// Fine della sessione "ricordami" su questo dispositivo.
  DateTime? sessionUntil;
  AdminSettings({
    this.username = '',
    this.passwordHash = '',
    this.passwordSalt = '',
    this.googleClientId = '',
    this.googleWasConnected = false,
    this.sessionUntil,
  });

  factory AdminSettings.fromJson(Map<String, dynamic> j) => AdminSettings(
    username: j['username'] ?? '',
    passwordHash: j['passwordHash'] ?? '',
    passwordSalt: j['passwordSalt'] ?? '',
    googleClientId: j['googleClientId'] ?? '',
    googleWasConnected: j['googleWasConnected'] ?? false,
    sessionUntil: DateTime.tryParse(j['sessionUntil'] ?? ''),
  );
  Map<String, dynamic> toJson() => {
    'username': username,
    'passwordHash': passwordHash,
    'passwordSalt': passwordSalt,
    'googleClientId': googleClientId,
    'googleWasConnected': googleWasConnected,
    'sessionUntil': sessionUntil?.toIso8601String(),
  };
}
