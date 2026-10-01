import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../domain/identification/context_mask.dart';
import '../../domain/identification/identification_context.dart';
import '../../domain/identification/iris_fusion.dart';
import '../../domain/identification/local_plant_model.dart';
import '../../domain/identification/plant_identifier.dart';
import 'iris10_input.dart';
import 'tflite_plant_model.dart';

/// Iris 10 : Iris 9 et l'encodeur distillé de BioCLIP, fusionnés.
///
/// Ce qui a été décidé au banc (§ 20 duodecies à quindecies de `docs/14`) :
/// les deux modèles regardent la même photo, Iris 10 la compare à ses
/// références, et la fusion `p9^0,5 · p10^0,5` répond — mieux que l'un ou
/// l'autre seul, en intérieur comme dehors. Elle affirme à 0,85.
///
/// **Iris 9 reste le socle.** Si les fichiers d'Iris 10 manquent, ne se
/// lisent pas ou ne rendent pas le vecteur de contrôle de l'export, le
/// modèle continue avec Iris 9 seul, à son propre seuil — exactement
/// l'application d'avant. Un Iris 10 qui calculerait faux est pire qu'un
/// Iris 10 absent : il afficherait des certitudes fausses.
///
/// La photo n'est décodée qu'une fois : le décodage d'une photo de 12 Mpx
/// coûte plus que les deux réseaux réunis. Les deux entrées sont préparées
/// dans le même isolat jetable, chaque réseau tourne dans le sien.
class FusedPlantModel implements LocalPlantModel {
  FusedPlantModel({
    TflitePlantModel? iris9,
    this.modelAsset = 'assets/model/iris10.tflite',
    this.metaAsset = 'assets/model/iris10.json',
    this.referencesAsset = 'assets/model/iris10-references.bin',
    this.threads = 4,
    AssetBundle? bundle,
  })  : iris9 = iris9 ?? TflitePlantModel(bundle: bundle),
        _bundle = bundle ?? rootBundle;

  final TflitePlantModel iris9;
  final String modelAsset;
  final String metaAsset;
  final String referencesAsset;

  /// Quatre fils : mesuré sur iPhone 16 Pro, 47 ms au lieu de 57 à deux
  /// (§ 20 terdecies). Metal et Core ML refusent le modèle ou le ralentissent.
  final int threads;
  final AssetBundle _bundle;

  Iris10References? _references;
  Interpreter? _interpreter;
  IsolateInterpreter? _worker;
  Future<bool>? _loading;
  String? _iris10Error;

  /// La file des inférences d'Iris 10, comme celle de `TflitePlantModel`.
  Future<void> _turn = Future<void>.value();

  /// Vrai quand Iris 10 est chargé et a passé son contrôle : la fusion
  /// répond. Faux avant le chargement et quand Iris 9 répond seul.
  bool get fused => _references != null && _interpreter != null;

  /// Pourquoi Iris 10 n'a pas été retenu, `null` s'il l'a été ou n'a pas
  /// encore été chargé. Ce n'est pas une panne du modèle — Iris 9 répond.
  String? get iris10Error => _iris10Error;

  @override
  bool get isAvailable => iris9.isAvailable;

  @override
  String? get version => fused ? _references!.version : iris9.version;

  @override
  int get speciesCount => fused ? _references!.species.length : iris9.speciesCount;

  @override
  String? get loadError => iris9.loadError;

  @override
  Set<IdentificationContext> get contexts => iris9.contexts;

  @override
  double? get acceptThreshold => fused ? _references!.acceptThreshold : iris9.acceptThreshold;

  @override
  Future<bool> warmUp() => _loading ??= _load();

  Future<bool> _load() async {
    if (!await iris9.warmUp()) return false;
    try {
      await _loadIris10();
    } on Object catch (e) {
      _iris10Error = e.toString();
      debugPrint('Iris 10 non retenu, Iris 9 répond seul : $e');
      _release();
    }
    return true;
  }

  Future<void> _loadIris10() async {
    final meta = await _bundle.loadString(metaAsset);
    final raw = await _bundle.load(referencesAsset);
    final labels = iris9.labels;
    // Les références pèsent quelques Mo de demi-flottants à convertir :
    // hors de l'isolat principal, comme tout ce qui se compte en millions.
    final references = await Isolate.run(() => Iris10References.parse(meta, raw, labels));

    final options = InterpreterOptions()..threads = threads;
    final interpreter = await Interpreter.fromAsset(modelAsset, options: options);
    _interpreter = interpreter;
    try {
      _worker = await IsolateInterpreter.create(address: interpreter.address);
    } on Object catch (e) {
      debugPrint('Iris 10 hors isolat impossible : $e');
      _worker = null;
    }

    // Le contrôle : le motif de l'export doit rendre le vecteur de l'export.
    final control = await _embed(iris10ControlInput(references.inputSize), references.dim);
    if (!references.matchesControl(control)) {
      throw StateError('Iris 10 ne rend pas le vecteur de contrôle de son export');
    }
    _references = references;
  }

  @override
  Future<List<IdentificationCandidate>> classify(File image,
      {IdentificationContext context = IdentificationContext.unknown}) async {
    if (!await warmUp()) return const [];
    final references = _references;
    if (!fused || references == null) return iris9.classify(image, context: context);

    final bytes = await image.readAsBytes();
    final framing = iris9.framing;
    final size10 = references.inputSize;
    final inputs = await Isolate.run(() => _prepareBoth(bytes, framing, size10));
    if (inputs == null) return const [];

    final p9 = await iris9.scores(inputs.iris9);
    if (p9 == null) return const [];
    final embedding = await _embed(inputs.iris10, references.dim);
    final scores = references.fuse(references.iris9ToSpecies(p9), references.speciesProbabilities(embedding));
    return maskedCandidates(scores, references.species,
        nameOf: TflitePlantModel.scientificNameOf, mask: references.speciesMask(iris9.maskFor(context)));
  }

  static ({Float32List iris9, Float32List iris10})? _prepareBoth(
      Uint8List bytes, ({int size, int load, int source}) framing, int size10) {
    final oriented = TflitePlantModel.decodeOriented(bytes);
    if (oriented == null) return null;
    return (
      iris9: TflitePlantModel.prepareDecoded(oriented, framing.size, framing.load, framing.source),
      iris10: iris10Input(oriented, size: size10),
    );
  }

  static const _inferenceTimeout = Duration(seconds: 15);

  /// Le vecteur d'Iris 10, une inférence à la fois (voir `TflitePlantModel._run`).
  Future<Float32List> _embed(Float32List input, int dim) {
    final output = [List<double>.filled(dim, 0)];
    final turn = _turn.then<void>((_) => _infer(input, output)).timeout(_inferenceTimeout);
    _turn = turn.then<void>((_) {}, onError: (Object _) {});
    return turn.then((_) {
      final v = Float32List.fromList(output.first);
      // Le graphe rend un vecteur unitaire ; on le renormalise quand même,
      // ce qui ne coûte rien et protège le produit scalaire d'un arrondi.
      var n = 0.0;
      for (final x in v) {
        n += x * x;
      }
      n = math.sqrt(n);
      if (n > 0) {
        for (var i = 0; i < v.length; i++) {
          v[i] /= n;
        }
      }
      return v;
    });
  }

  Future<void> _infer(Float32List input, List<List<double>> output) async {
    // La vue en octets, comme pour Iris 9 : `tflite_flutter` la recopie
    // d'un bloc au lieu de convertir 307 200 nombres un par un.
    final Object payload = Endian.host == Endian.little
        ? input.buffer.asUint8List(input.offsetInBytes, input.lengthInBytes)
        : input;
    final worker = _worker;
    if (worker != null) {
      await worker.run(payload, output);
    } else {
      _interpreter?.run(payload, output);
    }
  }

  void _release() {
    _worker?.close();
    _worker = null;
    _interpreter?.close();
    _interpreter = null;
    _references = null;
  }

  @override
  void dispose() {
    _release();
    iris9.dispose();
  }
}
