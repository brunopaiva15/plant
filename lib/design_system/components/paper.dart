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
/// Trois perforations en haut renforcent l'idée d'une vraie fiche cartonnée.
class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(Space.lg, Space.huge, Space.lg, Space.xxl),
    this.corner = true,
    this.holes = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Le coin replié : la page a été tournée, puis laissée ouverte.
  final bool corner;

  /// Trois trous de classeur, percés dans le haut de la fiche.
  final bool holes;

  /// Taille du coin replié.
  static const double _fold = 22;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final paper = c.surfaceElevated;

    final paperTop = Color.alphaBlend(
      Colors.white.withValues(alpha: c.isDark ? 0.025 : 0.22),
      paper,
    );
    final paperBottom = Color.alphaBlend(
      (c.isDark ? Colors.black : c.shadow).withValues(alpha: c.isDark ? 0.055 : 0.025),
      paper,
    );

    final fold = corner ? _fold : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // La face et son ombre partagent exactement la même silhouette. Le
        // coin inférieur droit est donc réellement absent au lieu d'être
        // recouvert par un triangle couleur canvas.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _PaperSheetPainter(
                fold: fold,
                paper: paper,
                paperTop: paperTop,
                paperBottom: paperBottom,
                border: c.line.withValues(alpha: c.isDark ? 0.62 : 0.88),
                shadowFar: c.isDark
                    ? Colors.black.withValues(alpha: 0.30)
                    : c.shadow.withValues(alpha: 0.10),
                shadowNear: c.isDark
                    ? Colors.black.withValues(alpha: 0.24)
                    : c.shadow.withValues(alpha: 0.12),
                topHighlight: Colors.white.withValues(alpha: c.isDark ? 0.08 : 0.50),
              ),
            ),
          ),
        ),
        ClipPath(
          clipper: _PaperSheetClipper(fold),
          child: Stack(
            children: [
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
              if (holes)
                Positioned(
                  top: Space.sm,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: _PaperHoles(
                      canvasColor: c.canvas,
                      line: c.line,
                      shadow: c.shadow,
                      dark: c.isDark,
                    ),
                  ),
                ),
            ],
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

Path _paperSheetPath(Size size, {required double radius, required double fold}) {
  final maxRadius = size.shortestSide / 2;
  final r = radius < maxRadius ? radius : maxRadius;
  final maxFold = size.shortestSide / 2;
  final f = fold < maxFold ? fold : maxFold;

  return Path()
    ..moveTo(r, 0)
    ..lineTo(size.width - r, 0)
    ..quadraticBezierTo(size.width, 0, size.width, r)
    ..lineTo(size.width, size.height - f)
    ..lineTo(size.width - f, size.height)
    ..lineTo(r, size.height)
    ..quadraticBezierTo(0, size.height, 0, size.height - r)
    ..lineTo(0, r)
    ..quadraticBezierTo(0, 0, r, 0)
    ..close();
}

class _PaperSheetClipper extends CustomClipper<Path> {
  const _PaperSheetClipper(this.fold);

  final double fold;

  @override
  Path getClip(Size size) => _paperSheetPath(
        size,
        radius: Radii.small,
        fold: fold,
      );

  @override
  bool shouldReclip(_PaperSheetClipper oldClipper) => oldClipper.fold != fold;
}

/// Peint la silhouette de la feuille elle-même, ombres comprises.
///
/// Une seule géométrie sert au fond, au filet et à l'ombre : le coin corné ne
/// peut ainsi plus laisser derrière lui un second coin rectangulaire.
class _PaperSheetPainter extends CustomPainter {
  const _PaperSheetPainter({
    required this.fold,
    required this.paper,
    required this.paperTop,
    required this.paperBottom,
    required this.border,
    required this.shadowFar,
    required this.shadowNear,
    required this.topHighlight,
  });

  final double fold;
  final Color paper;
  final Color paperTop;
  final Color paperBottom;
  final Color border;
  final Color shadowFar;
  final Color shadowNear;
  final Color topHighlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final path = _paperSheetPath(
      size,
      radius: Radii.small,
      fold: fold,
    );

    canvas.drawShadow(path, shadowFar, 9, false);
    canvas.drawShadow(path, shadowNear, 2.5, false);

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [paperTop, paper, paperBottom],
          stops: const [0, 0.28, 1],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = border,
    );

    // Reflet de tranche supérieur, volontairement interrompu sur les côtés.
    final left = 16.0;
    final right = size.width - 16.0;
    if (right > left) {
      canvas.drawLine(
        Offset(left, 1),
        Offset(right, 1),
        Paint()
          ..strokeWidth = 1
          ..shader = LinearGradient(
            colors: [Colors.transparent, topHighlight, Colors.transparent],
            stops: const [0, 0.5, 1],
          ).createShader(Rect.fromLTRB(left, 0, right, 2)),
      );
    }
  }

  @override
  bool shouldRepaint(_PaperSheetPainter old) =>
      old.fold != fold ||
      old.paper != paper ||
      old.paperTop != paperTop ||
      old.paperBottom != paperBottom ||
      old.border != border ||
      old.shadowFar != shadowFar ||
      old.shadowNear != shadowNear ||
      old.topHighlight != topHighlight;
}

/// Trois perforations discrètes. Le centre reprend vraiment la couleur du
/// canvas : la fiche paraît percée plutôt que décorée de trois pastilles.
class _PaperHoles extends StatelessWidget {
  const _PaperHoles({
    required this.canvasColor,
    required this.line,
    required this.shadow,
    required this.dark,
  });

  final Color canvasColor;
  final Color line;
  final Color shadow;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PaperHole(canvasColor: canvasColor, line: line, shadow: shadow, dark: dark),
        const SizedBox(width: Space.xxl),
        _PaperHole(canvasColor: canvasColor, line: line, shadow: shadow, dark: dark),
        const SizedBox(width: Space.xxl),
        _PaperHole(canvasColor: canvasColor, line: line, shadow: shadow, dark: dark),
      ],
    );
  }
}

class _PaperHole extends StatelessWidget {
  const _PaperHole({
    required this.canvasColor,
    required this.line,
    required this.shadow,
    required this.dark,
  });

  final Color canvasColor;
  final Color line;
  final Color shadow;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(11),
      painter: _PaperHolePainter(
        canvasColor: canvasColor,
        line: line,
        shadow: shadow,
        dark: dark,
      ),
    );
  }
}

class _PaperHolePainter extends CustomPainter {
  const _PaperHolePainter({
    required this.canvasColor,
    required this.line,
    required this.shadow,
    required this.dark,
  });

  final Color canvasColor;
  final Color line;
  final Color shadow;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;

    // Petite lèvre sombre en haut-gauche, comme sur du carton perforé.
    canvas.drawCircle(
      center.translate(-0.35, -0.45),
      radius + 0.7,
      Paint()..color = shadow.withValues(alpha: dark ? 0.34 : 0.16),
    );

    canvas.drawCircle(center, radius, Paint()..color = canvasColor);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..color = line.withValues(alpha: dark ? 0.46 : 0.70),
    );

    // Reflet inférieur très fin sur la tranche du papier.
    final rect = Rect.fromCircle(center: center, radius: radius - 0.45);
    canvas.drawArc(
      rect,
      0.20,
      2.70,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65
        ..color = Colors.white.withValues(alpha: dark ? 0.05 : 0.42),
    );
  }

  @override
  bool shouldRepaint(_PaperHolePainter old) =>
      old.canvasColor != canvasColor ||
      old.line != line ||
      old.shadow != shadow ||
      old.dark != dark;
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

/// Le dessous du coin replié.
///
/// Le triangle extérieur n'est plus peint ici : il n'existe déjà plus dans le
/// path de la feuille. Le painter ne dessine donc que le papier retourné, ce
/// qui évite le double coin visible sur les anciennes captures.
class _FoldPainter extends CustomPainter {
  const _FoldPainter({
    required this.paper,
    required this.shadow,
    required this.line,
    required this.dark,
  });

  final Color paper;
  final Color shadow;
  final Color line;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.shortestSide;

    // Dans le carré du coin, cette moitié est à l'intérieur de la feuille :
    // c'est la partie retournée. La moitié sous la diagonale reste vide et
    // laisse apparaître le canvas grâce à la silhouette découpée.
    final fold = Path()
      ..moveTo(0, c)
      ..lineTo(0, 0)
      ..quadraticBezierTo(c * 0.58, c * 0.10, c, 0)
      ..close();
    final foldRect = Rect.fromLTWH(0, 0, c, c);

    canvas.drawPath(
      fold,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color.alphaBlend(
              (dark ? Colors.black : shadow).withValues(alpha: dark ? 0.30 : 0.11),
              paper,
            ),
            Color.alphaBlend(
              Colors.white.withValues(alpha: dark ? 0.025 : 0.15),
              paper,
            ),
          ],
        ).createShader(foldRect),
    );

    // Un seul pli net et un reflet très faible : pas de seconde diagonale qui
    // puisse être lue comme un coin dupliqué.
    canvas.drawLine(
      Offset(0, c),
      Offset(c, 0),
      Paint()
        ..color = shadow.withValues(alpha: dark ? 0.46 : 0.23)
        ..strokeWidth = 0.9,
    );
    canvas.drawLine(
      Offset(1.6, c - 2.4),
      Offset(c - 2.4, 1.6),
      Paint()
        ..color = line.withValues(alpha: dark ? 0.22 : 0.30)
        ..strokeWidth = 0.45,
    );
  }

  @override
  bool shouldRepaint(_FoldPainter old) =>
      old.paper != paper ||
      old.shadow != shadow ||
      old.line != line ||
      old.dark != dark;
}
