import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    // In orizzontale la foto d'apertura parte dal bordo in alto, sotto la
    // barra trasparente.
    final landscape = context.w > context.h;
    return SiteScaffold(
      location: '/',
      photoUnderNav: landscape ? context.screenH : null,
      children: [
        HeroSlideshow(content: c, photos: s.heroPhotos, underNav: landscape),
        if (c.manifestoTitle.trim().isNotEmpty)
          Statement(text: c.manifestoTitle, number: '01'),
        if (s.gallery.isNotEmpty) PrintsTable(photos: s.gallery, number: '02'),
      ],
    );
  }
}
