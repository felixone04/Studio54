import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/system_bars.dart';
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
    // Come sul sito: schermo in verticale, le foto verticali; in orizzontale
    // quelle orizzontali, saltando una verticale caricata per sbaglio. Se la
    // serie è vuota si usa l'altra.
    final landscape = context.w > context.h;
    final aspects = PhotoAspects.instance;
    if (landscape) aspects.resolveAll(s.siteCarousel);
    return ListenableBuilder(
      listenable: aspects,
      builder: (context, _) {
        final site = s.siteCarousel, app = s.appCarousel;
        final wide = [
          for (final u in site)
            if (!aspects.notLandscape(u)) u,
        ];
        final List<String> photos;
        if (landscape) {
          photos = site.isEmpty ? app : (wide.isEmpty ? site : wide);
        } else {
          photos = app.isEmpty ? site : app;
        }
        final featured = s.featuredWorks;
        // Il carosello riempie lo schermo. Quando le barre tornano visibili
        // (si è già scorso oltre la foto) resta alto anche la lineetta in
        // meno: così quel che segue non fa un salto.
        final h =
            context.h +
            (SystemBars.fullScreen.value
                ? 0
                : MediaQueryData.fromView(View.of(context)).padding.bottom);
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
