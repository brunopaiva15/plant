import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

/// La photo telle qu'elle part vers un modèle qui voit les images : JPEG,
/// grand côté à [maxSide] au plus, décodée hors du fil de l'interface.
///
/// **Le côté entre au carré dans la facture.** Un modèle de vision découpe
/// l'image en tuiles de seize pixels et compte une tuile comme des jetons :
/// 1 024 px en coûtent quatre fois plus que 512. Réduire n'est donc pas une
/// politesse pour le réseau, c'est le poste principal d'un appel dont la
/// réponse ne pèse que quelques dizaines de jetons.
///
/// Une image illisible part telle quelle : le service dira ce qu'il en pense,
/// et c'est une meilleure réponse qu'une exception de décodeur.
Future<Uint8List> shrinkForModel(Uint8List bytes, {required int maxSide}) =>
    compute(_shrink, (bytes: bytes, maxSide: maxSide));

Uint8List _shrink(({Uint8List bytes, int maxSide}) arg) {
  final bytes = arg.bytes;
  final maxSide = arg.maxSide;
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } on Object {
    // Le décodeur peut lever sur un fichier tronqué : on envoie tel quel.
    return bytes;
  }
  if (decoded == null) return bytes;
  var image = decoded;
  if (image.width > maxSide || image.height > maxSide) {
    image = image.width >= image.height ? img.copyResize(image, width: maxSide) : img.copyResize(image, height: maxSide);
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}
