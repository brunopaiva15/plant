import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/utils/scientific_name.dart';
import '../../domain/identification/local_plant_model.dart';
import '../../domain/identification/plant_identifier.dart';

/// Le modèle embarqué, exécuté par TensorFlow Lite.
///
/// Le fichier de poids et la liste des classes sont des assets ; ils sont
/// chargés à la première identification, pas au démarrage — l'app doit
/// s'ouvrir en un instant, et beaucoup d'utilisateurs n'identifieront
/// jamais rien.
///
/// Le graphe inclut sa propre normalisation (MobileNetV3 attend des octets
/// 0–255) : ici on ne fait que décoder, recadrer au carré et redimensionner.
///
/// Rien de tout cela ne tourne sur l'isolat principal. Le décodage part dans
/// un `Isolate.run` jetable, l'inférence dans l'isolat permanent de
/// [IsolateInterpreter]. Ce second point n'est pas un raffinement : depuis
/// l'Iris 7 l'entrée est en 320 px, l'inférence demande près d'une seconde,
/// et la cascade en enchaîne une par photo. Trois photos, c'était trois
/// secondes d'interface gelée — que l'utilisateur lit comme une panne, pas
/// comme un calcul.
class TflitePlantModel implements LocalPlantModel {
  TflitePlantModel({
    this.modelAsset = 'assets/model/plants.tflite',
    this.labelsAsset = 'assets/model/labels.txt',
    this.metaAsset = 'assets/model/model.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String modelAsset;
  final String labelsAsset;
  final String metaAsset;
  final AssetBundle _bundle;

  Interpreter? _interpreter;
  IsolateInterpreter? _worker;
  List<String> _labels = const [];
  String? _version;
  int _inputSize = 224;
  int _loadSize = 256;
  int _sourceSize = 448;
  Future<bool>? _loading;
  bool _failed = false;
  String? _loadError;

  /// La file des inférences : une seule à la fois, voir [_run].
  Future<void> _turn = Future<void>.value();

  /// Vrai tant qu'un chargement n'a pas échoué : avant le premier appel, le
  /// modèle est présumé présent, et c'est la cascade qui le charge. Ne pas
  /// confondre avec « chargé », que dit [speciesCount] ou [version].
  @override
  bool get isAvailable => !_failed;

  @override
  String? get version => _version;

  @override
  int get speciesCount => _interpreter == null ? 0 : _labels.length;

  @override
  String? get loadError => _loadError;

  @override
  Future<bool> warmUp() => _loading ??= _load();

  Future<bool> _load() async {
    if (_failed) return false;
    try {
      final labels = await _bundle.loadString(labelsAsset);
      _labels = [for (final l in labels.split('\n')) if (l.trim().isNotEmpty) l.trim()];
      if (_labels.isEmpty) throw StateError('labels vides');
      try {
        final meta = await _bundle.loadString(metaAsset);
        _version = RegExp(r'"version"\s*:\s*"([^"]+)"').firstMatch(meta)?.group(1);
        final size = RegExp(r'"input_size"\s*:\s*(\d+)').firstMatch(meta)?.group(1);
        if (size != null) _inputSize = int.parse(size);
        final load = RegExp(r'"load_size"\s*:\s*(\d+)').firstMatch(meta)?.group(1);
        _loadSize = load != null ? int.parse(load) : _inputSize;
        final source = RegExp(r'"source_size"\s*:\s*(\d+)').firstMatch(meta)?.group(1);
        _sourceSize = source != null ? int.parse(source) : _loadSize;
      } on Object {
        // Les métadonnées sont un confort : sans elles, les valeurs par défaut
        // du graphe suffisent.
      }
      final options = InterpreterOptions()..threads = 2;
      final interpreter = await Interpreter.fromAsset(modelAsset, options: options);
      _interpreter = interpreter;
      try {
        // L'isolat de calcul est monté une fois pour toutes, ici, pendant
        // que l'utilisateur n'attend encore rien : le faire naître à la
        // première photo rendrait le démarrage de l'isolat visible dans la
        // première identification.
        _worker = await IsolateInterpreter.create(address: interpreter.address);
      } on Object catch (e) {
        // Un isolat en moins n'est pas un modèle en moins : on retombe sur
        // l'exécution sur place, qui gèle l'écran mais répond juste.
        debugPrint('inférence hors isolat impossible : $e');
        _worker = null;
      }
      return true;
    } on Object catch (e) {
      // Pas de modèle livré, fichier illisible, plateforme sans TFLite :
      // l'app doit continuer de fonctionner par le service distant.
      debugPrint('modèle local indisponible : $e');
      _loadError = e.toString();
      _failed = true;
      _interpreter = null;
      _worker = null;
      return false;
    }
  }

  @override
  Future<List<IdentificationCandidate>> classify(File image) async {
    if (!await warmUp()) return const [];
    if (_interpreter == null) return const [];

    final input = await _prepare(image, _inputSize, _loadSize, _sourceSize);
    if (input == null) return const [];

    final output = [List<double>.filled(_labels.length, 0)];
    await _run(input, output);
    final scores = output.first;

    final candidates = <IdentificationCandidate>[];
    for (var i = 0; i < _labels.length && i < scores.length; i++) {
      if (scores[i] < 0.01) continue;
      candidates.add(IdentificationCandidate(
        scientificName: scientificNameOf(_labels[i]),
        score: scores[i],
        source: IdentificationSource.local,
        internalId: _labels[i],
      ));
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(5).toList();
  }

  /// Le délai au-delà duquel on cesse d'attendre l'isolat de calcul.
  ///
  /// Une inférence demande environ une seconde à 320 px sur un téléphone
  /// récent, trois ou quatre sur un vieux : quinze secondes ne coupent
  /// jamais un calcul réel, elles ne coupent qu'un isolat mort. La cascade a
  /// son propre délai, bien plus court ; celui-ci ne protège que la file.
  static const _inferenceTimeout = Duration(seconds: 15);

  /// Une inférence à la fois, et jamais d'attente sans fin.
  ///
  /// [IsolateInterpreter] ne sait pas se dédoubler : appelé pendant qu'il
  /// travaille, il rend la main **sans rien exécuter**, et l'appelant lit un
  /// vecteur de zéros — une réponse fausse, pas une erreur. La cascade prend
  /// ses photos une par une, mais elle abandonne chaque appel au bout de
  /// quelques secondes sans que le calcul, lui, s'arrête : deux photos
  /// peuvent donc se croiser. D'où cette file d'un seul rang.
  ///
  /// Le délai porte sur la file entière et non sur la seule inférence : un
  /// isolat qui ne rendrait jamais la main bloquerait sinon toutes les
  /// identifications de la session, silencieusement.
  Future<void> _run(Float32List input, List<List<double>> output) {
    final turn = _turn.then<void>((_) => _infer(input, output)).timeout(_inferenceTimeout);
    _turn = turn.then<void>((_) {}, onError: (Object _) {});
    return turn;
  }

  Future<void> _infer(Float32List input, List<List<double>> output) async {
    // `Uint8List` est le seul type que `tflite_flutter` recopie tel quel vers
    // le tenseur natif ; tout le reste, `Float32List` comprise, il le
    // parcourt élément par élément en allouant quatre octets par nombre
    // (`ByteConversionUtils.convertObjectToBytes`). On lui passe donc la vue
    // en octets de nos flottants : un memcpy d'un mégaoctet au lieu de
    // 307 200 conversions.
    //
    // En contrepartie la bibliothèque ne cherche plus la forme de l'entrée
    // et ne redimensionne plus le tenseur : une taille qui ne collerait pas
    // au graphe échouerait au lieu d'être rattrapée. `model.json` et le
    // `.tflite` sortent du même export (`export_tflite`), ils ne peuvent pas
    // diverger.
    final Object payload = Endian.host == Endian.little
        ? input.buffer.asUint8List(input.offsetInBytes, input.lengthInBytes)
        // Aucune plateforme visée n'est gros-boutienne ; ce repli est juste,
        // pas rapide.
        : input;
    final worker = _worker;
    if (worker != null) {
      await worker.run(payload, output);
    } else {
      _interpreter?.run(payload, output);
    }
  }

  @override
  void dispose() {
    // L'isolat d'abord : il travaille sur l'adresse de l'interpréteur, le
    // fermer après reviendrait à le laisser un instant sur de la mémoire
    // libérée.
    _worker?.close();
    _worker = null;
    _interpreter?.close();
    _interpreter = null;
  }

  /// « monstera-deliciosa » → « Monstera deliciosa ». Le nom exact vient
  /// ensuite du catalogue ; ceci n'est qu'un repli lisible.
  @visibleForTesting
  static String scientificNameOf(String internalId) {
    final words = internalId.split('-');
    if (words.isEmpty) return internalId;
    final rest = words.skip(1).map((w) => w == 'x' ? '×' : w).join(' ');
    final genus = words.first.isEmpty ? '' : words.first[0].toUpperCase() + words.first.substring(1);
    return normalizeScientificName('$genus $rest'.trim());
  }

  /// Décodage et cadrage, dans un isolat : une photo de 12 Mpx bloquerait
  /// sinon l'interface pendant une seconde.
  ///
  /// La recette doit être **exactement** celle de l'entraînement — carré
  /// central, redimensionnement à `loadSize`, puis recadrage central à
  /// `size`. Redimensionner directement à 224 donne un cadrage plus large
  /// et coûte plusieurs points de précision, mesurés sur le jeu de test.
  static Future<Float32List?> _prepare(File file, int size, int loadSize, int sourceSize) async {
    final bytes = await file.readAsBytes();
    return Isolate.run(() => _decode(bytes, size, loadSize, sourceSize));
  }

  @visibleForTesting
  static Float32List? decodeForTest(Uint8List bytes, int size, int loadSize, [int sourceSize = 448]) =>
      _decode(bytes, size, loadSize, sourceSize);

  static Float32List? _decode(Uint8List bytes, int size, int loadSize, int sourceSize) {
    // Un fichier tronqué ou dans un format inattendu n'est pas une panne du
    // modèle : c'est une photo sans candidat, et la cascade ira au service
    // distant. Le décodeur lève sur certaines entrées au lieu de rendre null.
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } on Object {
      return null;
    }
    if (decoded == null) return null;
    final oriented = img.bakeOrientation(decoded);
    final side = oriented.width < oriented.height ? oriented.width : oriented.height;
    final square = img.copyCrop(oriented,
        x: (oriented.width - side) ~/ 2, y: (oriented.height - side) ~/ 2, width: side, height: side);
    // Les images d'entraînement ont été réduites en deux temps : d'abord à
    // `sourceSize` par une réduction de qualité (moyenne de zone), puis à
    // `loadSize` par un simple bilinéaire. Une photo de téléphone fait
    // 4000 px : la ramener d'un coup à 256 par bilinéaire produit un
    // crénelage que le modèle n'a jamais vu à l'entraînement. On refait donc
    // exactement les deux étapes.
    final load = loadSize < size ? size : loadSize;
    var source = square;
    if (source.width > sourceSize && sourceSize > load) {
      source = img.copyResize(source, width: sourceSize, height: sourceSize, interpolation: img.Interpolation.average);
    }
    final resized = img.copyResize(source, width: load, height: load, interpolation: img.Interpolation.linear);
    final offset = (load - size) ~/ 2;
    final small = load == size ? resized : img.copyCrop(resized, x: offset, y: offset, width: size, height: size);
    // Forme [1, size, size, 3] mise à plat, en octets 0–255 : le graphe
    // normalise lui-même. À plat, et non en listes imbriquées : à 320 px
    // celles-ci pesaient 102 400 listes et 307 200 nombres emballés, tous
    // recopiés un par un au retour de l'isolat. Le `Float32List` traverse
    // en un bloc et part au tenseur natif sans conversion (voir [_infer]).
    final out = Float32List(size * size * 3);
    var i = 0;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final p = small.getPixel(x, y);
        out[i++] = p.r.toDouble();
        out[i++] = p.g.toDouble();
        out[i++] = p.b.toDouble();
      }
    }
    return out;
  }
}
