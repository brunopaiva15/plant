import 'dart:math' as math;
import 'dart:typed_data';

/// Les filtres de PIL que l'application a besoin de refaire.
enum ResampleFilter {
  /// `Image.BICUBIC` : la réduction de `student.preparer`, la dernière que
  /// voit Iris 10 avant le réseau.
  bicubic(2),

  /// `Image.LANCZOS` : celle de `plant_dataset.images.prepare`, qui a ramené
  /// les photos d'entraînement à 384 px de côté long.
  lanczos(3);

  const ResampleFilter(this.support);

  final double support;

  double weight(double x) => switch (this) {
        ResampleFilter.bicubic => _bicubic(x),
        ResampleFilter.lanczos => _lanczos(x),
      };

  static double _bicubic(double x) {
    const a = -0.5;
    final t = x.abs();
    if (t < 1) return ((a + 2) * t - (a + 3)) * t * t + 1;
    if (t < 2) return (((t - 5) * t + 8) * t - 4) * a;
    return 0;
  }

  static double _sinc(double x) {
    if (x == 0) return 1;
    final y = x * math.pi;
    return math.sin(y) / y;
  }

  static double _lanczos(double x) => (-3 <= x && x < 3) ? _sinc(x) * _sinc(x / 3) : 0;
}

/// Une image RGB 8 bits redimensionnée **exactement comme PIL** (`Resample.c`,
/// Pillow 12), au niveau du pixel.
///
/// Le bicubique de la bibliothèque `image` n'est pas celui de PIL : il
/// échantillonne la source sans l'adoucir quand il réduit, là où PIL élargit
/// son filtre à proportion de la réduction. Iris 10 a appris sur des images
/// réduites par PIL ; lui en donner d'autres, c'est lui montrer un grain
/// qu'il n'a jamais vu. Le calcul est donc recopié : coefficients par sortie,
/// virgule fixe sur 22 bits, passe horizontale puis verticale, arrondi et
/// écrêtage à 8 bits entre les deux — `test/data/pil_resample_test.dart` le
/// compare à PIL lui-même.
Uint8List resampleRgb(Uint8List rgb, int width, int height, int outWidth, int outHeight,
    ResampleFilter filter) {
  if (rgb.length != width * height * 3) {
    throw ArgumentError('${rgb.length} octets pour $width×$height');
  }
  var data = rgb;
  var w = width;
  if (outWidth != width) {
    data = _horizontal(data, width, height, outWidth, filter);
    w = outWidth;
  }
  if (outHeight != height) {
    data = _vertical(data, w, height, outHeight, filter);
  }
  return identical(data, rgb) ? Uint8List.fromList(rgb) : data;
}

const _precisionBits = 32 - 8 - 2;

/// Les coefficients d'une passe : pour chaque pixel de sortie, la première
/// source lue, combien en lire, et leurs poids en virgule fixe.
class _Coefficients {
  _Coefficients(this.start, this.count, this.weights, this.size);

  final Int32List start;
  final Int32List count;
  final Int32List weights;
  final int size;
}

_Coefficients _coefficients(int inSize, int outSize, ResampleFilter filter) {
  final scale = inSize / outSize;
  final filterScale = math.max(scale, 1.0);
  final support = filter.support * filterScale;
  final size = support.ceil() * 2 + 1;
  final start = Int32List(outSize);
  final count = Int32List(outSize);
  final weights = Int32List(outSize * size);
  final k = Float64List(size);
  for (var xx = 0; xx < outSize; xx++) {
    final center = (xx + 0.5) * scale;
    // `(int)` de C : troncature vers zéro, puis bornes.
    var xmin = (center - support + 0.5).truncate();
    if (xmin < 0) xmin = 0;
    var xmax = (center + support + 0.5).truncate();
    if (xmax > inSize) xmax = inSize;
    xmax -= xmin;
    var ww = 0.0;
    for (var x = 0; x < xmax; x++) {
      final w = filter.weight((x + xmin - center + 0.5) / filterScale);
      k[x] = w;
      ww += w;
    }
    for (var x = 0; x < xmax; x++) {
      final v = ww != 0 ? k[x] / ww : k[x];
      weights[xx * size + x] = v < 0
          ? (-0.5 + v * (1 << _precisionBits)).truncate()
          : (0.5 + v * (1 << _precisionBits)).truncate();
    }
    start[xx] = xmin;
    count[xx] = xmax;
  }
  return _Coefficients(start, count, weights, size);
}

int _clip8(int v) {
  final x = v >> _precisionBits;
  return x < 0 ? 0 : (x > 255 ? 255 : x);
}

Uint8List _horizontal(Uint8List src, int width, int height, int outWidth, ResampleFilter filter) {
  final c = _coefficients(width, outWidth, filter);
  final out = Uint8List(outWidth * height * 3);
  const half = 1 << (_precisionBits - 1);
  for (var y = 0; y < height; y++) {
    final row = y * width * 3;
    final outRow = y * outWidth * 3;
    for (var xx = 0; xx < outWidth; xx++) {
      final xmin = c.start[xx];
      final n = c.count[xx];
      final base = xx * c.size;
      var r = half, g = half, b = half;
      for (var x = 0; x < n; x++) {
        final w = c.weights[base + x];
        final p = row + (xmin + x) * 3;
        r += src[p] * w;
        g += src[p + 1] * w;
        b += src[p + 2] * w;
      }
      final o = outRow + xx * 3;
      out[o] = _clip8(r);
      out[o + 1] = _clip8(g);
      out[o + 2] = _clip8(b);
    }
  }
  return out;
}

Uint8List _vertical(Uint8List src, int width, int height, int outHeight, ResampleFilter filter) {
  final c = _coefficients(height, outHeight, filter);
  final out = Uint8List(width * outHeight * 3);
  const half = 1 << (_precisionBits - 1);
  final stride = width * 3;
  for (var yy = 0; yy < outHeight; yy++) {
    final ymin = c.start[yy];
    final n = c.count[yy];
    final base = yy * c.size;
    final outRow = yy * stride;
    for (var x = 0; x < stride; x++) {
      var s = half;
      for (var y = 0; y < n; y++) {
        s += src[(ymin + y) * stride + x] * c.weights[base + y];
      }
      out[outRow + x] = _clip8(s);
    }
  }
  return out;
}
