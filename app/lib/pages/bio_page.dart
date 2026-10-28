import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

/// Biografia: poche parole, una foto, il metodo. Niente di più.
class BioPage extends StatelessWidget {
  const BioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    final paragraphs = c.bioStory
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return SiteScaffold(
      location: '/biografia',
      children: [
        _Intro(content: c, paragraphs: paragraphs),
        if (c.timeline.isNotEmpty) _Method(items: c.timeline),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.content, required this.paragraphs});
  final SiteContent content;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final c = content;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MaskReveal(
          child: Tag(c.tagline.trim().isEmpty ? 'Chi siamo' : c.tagline),
        ),
        SizedBox(height: context.fluid(16, 24)),
        MaskReveal(
          delay: 120,
          child: Text(
            c.bioTitle.toUpperCase(),
            style: display(context.fluid(34, 60), spacing: 0.08, height: 1.08),
          ),
        ),
        if (c.bioIntro.trim().isNotEmpty) ...[
          SizedBox(height: context.fluid(16, 22)),
          MaskReveal(
            delay: 240,
            child: Text(
              c.bioIntro,
              style: display(
                context.fluid(19, 26),
                color: Palette.stone,
                italic: true,
                height: 1.4,
              ),
            ),
          ),
        ],
        if (paragraphs.isNotEmpty) ...[
          SizedBox(height: context.fluid(28, 44)),
          Container(width: 48, height: 1, color: Palette.ink),
          SizedBox(height: context.fluid(28, 44)),
          for (var i = 0; i < paragraphs.length; i++)
            Reveal(
              delay: Duration(milliseconds: 80 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  paragraphs[i],
                  style: i == 0
                      ? display(context.fluid(20, 25), height: 1.5)
                      : body(
                          context.fluid(16, 18),
                          color: Palette.stone,
                          height: 1.75,
                        ),
                ),
              ),
            ),
        ],
      ],
    );
    final image = c.bioImage.trim().isEmpty
        ? null
        : Reveal(
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: PhotoImage(c.bioImage),
            ),
          );

    return Section(
      top: context.fluid(40, 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: context.isTablet || image == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text,
                    if (image != null) ...[
                      SizedBox(height: context.fluid(20, 40)),
                      image,
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: text),
                    SizedBox(width: context.fluid(40, 110)),
                    Expanded(flex: 5, child: image),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Il metodo di lavoro, in quattro tempi.
class _Method extends StatelessWidget {
  const _Method({required this.items});
  final List<Milestone> items;

  @override
  Widget build(BuildContext context) {
    final cols = context.isPhone ? 1 : (items.length >= 4 ? 4 : items.length);
    return Section(
      top: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 1, color: Palette.line),
              SizedBox(height: context.fluid(56, 120)),
              const Tag('Il metodo'),
              SizedBox(height: context.fluid(30, 56)),
              LayoutBuilder(
                builder: (context, box) {
                  final gap = context.fluid(16, 32);
                  final w = (box.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: context.fluid(28, 48),
                    children: [
                      for (var i = 0; i < items.length; i++)
                        SizedBox(
                          width: w,
                          child: Reveal(
                            delay: Duration(milliseconds: 100 * (i % cols)),
                            child: Container(
                              padding: const EdgeInsets.only(top: 18),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Palette.lineStrong),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      items[i].year,
                                      style: display(
                                        context.fluid(30, 48),
                                        color: context.accentInk,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    items[i].title.toUpperCase(),
                                    style: label(11),
                                  ),
                                  if (items[i].text.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      items[i].text,
                                      style: body(14.5, color: Palette.stone),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
