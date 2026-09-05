import 'package:flutter/material.dart';

/// Efface le bas d'un en-tête en transparence.
///
/// L'image ne s'arrête plus net sur le contenu : elle se dissout dans le fond
/// de l'écran. Le fondu est calé sur la boîte visible et non sur l'image, si
/// bien qu'une photo qui défile en parallaxe derrière reste toujours effacée
/// exactement à la limite du contenu, à toute position de défilement.
///
/// Le fondu joue sur l'opacité plutôt que sur une couche colorée : c'est ce
/// qui évite la ligne d'un pixel qu'un dégradé peint par-dessus laisse là où
/// la barre s'arrête sur une fraction de pixel.
class HeaderFade extends StatelessWidget {
  const HeaderFade({super.key, required this.child, this.height = 180});

  /// Hauteur du fondu, en pixels logiques. Un en-tête plus court que cela est
  /// effacé de haut en bas : replié, il ne laisse plus rien voir.
  final double height;

  final Widget child;

  /// De combien le masque dépasse sous la boîte visible.
  ///
  /// Quand la hauteur de l'en-tête tombe sur une fraction de pixel — la
  /// largeur × 1,05 sur un iPhone, presque toujours —, le moteur de rendu
  /// n'arrondit pas de la même façon le bord du masque et celui de l'image :
  /// il restait une rangée de photo crue, un trait fin sur toute la largeur.
  /// En prolongeant le masque sous le bord, cette rangée reste masquée, et
  /// c'est la barre elle-même qui rogne le surplus, hors de vue.
  static const double _bleed = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final visible = box.maxHeight;
        final total = visible + _bleed;
        final start = visible <= height ? 0.0 : (visible - height) / visible;
        // Les arrêts sont pensés dans la boîte visible, puis ramenés à la
        // boîte agrandie : le fondu atteint zéro pile au bord, et y reste.
        final k = visible / total;
        double at(double t) => (start + (1 - start) * t) * k;
        return OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: total,
          maxHeight: total,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // Une descente adoucie : l'opacité chute d'abord lentement, pour
              // que l'œil ne voie pas où le fondu commence.
              colors: const [Color(0xFF000000), Color(0xFF000000), Color(0xEB000000), Color(0xA8000000), Color(0x4C000000), Color(0x00000000), Color(0x00000000)],
              stops: [0, start * k, at(0.4), at(0.68), at(0.87), k, 1],
            ).createShader(rect),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: box.maxWidth, height: visible, child: child),
            ),
          ),
        );
      },
    );
  }
}
