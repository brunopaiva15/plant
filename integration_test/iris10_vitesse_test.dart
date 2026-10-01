// La vitesse d'Iris 10 sur un vrai téléphone, à côté d'Iris 9 (§ 20 terdecies
// de docs/14). Aucun écran : le test charge les modèles, les chronomètre et
// rend un tableau.
//
// Les fichiers d'Iris 10 ne sont pas livrés. Les copier d'abord dans
// assets/model/ — le dossier est déjà déclaré dans pubspec.yaml, et
// .gitignore les tient hors du dépôt — puis, depuis le Mac, iPhone branché :
//
//   flutter drive --profile --driver=test_driver/integration_test.dart \
//     --target=integration_test/iris10_vitesse_test.dart -d <iPhone>
//
// Le tableau s'affiche dans la console et s'écrit dans
// build/integration_response_data.json. Retirer ensuite les fichiers de
// assets/model/ : ils pèsent 35 Mo dans l'app.
//
// **Ce qui est mesuré** : `invoke()` seul, entrée déjà en place — le calcul du
// réseau, pas le décodage de la photo, identique pour les deux modèles.
// Cinq tours de chauffe, puis trente mesurés ; la médiane et le 9ᵉ décile.
// Le chargement (lecture du fichier, préparation de l'accélérateur) est
// donné à part : c'est l'attente du premier scan.
//
// **Les accélérateurs** : le processeur à 2 fils, le réglage de l'app pour
// Iris 9 (`TflitePlantModel`), puis 4 fils, Metal et Core ML. Un accélérateur
// qui refuse le modèle est noté, pas fatal.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

const _modeles = {
  'Iris 9': 'assets/model/plants.tflite',
  'Iris 10 fp16': 'assets/model/iris10-fp16.tflite',
  'Iris 10 int8w': 'assets/model/iris10-int8w.tflite',
};

const _chauffe = 5;
const _mesures = 30;

InterpreterOptions _options(String accelerateur) {
  final o = InterpreterOptions();
  switch (accelerateur) {
    case 'CPU 2 fils':
      o.threads = 2;
    case 'CPU 4 fils':
      o.threads = 4;
    case 'Metal':
      o.addDelegate(GpuDelegate());
    case 'Core ML':
      o.addDelegate(CoreMlDelegate());
  }
  return o;
}

/// Une entrée plausible : des valeurs 0-1 pour un tenseur flottant, des
/// octets au hasard sinon. Des zéros laisseraient passer des raccourcis de
/// calcul qu'une vraie photo n'offre pas.
Uint8List _entree(Tensor t, math.Random hasard) {
  if (t.type == TensorType.float32) {
    final n = t.numBytes() ~/ 4;
    return Float32List.fromList([for (var i = 0; i < n; i++) hasard.nextDouble()]).buffer.asUint8List();
  }
  return Uint8List.fromList([for (var i = 0; i < t.numBytes(); i++) hasard.nextInt(256)]);
}

double _quantile(List<double> valeurs, double q) {
  final triees = [...valeurs]..sort();
  return triees[((triees.length - 1) * q).round()];
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('vitesse des modèles', (tester) async {
    final hasard = math.Random(20260929);
    final resultats = <String, Object>{};
    final lignes = <String>['modèle            accélérateur   chargement   médiane   9ᵉ décile'];

    for (final MapEntry(key: nom, value: asset) in _modeles.entries) {
      final ByteData octets;
      try {
        octets = await rootBundle.load(asset);
      } on Object {
        lignes.add('${nom.padRight(17)} absent — copier $asset');
        continue;
      }
      for (final accelerateur in ['CPU 2 fils', 'CPU 4 fils', 'Metal', 'Core ML']) {
        final cle = '$nom · $accelerateur';
        try {
          final debut = Stopwatch()..start();
          final interprete = Interpreter.fromBuffer(octets.buffer.asUint8List(), options: _options(accelerateur));
          final entree = interprete.getInputTensor(0);
          entree.data = _entree(entree, hasard);
          interprete.invoke();
          final chargement = debut.elapsedMicroseconds / 1000;

          for (var i = 0; i < _chauffe; i++) {
            interprete.invoke();
          }
          final temps = <double>[];
          for (var i = 0; i < _mesures; i++) {
            final chrono = Stopwatch()..start();
            interprete.invoke();
            temps.add(chrono.elapsedMicroseconds / 1000);
          }
          interprete.close();

          final mediane = _quantile(temps, 0.5);
          final decile = _quantile(temps, 0.9);
          resultats[cle] = {'chargement_ms': chargement, 'mediane_ms': mediane, 'decile9_ms': decile};
          lignes.add('${nom.padRight(17)} ${accelerateur.padRight(14)} '
              '${chargement.toStringAsFixed(0).padLeft(7)} ms '
              '${mediane.toStringAsFixed(1).padLeft(7)} ms '
              '${decile.toStringAsFixed(1).padLeft(8)} ms');
        } on Object catch (e) {
          resultats[cle] = {'erreur': '$e'};
          lignes.add('${nom.padRight(17)} ${accelerateur.padRight(14)} refusé : $e');
        }
      }
    }

    // ignore: avoid_print
    print(['', ...lignes, ''].join('\n'));
    binding.reportData = {'vitesse': resultats};
  }, timeout: const Timeout(Duration(minutes: 20)));
}
