import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/site_scaffold.dart' show openUrl;
import 'admin_appointment.dart';
import 'admin_widgets.dart';

Color statusColor(QuoteStatus s) => switch (s) {
  QuoteStatus.nuova => const Color(0xFFC25B2E),
  QuoteStatus.contattata => const Color(0xFF3B6FB6),
  QuoteStatus.confermata => const Color(0xFF2E7D4F),
  QuoteStatus.archiviata => const Color(0xFF7A746B),
};

class AdminQuotes extends StatefulWidget {
  const AdminQuotes({super.key});

  @override
  State<AdminQuotes> createState() => _AdminQuotesState();
}

class _AdminQuotesState extends State<AdminQuotes> {
  QuoteStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.quotes
        .where((q) => _filter == null || q.status == _filter)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminHeader(
          title: 'Richieste di preventivo',
          subtitle: 'Chi ha chiesto di essere richiamato. Cambia lo stato man mano che li contatti e fissa un appuntamento.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Tutte (${s.quotes.length})'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final st in QuoteStatus.values)
              ChoiceChip(
                label: Text(
                  '${st.label} (${s.quotes.where((q) => q.status == st).length})',
                ),
                selected: _filter == st,
                onSelected: (_) => setState(() => _filter = st),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (list.isEmpty)
          const Card(
            child: EmptyState(
              icon: Icons.inbox_outlined,
              message: 'Nessuna richiesta qui. Quando un cliente compilerà il modulo preventivo la vedrai comparire.',
            ),
          )
        else
          for (final q in list) _QuoteCard(quote: q),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final QuoteRequest quote;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final q = quote;
    final date = DateFormat(
      "d MMM y 'alle' HH:mm",
      'it_IT',
    ).format(q.createdAt);
    final appt = s.appointments
        .where((a) => a.id == q.appointmentId)
        .firstOrNull;
    final pkg = s.packageById(q.packageId);
    double total = 0;
    var priced = 0;
    for (final id in q.serviceIds) {
      final p = s.serviceById(id)?.internalPrice;
      if (p != null) {
        total += p;
        priced++;
      }
    }
    final digits = q.phone.replaceAll(RegExp(r'[^0-9+]'), '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: q.status == QuoteStatus.nuova,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    q.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
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
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${q.eventType}'
                '${q.eventDate != null ? ' · ${DateFormat('d MMM y', 'it_IT').format(q.eventDate!)}' : ''}'
                ' · richiesta del $date',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => openUrl('tel:$digits'),
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: Text(q.phone),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        openUrl('https://wa.me/${digits.replaceAll('+', '')}'),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => openUrl('mailto:${q.email}'),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: Text(q.email),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                pkg != null
                    ? 'Pacchetto ${pkg.name} · servizi richiesti'
                    : 'Servizi richiesti',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in q.serviceIds)
                    Chip(
                      label: Text(
                        s.serviceById(id)?.name ?? '(servizio rimosso)',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (priced > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'Stima interna: ${formatEuro(total)}${priced < q.serviceIds.length ? ' (parziale)' : ''}  ·  non visibile al cliente',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
              if (q.message.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Note del cliente',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(q.message),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<QuoteStatus>(
                      initialValue: q.status,
                      decoration: const InputDecoration(
                        labelText: 'Stato',
                        isDense: true,
                      ),
                      items: [
                        for (final st in QuoteStatus.values)
                          DropdownMenuItem(value: st, child: Text(st.label)),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        q.status = v;
                        s.updateQuote(q);
                      },
                    ),
                  ),
                  if (appt == null)
                    FilledButton.icon(
                      onPressed: () => showAppointmentDialog(context, quote: q),
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: const Text('Fissa appuntamento'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => context.go('/admin/calendario'),
                      icon: const Icon(Icons.event_available_rounded, size: 18),
                      label: Text(
                        'Appuntamento: ${DateFormat('d MMM HH:mm', 'it_IT').format(appt.start)}',
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      if (await confirmDialog(
                        context,
                        'Eliminare definitivamente la richiesta di ${q.fullName}?',
                      )) {
                        s.deleteQuote(q.id);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB3382A),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Elimina'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
