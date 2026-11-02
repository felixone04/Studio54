import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/line_icons.dart';
import '../widgets/sections.dart' show RoundIconButton;
import '../widgets/site_scaffold.dart';

// La pagina "Privacy e cookie", come sul sito: informativa, cookie e note
// legali. I testi si scrivono nel gestionale e valgono per sito e app.

/// Il testo con i dati dello studio al posto di {studio}, {indirizzo}...
String fillLegal(String text, SiteContent c) => text
    .replaceAll('{studio}', c.studioName)
    .replaceAll('{indirizzo}', c.contacts.address)
    .replaceAll('{email}', c.contacts.email)
    .replaceAll('{telefono}', c.contacts.phone)
    .replaceAll('{piva}', c.contacts.vat);

/// Le tre parti della pagina: (ancora, titolo, testo).
List<(String, String, String)> legalParts(SiteContent c) => [
  ('privacy', 'Informativa privacy', c.privacyText),
  ('cookie', 'Cookie', c.cookieText),
  ('note-legali', 'Note legali', c.legalText),
].where((p) => p.$3.trim().isNotEmpty).toList();

/// Un testo legale: righe con "## " sono titoli, con "- " voci di elenco,
/// le altre paragrafi (una riga vuota li separa).
class LegalText extends StatelessWidget {
  const LegalText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    final para = <String>[];
    final list = <String>[];
    void close() {
      if (para.isNotEmpty) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(para.join(' '), style: body(15.5, height: 1.65)),
          ),
        );
        para.clear();
      }
      if (list.isNotEmpty) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final v in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 11, right: 12),
                          child: Container(
                            width: 10,
                            height: 1,
                            color: Palette.stone,
                          ),
                        ),
                        Expanded(
                          child: Text(v, style: body(15.5, height: 1.65)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
        list.clear();
      }
    }

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        close();
      } else if (line.startsWith('## ')) {
        close();
        blocks.add(
          Padding(
            padding: EdgeInsets.only(top: blocks.isEmpty ? 0 : 14, bottom: 10),
            child: Text(
              line.substring(3).toUpperCase(),
              style: display(17, spacing: 0.08, height: 1.3),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        if (para.isNotEmpty) close();
        list.add(line.substring(2));
      } else {
        if (list.isNotEmpty) close();
        para.add(line);
      }
    }
    close();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }
}

/// Le tre parti una sotto l'altra, ognuna col suo titolo piccolo.
class LegalBody extends StatelessWidget {
  const LegalBody({super.key, required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, (_, title, text)) in legalParts(content).indexed) ...[
        if (i > 0) ...[
          SizedBox(height: context.spaceBlock),
          Container(height: 1, color: Palette.line),
          SizedBox(height: context.spaceBlock),
        ],
        Text(title.toUpperCase(), style: label(11, color: Palette.stone)),
        const SizedBox(height: 18),
        LegalText(fillLegal(text, content)),
      ],
    ],
  );
}

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    return SiteScaffold(
      location: '/privacy',
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            context.spaceTop,
            context.gutter,
            context.spaceSection,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PRIVACY E COOKIE',
                    style: display(
                      context.fluid(26, 38),
                      spacing: 0.1,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: context.spaceBlock),
                  LegalBody(content: c),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// L'informativa sopra la pagina in cui si è (es. il preventivo), senza
/// lasciarla: chiudendo si ritrova tutto com'era.
Future<void> showLegal(BuildContext context) {
  final c = context.read<AppState>().content;
  return showGeneralDialog(
    context: context,
    barrierColor: Palette.paper,
    barrierLabel: 'Chiudi',
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, a, _, child) =>
        FadeTransition(opacity: a, child: child),
    pageBuilder: (ctx, _, _) => Material(
      color: Palette.paper,
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                ctx.gutter,
                72,
                ctx.gutter,
                ctx.spaceSection,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: LegalBody(content: c),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: RoundIconButton(
                Ico.close,
                () => Navigator.pop(ctx),
                'Chiudi',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
