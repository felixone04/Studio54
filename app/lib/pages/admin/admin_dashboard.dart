import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'admin_quotes.dart' show statusColor;
import 'admin_widgets.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    // Gli appuntamenti "tutto il giorno" finiscono a mezzanotte del giorno
    // stesso: restano "prossimi" fino alla fine della giornata.
    final upcoming =
        s.appointments
            .where(
              (a) =>
                  (a.allDay
                          ? DateTime(a.end.year, a.end.month, a.end.day + 1)
                          : a.end)
                      .isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final newQuotes = s.quotes
        .where((q) => q.status == QuoteStatus.nuova)
        .length;
    final wide = MediaQuery.sizeOf(context).width > 980;
    final in30 = now.add(const Duration(days: 30));

    // Le stesse quattro schede del gestionale sul computer.
    final stats = [
      _Stat(
        'Richieste da leggere',
        '$newQuotes',
        Icons.mark_email_unread_outlined,
        () => context.go('/admin/richieste'),
      ),
      _Stat(
        'Appuntamenti nei prossimi 30 giorni',
        '${upcoming.where((a) => a.start.isBefore(in30)).length}',
        Icons.event_outlined,
        () => context.go('/admin/calendario'),
      ),
      _Stat(
        'Lavori pubblicati',
        '${s.works.where((w) => w.published).length}',
        Icons.auto_stories_outlined,
        () => context.go('/admin/lavori'),
      ),
      _Stat(
        'Clienti con accesso all\'app',
        '${s.clients.where((c) => c.active).length}',
        Icons.people_alt_outlined,
        () => context.go('/admin/clienti'),
      ),
    ];

    final recent = Panel(
      title: 'Ultime richieste',
      trailing: TextButton(
        onPressed: () => context.go('/admin/richieste'),
        style: _link,
        child: const Text('Tutte'),
      ),
      child: s.quotes.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              message: 'Ancora nessuna richiesta di preventivo.',
            )
          : Column(
              children: [
                for (final q in s.quotes.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.go('/admin/richieste'),
                    title: Text(
                      q.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        q.eventType,
                        DateFormat('d MMM', 'it_IT').format(q.createdAt),
                      ].where((e) => e.trim().isNotEmpty).join(' · '),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor(q.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        q.status.label,
                        style: TextStyle(
                          color: statusColor(q.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );

    final next = Panel(
      title: 'Prossimi appuntamenti',
      trailing: TextButton(
        onPressed: () => context.go('/admin/calendario'),
        style: _link,
        child: const Text('Calendario'),
      ),
      child: upcoming.isEmpty
          ? const EmptyState(
              icon: Icons.event_available_outlined,
              message: 'Nessun appuntamento in programma.',
            )
          : Column(
              children: [
                for (final a in upcoming.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.go('/admin/calendario'),
                    leading: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('d', 'it_IT').format(a.start),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM',
                              'it_IT',
                            ).format(a.start).toUpperCase(),
                            style: const TextStyle(fontSize: 10, height: 1.1),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      a.allDay
                          ? 'Tutto il giorno'
                          : DateFormat.Hm().format(a.start),
                    ),
                  ),
              ],
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(title: 'Benvenuto', subtitle: 'La situazione di oggi.'),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth > 900 ? 4 : 2;
            const gap = 16.0;
            final w = (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final st in stats) SizedBox(width: w, child: st)],
            );
          },
        ),
        const SizedBox(height: 22),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: recent),
              const SizedBox(width: 20),
              Expanded(child: next),
            ],
          )
        else ...[
          recent,
          const SizedBox(height: 20),
          next,
        ],
      ],
    );
  }
}

/// "Tutte", "Calendario": allineati al bordo del pannello, senza rientro.
final _link = TextButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 4),
  minimumSize: const Size(0, 40),
);

/// Una scheda come sul computer: il numero grande e sottile, sotto la
/// descrizione, l'icona in alto a destra. Tutte alte uguali.
class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.onTap);
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 128,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(icon, size: 20, color: const Color(0xFF7A6340)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: display(38, weight: FontWeight.w300, height: 1),
                    ),
                    const Spacer(),
                    Text(
                      label,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B635A),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
