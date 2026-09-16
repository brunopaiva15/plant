import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// La feuille de papier : un support, pas une pièce d'argile.
///
/// L'application est faite d'argile — ombres décalées, reflets intérieurs,
/// coins de pâte ; une feuille, elle, est posée à plat. Elle se lit par sa
/// teinte, un cran plus claire que le canvas, par une ombre douce qui tombe
/// droit sous elle, par son filet, et par son coin corné en bas à droite.
/// Les cartes d'argile qui reposent dessus gardent leur relief : deux
/// matières, et c'est leur écart qui dit que la fiche est un objet.
///
/// Le papier n'est pas parfaitement plat : une lumière très légère accroche
/// son bord supérieur et quelques fibres presque invisibles cassent l'aplat.
/// Ces détails restent volontairement plus faibles que le relief des cartes.
///
/// Le coin s'efface dans la couleur du canvas, et emporte l'ombre portée du
/// coin avec lui. La feuille se pose donc sur le fond crème des pages, et
/// nulle part ailleurs ; posée sur une autre surface, le coin se verrait.
class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.xxl),
    this.corner = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Le coin replié : la page a été tournée, puis laissée ouverte.
  final bool corner;

  /// La taille du coin replié. Le bas de [padding] lui laisse la place.
  static const double _fold = 22;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(Radii.small);
    final paper = c.surfaceElevated;

    // Une variation verticale minuscule suffit à donner une face au papier.
    // Elle reste axée haut → bas : la lumière de la fiche vient du dessus,
    // contrairement aux pièces d'argile volontairement plus modelées.
    final paperTop = Color.alphaBlend(
      Colors.white.withValues(alpha: c.isDark ? 0.025 : 0.22),
      paper,
    );
    final paperBottom = Color.alphaBlend(
      (c.isDark ? Colors.black : c.shadow).withValues(alpha: c.isDark ? 0.055 : 0.025),
      paper,
    );

    return Stack(
      // L'ombre tombe sous la feuille, donc hors d'elle : c'est la pile qui ne
      // doit pas la rogner.
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [paperTop, paper, paperBottom],
              stops: const [0, 0.28, 1],
            ),
            borderRadius: radius,
            border: Border.all(
              color: c.line.withValues(alpha: c.isDark ? 0.62 : 0.88),
              width: 0.8,
            ),
            // Deux ombres plutôt qu'une grosse : la première pose la feuille
            // sur le canvas, la seconde garde un contact net près du bord.
            boxShadow: [
              BoxShadow(
                color: c.isDark
                    ? Colors.black.withValues(alpha: 0.30)
                    : c.shadow.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: c.isDark
                    ? Colors.black.withValues(alpha: 0.24)
                    : c.shadow.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // Le grain est peint derrière le contenu et ignore les gestes.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PaperTexturePainter(
                        fiber: c.line,
                        dark: c.isDark,
                      ),
                    ),
                  ),
                ),
                Padding(padding: padding, child: child),
                // Un reflet de tranche, court et neutre : suffisamment présent
                // pour lire la feuille, pas assez pour devenir un encadrement.
                Positioned(
                  left: 2,
                  right: 2,
                  top: 1,
                  child: IgnorePointer(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: c.isDark ? 0.08 : 0.52),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (corner)
          Positioned(
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size.square(_fold),
                painter: _FoldPainter(
                  paper: paper,
                  canvasColor: c.canvas,
                  shadow: c.shadow,
                  line: c.line,
                  dark: c.isDark,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Texture sèche et très légère du papier.
///
/// Elle est déterministe : pas d'animation ni de changement de grain à chaque
/// rebuild. Les fibres sont assez espacées pour ne jamais concurrencer le
/// texte ou les cartes posées par-dessus.
class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter({required this.fiber, required this.dark});

  final Color fiber;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    var state = 0x29a3f51;
    double nextUnit() {
      state = (1103515245 * state + 12345) & 0x7fffffff;
      return state / 0x7fffffff;
    }

    final count = (size.width * size.height / 5200).clamp(14, 72).round();
    final paint = Paint()
      ..color = fiber.withValues(alpha: dark ? 0.055 : 0.12)
      ..strokeWidth = 0.55
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < count; i++) {
      final x = nextUnit() * size.width;
      final y = nextUnit() * size.height;
      final length = 4 + nextUnit() * 11;
      final drift = (nextUnit() - 0.5) * 0.8;
      final x2 = (x + length).clamp(0, size.width).toDouble();
      final y2 = (y + drift).clamp(0, size.height).toDouble();
      canvas.drawLine(Offset(x, y), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_PaperTexturePainter old) => old.fiber != fiber || old.dark != dark;
}

/// Le coin corné, peint sur la feuille : le coin s'en va, le dessous du papier
/// se replie dessus, et le pli reste marqué.
class _FoldPainter extends CustomPainter {
  const _FoldPainter({
    required this.paper,
    required this.canvasColor,
    required this.shadow,
    required this.line,
    required this.dark,
  });

  final Color paper;
  final Color canvasColor;
  final Color shadow;
  final Color line;
  final bool dark;

  /// De combien le coin coupé déborde, pour emporter l'ombre portée avec lui.
  static const double _spill = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.shortestSide;

    // Le coin de la feuille s'en va : le fond de la page reprend sa place et
    // masque en même temps la portion d'ombre qui aurait trahi le triangle.
    canvas.drawPath(
      Path()
        ..moveTo(0, c)
        ..lineTo(c, 0)
        ..lineTo(c + _spill, c + _spill)
        ..close(),
      Paint()..color = canvasColor,
    );

    final fold = Path()
      ..moveTo(0, c)
      ..lineTo(0, 0)
      ..quadraticBezierTo(c * 0.56, c * 0.12, c, 0)
      ..close();
    final foldRect = Rect.fromLTWH(0, 0, c, c);

    // Le dessous reçoit un dégradé court : sombre près du pli, plus clair vers
    // la pointe. Cela donne une épaisseur au coin sans en faire une tuile.
    canvas.drawPath(
      fold,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color.alphaBlend(
              (dark ? Colors.black : shadow).withValues(alpha: dark ? 0.34 : 0.12),
              paper,
            ),
            Color.alphaBlend(
              Colors.white.withValues(alpha: dark ? 0.025 : 0.16),
              paper,
            ),
          ],
        ).createShader(foldRect),
    );

    // Le pli principal puis son petit reflet intérieur : deux traits fins
    // suffisent à rendre le papier courbé plutôt que simplement découpé.
    canvas.drawLine(
      Offset(0, c),
      Offset(c, 0),
      Paint()
        ..color = shadow.withValues(alpha: dark ? 0.52 : 0.25)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(2, c - 2),
      Offset(c - 2, 2),
      Paint()
        ..color = line.withValues(alpha: dark ? 0.46 : 0.72)
        ..strokeWidth = 0.65,
    );
  }

  @override
  bool shouldRepaint(_FoldPainter old) =>
      old.paper != paper ||
      old.canvasColor != canvasColor ||
      old.shadow != shadow ||
      old.line != line ||
      old.dark != dark;
}
