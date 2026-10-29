import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

/// La home dell'app: il carosello a tutto schermo (verticale o orizzontale,
/// come lo schermo), sotto la barra trasparente, poi i lavori in evidenza uno sotto l'altro e le informazioni.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // Schermo in verticale: le foto verticali dell'app; girato in
    // orizzontale (telefono o tablet): quelle orizzontali del sito, saltando
    // (come sul sito) una verticale caricata per sbaglio.
    final landscape = context.w > context.h;
    final aspects = PhotoAspects.instance;
    if (landscape) aspects.resolveAll(s.siteCarousel);
    return ListenableBuilder(
      listenable: aspects,
      builder: (context, _) {
        final wide = [
          for (final u in s.siteCarousel)
            if (!aspects.notLandscape(u)) u,
        ];
        final photos = landscape
            ? (wide.isEmpty ? s.siteCarousel : wide)
            : s.appCarousel;
        final featured = s.featuredWorks;
        final h = context.h;
        return SiteScaffold(
          location: '/',
          photoUnderNav: photos.isEmpty ? null : h,
          children: [
            if (photos.isNotEmpty) AppCarousel(photos: photos, height: h),
            if (featured.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.gutter,
                  context.spaceSection,
                  context.gutter,
                  context.spaceSection,
                ),
                child: WorkList(works: featured),
              ),
          ],
        );
      },
    );
  }
}
