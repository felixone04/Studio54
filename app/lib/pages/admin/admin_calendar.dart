import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/google_token.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'admin_appointment.dart';
import 'admin_widgets.dart';

const _googleBlue = Color(0xFF4A78C2);
const _weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Somma giorni di calendario. Con `add(Duration(days: n))` al cambio
/// dell'ora legale si finisce alle 23:00 del giorno prima (giorni doppi o
/// mancanti nella griglia).
DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class AdminCalendar extends StatefulWidget {
  const AdminCalendar({super.key});

  @override
  State<AdminCalendar> createState() => _AdminCalendarState();
}

class _AdminCalendarState extends State<AdminCalendar> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = _day(DateTime.now());
  List<Appointment> _google = [];
  bool _loading = false;
  String? _error;

  DateTime get _gridStart {
    final first = DateTime(_month.year, _month.month, 1);
    return _addDays(first, -(first.weekday - 1));
  }

  /// Numero della richiesta a Google più recente: le risposte arrivate in
  /// ritardo (es. cambiando mese velocemente) vengono ignorate.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoogle());
  }

  Future<void> _loadGoogle() async {
    // Può essere chiamata dopo un'attesa (dialoghi, rete): la pagina potrebbe
    // non esserci più.
    if (!mounted) return;
    final s = context.read<AppState>();
    final request = ++_request;
    if (!s.calendar.connected) {
      if (_google.isNotEmpty || _loading) {
        setState(() {
          _google = [];
          _loading = false;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    bool current() => mounted && request == _request;
    try {
      final start = _gridStart;
      final list = await s.calendar.listEvents(start, _addDays(start, 42));
      if (current()) setState(() => _google = list);
    } on GoogleAuthException catch (e) {
      if (current()) setState(() => _error = e.message);
    } catch (e) {
      if (current()) {
        setState(() => _error = 'Impossibile leggere Google Calendar: $e');
      }
    } finally {
      if (current()) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _loadGoogle();
  }

  void _today() {
    final n = DateTime.now();
    setState(() {
      _month = DateTime(n.year, n.month);
      _selected = _day(n);
    });
    _loadGoogle();
  }

  /// Appuntamenti locali + eventi presenti solo su Google (senza duplicati).
  List<Appointment> _all(AppState s) {
    final linked = {
      for (final a in s.appointments)
        if (a.googleEventId != null) a.googleEventId,
    };
    return [
      ...s.appointments,
      ..._google.where((g) => !linked.contains(g.googleEventId)),
    ];
  }

  List<Appointment> _on(List<Appointment> all, DateTime day) {
    final d = _day(day);
    final res = all.where((a) {
      final s = _day(a.start);
      var eEnd = a.end;
      if (!a.allDay &&
          eEnd.isAfter(a.start) &&
          eEnd.hour == 0 &&
          eEnd.minute == 0) {
        eEnd = eEnd.subtract(const Duration(minutes: 1));
      }
      final e = _day(eEnd);
      return !d.isBefore(s) && !d.isAfter(e);
    }).toList();
    res.sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      return a.start.compareTo(b.start);
    });
    return res;
  }

  Future<void> _connect() async {
    final s = context.read<AppState>();
    try {
      await s.connectGoogle();
    } on GoogleAuthException catch (e) {
      if (mounted) toast(context, e.message, error: true);
      return;
    } catch (e) {
      if (mounted) toast(context, 'Collegamento non riuscito: $e', error: true);
      return;
    }
    if (!mounted) return;
    toast(
      context,
      'Google Calendar collegato${s.calendar.calendarName != null ? ' (${s.calendar.calendarName})' : ''}.',
    );
    final unsynced = s.appointments
        .where((a) => a.googleEventId == null)
        .length;
    if (unsynced > 0) {
      final ok = await confirmDialog(
        context,
        'Hai $unsynced appuntamenti salvati solo su questo sito. Vuoi inviarli anche a Google Calendar?',
        confirm: 'Invia a Google',
        title: 'Sincronizza appuntamenti',
      );
      if (ok && mounted) await _push();
    }
    await _loadGoogle();
  }

  Future<void> _push() async {
    final s = context.read<AppState>();
    try {
      final n = await s.pushUnsyncedToGoogle();
      if (mounted) {
        toast(
          context,
          n == 0
              ? 'Era già tutto sincronizzato.'
              : '$n appuntamenti inviati a Google Calendar.',
        );
      }
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    await _loadGoogle();
  }

  Future<void> _newAppointment() async {
    final changed = await showAppointmentDialog(context, day: _selected);
    if (changed) _loadGoogle();
  }

  Future<void> _edit(Appointment a) async {
    final changed = await showAppointmentDialog(context, existing: a);
    if (changed) _loadGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = _all(s);
    final wide = MediaQuery.sizeOf(context).width > 1100;

    final grid = _MonthGrid(
      month: _month,
      start: _gridStart,
      selected: _selected,
      eventsOn: (d) => _on(all, d),
      onSelect: (d) => setState(() => _selected = d),
      onPrev: () => _changeMonth(-1),
      onNext: () => _changeMonth(1),
      onToday: _today,
      loading: _loading,
    );
    final agenda = _Agenda(
      day: _selected,
      events: _on(all, _selected),
      state: s,
      onAdd: _newAppointment,
      onEdit: _edit,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Calendario',
          subtitle: 'Appuntamenti e Google Calendar.',
          actions: [
            FilledButton.icon(
              onPressed: _newAppointment,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuovo appuntamento'),
            ),
          ],
        ),
        _GoogleBar(
          state: s,
          error: _error,
          loading: _loading,
          onConnect: _connect,
          onRefresh: _loadGoogle,
          onPush: _push,
          onDisconnect: () async {
            await s.disconnectGoogle();
            if (!mounted) return;
            setState(() {
              _google = [];
              _error = null;
            });
          },
        ),
        const SizedBox(height: 18),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: grid),
              const SizedBox(width: 20),
              SizedBox(width: 380, child: agenda),
            ],
          )
        else ...[
          grid,
          const SizedBox(height: 18),
          agenda,
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- Google bar

class _GoogleBar extends StatelessWidget {
  const _GoogleBar({
    required this.state,
    required this.error,
    required this.loading,
    required this.onConnect,
    required this.onRefresh,
    required this.onPush,
    required this.onDisconnect,
  });
  final AppState state;
  final String? error;
  final bool loading;
  final VoidCallback onConnect;
  final VoidCallback onRefresh;
  final VoidCallback onPush;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final connected = state.calendar.connected;
    final unsynced = state.appointments
        .where((a) => a.googleEventId == null)
        .length;

    Widget content;
    if (!state.googleConfigured) {
      content = Row(
        children: [
          const Icon(Icons.event_available_outlined, color: _googleBlue),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Per vedere gli appuntamenti su tutti i dispositivi collega il tuo Google Calendar: '
              'serve un breve passaggio di configurazione, una sola volta.',
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => context.go('/admin/impostazioni'),
            child: const Text('Configura'),
          ),
        ],
      );
    } else if (!connected) {
      content = Row(
        children: [
          const Icon(Icons.event_busy_outlined, color: _googleBlue),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              state.settings.googleWasConnected
                  ? 'La sessione con Google è scaduta: ricollega il calendario per sincronizzare.'
                  : 'Google Calendar non è ancora collegato.',
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.link_rounded, size: 18),
            label: Text(
              state.settings.googleWasConnected
                  ? 'Ricollega Google'
                  : 'Collega Google Calendar',
            ),
          ),
        ],
      );
    } else {
      content = Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          const Icon(Icons.event_available, color: Color(0xFF2E7D4F)),
          Text(
            'Collegato a Google Calendar${state.calendar.calendarName != null ? ' · ${state.calendar.calendarName}' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (unsynced > 0)
            ActionChip(
              avatar: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text('Invia $unsynced a Google'),
              onPressed: onPush,
            ),
          TextButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Aggiorna'),
          ),
          TextButton(onPressed: onDisconnect, child: const Text('Scollega')),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            content,
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: Color(0xFFB3382A))),
            ],
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- month grid

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.start,
    required this.selected,
    required this.eventsOn,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.loading,
  });
  final DateTime month;
  final DateTime start;
  final DateTime selected;
  final List<Appointment> Function(DateTime) eventsOn;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mobile = MediaQuery.sizeOf(context).width < 720;
    final title = toBeginningOfSentenceCase(
      DateFormat('MMMM y', 'it_IT').format(month),
    );
    final days = [for (var i = 0; i < 42; i++) _addDays(start, i)];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(mobile ? 10 : 18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: display(mobile ? 26 : 32),
                        ),
                      ),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(onPressed: onToday, child: const Text('Oggi')),
                IconButton(
                  onPressed: onPrev,
                  tooltip: 'Mese precedente',
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  onPressed: onNext,
                  tooltip: 'Mese successivo',
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final w in _weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        w.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          letterSpacing: 1.4,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var r = 0; r < 6; r++)
              Row(
                children: [
                  for (final date in days.skip(r * 7).take(7))
                    Expanded(
                      child: _DayCell(
                        date: date,
                        inMonth: date.month == month.month,
                        selected: _sameDay(date, selected),
                        events: eventsOn(date),
                        primary: primary,
                        mobile: mobile,
                        onTap: () => onSelect(date),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Color _eventColor(Appointment a, Color primary) =>
    a.id.startsWith('google:') ? _googleBlue : primary;

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.selected,
    required this.events,
    required this.primary,
    required this.mobile,
    required this.onTap,
  });
  final DateTime date;
  final bool inMonth;
  final bool selected;
  final List<Appointment> events;
  final Color primary;
  final bool mobile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = _sameDay(date, DateTime.now());
    final h = mobile ? 54.0 : 104.0;
    // Nella cella ci stanno due appuntamenti; se sono di più, uno + "altri".
    final shown = events.length > 2 ? 1 : events.length;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: h,
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.10)
              : (inMonth ? Colors.white : const Color(0xFFFAF8F5)),
          border: Border.all(
            color: selected ? primary : const Color(0xFFEDE8DF),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: today ? primary : null,
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: today ? FontWeight.w600 : FontWeight.w400,
                  color: today
                      ? Colors.white
                      : (inMonth ? Colors.black87 : Colors.black38),
                ),
              ),
            ),
            if (mobile)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                // Su 320 px la cella è larga ~22 px: con spaziatura 2 i tre
                // pallini stanno su una riga sola e non escono dalla cella.
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    for (final e in events.take(3))
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _eventColor(e, primary),
                        ),
                      ),
                  ],
                ),
              )
            else ...[
              const SizedBox(height: 3),
              for (final e in events.take(shown))
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _eventColor(e, primary).withValues(alpha: 0.14),
                    border: Border(
                      left: BorderSide(
                        color: _eventColor(e, primary),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    '${e.allDay ? '' : '${DateFormat.Hm().format(e.start)} '}${e.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, height: 1.2),
                  ),
                ),
              if (events.length > shown)
                Text(
                  '+${events.length - shown} altri',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: Colors.black54,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- agenda

class _Agenda extends StatelessWidget {
  const _Agenda({
    required this.day,
    required this.events,
    required this.state,
    required this.onAdd,
    required this.onEdit,
  });
  final DateTime day;
  final List<Appointment> events;
  final AppState state;
  final VoidCallback onAdd;
  final ValueChanged<Appointment> onEdit;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final label = toBeginningOfSentenceCase(
      DateFormat('EEEE d MMMM', 'it_IT').format(day),
    );
    return Panel(
      title: label,
      subtitle: events.isEmpty
          ? 'Nessun appuntamento'
          : '${events.length} ${events.length == 1 ? 'appuntamento' : 'appuntamenti'}',
      trailing: IconButton.filledTonal(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Aggiungi',
      ),
      child: events.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Giornata libera',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            )
          : Column(
              children: [
                for (final e in events)
                  InkWell(
                    onTap: () => onEdit(e),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _eventColor(e, primary).withValues(alpha: 0.08),
                        border: Border(
                          left: BorderSide(
                            color: _eventColor(e, primary),
                            width: 4,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.allDay
                                ? 'Tutto il giorno'
                                : '${DateFormat.Hm().format(e.start)} – ${DateFormat.Hm().format(e.end)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            e.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (e.location.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: Colors.black45,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      e.location,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (e.quoteId != null)
                                const _Tag(
                                  'Da preventivo',
                                  Icons.request_quote_outlined,
                                ),
                              if (e.googleEventId != null)
                                const _Tag(
                                  'Google Calendar',
                                  Icons.event_available_outlined,
                                )
                              else
                                const _Tag(
                                  'Solo qui',
                                  Icons.cloud_off_outlined,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.icon);
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.black54),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11.5, color: Colors.black54),
        ),
      ],
    ),
  );
}
