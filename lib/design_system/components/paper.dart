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
  static const double _fold = 18;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      // L'ombre tombe sous la feuille, donc hors d'elle : c'est la pile qui ne
      // doit pas la rogner.
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surfaceElevated,
            borderRadius: BorderRadius.circular(Radii.small),
            border: Border.all(color: c.line.withValues(alpha: c.isDark ? 0.55 : 0.9)),
            boxShadow: [
              BoxShadow(
                color: c.isDark ? Colors.black.withValues(alpha: 0.35) : c.shadow,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
        if (corner)
          Positioned(
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size.square(_fold),
              painter: _FoldPainter(paper: c.surfaceElevated, canvasColor: c.canvas, shadow: c.shadow, dark: c.isDark),
            ),
          ),
      ],
    );
  }
}

/// Le coin corné, peint sur la feuille : le coin s'en va, le dessous du papier
/// se replie dessus, et le pli reste marqué.
class _FoldPainter extends CustomPainter {
  const _FoldPainter({required this.paper, required this.canvasColor, required this.shadow, required this.dark});

  final Color paper;
  final Color canvasColor;
  final Color shadow;
  final bool dark;

  /// De combien le coin coupé déborde, pour emporter l'ombre portée avec lui.
  static const double _spill = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.shortestSide;
    // Le coin de la feuille s'en va : le fond de la page reprend sa place.
    canvas.drawPath(
      Path()
        ..moveTo(0, c)
        ..lineTo(c, 0)
        ..lineTo(c + _spill, c + _spill)
        ..close(),
      Paint()..color = canvasColor,
    );
    // Le dessous du papier, un peu plus mat que le dessus.
    canvas.drawPath(
      Path()
        ..moveTo(0, c)
        ..lineTo(0, 0)
        ..lineTo(c, 0)
        ..close(),
      Paint()..color = Color.alphaBlend((dark ? Colors.black : shadow).withValues(alpha: dark ? 0.45 : 0.12), paper),
    );
    // Le pli, du côté de la feuille.
    canvas.drawLine(
      Offset(0, c),
      Offset(c, 0),
      Paint()
        ..color = shadow.withValues(alpha: dark ? 0.5 : 0.25)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_FoldPainter old) => old.paper != paper || old.canvasColor != canvasColor || old.shadow != shadow || old.dark != dark;
}
