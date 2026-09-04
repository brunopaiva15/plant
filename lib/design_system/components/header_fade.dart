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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final start = box.maxHeight <= height ? 0.0 : (box.maxHeight - height) / box.maxHeight;
        double at(double t) => start + (1 - start) * t;
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Une descente adoucie : l'opacité chute d'abord lentement, pour
            // que l'œil ne voie pas où le fondu commence.
            colors: const [Color(0xFF000000), Color(0xFF000000), Color(0xEB000000), Color(0xA8000000), Color(0x4C000000), Color(0x00000000)],
            stops: [0, start, at(0.4), at(0.68), at(0.87), 1],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}
