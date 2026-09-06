import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';

/// Profondeur du relief : léger pour une carte crème, franc pour un bouton
/// plein ou une carte de couleur.
enum ClayDepth { light, deep }

/// La forme d'une pièce d'argile : coins ronds réguliers, pilule, ou pâte
/// aux coins irréguliers — quatre variantes, pour que deux tuiles voisines
/// ne soient jamais identiques.
class ClayShape {
  const ClayShape.rounded(this.radius) : blob = -1;

  const ClayShape.pill()
      : radius = 999,
        blob = -1;

  /// Une forme de pâte. [variant] choisit parmi quatre gabarits ; passer un
  /// index de liste suffit à varier les tuiles d'une rangée.
  const ClayShape.blob([int variant = 0])
      : radius = 0,
        blob = variant;

  final double radius;
  final int blob;

  /// Rayons des pâtes, en fractions de la largeur et de la hauteur : coin
  /// haut gauche, haut droit, bas droit, bas gauche, chacun (x, y).
  static const _blobs = <List<double>>[
    [0.45, 0.50, 0.55, 0.45, 0.50, 0.55, 0.50, 0.50],
    [0.55, 0.45, 0.45, 0.55, 0.50, 0.50, 0.50, 0.50],
    [0.40, 0.50, 0.60, 0.45, 0.55, 0.55, 0.45, 0.50],
    [0.50, 0.55, 0.50, 0.45, 0.40, 0.55, 0.60, 0.45],
  ];

  RRect toRRect(Rect rect) {
    if (blob < 0) return RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final b = _blobs[blob % _blobs.length];
    final w = rect.width, h = rect.height;
    return RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.elliptical(w * b[0], h * b[1]),
      topRight: Radius.elliptical(w * b[2], h * b[3]),
      bottomRight: Radius.elliptical(w * b[4], h * b[5]),
      bottomLeft: Radius.elliptical(w * b[6], h * b[7]),
    ).scaleRadii();
  }
}

/// Une pièce d'argile : une couleur pleine, un bord clair en haut à gauche,
/// une ombre logée en bas à droite, et une ombre portée dans sa teinte.
///
/// C'est la matière de l'app : cartes, boutons, tuiles, barre d'onglets.
/// Le relief est peint, pas simulé par une ombre plate ; les deux ombres
/// intérieures sont ce qui fait la pâte. Le contenu est rogné à la forme
/// quand [clip] est vrai.
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
    this.alignment,
  });

  final Color color;
  final Widget child;
  final ClayShape shape;
  final ClayDepth depth;
  final EdgeInsetsGeometry padding;
  final bool clip;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget content = Padding(padding: padding, child: child);
    if (alignment != null) content = Align(alignment: alignment!, child: content);
    if (clip) content = _ClayClip(shape: shape, child: content);
    return RepaintBoundary(
      child: CustomPaint(
        painter: ClayPainter(color: color, shape: shape, depth: depth, dark: c.isDark),
        child: SizedBox(width: width, height: height, child: content),
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

/// Le peintre de l'argile, exposé pour les décors qui ne passent pas par
/// [ClayBox].
class ClayPainter extends CustomPainter {
  const ClayPainter({required this.color, required this.shape, required this.depth, required this.dark});

  final Color color;
  final ClayShape shape;
  final ClayDepth depth;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = shape.toRRect(rect);
    final path = Path()..addRRect(rrect);
    final deep = depth == ClayDepth.deep;
    // Le relief s'accorde à la taille : une tuile de 40 points n'a pas
    // l'ombre d'une carte de 300.
    final unit = (size.shortestSide / 48).clamp(0.6, 1.6);
    final shade = Color.lerp(color, Colors.black, 0.3)!;

    // L'ombre portée, dans la teinte de la pièce, décalée en bas à droite :
    // la lumière vient d'un coin.
    final drop = deep ? (dark ? 0.32 : 0.24) : (dark ? 0.28 : 0.14);
    canvas.drawPath(
      path.shift(Offset(5 * unit, 7 * unit)),
      Paint()
        ..color = (dark ? Colors.black : shade).withValues(alpha: drop)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * unit),
    );
    canvas.drawPath(path, Paint()..color = color);

    // Les ombres intérieures : tout ce qui est hors de la forme, décalé et
    // flouté, rogné à la forme. Décalé vers le bas à droite, le trou laisse
    // une lumière en haut à gauche ; vers le haut à gauche, une ombre en
    // bas à droite.
    final outside = rect.inflate(size.shortestSide);
    Path rim(Offset by) => Path.combine(PathOperation.difference, Path()..addRect(outside), path.shift(by));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
      rim(Offset(3 * unit, 3 * unit)),
      Paint()
        ..color = Colors.white.withValues(alpha: deep ? (dark ? 0.22 : 0.30) : (dark ? 0.10 : 0.75))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * unit),
    );
    canvas.drawPath(
      rim(Offset(-4 * unit, -5 * unit)),
      Paint()
        ..color = shade.withValues(alpha: deep ? (dark ? 0.40 : 0.28) : (dark ? 0.35 : 0.10))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * unit),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ClayPainter old) =>
      old.color != color || old.shape.radius != shape.radius || old.shape.blob != shape.blob || old.depth != depth || old.dark != dark;
}

/// Le grain du papier : un bruit très léger posé par-dessus l'écran, comme
/// une feuille sous la lumière. Il ne touche pas au contraste du texte.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: c.isDark ? 0.10 : 0.07,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/textures/grain.png'), repeat: ImageRepeat.repeat, filterQuality: FilterQuality.none),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
