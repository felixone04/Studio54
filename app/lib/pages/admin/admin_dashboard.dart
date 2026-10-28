import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
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

    final stats = [
      _Stat(
        'Richieste nuove',
        '$newQuotes',
        Icons.mark_email_unread_outlined,
        newQuotes > 0 ? const Color(0xFFC25B2E) : null,
        () => context.go('/admin/richieste'),
      ),
      _Stat(
        'Richieste totali',
        '${s.quotes.length}',
        Icons.inbox_outlined,
        null,
        () => context.go('/admin/richieste'),
      ),
      _Stat(
        'Prossimi appuntamenti',
        '${upcoming.length}',
        Icons.event_outlined,
        null,
        () => context.go('/admin/calendario'),
      ),
      _Stat(
        'Clienti con accesso',
        '${s.clients.where((c) => c.active).length}',
        Icons.people_alt_outlined,
        null,
        () => context.go('/admin/clienti'),
      ),
    ];

    final recent = Panel(
      title: 'Ultime richieste',
      trailing: TextButton(
        onPressed: () => context.go('/admin/richieste'),
        child: const Text('Vedi tutte'),
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
                      '${q.eventType} · ${DateFormat('d MMM', 'it_IT').format(q.createdAt)}',
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
        child: const Text('Apri calendario'),
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
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('d', 'it_IT').format(a.start),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM',
                              'it_IT',
                            ).format(a.start).toUpperCase(),
                            style: const TextStyle(fontSize: 10.5),
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

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.highlight, this.onTap);
  final String label;
  final String value;
  final IconData icon;
  final Color? highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = highlight ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
