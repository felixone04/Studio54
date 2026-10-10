import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'admin_widgets.dart';

/// Pagina di amministrazione scorrevole con margini coerenti.
class AdminPageScroll extends StatelessWidget {
  const AdminPageScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        mobile ? 16 : 36,
        mobile ? 20 : 32,
        mobile ? 16 : 36,
        48,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// Editor a bozza dei contenuti del sito: le modifiche si applicano solo al
/// clic su "Salva", e si possono annullare.
class DraftEditor extends StatefulWidget {
  const DraftEditor({
    super.key,
    required this.title,
    this.subtitle,
    required this.builder,
  });
  final String title;
  final String? subtitle;
  final List<Widget> Function(
    BuildContext context,
    SiteContent draft,
    VoidCallback changed,
  )
  builder;

  @override
  State<DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends State<DraftEditor> {
  late SiteContent _draft = context.read<AppState>().content.copy();
  bool _dirty = false;
  int _rev = 0;

  void _rebuild() => setState(() => _dirty = true);

  Future<void> _save() async {
    await context.read<AppState>().updateContent(_draft);
    if (!mounted) return;
    setState(() {
      _draft = context.read<AppState>().content.copy();
      _dirty = false;
    });
    toast(context, 'Modifiche salvate: il sito è aggiornato.');
  }

  void _discard() => setState(() {
    _draft = context.read<AppState>().content.copy();
    _dirty = false;
    _rev++;
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AdminPageScroll(
            child: KeyedSubtree(
              key: ValueKey(_rev),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminHeader(title: widget.title, subtitle: widget.subtitle),
                  for (final w in widget.builder(
                    context,
                    _draft,
                    _rebuild,
                  )) ...[w, const SizedBox(height: 20)],
                ],
              ),
            ),
          ),
        ),
        SaveBar(dirty: _dirty, onSave: _save, onDiscard: _discard),
      ],
    );
  }
}

const _gap = SizedBox(height: 16);

// ====================================================================== HOME

class AdminHomeEditor extends StatelessWidget {
  const AdminHomeEditor({super.key});

  @override
  Widget build(BuildContext context) {
    Widget field(
      String label,
      String value,
      void Function(String) set,
      VoidCallback changed, {
      int maxLines = 1,
      String? helper,
    }) => BoundField(
      label: label,
      value: value,
      maxLines: maxLines,
      helper: helper,
      onChanged: (v) {
        set(v);
        changed();
      },
    );

    return DraftEditor(
      title: 'Pagina Home',
      subtitle:
          'Pochi testi, grandi immagini. Le foto del carosello e della mostra '
          'si gestiscono dalla Galleria.',
      builder: (context, d, changed) => [
        Panel(
          title: 'Apertura',
          subtitle:
              'Il nome dello studio (da “Identità e contatti”) appare gigante; '
              'qui la riga sopra e la frase sotto.',
          child: Column(
            children: [
              field(
                'Riga sopra il nome',
                d.heroKicker,
                (v) => d.heroKicker = v,
                changed,
              ),
              _gap,
              field(
                'Frase sotto il nome',
                d.heroTitle,
                (v) => d.heroTitle = v,
                changed,
                maxLines: 2,
                helper: 'Breve. Vai a capo per spezzarla su due righe.',
              ),
            ],
          ),
        ),
        Panel(
          title: 'Manifesto',
          subtitle: 'Una frase sola, molto grande.',
          child: field(
            'Frase',
            d.manifestoTitle,
            (v) => d.manifestoTitle = v,
            changed,
            maxLines: 3,
            helper: 'La seconda riga appare in corsivo colorato.',
          ),
        ),
        Panel(
          title: 'La mostra',
          trailing: TextButton.icon(
            onPressed: () => context.go('/admin/galleria'),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Gestisci le foto'),
          ),
          child: Column(
            children: [
              field(
                'Etichetta',
                d.galleryKicker,
                (v) => d.galleryKicker = v,
                changed,
              ),
              _gap,
              field(
                'Titolo',
                d.galleryTitle,
                (v) => d.galleryTitle = v,
                changed,
              ),
            ],
          ),
        ),
        Panel(
          title: 'Servizi',
          trailing: TextButton.icon(
            onPressed: () => context.go('/admin/servizi'),
            icon: const Icon(Icons.design_services_outlined, size: 18),
            label: const Text('Gestisci i servizi'),
          ),
          child: field(
            'Titolo',
            d.servicesTitle,
            (v) => d.servicesTitle = v,
            changed,
          ),
        ),
      ],
    );
  }
}

// ================================================================= BIOGRAFIA

class AdminBioEditor extends StatelessWidget {
  const AdminBioEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return DraftEditor(
      title: 'Biografia e team',
      subtitle: 'La storia dello studio e le persone che lo compongono.',
      builder: (context, d, changed) => [
        Panel(
          title: 'La storia',
          child: Column(
            children: [
              BoundField(
                label: 'Titolo della pagina',
                value: d.bioTitle,
                onChanged: (v) {
                  d.bioTitle = v;
                  changed();
                },
              ),
              _gap,
              BoundField(
                label: 'Introduzione (frase in evidenza)',
                value: d.bioIntro,
                maxLines: 3,
                onChanged: (v) {
                  d.bioIntro = v;
                  changed();
                },
              ),
              _gap,
              BoundField(
                label: 'Racconto',
                value: d.bioStory,
                maxLines: 14,
                minLines: 8,
                helper: 'Separa i paragrafi con una riga vuota.',
                onChanged: (v) {
                  d.bioStory = v;
                  changed();
                },
              ),
              _gap,
              ImageField(
                label: 'Immagine accanto al racconto',
                aspect: 4 / 5,
                value: d.bioImage,
                onChanged: (v) {
                  d.bioImage = v;
                  changed();
                },
              ),
            ],
          ),
        ),
        Panel(
          title: 'Tappe del percorso',
          subtitle: 'Una breve linea del tempo (anno, titolo, testo).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < d.timeline.length; i++)
                ItemCard(
                  key: ObjectKey(d.timeline[i]),
                  title: 'Tappa ${i + 1}',
                  onUp: i == 0
                      ? null
                      : () {
                          d.timeline.insert(i - 1, d.timeline.removeAt(i));
                          changed();
                        },
                  onDown: i == d.timeline.length - 1
                      ? null
                      : () {
                          d.timeline.insert(i + 1, d.timeline.removeAt(i));
                          changed();
                        },
                  onDelete: () {
                    d.timeline.removeAt(i);
                    changed();
                  },
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: BoundField(
                              label: 'Anno',
                              value: d.timeline[i].year,
                              onChanged: (v) {
                                d.timeline[i].year = v;
                                changed();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BoundField(
                              label: 'Titolo',
                              value: d.timeline[i].title,
                              onChanged: (v) {
                                d.timeline[i].title = v;
                                changed();
                              },
                            ),
                          ),
                        ],
                      ),
                      _gap,
                      BoundField(
                        label: 'Testo',
                        value: d.timeline[i].text,
                        maxLines: 2,
                        onChanged: (v) {
                          d.timeline[i].text = v;
                          changed();
                        },
                      ),
                    ],
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  d.timeline.add(
                    Milestone(
                      year: '${DateTime.now().year}',
                      title: '',
                      text: '',
                    ),
                  );
                  changed();
                },
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi tappa'),
              ),
            ],
          ),
        ),
        Panel(
          title: 'Il team',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoundField(
                label: 'Titolo della sezione',
                value: d.teamTitle,
                onChanged: (v) {
                  d.teamTitle = v;
                  changed();
                },
              ),
              const SizedBox(height: 22),
              for (var i = 0; i < d.team.length; i++)
                ItemCard(
                  key: ObjectKey(d.team[i]),
                  title: d.team[i].name.isEmpty
                      ? 'Nuova persona'
                      : d.team[i].name,
                  onUp: i == 0
                      ? null
                      : () {
                          d.team.insert(i - 1, d.team.removeAt(i));
                          changed();
                        },
                  onDown: i == d.team.length - 1
                      ? null
                      : () {
                          d.team.insert(i + 1, d.team.removeAt(i));
                          changed();
                        },
                  onDelete: () {
                    d.team.removeAt(i);
                    changed();
                  },
                  child: Column(
                    children: [
                      FieldRow(
                        children: [
                          Expanded(
                            child: BoundField(
                              label: 'Nome e cognome',
                              value: d.team[i].name,
                              onChanged: (v) {
                                d.team[i].name = v;
                                changed();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BoundField(
                              label: 'Ruolo',
                              value: d.team[i].role,
                              onChanged: (v) {
                                d.team[i].role = v;
                                changed();
                              },
                            ),
                          ),
                        ],
                      ),
                      _gap,
                      BoundField(
                        label: 'Breve presentazione',
                        value: d.team[i].bio,
                        maxLines: 3,
                        onChanged: (v) {
                          d.team[i].bio = v;
                          changed();
                        },
                      ),
                      _gap,
                      ImageField(
                        label: 'Foto',
                        aspect: 4 / 5,
                        value: d.team[i].photo,
                        onChanged: (v) {
                          d.team[i].photo = v;
                          changed();
                        },
                      ),
                    ],
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  d.team.add(
                    TeamMember(name: '', role: '', bio: '', photo: ''),
                  );
                  changed();
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Aggiungi persona'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================= IDENTITÀ E CONTATTI

class AdminIdentityEditor extends StatelessWidget {
  const AdminIdentityEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return DraftEditor(
      title: 'Identità e contatti',
      subtitle: 'Nome, colore, recapiti e opzioni del modulo preventivo.',
      builder: (context, d, changed) => [
        Panel(
          title: 'Identità',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoundField(
                label: 'Nome dello studio',
                value: d.studioName,
                onChanged: (v) {
                  d.studioName = v;
                  changed();
                },
              ),
              _gap,
              BoundField(
                label: 'Slogan (in apertura della biografia)',
                value: d.tagline,
                onChanged: (v) {
                  d.tagline = v;
                  changed();
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Colore di accento',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (final e in accentChoices.entries)
                    Tooltip(
                      message: e.key,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          d.accent = e.value;
                          changed();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(e.value),
                            border: Border.all(
                              color: d.accent == e.value
                                  ? Colors.black87
                                  : Colors.black12,
                              width: d.accent == e.value ? 3 : 1,
                            ),
                          ),
                          child: d.accent == e.value
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 20,
                                  color: Colors.black87,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Panel(
          title: 'Contatti',
          subtitle: 'Compaiono nel footer del sito. I campi vuoti non vengono mostrati.',
          child: Column(
            children: [
              FieldRow(
                children: [
                  Expanded(
                    child: BoundField(
                      label: 'Telefono',
                      value: d.contacts.phone,
                      prefixIcon: Icons.phone_outlined,
                      onChanged: (v) {
                        d.contacts.phone = v;
                        changed();
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: BoundField(
                      label: 'WhatsApp',
                      value: d.contacts.whatsapp,
                      prefixIcon: Icons.chat_bubble_outline_rounded,
                      onChanged: (v) {
                        d.contacts.whatsapp = v;
                        changed();
                      },
                    ),
                  ),
                ],
              ),
              _gap,
              BoundField(
                label: 'Email',
                value: d.contacts.email,
                prefixIcon: Icons.mail_outline_rounded,
                onChanged: (v) {
                  d.contacts.email = v;
                  changed();
                },
              ),
              _gap,
              BoundField(
                label: 'Indirizzo',
                value: d.contacts.address,
                prefixIcon: Icons.place_outlined,
                onChanged: (v) {
                  d.contacts.address = v;
                  changed();
                },
              ),
              _gap,
              BoundField(
                label: 'Orari di apertura',
                value: d.contacts.hours,
                prefixIcon: Icons.schedule_rounded,
                onChanged: (v) {
                  d.contacts.hours = v;
                  changed();
                },
              ),
              _gap,
              FieldRow(
                children: [
                  Expanded(
                    child: BoundField(
                      label: 'Instagram (link)',
                      value: d.contacts.instagram,
                      onChanged: (v) {
                        d.contacts.instagram = v;
                        changed();
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: BoundField(
                      label: 'Facebook (link)',
                      value: d.contacts.facebook,
                      onChanged: (v) {
                        d.contacts.facebook = v;
                        changed();
                      },
                    ),
                  ),
                ],
              ),
              _gap,
              BoundField(
                label: 'Partita IVA / dati legali',
                value: d.contacts.vat,
                onChanged: (v) {
                  d.contacts.vat = v;
                  changed();
                },
              ),
            ],
          ),
        ),
        Panel(
          title: 'Tipi di festa nel preventivo',
          subtitle: 'Le voci del menù “Tipo di festa / evento” del modulo. “Altro” permette al cliente di specificare.',
          child: StringListEditor(
            items: d.eventTypes,
            addLabel: 'Nuovo tipo di evento',
            onChanged: (v) {
              d.eventTypes = v;
              changed();
            },
          ),
        ),
      ],
    );
  }
}
