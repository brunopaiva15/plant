import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import 'pressable.dart';

/// Profondeur : légère pour une carte posée sur la feuille, franche pour un
/// bouton plein ou une carte de couleur. Les pièces sont désormais des
/// aplats ; la profondeur ne décide plus que de ce que les appelants en
/// font (une carte franche prend un accent vif).
enum ClayDepth { light, deep }

/// La forme d'une pièce : coins ronds réguliers, pilule, ou tuile.
class ClayShape {
  const ClayShape.rounded(this.radius) : blob = -1;

  const ClayShape.pill() : radius = 999, blob = -1;

  /// Une tuile : un carré aux coins francs, arrondis au tiers de son petit
  /// côté. [variant] ne change plus la forme — les pâtes irrégulières de la
  /// première direction sont parties avec l'argile —, il reste pour les
  /// appelants qui variaient les tuiles d'une rangée.
  const ClayShape.blob([int variant = 0]) : radius = 0, blob = variant;

  final double radius;
  final int blob;

  RRect toRRect(Rect rect) {
    if (blob < 0) return RRect.fromRectAndRadius(rect, Radius.circular(radius));
    return RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.32));
  }
}

/// Une pièce : un aplat de couleur franche dans sa forme, qui fonce d'un
/// cran sous le doigt. [floating] lui donne une ombre portée, pour ce qui
/// flotte au-dessus du contenu.
///
/// C'est la matière de l'app : cartes, boutons, tuiles. Le nom vient de la
/// première direction, en argile ; le dessin, lui, est devenu plat. Le
/// contenu est rogné à la forme quand [clip] est vrai.
class ClayBox extends StatelessWidget {
  const ClayBox({
    super.key,
    required this.color,
    required this.child,
    this.shape = const ClayShape.rounded(24),
    this.depth = ClayDepth.light,
    this.padding = EdgeInsets.zero,
    this.clip = false,
    this.width,
    this.height,
    this.minHeight,
    this.alignment,
    this.floating = false,
  });

  final Color color;
  final Widget child;
  final ClayShape shape;
  final ClayDepth depth;
  final EdgeInsetsGeometry padding;
  final bool clip;
  final double? width;
  final double? height;

  /// Hauteur plancher : la pièce ne descend pas en dessous, mais grandit si
  /// son contenu le demande — un libellé qui passe à deux lignes quand
  /// l'utilisateur agrandit le texte, par exemple.
  final double? minHeight;
  final AlignmentGeometry? alignment;

  /// Une ombre portée, pour une pièce qui flotte au-dessus du contenu.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget content = Padding(padding: padding, child: child);
    if (alignment != null) content = Align(alignment: alignment!, child: content);
    if (clip) content = _ClayClip(shape: shape, child: content);
    content = minHeight == null
        ? SizedBox(width: width, height: height, child: content)
        : ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight!),
            child: SizedBox(width: width, height: height, child: content),
          );
    // Sous un [Pressable], la pièce s'enfonce pendant qu'on appuie : seul le
    // peintre repasse, le contenu ne se reconstruit pas.
    final press = PressDepth.maybeOf(context);
    return RepaintBoundary(
      child: press == null
          ? CustomPaint(
              painter: ClayPainter(color: color, shape: shape, depth: depth, dark: c.isDark, floating: floating),
              child: content,
            )
          : AnimatedBuilder(
              animation: press,
              builder: (context, child) => CustomPaint(
                painter: ClayPainter(color: color, shape: shape, depth: depth, dark: c.isDark, floating: floating, press: press.value.clamp(0.0, 1.0)),
                child: child,
              ),
              child: content,
            ),
    );
  }
}

class _ClayClip extends StatelessWidget {
  const _ClayClip({required this.shape, required this.child});

  final ClayShape shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(clipper: _ShapeClipper(shape), child: child);
  }
}

class _ShapeClipper extends CustomClipper<Path> {
  const _ShapeClipper(this.shape);

  final ClayShape shape;

  @override
  Path getClip(Size size) => Path()..addRRect(shape.toRRect(Offset.zero & size));

  @override
  bool shouldReclip(_ShapeClipper old) => old.shape.radius != shape.radius || old.shape.blob != shape.blob;
}

/// Le peintre des pièces, exposé pour les décors qui ne passent pas par
/// [ClayBox].
class ClayPainter extends CustomPainter {
  const ClayPainter({required this.color, required this.shape, required this.depth, required this.dark, this.floating = false, this.press = 0});

  final Color color;
  final ClayShape shape;
  final ClayDepth depth;
  final bool dark;
  final bool floating;

  /// De 0 (au repos) à 1 (enfoncée sous le doigt).
  final double press;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintClay(canvas, Path()..addRRect(shape.toRRect(rect)), bounds: rect, color: color, depth: depth, dark: dark, dropShadow: floating, press: press);
  }

  @override
  bool shouldRepaint(ClayPainter old) => old.color != color || old.shape.radius != shape.radius || old.shape.blob != shape.blob || old.depth != depth || old.dark != dark || old.floating != floating || old.press != press;
}

/// La recette d'une pièce, sur n'importe quel [path] : un aplat franc, sans
/// reflet ni ombre logée — la couleur fait le relief. [bounds] proportionne
/// l'ombre portée.
///
/// L'ombre portée ne reste qu'aux pièces qui flottent au-dessus du contenu
/// ([dropShadow]) : un toast, une barre de sélection. Posée sur la feuille,
/// une carte n'en a pas besoin, son aplat la détache déjà.
///
/// [press], de 0 à 1, enfonce la pièce : l'aplat fonce d'un cran sous le
/// doigt. C'est le même dessin, sous le doigt — pas une autre pièce.
void paintClay(Canvas canvas, Path path, {required Rect bounds, required Color color, required ClayDepth depth, required bool dark, bool dropShadow = false, double press = 0}) {
  if (dropShadow) {
    final unit = (bounds.shortestSide / 48).clamp(0.6, 1.6);
    canvas.drawPath(
      path.shift(Offset(0, 8 * unit * (1 - 0.5 * press))),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.40 : 0.14)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * unit),
    );
  }
  canvas.drawPath(path, Paint()..color = color);
  if (press > 0) {
    canvas.drawPath(path, Paint()..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.08 * press));
  }
}
