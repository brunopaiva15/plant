import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'pil_resample.dart';

/// Le côté long des photos d'entraînement d'Iris 10.
///
/// `plant_dataset.images.prepare` a ramené chaque image à 384 px de côté
/// long, en Lanczos, avant de la ranger : c'est la résolution que le modèle
/// connaît. Une photo de téléphone en fait 4 000. La recadrer puis la réduire
/// d'un coup à 320 lui montrerait des détails qu'il n'a jamais vus — on
/// refait donc d'abord l'étape du jeu de données.
const iris10StoredSide = 384;

/// L'entrée d'Iris 10 pour une photo déjà décodée et redressée :
/// `[1, size, size, 3]` à plat, valeurs 0–1.
///
/// La recette est celle de l'entraînement, dans l'ordre :
/// 1. le côté long ramené à [storedSide] en Lanczos (le jeu de données) ;
/// 2. le carré central ;
/// 3. une réduction bicubique à [size] (`student.preparer`).
///
/// Les deux réductions sont celles de PIL au pixel près (`resampleRgb`).
/// Une seule entorse : au-delà de deux fois [storedSide], la photo est
/// d'abord moyennée par blocs, pour que le Lanczos ne lise pas 60 pixels par
/// sortie. Le Lanczos qui suit réduit encore d'au moins deux fois, et c'est
/// lui qui fixe le grain.
Float32List iris10Input(img.Image oriented, {int size = 320, int storedSide = iris10StoredSide}) {
  var image = oriented;
  if (image.format != img.Format.uint8 || image.numChannels != 3) {
    image = image.convert(format: img.Format.uint8, numChannels: 3);
  }
  var w = image.width;
  var h = image.height;
  final long = math.max(w, h);
  var rgb = image.getBytes(order: img.ChannelOrder.rgb);
  if (long > storedSide) {
    final tw = math.max(1, (w * storedSide / long).round());
    final th = math.max(1, (h * storedSide / long).round());
    final k = long ~/ (2 * storedSide);
    if (k >= 2) {
      image = img.copyResize(image, width: w ~/ k, height: h ~/ k, interpolation: img.Interpolation.average);
      w = image.width;
      h = image.height;
      rgb = image.getBytes(order: img.ChannelOrder.rgb);
    }
    rgb = resampleRgb(rgb, w, h, tw, th, ResampleFilter.lanczos);
    w = tw;
    h = th;
  }

  final side = math.min(w, h);
  final x0 = (w - side) ~/ 2;
  final y0 = (h - side) ~/ 2;
  final square = Uint8List(side * side * 3);
  for (var y = 0; y < side; y++) {
    final from = ((y0 + y) * w + x0) * 3;
    square.setRange(y * side * 3, (y + 1) * side * 3, rgb, from);
  }

  final small = resampleRgb(square, side, side, size, size, ResampleFilter.bicubic);
  final out = Float32List(small.length);
  for (var i = 0; i < small.length; i++) {
    out[i] = small[i] / 255;
  }
  return out;
}
