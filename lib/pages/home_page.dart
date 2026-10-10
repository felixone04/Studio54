import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    return SiteScaffold(
      location: '/',
      darkHero: true,
      children: [
        HeroSlideshow(content: c, photos: s.heroPhotos),
        if (c.manifestoTitle.trim().isNotEmpty)
          Statement(text: c.manifestoTitle, number: '01'),
        if (s.gallery.isNotEmpty)
          GalleryWall(content: c, photos: s.gallery, number: '02'),
        if (s.activeServices.isNotEmpty)
          ServicesStrip(
            title: c.servicesTitle,
            services: s.activeServices,
            number: '03',
          ),
      ],
    );
  }
}
