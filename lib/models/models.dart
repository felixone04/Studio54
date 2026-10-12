import 'dart:math';

/// Genera un id univoco leggero (niente dipendenze extra).
String newId() {
  final r = Random();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${r.nextInt(1 << 20).toRadixString(36)}';
}

class Highlight {
  String title;
  String text;
  Highlight({required this.title, required this.text});

  factory Highlight.fromJson(Map<String, dynamic> j) =>
      Highlight(title: j['title'] ?? '', text: j['text'] ?? '');
  Map<String, dynamic> toJson() => {'title': title, 'text': text};
}

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

class TeamMember {
  String id;
  String name;
  String role;
  String bio;
  String photo;
  TeamMember({
    String? id,
    required this.name,
    required this.role,
    required this.bio,
    required this.photo,
  }) : id = id ?? newId();

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    id: j['id'],
    name: j['name'] ?? '',
    role: j['role'] ?? '',
    bio: j['bio'] ?? '',
    photo: j['photo'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'bio': bio,
    'photo': photo,
  };
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

/// Tutti i testi e le immagini modificabili del sito.
class SiteContent {
  String studioName;
  String tagline;

  // Home – hero
  String heroKicker;
  String heroTitle;
  String heroSubtitle;
  String marquee; // parole della striscia scorrevole, separate da virgola

  // Home – manifesto ed emozioni
  String manifestoTitle;
  String manifestoText;
  List<Highlight> highlights;

  // Home – galleria / mostra
  String galleryKicker;
  String galleryTitle;
  String galleryIntro;

  // Home – servizi
  String servicesTitle;
  String servicesIntro;

  // Home – banner preventivo
  String bannerTitle;
  String bannerText;
  String bannerButton;
  String bannerImage;

  // Biografia
  String bioTitle;
  String bioIntro;
  String bioStory; // paragrafi separati da riga vuota
  String bioImage;
  List<Milestone> timeline;
  List<TeamMember> team;
  String teamTitle;

  Contacts contacts;
  String footerNote;
  int accent; // colore ARGB
  List<String> eventTypes;

  SiteContent({
    required this.studioName,
    required this.tagline,
    required this.heroKicker,
    required this.heroTitle,
    required this.heroSubtitle,
    this.marquee = '',
    required this.manifestoTitle,
    required this.manifestoText,
    required this.highlights,
    required this.galleryKicker,
    required this.galleryTitle,
    required this.galleryIntro,
    required this.servicesTitle,
    required this.servicesIntro,
    required this.bannerTitle,
    required this.bannerText,
    required this.bannerButton,
    required this.bannerImage,
    required this.bioTitle,
    required this.bioIntro,
    required this.bioStory,
    required this.bioImage,
    required this.timeline,
    required this.team,
    required this.teamTitle,
    required this.contacts,
    required this.footerNote,
    required this.accent,
    required this.eventTypes,
  });

  factory SiteContent.fromJson(Map<String, dynamic> j, SiteContent fallback) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f, List<T> d) {
      final v = j[k];
      if (v is! List) return d;
      return v.map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    }

    String s(String k, String d) => (j[k] as String?) ?? d;

    return SiteContent(
      studioName: s('studioName', fallback.studioName),
      tagline: s('tagline', fallback.tagline),
      heroKicker: s('heroKicker', fallback.heroKicker),
      heroTitle: s('heroTitle', fallback.heroTitle),
      heroSubtitle: s('heroSubtitle', fallback.heroSubtitle),
      marquee: s('marquee', fallback.marquee),
      manifestoTitle: s('manifestoTitle', fallback.manifestoTitle),
      manifestoText: s('manifestoText', fallback.manifestoText),
      highlights: list('highlights', Highlight.fromJson, fallback.highlights),
      galleryKicker: s('galleryKicker', fallback.galleryKicker),
      galleryTitle: s('galleryTitle', fallback.galleryTitle),
      galleryIntro: s('galleryIntro', fallback.galleryIntro),
      servicesTitle: s('servicesTitle', fallback.servicesTitle),
      servicesIntro: s('servicesIntro', fallback.servicesIntro),
      bannerTitle: s('bannerTitle', fallback.bannerTitle),
      bannerText: s('bannerText', fallback.bannerText),
      bannerButton: s('bannerButton', fallback.bannerButton),
      bannerImage: s('bannerImage', fallback.bannerImage),
      bioTitle: s('bioTitle', fallback.bioTitle),
      bioIntro: s('bioIntro', fallback.bioIntro),
      bioStory: s('bioStory', fallback.bioStory),
      bioImage: s('bioImage', fallback.bioImage),
      timeline: list('timeline', Milestone.fromJson, fallback.timeline),
      team: list('team', TeamMember.fromJson, fallback.team),
      teamTitle: s('teamTitle', fallback.teamTitle),
      contacts: j['contacts'] is Map
          ? Contacts.fromJson(Map<String, dynamic>.from(j['contacts']))
          : fallback.contacts,
      footerNote: s('footerNote', fallback.footerNote),
      accent: (j['accent'] as int?) ?? fallback.accent,
      eventTypes: j['eventTypes'] is List
          ? List<String>.from(j['eventTypes'])
          : fallback.eventTypes,
    );
  }

  Map<String, dynamic> toJson() => {
    'studioName': studioName,
    'tagline': tagline,
    'heroKicker': heroKicker,
    'heroTitle': heroTitle,
    'heroSubtitle': heroSubtitle,
    'marquee': marquee,
    'manifestoTitle': manifestoTitle,
    'manifestoText': manifestoText,
    'highlights': highlights.map((e) => e.toJson()).toList(),
    'galleryKicker': galleryKicker,
    'galleryTitle': galleryTitle,
    'galleryIntro': galleryIntro,
    'servicesTitle': servicesTitle,
    'servicesIntro': servicesIntro,
    'bannerTitle': bannerTitle,
    'bannerText': bannerText,
    'bannerButton': bannerButton,
    'bannerImage': bannerImage,
    'bioTitle': bioTitle,
    'bioIntro': bioIntro,
    'bioStory': bioStory,
    'bioImage': bioImage,
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'team': team.map((e) => e.toJson()).toList(),
    'teamTitle': teamTitle,
    'contacts': contacts.toJson(),
    'footerNote': footerNote,
    'accent': accent,
    'eventTypes': eventTypes,
  };

  /// Copia profonda, usata dagli editor admin per lavorare su una bozza.
  SiteContent copy() => SiteContent.fromJson(toJson(), this);
}

class ServiceItem {
  String id;
  String name;
  String description;
  String category;
  String image;
  double? internalPrice; // visibile solo in admin, mai sul sito pubblico
  bool active;
  ServiceItem({
    String? id,
    required this.name,
    this.description = '',
    this.category = 'Servizi',
    this.image = '',
    this.internalPrice,
    this.active = true,
  }) : id = id ?? newId();

  factory ServiceItem.fromJson(Map<String, dynamic> j) => ServiceItem(
    id: j['id'],
    name: j['name'] ?? '',
    description: j['description'] ?? '',
    category: j['category'] ?? 'Servizi',
    image: j['image'] ?? '',
    internalPrice: (j['internalPrice'] as num?)?.toDouble(),
    active: j['active'] ?? true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'image': image,
    'internalPrice': internalPrice,
    'active': active,
  };
}

class ServicePackage {
  String id;
  String name;
  String tagline;
  String description;
  List<String> serviceIds;
  String image;
  bool featured;
  bool active;
  ServicePackage({
    String? id,
    required this.name,
    this.tagline = '',
    this.description = '',
    List<String>? serviceIds,
    this.image = '',
    this.featured = false,
    this.active = true,
  }) : id = id ?? newId(),
       serviceIds = serviceIds ?? [];

  factory ServicePackage.fromJson(Map<String, dynamic> j) => ServicePackage(
    id: j['id'],
    name: j['name'] ?? '',
    tagline: j['tagline'] ?? '',
    description: j['description'] ?? '',
    serviceIds: List<String>.from(j['serviceIds'] ?? const []),
    image: j['image'] ?? '',
    featured: j['featured'] ?? false,
    active: j['active'] ?? true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'description': description,
    'serviceIds': serviceIds,
    'image': image,
    'featured': featured,
    'active': active,
  };
}

class GalleryPhoto {
  String id;
  String url;
  String title;
  String caption;
  String category;
  String location;
  String year;
  bool inHero; // mostrata anche nel carosello iniziale
  GalleryPhoto({
    String? id,
    required this.url,
    required this.title,
    this.caption = '',
    this.category = '',
    this.location = '',
    this.year = '',
    this.inHero = true,
  }) : id = id ?? newId();

  factory GalleryPhoto.fromJson(Map<String, dynamic> j) => GalleryPhoto(
    id: j['id'],
    url: j['url'] ?? '',
    title: j['title'] ?? '',
    caption: j['caption'] ?? '',
    category: j['category'] ?? '',
    location: j['location'] ?? '',
    year: j['year'] ?? '',
    inHero: j['inHero'] ?? true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'title': title,
    'caption': caption,
    'category': category,
    'location': location,
    'year': year,
    'inHero': inHero,
  };
}

/// Una foto all'interno di un lavoro, con la sua didascalia.
class WorkPhoto {
  String id;
  String url;
  String caption;
  WorkPhoto({String? id, required this.url, this.caption = ''})
    : id = id ?? newId();

  factory WorkPhoto.fromJson(Map<String, dynamic> j) =>
      WorkPhoto(id: j['id'], url: j['url'] ?? '', caption: j['caption'] ?? '');
  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'caption': caption};
}

/// Un lavoro realizzato (un matrimonio, un evento…), raccontato come una
/// piccola mostra: copertina, scheda, testo e sequenza di foto.
class Work {
  String id;
  String title;
  String category;
  String location;
  String date; // testo libero, es. "Giugno 2024"
  String story;
  String credits; // cosa è stato realizzato, es. "Reportage · Album fine art"
  String cover;
  List<WorkPhoto> photos;
  bool published;
  Work({
    String? id,
    required this.title,
    this.category = '',
    this.location = '',
    this.date = '',
    this.story = '',
    this.credits = '',
    this.cover = '',
    List<WorkPhoto>? photos,
    this.published = true,
  }) : id = id ?? newId(),
       photos = photos ?? [];

  /// Copertina: quella scelta, altrimenti la prima foto.
  String get coverUrl => cover.trim().isNotEmpty
      ? cover
      : (photos.isEmpty ? '' : photos.first.url);

  factory Work.fromJson(Map<String, dynamic> j) => Work(
    id: j['id'],
    title: j['title'] ?? '',
    category: j['category'] ?? '',
    location: j['location'] ?? '',
    date: j['date'] ?? '',
    story: j['story'] ?? '',
    credits: j['credits'] ?? '',
    cover: j['cover'] ?? '',
    photos: [
      for (final p in (j['photos'] as List? ?? const []))
        WorkPhoto.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
    published: j['published'] ?? true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'location': location,
    'date': date,
    'story': story,
    'credits': credits,
    'cover': cover,
    'photos': photos.map((e) => e.toJson()).toList(),
    'published': published,
  };
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
  String message;
  List<String> serviceIds;
  String? packageId;
  QuoteStatus status;
  String? appointmentId;

  QuoteRequest({
    String? id,
    DateTime? createdAt,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.eventType,
    this.eventDate,
    this.message = '',
    required this.serviceIds,
    this.packageId,
    this.status = QuoteStatus.nuova,
    this.appointmentId,
  }) : id = id ?? newId(),
       createdAt = createdAt ?? DateTime.now();

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
    message: j['message'] ?? '',
    serviceIds: List<String>.from(j['serviceIds'] ?? const []),
    packageId: j['packageId'],
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
    'message': message,
    'serviceIds': serviceIds,
    'packageId': packageId,
    'status': status.name,
    'appointmentId': appointmentId,
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
  String passwordHash;
  String passwordSalt;
  String googleClientId;
  bool googleWasConnected;

  /// Fine della sessione "ricordami" su questo dispositivo.
  DateTime? sessionUntil;
  AdminSettings({
    this.passwordHash = '',
    this.passwordSalt = '',
    this.googleClientId = '',
    this.googleWasConnected = false,
    this.sessionUntil,
  });

  factory AdminSettings.fromJson(Map<String, dynamic> j) => AdminSettings(
    passwordHash: j['passwordHash'] ?? '',
    passwordSalt: j['passwordSalt'] ?? '',
    googleClientId: j['googleClientId'] ?? '',
    googleWasConnected: j['googleWasConnected'] ?? false,
    sessionUntil: DateTime.tryParse(j['sessionUntil'] ?? ''),
  );
  Map<String, dynamic> toJson() => {
    'passwordHash': passwordHash,
    'passwordSalt': passwordSalt,
    'googleClientId': googleClientId,
    'googleWasConnected': googleWasConnected,
    'sessionUntil': sessionUntil?.toIso8601String(),
  };
}
