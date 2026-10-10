import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

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
      darkHero: true,
      children: [
        PageHero(
          image: c.bioImage,
          title: c.bioTitle,
          subtitle: c.bioIntro,
          kicker: c.tagline,
        ),
        if (paragraphs.isNotEmpty) _Story(paragraphs: paragraphs),
        if (c.timeline.isNotEmpty) _Timeline(items: c.timeline),
        if (c.team.isNotEmpty) _Team(title: c.teamTitle, members: c.team),
      ],
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.paragraphs});
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final lead = Reveal(
      child: Text(
        paragraphs.first,
        style: display(context.fluid(30, 64), height: 1.08),
      ),
    );
    final rest = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in paragraphs.skip(1))
          Reveal(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                p,
                style: body(
                  context.fluid(16, 19),
                  color: Palette.stone,
                  height: 1.75,
                ),
              ),
            ),
          ),
      ],
    );
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Tag('La storia', number: '01'),
          SizedBox(height: context.fluid(28, 48)),
          if (context.isTablet) ...[
            lead,
            SizedBox(height: context.fluid(24, 40)),
            rest,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: lead),
                SizedBox(width: context.fluid(40, 120)),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: rest,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});
  final List<Milestone> items;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cols = context.isPhone ? 2 : (items.length >= 4 ? 4 : items.length);
    return Section(
      color: Palette.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Tag('Il percorso', number: '02', color: Palette.paper),
          SizedBox(height: context.fluid(36, 70)),
          LayoutBuilder(
            builder: (context, box) {
              final gap = context.fluid(16, 32);
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: context.fluid(36, 56),
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
                              top: BorderSide(color: Palette.lineDark),
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
                                    context.fluid(56, 130),
                                    color: i.isOdd ? accent : Palette.paper,
                                    italic: i.isOdd,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                items[i].title.toUpperCase(),
                                style: label(11, color: Palette.paper),
                              ),
                              if (items[i].text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  items[i].text,
                                  style: body(14, color: Palette.ash),
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
    );
  }
}

class _Team extends StatelessWidget {
  const _Team({required this.title, required this.members});
  final String title;
  final List<TeamMember> members;

  @override
  Widget build(BuildContext context) {
    final cols = context.isPhone ? 2 : 3;
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Tag('Le persone', number: '03'),
          SizedBox(height: context.fluid(14, 22)),
          Reveal(
            child: Text(
              title,
              style: display(context.fluid(56, 160), height: 0.92),
            ),
          ),
          SizedBox(height: context.fluid(36, 80)),
          LayoutBuilder(
            builder: (context, box) {
              final gap = context.fluid(12, 32);
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: context.fluid(32, 56),
                children: [
                  for (var i = 0; i < members.length; i++)
                    SizedBox(
                      width: w,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: !context.isPhone && i % cols == 1
                              ? context.fluid(0, 100)
                              : 0,
                        ),
                        child: Reveal(
                          delay: Duration(milliseconds: 100 * (i % cols)),
                          child: _Member(member: members[i]),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Member extends StatefulWidget {
  const _Member({required this.member});
  final TeamMember member;

  @override
  State<_Member> createState() => _MemberState();
}

class _MemberState extends State<_Member> {
  bool _hover = false;

  static const _identity = <double>[
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];
  static const _gray = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  ColorFilter _filter(double t) => ColorFilter.matrix([
    for (var i = 0; i < 20; i++) _identity[i] + (_gray[i] - _identity[i]) * t,
  ]);

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final small = context.isPhone;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => setState(() => _hover = !_hover),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRect(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: _hover ? 0 : 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (_, t, child) => ColorFiltered(
                    colorFilter: _filter(t),
                    child: Transform.scale(
                      scale: 1 + (1 - t) * 0.05,
                      child: child,
                    ),
                  ),
                  child: SizedBox.expand(
                    child: PhotoImage(m.photo, alignment: Alignment.topCenter),
                  ),
                ),
              ),
            ),
            SizedBox(height: small ? 10 : 18),
            Text(
              m.name,
              style: display(small ? 20 : context.fluid(24, 38), height: 1.05),
            ),
            const SizedBox(height: 6),
            Text(
              m.role.toUpperCase(),
              style: label(small ? 9 : 10.5, color: context.accentInk),
            ),
            if (m.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(m.bio, style: body(14, color: Palette.stone)),
            ],
          ],
        ),
      ),
    );
  }
}
