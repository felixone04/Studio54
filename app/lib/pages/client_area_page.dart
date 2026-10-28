import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/models.dart';
import '../services/media_saver.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/lightbox.dart';
import '../widgets/sections.dart' show MaskReveal, RoundIconButton;
import '../widgets/site_scaffold.dart';

// L'area clienti dell'app. Gli account li crea il titolare dal gestionale:
// il cliente entra con email (o nome utente) e password, guarda le foto e i
// video della sua festa e li scarica sul telefono in alta qualità. Con le
// sue credenziali il titolare entra da qui nel gestionale.

class ClientAreaPage extends StatelessWidget {
  const ClientAreaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().currentClient;
    return SiteScaffold(
      location: '/area-clienti',
      children: [c == null ? const SignInView() : _ClientHome(client: c)],
    );
  }
}

// ==================================================================== ACCESSO

class SignInView extends StatefulWidget {
  const SignInView({super.key, this.adminOnly = false});

  /// Dal gestionale: si accetta solo l'accesso del titolare.
  final bool adminOnly;

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _login = TextEditingController();
  final _pw = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    if (_login.text.trim().isEmpty || _pw.text.isEmpty) {
      setState(() => _error = 'Inserite email (o nome utente) e password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = widget.adminOnly
        ? (await s.loginAdmin(_login.text, _pw.text)
              ? SignIn.admin
              : SignIn.wrong)
        : await s.signIn(_login.text, _pw.text);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case SignIn.admin:
        _pw.clear();
        context.go('/admin');
      case SignIn.client:
        _pw.clear();
      case SignIn.wrong:
        setState(() => _error = 'Email, nome utente o password non corretti.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        context.fluid(30, 70),
        context.gutter,
        context.fluid(70, 120),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MaskReveal(
                  child: Tag(widget.adminOnly ? 'Gestionale' : 'Area clienti'),
                ),
                const SizedBox(height: 16),
                MaskReveal(
                  delay: 120,
                  child: Text(
                    widget.adminOnly ? 'Bentornato.' : 'Le vostre foto.',
                    style: display(context.fluid(38, 54), height: 1.05),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.adminOnly
                      ? 'Entra con le credenziali del titolare.'
                      : 'Entrate con l\'email (o il nome utente) e la password '
                            'che vi abbiamo mandato.',
                  style: body(15, color: Palette.stone),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _login,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.username,
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: widget.adminOnly
                        ? 'Nome utente'
                        : 'Email o nome utente',
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pw,
                  obscureText: !_show,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      tooltip: _show ? 'Nascondi' : 'Mostra',
                      onPressed: () => setState(() => _show = !_show),
                      icon: Icon(
                        _show
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: body(13.5, color: Palette.error)),
                ],
                const SizedBox(height: 22),
                PillButton(
                  'Entra',
                  big: true,
                  loading: _busy,
                  icon: Icons.arrow_forward_rounded,
                  onTap: _submit,
                ),
                const SizedBox(height: 18),
                Text(
                  widget.adminOnly
                      ? 'Prova: nome utente "titolare", password "studio54".'
                      : 'Non avete le credenziali? Scriveteci: ve le mandiamo noi.',
                  textAlign: TextAlign.center,
                  style: body(13, color: Palette.ash),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================ AREA DEL CLIENTE

class _ClientHome extends StatefulWidget {
  const _ClientHome({required this.client});
  final ClientAccount client;

  @override
  State<_ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<_ClientHome> {
  /// La cartella aperta (null = tutte le cartelle).
  String? _folder;

  /// Download in corso (id del file).
  final _saving = <String>{};

  void _snack(String m) {
    final s = ScaffoldMessenger.maybeOf(context);
    s?.hideCurrentSnackBar();
    s?.showSnackBar(SnackBar(content: Text(m)));
  }

  /// Si scarica una foto (o un video) alla volta, guardandola.
  Future<bool> _save(ClientMedia m) async {
    if (_saving.contains(m.id)) return false;
    setState(() => _saving.add(m.id));
    try {
      await mediaSaver.save(m);
      if (mounted) {
        _snack(
          m.isVideo
              ? 'Video salvato nella galleria (album Studio 54).'
              : 'Foto salvata nella galleria (album Studio 54).',
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        _snack(
          e is SaveException ? e.message : 'Download non riuscito: riprovate.',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving.remove(m.id));
    }
  }

  void _open(List<ClientMedia> media, int i) {
    showGeneralDialog(
      context: context,
      barrierColor: Palette.paper,
      barrierLabel: 'Chiudi',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
      pageBuilder: (ctx, _, _) => PhotoViewer(
        photos: [for (final m in media) m.isVideo ? m.poster : m.url],
        start: i,
        itemBuilder: (_, k) =>
            media[k].isVideo ? _VideoView(media: media[k]) : null,
        actions: (_, k) => [
          _DownloadButton(
            key: ValueKey(media[k].id),
            busy: _saving.contains(media[k].id),
            onTap: () => _save(media[k]),
          ),
        ],
      ),
    );
  }

  String _count(List<ClientMedia> l) {
    final v = l.where((m) => m.isVideo).length, p = l.length - v;
    return [
      if (p > 0) '$p foto',
      if (v > 0) '$v video',
    ].join(' · ').toUpperCase();
  }

  Widget _grid(List<ClientMedia> media) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth >= 720 ? 4 : (box.maxWidth >= 480 ? 3 : 2);
      const gap = 8.0;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < media.length; i++)
            SizedBox(
              width: w,
              height: w,
              child: _Tile(
                media: media[i],
                number: i + 1,
                onTap: () => _open(media, i),
              ),
            ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.client;
    final s = context.read<AppState>();
    final folder = c.folders.where((f) => f.id == _folder).firstOrNull;
    final info = [
      c.eventDate,
      c.location,
    ].where((e) => e.trim().isNotEmpty).join(' · ');

    final List<Widget> content;
    if (folder != null) {
      // Dentro una cartella: le sue foto, come sempre.
      final media = c.mediaIn(folder.id);
      content = [
        HoverLink(
          '← TUTTE LE CARTELLE',
          style: label(10.5, color: Palette.stone),
          onTap: () => setState(() => _folder = null),
        ),
        const SizedBox(height: 14),
        Text(
          folder.name.toUpperCase(),
          style: display(context.fluid(24, 36), spacing: 0.08, height: 1.15),
        ),
        const SizedBox(height: 6),
        Text(_count(media), style: label(10.5, color: Palette.stone)),
        const SizedBox(height: 18),
        if (media.isEmpty)
          Text(
            'Questa cartella è ancora vuota.',
            style: display(20, italic: true, color: Palette.stone),
          )
        else
          _grid(media),
      ];
    } else {
      final loose = c.mediaIn('');
      final folders = [
        for (final f in c.folders)
          if (c.mediaIn(f.id).isNotEmpty) f,
      ];
      content = [
        if (c.media.isEmpty)
          Text(
            'Le foto della vostra festa arriveranno qui a breve.',
            style: display(20, italic: true, color: Palette.stone),
          ),
        if (folders.isNotEmpty) ...[
          Text('LE CARTELLE', style: label(10.5)),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 720 ? 3 : 2;
              final gap = context.fluid(14, 22);
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap + 6,
                children: [
                  for (final f in folders)
                    SizedBox(
                      width: w,
                      child: _FolderCard(
                        name: f.name,
                        media: c.mediaIn(f.id),
                        count: _count(c.mediaIn(f.id)),
                        onTap: () => setState(() => _folder = f.id),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        if (loose.isNotEmpty) ...[
          if (folders.isNotEmpty) const SizedBox(height: 36),
          Text(
            folders.isEmpty ? _count(loose) : 'ALTRE FOTO · ${_count(loose)}',
            style: label(10.5),
          ),
          const SizedBox(height: 14),
          _grid(loose),
        ],
        if (c.media.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Toccate una foto o un video per vederlo grande e scaricarlo.',
            style: body(13, color: Palette.ash),
          ),
        ],
      ];
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        context.fluid(20, 50),
        context.gutter,
        context.fluid(60, 110),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: Tag('Area clienti')),
                  HoverLink(
                    'ESCI',
                    style: label(10.5, color: Palette.stone),
                    onTap: s.logoutClient,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                (c.eventTitle.trim().isEmpty ? c.name : c.eventTitle)
                    .toUpperCase(),
                style: display(
                  context.fluid(28, 46),
                  spacing: 0.06,
                  height: 1.12,
                ),
              ),
              if (info.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  info.toUpperCase(),
                  style: label(10.5, color: Palette.stone),
                ),
              ],
              if (c.welcome.trim().isNotEmpty && folder == null) ...[
                const SizedBox(height: 16),
                Text(
                  c.welcome,
                  style: body(15.5, color: Palette.stone, height: 1.65),
                ),
              ],
              const SizedBox(height: 28),
              ...content,
              if (c.files.isNotEmpty && folder == null) ...[
                const SizedBox(height: 40),
                Text('DOCUMENTI E LINK', style: label(10.5)),
                const SizedBox(height: 10),
                for (final f in c.files)
                  InkWell(
                    onTap: () => openUrl(f.url),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Palette.line)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            f.isLink
                                ? Icons.link_rounded
                                : Icons.picture_as_pdf_outlined,
                            color: context.accentInk,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.name,
                                  style: body(15, weight: FontWeight.w500),
                                ),
                                if (f.note.trim().isNotEmpty)
                                  Text(
                                    f.note,
                                    style: body(13, color: Palette.stone),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            f.isLink ? 'APRI' : 'SCARICA',
                            style: label(10, color: Palette.stone),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Una cartella dell'area clienti, come un piccolo album: tre foto
/// sovrapposte e un po' ruotate, il nome e quante foto contiene.
class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.name,
    required this.media,
    required this.count,
    required this.onTap,
  });
  final String name;
  final List<ClientMedia> media;
  final String count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final covers = [
      for (final m in media.take(3))
        if (m.thumb.isNotEmpty) m.thumb,
    ];
    Widget sheet(String? url, double turns, Offset shift) =>
        Transform.translate(
          offset: shift,
          child: Transform.rotate(
            angle: turns,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x261E1B17),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: url == null
                  ? const ColoredBox(color: Palette.linen)
                  : PhotoImage(url),
            ),
          ),
        );
    return Semantics(
      button: true,
      label: 'Cartella $name',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Palette.linen,
                padding: const EdgeInsets.all(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (covers.length > 2)
                      sheet(covers[2], 0.07, const Offset(6, 2)),
                    if (covers.length > 1)
                      sheet(covers[1], -0.06, const Offset(-5, 3)),
                    sheet(covers.firstOrNull, 0, Offset.zero),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 18, color: context.accentInk),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: display(17, spacing: 0.08, height: 1.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(count, style: label(9.5, color: Palette.stone)),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.media, required this.number, required this.onTap});
  final ClientMedia media;
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: media.isVideo ? 'Video $number' : 'Foto $number',
    child: GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhotoImage(media.thumb),
          if (media.isVideo)
            Center(
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.ink.withValues(alpha: 0.55),
                  border: Border.all(color: const Color(0xB3FFFFFF)),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _DownloadButton extends StatefulWidget {
  const _DownloadButton({super.key, required this.busy, required this.onTap});
  final bool busy;
  final Future<bool> Function() onTap;

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  late bool _busy = widget.busy;

  @override
  Widget build(BuildContext context) => PillButton(
    'Scarica',
    loading: _busy,
    icon: Icons.download_rounded,
    onTap: () async {
      setState(() => _busy = true);
      await widget.onTap();
      if (mounted) setState(() => _busy = false);
    },
  );
}

/// Un video della festa: l'anteprima, poi parte toccandolo.
class _VideoView extends StatefulWidget {
  const _VideoView({required this.media});
  final ClientMedia media;

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  VideoPlayerController? _c;
  bool _failed = false;

  Future<void> _start() async {
    if (_c != null) {
      setState(() => _c!.value.isPlaying ? _c!.pause() : _c!.play());
      return;
    }
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.media.url));
    setState(() => _c = c);
    try {
      await c.initialize();
      c.addListener(() {
        if (mounted) setState(() {});
      });
      await c.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    return GestureDetector(
      onTap: _failed ? null : _start,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (ready)
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            )
          else if (widget.media.poster.isNotEmpty)
            Positioned.fill(
              child: PhotoImage(widget.media.poster, fit: BoxFit.contain),
            ),
          if (_failed)
            Container(
              padding: const EdgeInsets.all(16),
              color: Palette.paper.withValues(alpha: 0.9),
              child: Text(
                'Il video non si riesce a riprodurre: potete comunque scaricarlo.',
                textAlign: TextAlign.center,
                style: body(14),
              ),
            )
          else if (!ready || !c.value.isPlaying)
            c != null && !ready
                ? const CircularProgressIndicator(color: Palette.ink)
                : RoundIconButton(
                    Icons.play_arrow_rounded,
                    _start,
                    'Guarda il video',
                    size: 64,
                  ),
        ],
      ),
    );
  }
}
