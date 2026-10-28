import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

/// La home dell'app: il carosello verticale a tutto schermo, sotto la barra
/// trasparente, poi i lavori in evidenza uno sotto l'altro e le informazioni.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final photos = s.appCarousel;
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
              context.fluid(48, 100),
              context.gutter,
              context.fluid(56, 110),
            ),
            child: WorkList(works: featured),
          ),
      ],
    );
  }
}
