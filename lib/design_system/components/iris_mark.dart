import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import 'clay.dart';

/// Le logo du modèle embarqué : une feuille d'argile, sa nervation, et en son
/// centre un iris clair à cœur de terre cuite. Iris, c'est l'œil, le
/// diaphragme d'un appareil photo et la fleur ; le dessin garde les trois.
///
/// Sans trois écarts, une vésique symétrique ne serait qu'un œil : la feuille
/// penche, sa base est plus ronde que sa pointe, et ses nervures partent
/// toutes vers celle-ci.
///
/// Peinte par [paintClay], comme les cartes. Feuille en `sage`, iris en
/// `onAccent`, cœur en `terracotta` : trois paires que le contrat de contraste
/// tient déjà, donc la marque se retourne seule en sombre et en contraste
/// élevé.
class IrisMark extends StatelessWidget {
  const IrisMark({super.key, this.size = 72, this.semanticLabel});

  /// Côté du carré. Seule l'ombre portée déborde, comme celle d'une carte.
  final double size;

  /// À ne donner que si la marque est seule : posée à côté du nom du modèle,
  /// elle est décorative et VoiceOver n'a pas à l'annoncer deux fois.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mark = RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: _IrisMarkPainter(blade: c.sage, iris: c.onAccent, heart: c.terracotta, dark: c.isDark),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: mark)
        : Semantics(label: semanticLabel, image: true, child: mark);
  }
}

class _IrisMarkPainter extends CustomPainter {
  const _IrisMarkPainter({required this.blade, required this.iris, required this.heart, required this.dark});

  final Color blade;
  final Color iris;
  final Color heart;
  final bool dark;

  static const double _tilt = -0.30;

  /// Où les nervures quittent la nervure centrale, en fraction de la
  /// demi-longueur. Négatif du côté de la base.
  static const List<double> _veins = [-0.78, -0.55, -0.3, 0.3, 0.55, 0.78];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    // Le centre remonte : l'ombre portée tombe en bas à droite, il lui faut
    // la place.
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.47);
    canvas.rotate(_tilt);

    final length = s * 0.42; // du centre à la pointe
    final half = s * 0.235; // demi-largeur au milieu

    // Deux cubiques qui se rejoignent en pointe. Les contrôles côté base — à
    // gauche — sont plus rentrés et plus hauts : la feuille s'y arrondit.
    final leaf = Path()
      ..moveTo(-length, 0)
      ..cubicTo(-length * 0.43, -half * 1.53, length * 0.55, -half * 1.35, length, 0)
      ..cubicTo(length * 0.55, half * 1.35, -length * 0.43, half * 1.53, -length, 0)
      ..close();
    // Le relief se proportionne à la feuille, pas au carré qui la contient.
    paintClay(canvas, leaf, bounds: leaf.getBounds(), color: blade, depth: ClayDepth.deep, dark: dark);

    // Les nervures sont rognées à la feuille : un trait qui dépasse ferait un
    // dessin posé sur une forme, au lieu d'une seule pièce.
    canvas.save();
    canvas.clipPath(leaf);
    final vein = Paint()
      ..color = iris.withValues(alpha: dark ? 0.32 : 0.42)
      ..strokeWidth = math.max(1, s * 0.019)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-length * 0.9, 0), Offset(length * 0.9, 0), vein);
    for (final along in _veins) {
      final from = Offset(length * along, 0);
      // Toujours +0,15, y compris à la base : une nervation pennée monte tout
      // entière vers la pointe. Les faire diverger dessinerait une arête.
      for (final sign in const [-1.0, 1.0]) {
        canvas.drawLine(from, from + Offset(length * 0.15, sign * half * 0.6), vein);
      }
    }
    canvas.restore();

    // L'iris est enfoncé dans la feuille, pas posé dessus : relief léger, pas
    // d'ombre portée.
    final radius = s * 0.118;
    final disc = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: radius));
    paintClay(canvas, disc, bounds: disc.getBounds(), color: iris, depth: ClayDepth.light, dark: dark, dropShadow: false);
    canvas.drawCircle(Offset.zero, radius * 0.72, Paint()..color = heart);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_IrisMarkPainter old) =>
      old.blade != blade || old.iris != iris || old.heart != heart || old.dark != dark;
}
