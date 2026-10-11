import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'google_auth.dart';
import 'google_token.dart';

/// Parla con Google Calendar (calendario principale dell'account che fa
/// l'accesso) tramite le API REST. Il token vive solo in memoria.
class GoogleCalendarService {
  static const scope = 'https://www.googleapis.com/auth/calendar.events';
  static const _base =
      'https://www.googleapis.com/calendar/v3/calendars/primary';

  GoogleToken? _token;
  String? calendarName;

  bool get connected => _token?.isValid ?? false;

  Future<void> connect(String clientId, {String prompt = ''}) async {
    if (clientId.trim().isEmpty) {
      throw GoogleAuthException(
        'Manca il Client ID Google: inseriscilo in Impostazioni.',
      );
    }
    _token = await requestGoogleAccessToken(
      clientId: clientId.trim(),
      scope: scope,
      prompt: prompt,
    );
    // Legge il nome del calendario (di solito l'indirizzo Gmail).
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final res = await _get('/events', {'maxResults': '1', 'timeMin': now});
      calendarName = res['summary'] as String?;
    } catch (_) {}
  }

  void disconnect() {
    _token = null;
    calendarName = null;
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_token!.accessToken}',
    'Content-Type': 'application/json',
  };

  void _ensure() {
    if (!connected) {
      _token = null;
      throw GoogleAuthException(
        'Sessione Google scaduta: ricollega il calendario.',
      );
    }
  }

  Future<Map<String, dynamic>> _handle(http.Response res) async {
    if (res.statusCode == 401) {
      _token = null;
      throw GoogleAuthException(
        'Sessione Google scaduta: ricollega il calendario.',
      );
    }
    if (res.statusCode >= 400) {
      String msg = 'Errore Google Calendar (${res.statusCode}).';
      try {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        msg = (j['error']?['message'] as String?) ?? msg;
      } catch (_) {}
      if (res.statusCode == 403) {
        msg =
            '$msg Verifica di aver abilitato "Google Calendar API" nel '
            'progetto Google Cloud.';
      }
      throw GoogleAuthException(msg);
    }
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _get(String path, Map<String, String> q) async {
    _ensure();
    final res = await http.get(
      Uri.parse('$_base$path').replace(queryParameters: q),
      headers: _headers,
    );
    return _handle(res);
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _body(Appointment a) {
    final allDay = a.allDay;
    final startDay = DateTime(a.start.year, a.start.month, a.start.day);
    return {
      'summary': a.title,
      'location': a.location,
      'description': a.notes,
      'start': allDay
          ? {'date': _date(startDay)}
          : {'dateTime': a.start.toUtc().toIso8601String()},
      // Giorno dopo (fine esclusiva) calcolato sul calendario: con
      // `add(Duration(days: 1))` il giorno del cambio d'ora resterebbe uguale
      // all'inizio e Google rifiuterebbe l'evento.
      'end': allDay
          ? {
              'date': _date(
                DateTime(startDay.year, startDay.month, startDay.day + 1),
              ),
            }
          : {'dateTime': a.end.toUtc().toIso8601String()},
    };
  }

  Future<List<Appointment>> listEvents(DateTime from, DateTime to) async {
    final out = <Appointment>[];
    String? pageToken;
    do {
      final res = await _get('/events', {
        'timeMin': from.toUtc().toIso8601String(),
        'timeMax': to.toUtc().toIso8601String(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'maxResults': '250',
        'pageToken': ?pageToken,
      });
      calendarName ??= res['summary'] as String?;
      for (final e in (res['items'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        if (m['status'] == 'cancelled') continue;
        final s = m['start'] as Map<String, dynamic>?;
        final en = m['end'] as Map<String, dynamic>?;
        if (s == null || en == null) continue;
        final allDay = s['date'] != null;
        final start = allDay
            ? DateTime.parse(s['date'])
            : DateTime.parse(s['dateTime']).toLocal();
        final endDay = allDay ? DateTime.parse(en['date']) : null;
        var end = endDay != null
            // Fine esclusiva → ultimo giorno incluso (sicuro con l'ora legale).
            ? DateTime(endDay.year, endDay.month, endDay.day - 1)
            : DateTime.parse(en['dateTime']).toLocal();
        if (end.isBefore(start)) end = start;
        out.add(
          Appointment(
            id: 'google:${m['id']}',
            title: (m['summary'] as String?) ?? '(senza titolo)',
            start: start,
            end: end,
            allDay: allDay,
            location: (m['location'] as String?) ?? '',
            notes: (m['description'] as String?) ?? '',
            googleEventId: m['id'] as String?,
          ),
        );
      }
      pageToken = res['nextPageToken'] as String?;
    } while (pageToken != null);
    return out;
  }

  Future<String> insert(Appointment a) async {
    _ensure();
    final res = await http.post(
      Uri.parse('$_base/events'),
      headers: _headers,
      body: jsonEncode(_body(a)),
    );
    final j = await _handle(res);
    return j['id'] as String;
  }

  Future<void> update(Appointment a) async {
    _ensure();
    final res = await http.patch(
      Uri.parse('$_base/events/${a.googleEventId}'),
      headers: _headers,
      body: jsonEncode(_body(a)),
    );
    await _handle(res);
  }

  Future<void> delete(String googleEventId) async {
    _ensure();
    final res = await http.delete(
      Uri.parse('$_base/events/$googleEventId'),
      headers: _headers,
    );
    if (res.statusCode == 404 || res.statusCode == 410) return;
    await _handle(res);
  }
}
