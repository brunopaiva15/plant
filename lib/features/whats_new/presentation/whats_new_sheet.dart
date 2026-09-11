import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../application/release_notes.dart';

/// La fenêtre des nouveautés.
///
/// Présentée par [showFloraScrollableFlow], donc native des deux côtés : sur
/// iOS la sheet empilée d'iOS 18, qui repousse l'écran en arrière-plan et se
/// ferme d'un glissement vers le bas une fois la page revenue en haut ; sur
/// Android le dialogue plein écran de Material 3, qui est le pendant
/// documenté d'un contenu modal aussi long.
/// Le dessin, lui, est le même des deux côtés — c'est la règle de la maison :
/// conventions de la plateforme, identité commune.
///
/// Elle rend la route du lien « en savoir plus » si l'utilisateur l'a suivi,
/// pour que l'appelant l'ouvre une fois la fenêtre refermée.
Future<void> showWhatsNew(BuildContext context, ReleaseNote note) async {
  final route = await showFloraScrollableFlow<String>(
    context,
    builder: (ctx, controller) => WhatsNewView(note: note, controller: controller),
  );
  if (route != null && context.mounted) context.push(route);
}

/// Le contenu de la fenêtre : un héros, un titre, trois points forts, et le
/// bouton qui referme.
class WhatsNewView extends StatelessWidget {
  const WhatsNewView({super.key, required this.note, this.controller});

  final ReleaseNote note;

  /// Le contrôleur que la sheet d'iOS prête à son contenu. Sans lui, elle
  /// remporte tous les gestes verticaux et la page ne défile pas —
  /// [showFloraScrollableFlow] raconte pourquoi. `null` sur Android, où la vue
  /// défilante garde le sien.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final side = Space.page + readableInset(context);

    void close([String? route]) => Navigator.of(context, rootNavigator: true).pop(route);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: controller,
                    physics: floraScrollPhysics,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ReleaseHero(note: note),
                        Padding(
                          padding: EdgeInsets.fromLTRB(side, Space.lg, side, Space.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.eyebrow.toUpperCase(),
                                style: context.text.caption.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: Space.xxs),
                              Text(note.title, style: context.text.display),
                              const SizedBox(height: Space.sm),
                              Text(note.body, style: context.text.body.copyWith(color: c.inkSecondary)),
                              const SizedBox(height: Space.xl),
                              for (final (i, h) in note.highlights.indexed) ...[
                                if (i > 0) const SizedBox(height: Space.lg),
                                _HighlightRow(highlight: h),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Le contenu se dissout dans le pied plutôt que d'y buter :
                // un voile de la couleur du fond, posé au ras du bouton.
                const Positioned(left: 0, right: 0, bottom: 0, child: IgnorePointer(child: _BottomVeil())),
                // La croix ne défile pas : elle reste là où le pouce la
                // cherche, quelle que soit la position dans la page.
                Positioned(
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(Space.sm),
                      child: FloraIconButton(
                        icon: CupertinoIcons.xmark,
                        size: 34,
                        semanticLabel: l10n.close,
                        onPressed: close,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, Space.xs, side, Space.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloraButton(label: l10n.continueLabel, expand: true, onPressed: close),
                  if (note.link != null)
                    FloraButton(
                      label: note.link!.label,
                      style: FloraButtonStyle.ghost,
                      size: FloraButtonSize.small,
                      trailingIcon: CupertinoIcons.chevron_right,
                      onPressed: () => close(note.link!.route),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le bandeau du haut : une teinte qui s'éteint dans le fond de la page, et
/// la marque posée au centre sur sa médaille d'argile.
class _ReleaseHero extends StatefulWidget {
  const _ReleaseHero({required this.note});

  final ReleaseNote note;

  @override
  State<_ReleaseHero> createState() => _ReleaseHeroState();
}

class _ReleaseHeroState extends State<_ReleaseHero> with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));

  @override
  void initState() {
    super.initState();
    _breath.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final note = widget.note;
    final tint = note.accent.color(c);
    final size = MediaQuery.sizeOf(context);
    // Le bandeau passe sous la barre d'état — c'est ce qui lui donne l'air
    // d'une image et non d'un en-tête —, et sa hauteur visible garde la même
    // proportion sur un petit téléphone que sur une tablette.
    final top = MediaQuery.paddingOf(context).top;
    final band = math.min(272.0, size.height * 0.32);
    final medal = math.min(band * 0.56, size.width * 0.36);
    // La médaille respire, comme les objets de l'onboarding. Avec « réduire
    // les animations », elle se pose à mi-course et n'en bouge plus.
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _breath.isAnimating) _breath.stop();
    if (!reduce && !_breath.isAnimating) _breath.repeat(reverse: true);

    return SizedBox(
      height: band + top,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // La teinte, du plus soutenu en haut au fond de la page en bas.
          // Mêlée au fond plutôt que posée dessus en transparence : les deux
          // thèmes et les deux contrastes élevés y gardent leur matière.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.alphaBlend(tint.withValues(alpha: c.isDark ? 0.30 : 0.20), c.canvas),
                    Color.alphaBlend(tint.withValues(alpha: c.isDark ? 0.14 : 0.09), c.canvas),
                    c.canvas,
                  ],
                  stops: const [0, 0.62, 1],
                ),
              ),
            ),
          ),
          // L'horizon : une lueur large et basse, sous la médaille.
          Positioned(
            left: 0,
            right: 0,
            top: top + band * 0.42,
            height: band * 0.52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.62,
                  colors: [tint.withValues(alpha: c.isDark ? 0.34 : 0.24), tint.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          // Les satellites : deux icônes de la page, effacées, qui flottent de
          // part et d'autre. Purement décoratives — VoiceOver les ignore.
          if (note.highlights.length >= 2)
            Positioned(
              top: top,
              bottom: 0,
              left: 0,
              right: 0,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Satellite(icon: note.highlights.first.icon, side: medal * 0.42, color: tint),
                    SizedBox(width: medal),
                    _Satellite(icon: note.highlights.last.icon, side: medal * 0.42, color: tint),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: top),
            child: _Breathing(
              progress: reduce ? const AlwaysStoppedAnimation(0.5) : _breath,
              // La médaille est de la couleur des cartes, et non de la teinte :
              // la marque d'Iris a ses propres couleurs, figées, et ce sont
              // les fonds `surface` des quatre palettes sur lesquels elles
              // sont garanties lisibles.
              child: ClayBox(
                color: c.surface,
                shape: const ClayShape.blob(),
                depth: ClayDepth.deep,
                width: medal,
                height: medal,
                alignment: Alignment.center,
                child: switch (note.mark) {
                  ReleaseMark.iris => IrisMark(size: medal * 0.66),
                  ReleaseMark.icon => Icon(note.icon ?? CupertinoIcons.sparkles, size: medal * 0.42, color: tint),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le flottement de la médaille : trois points de haut en bas, sans fin.
///
/// Un widget à part pour que le héros entier ne se reconstruise pas à chaque
/// image — seule cette branche suit l'animation.
class _Breathing extends StatelessWidget {
  const _Breathing({required this.progress, required this.child});

  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: progress,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -3 + 6 * Curves.easeInOut.transform(progress.value)),
          child: child,
        ),
        child: child,
      );
}

class _Satellite extends StatelessWidget {
  const _Satellite({required this.icon, required this.side, required this.color});

  final IconData icon;
  final double side;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      child: Icon(icon, size: side, color: color.withValues(alpha: 0.28)),
    );
  }
}

/// Un point fort : la pastille de couleur, le titre, deux lignes.
class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight});

  final ReleaseHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = highlight;
    // La pastille suit le texte : à 300 %, une tuile de 40 points à côté d'un
    // titre de 50 aurait l'air d'une miette. Elle s'arrête à 60 pour laisser
    // au texte la largeur dont il a besoin.
    final tile = MediaQuery.textScalerOf(context).scale(40).clamp(40.0, 60.0);
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClayBox(
            color: h.accent.soft(c),
            shape: ClayShape.rounded(tile * 0.32),
            width: tile,
            height: tile,
            alignment: Alignment.center,
            child: Icon(h.icon, size: tile * 0.5, color: h.accent.color(c)),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.title, style: context.text.title3),
                const SizedBox(height: 2),
                Text(h.body, style: context.text.callout),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le voile du bas : le fond de la page, rendu progressivement opaque sur la
/// dernière bande. Il n'y a rien dessous à lire — le bouton est en dessous,
/// hors de la zone de défilement —, seulement du texte qui s'efface au lieu
/// de se couper net.
class _BottomVeil extends StatelessWidget {
  const _BottomVeil();

  @override
  Widget build(BuildContext context) {
    final canvas = context.colors.canvas;
    return SizedBox(
      height: Space.xxl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [canvas.withValues(alpha: 0), canvas],
          ),
        ),
      ),
    );
  }
}
