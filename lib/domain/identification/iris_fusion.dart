import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Iris 10 lu comme au banc, et fusionné avec Iris 9.
///
/// Iris 10 ne rend pas des classes : il rend un vecteur, que l'on compare à
/// des **références**, une ou plusieurs par espèce (centroïdes de photos,
/// vues `#captive` et `#pot`). C'est `voisins.classer`, puis
/// `seuils.fusion_probas`, recopiés sans numpy (§ 20 duodecies à quindecies
/// de `docs/14`) :
///
/// 1. pour chaque espèce, le meilleur cosinus parmi ses références ;
/// 2. un softmax de ces cosinus multipliés par [temperature] ;
/// 3. les sorties d'Iris 9 regroupées par espèce, synonymes additionnés ;
/// 4. `p9^poids · p10^(1−poids)`, renormalisé.
///
/// Le masque du lieu ne s'applique pas ici, mais **après**, par
/// `maskedCandidates` : renormaliser une moyenne géométrique sur le masque
/// donne exactement la moyenne géométrique des deux distributions déjà
/// masquées, ce que le banc a mesuré. Un seul vecteur global sert donc aux
/// candidats du lieu comme à ceux d'ailleurs.
///
/// Tout vient de `assets/model/iris10.json`, écrit par
/// `tools/plant_model/exporter.py livrer` : aucun réglage n'est recopié ici.
class Iris10References {
  Iris10References._({
    required this.version,
    required this.inputSize,
    required this.dim,
    required this.temperature,
    required this.iris9Weight,
    required this.floor,
    required this.acceptThreshold,
    required this.species,
    required this.rowSpecies,
    required this.matrix,
    required this.iris9Species,
    required this.control,
  });

  /// « 10 ».
  final String version;
  final int inputSize;
  final int dim;
  final double temperature;

  /// La part d'Iris 9 dans la fusion, 0,5.
  final double iris9Weight;

  /// Sous ce score, une probabilité compte pour le plancher : un zéro d'un
  /// modèle ne doit pas opposer un veto à l'autre.
  final double floor;

  /// Le seuil d'affirmation mesuré pour la fusion (0,85). Il remplace celui
  /// d'Iris 9 seul : un seuil ne se transporte pas d'un modèle à l'autre.
  final double acceptThreshold;

  /// Les espèces de la fusion, identifiants internes canoniques, dans
  /// l'ordre d'Iris 9.
  final List<String> species;

  /// Pour chaque référence (ligne de [matrix]), l'indice de son espèce.
  final Int32List rowSpecies;

  /// Les références, unitaires, à plat : `rowSpecies.length × dim`.
  final Float32List matrix;

  /// Pour chaque sortie d'Iris 9, l'indice de son espèce, ou −1.
  final Int32List iris9Species;

  /// Les 16 premières valeurs du vecteur d'Iris 10 sur le motif de contrôle,
  /// telles que l'export les a calculées.
  final List<double> control;

  /// Lit `iris10.json` et la matrice des références (`float16`), et vérifie
  /// qu'ils parlent des mêmes sorties qu'Iris 9 — un fichier d'un autre
  /// export ferait une fusion fausse sans erreur visible.
  static Iris10References parse(String meta, ByteData references, List<String> iris9Labels) {
    final m = jsonDecode(meta) as Map<String, dynamic>;
    final species = (m['especes'] as List).cast<String>();
    final rows = Int32List.fromList((m['lignes'] as List).cast<int>());
    final iris9 = Int32List.fromList((m['iris9'] as List).cast<int>());
    final synonyms = (m['synonymes'] as Map<String, dynamic>? ?? const {}).cast<String, String>();
    final dim = m['dim'] as int;
    final fusion = m['fusion'] as Map<String, dynamic>;

    if (iris9.length != iris9Labels.length) {
      throw FormatException('iris10.json décrit ${iris9.length} sorties d\'Iris 9, le modèle en a ${iris9Labels.length}');
    }
    for (var i = 0; i < iris9.length; i++) {
      final s = iris9[i];
      if (s < 0) continue;
      final label = iris9Labels[i];
      if (s >= species.length || species[s] != (synonyms[label] ?? label)) {
        throw FormatException('iris10.json ne suit pas les sorties d\'Iris 9 ($label)');
      }
    }
    for (final s in rows) {
      if (s < 0 || s >= species.length) throw const FormatException('référence sans espèce');
    }
    if (references.lengthInBytes != rows.length * dim * 2) {
      throw FormatException('${references.lengthInBytes} octets de références pour ${rows.length} × $dim');
    }

    return Iris10References._(
      version: '${m['version']}',
      inputSize: m['input_size'] as int,
      dim: dim,
      temperature: (m['temperature'] as num).toDouble(),
      iris9Weight: (fusion['poids_iris9'] as num).toDouble(),
      floor: (fusion['plancher'] as num).toDouble(),
      acceptThreshold: (m['accept_threshold'] as num).toDouble(),
      species: species,
      rowSpecies: rows,
      matrix: float16ToFloat32(references),
      iris9Species: iris9,
      control: [for (final v in (m['controle'] as Map<String, dynamic>)['vecteur'] as List) (v as num).toDouble()],
    );
  }

  /// La distribution d'Iris 10 sur [species] pour un vecteur (unitaire) :
  /// meilleur cosinus par espèce, puis softmax tempéré.
  List<double> speciesProbabilities(Float32List embedding) {
    if (embedding.length != dim) {
      throw ArgumentError('vecteur de ${embedding.length}, $dim attendus');
    }
    final best = Float64List(species.length)..fillRange(0, species.length, -2);
    for (var r = 0; r < rowSpecies.length; r++) {
      final base = r * dim;
      var dot = 0.0;
      for (var k = 0; k < dim; k++) {
        dot += matrix[base + k] * embedding[k];
      }
      final s = rowSpecies[r];
      if (dot > best[s]) best[s] = dot;
    }
    var top = double.negativeInfinity;
    for (final b in best) {
      if (b > top) top = b;
    }
    final out = List<double>.filled(species.length, 0);
    var sum = 0.0;
    for (var s = 0; s < species.length; s++) {
      final e = math.exp((best[s] - top) * temperature);
      out[s] = e;
      sum += e;
    }
    for (var s = 0; s < out.length; s++) {
      out[s] /= sum;
    }
    return out;
  }

  /// Les sorties d'Iris 9 regroupées par espèce de la fusion : deux noms
  /// d'une même plante s'additionnent, une espèce sans référence sort.
  List<double> iris9ToSpecies(List<double> scores) {
    final out = List<double>.filled(species.length, 0);
    final n = math.min(scores.length, iris9Species.length);
    for (var i = 0; i < n; i++) {
      final s = iris9Species[i];
      if (s >= 0) out[s] += scores[i];
    }
    return out;
  }

  /// `p9^poids · p10^(1−poids)`, renormalisé : une distribution, que la
  /// politique de l'application lit comme celle d'Iris 9.
  List<double> fuse(List<double> iris9, List<double> iris10) {
    final logs = Float64List(species.length);
    var top = double.negativeInfinity;
    for (var s = 0; s < species.length; s++) {
      final l = iris9Weight * math.log(math.max(iris9[s], floor)) +
          (1 - iris9Weight) * math.log(math.max(iris10[s], floor));
      logs[s] = l;
      if (l > top) top = l;
    }
    final out = List<double>.filled(species.length, 0);
    var sum = 0.0;
    for (var s = 0; s < species.length; s++) {
      final e = math.exp(logs[s] - top);
      out[s] = e;
      sum += e;
    }
    for (var s = 0; s < out.length; s++) {
      out[s] /= sum;
    }
    return out;
  }

  /// Le masque d'un lieu, des sorties d'Iris 9 vers les espèces de la
  /// fusion. Une plante est du lieu dès qu'un de ses noms l'est.
  Set<int>? speciesMask(Set<int>? iris9Mask) {
    if (iris9Mask == null) return null;
    return {
      for (final i in iris9Mask)
        if (i >= 0 && i < iris9Species.length && iris9Species[i] >= 0) iris9Species[i],
    };
  }

  /// Le vecteur rendu sur le motif de contrôle est-il celui de l'export ?
  /// Comparé sur ses 16 premières valeurs : un fichier corrompu, tronqué ou
  /// d'un autre export s'en écarte de loin, la demi-précision d'un
  /// processeur à l'autre de quelques millièmes.
  bool matchesControl(Float32List embedding, {double tolerance = 0.01}) {
    if (control.isEmpty || embedding.length < control.length) return false;
    for (var i = 0; i < control.length; i++) {
      if ((embedding[i] - control[i]).abs() > tolerance) return false;
    }
    return true;
  }
}

/// Le motif de contrôle de `exporter.motif_de_controle`, en entiers des deux
/// côtés pour s'écrire à l'identique.
Float32List iris10ControlInput(int size) {
  final out = Float32List(size * size * 3);
  for (var i = 0; i < out.length; i++) {
    out[i] = (i * 7919 % 1000) / 999;
  }
  return out;
}

/// Des demi-flottants IEEE 754, petit-boutiens, en `Float32List`.
Float32List float16ToFloat32(ByteData data) {
  final n = data.lengthInBytes ~/ 2;
  final out = Float32List(n);
  final bits = ByteData(4);
  for (var i = 0; i < n; i++) {
    final h = data.getUint16(i * 2, Endian.little);
    final sign = (h & 0x8000) << 16;
    final exponent = (h >> 10) & 0x1f;
    final mantissa = h & 0x3ff;
    int f;
    if (exponent == 0) {
      if (mantissa == 0) {
        f = sign;
      } else {
        // Sous-normal : la valeur vaut mantisse × 2⁻²⁴, exacte en float32.
        out[i] = (sign != 0 ? -1 : 1) * mantissa * 5.9604644775390625e-8;
        continue;
      }
    } else if (exponent == 0x1f) {
      f = sign | 0x7f800000 | (mantissa << 13);
    } else {
      f = sign | ((exponent - 15 + 127) << 23) | (mantissa << 13);
    }
    bits.setUint32(0, f);
    out[i] = bits.getFloat32(0);
  }
  return out;
}
