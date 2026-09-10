import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'clay.dart';

/// Le logo du modèle embarqué : une feuille d'argile, sa nervation, et en son
/// centre un iris clair à cœur de terre cuite. Iris, c'est l'œil, le
/// diaphragme d'un appareil photo et la fleur ; le dessin garde les trois.
///
/// Sans trois écarts, une vésique symétrique ne serait qu'un œil : la feuille
/// penche, sa base est plus ronde que sa pointe, et ses nervures partent
/// toutes vers celle-ci.
///
/// Peinte par [paintClay], comme les cartes, mais **avec ses propres
/// couleurs** : une marque ne se retourne pas avec le thème. La première
/// version prenait `sage`, `onAccent` et `terracotta` de la palette du
/// moment ; en sombre la feuille pâlissait, l'iris passait au presque-noir et
/// le cœur au saumon — le même dessin, pas le même logo. [blade], [iris] et
/// [heart] sont donc des constantes, et [paintClay] est appelé en `dark:
/// false` : le relief, l'ombre portée et le liseré ne bougent pas non plus.
/// La marque est identique au pixel près dans les quatre palettes.
///
/// [blade] n'est pas `sage` mais un vert un peu plus clair : figée, la feuille
/// doit tenir seule sur les fonds clairs *et* sombres. À cette luminance elle
/// passe 3:1 sur les quatre — canvas clair, canvas sombre, carte `sageSoft`
/// des deux côtés (`colors_contrast_test.dart`). Le halo vert de l'onboarding
/// est le seul fond qu'aucune couleur figée ne pouvait tenir ; c'est lui qui
/// s'efface, pas elle (`OnboardingStage.mark`).
class IrisMark extends StatelessWidget {
  const IrisMark({super.key, this.size = 72, this.semanticLabel});

  /// La feuille. Même teinte que `sage`, montée en clarté jusqu'à la seule
  /// bande où elle tient 3:1 aussi bien sur la crème que sur le brun sombre.
  static const Color blade = Color(0xFF369361);

  /// L'iris, blanc, et son cœur de terre cuite. Les deux valeurs claires de
  /// la palette : sur la feuille, elles gardent 3,8:1 et 6,2:1.
  static const Color iris = Color(0xFFFFFFFF);
  static const Color heart = Color(0xFF9C482C);

  /// Côté du carré. Seule l'ombre portée déborde, comme celle d'une carte.
  final double size;

  /// À ne donner que si la marque est seule : posée à côté du nom du modèle,
  /// elle est décorative et VoiceOver n'a pas à l'annoncer deux fois.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = RepaintBoundary(
      child: CustomPaint(size: Size(size, size), painter: const _IrisMarkPainter()),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: mark)
        : Semantics(label: semanticLabel, image: true, child: mark);
  }
}

/// Le peintre de la marque. Sans champ : tout ce qu'il lui faut est constant,
/// et le même exemplaire `const` sert donc les quatre palettes — c'est ce qui
/// rend l'identité entre clair et sombre vérifiable plutôt que promise.
class _IrisMarkPainter extends CustomPainter {
  const _IrisMarkPainter();

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
    paintClay(canvas, leaf, bounds: leaf.getBounds(), color: IrisMark.blade, depth: ClayDepth.deep, dark: false);

    // Les nervures sont rognées à la feuille : un trait qui dépasse ferait un
    // dessin posé sur une forme, au lieu d'une seule pièce.
    canvas.save();
    canvas.clipPath(leaf);
    final vein = Paint()
      ..color = IrisMark.iris.withValues(alpha: 0.42)
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
    paintClay(canvas, disc, bounds: disc.getBounds(), color: IrisMark.iris, depth: ClayDepth.light, dark: false, dropShadow: false);
    canvas.drawCircle(Offset.zero, radius * 0.72, Paint()..color = IrisMark.heart);

    canvas.restore();
  }

  /// Rien ne peut changer : ni le thème, ni le contraste élevé, ni une
  /// couleur passée d'ailleurs. Seule la taille repeint, et c'est le
  /// [CustomPaint] qui s'en charge.
  @override
  bool shouldRepaint(_IrisMarkPainter old) => false;
}
