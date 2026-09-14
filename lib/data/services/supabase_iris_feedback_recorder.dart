import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/scientific_name.dart';
import '../../domain/identification/iris_feedback.dart';
import '../../domain/identification/plant_identifier.dart';

/// Envoie un retour dans la table `iris_feedback` et le seau `iris-feedback`.
///
/// Un seau à part, pas celui des photos de jardin : celui-là est partagé
/// avec les membres, et une photo donnée pour l'entraînement ne doit être
/// lisible que par son auteur. Les photos partent réduites à [maxSide] —
/// assez pour tout ce qu'un modèle voit aujourd'hui (448 px stockés au jeu)
/// et de la marge pour une entrée plus large — et sans coordonnées GPS,
/// comme tout ce que l'app stocke.
///
/// Rien ici ne remonte : l'enregistrement d'une plante ne dépend pas d'un
/// envoi, et un réseau absent ne doit pas se voir.
class SupabaseIrisFeedbackRecorder implements IrisFeedbackRecorder {
  SupabaseIrisFeedbackRecorder(this._client, {required this.userId, this.appVersion = AppConfig.version});

  static const bucket = 'iris-feedback';
  static const table = 'iris_feedback';
  static const maxSide = 640;
  static const _uuid = Uuid();

  final SupabaseClient _client;
  final String userId;
  final String appVersion;

  @override
  Future<void> record(IrisFeedback feedback) async {
    // Sans passage par Iris, il n'y a rien à lui apprendre ; et sans photo,
    // rien à envoyer.
    if (feedback.local.isEmpty || feedback.photos.isEmpty) return;
    // Un nom de genre — « Picea », retenu quand aucune espèce ne passait —
    // n'est pas une étiquette d'espèce : `auxine.py` ne saurait pas le
    // rattacher à une classe, et le modèle n'en apprendrait rien.
    if (!feedback.chosenName.trim().contains(' ')) return;
    try {
      final id = _uuid.v4();
      final folder = '$userId/$id';
      var sent = 0;
      for (final photo in feedback.photos.take(3)) {
        final reduced = await compute(_reduce, await photo.readAsBytes());
        if (reduced == null) continue;
        await _client.storage.from(bucket).uploadBinary('$folder/$sent.jpg', reduced,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
        sent++;
      }
      if (sent == 0) return;
      await _client.from(table).insert({
        'id': id,
        'user_id': userId,
        'storage_path': folder,
        'photos': sent,
        'species_id': feedback.chosenId ?? internalPlantId(normalizeScientificName(feedback.chosenName)),
        'species_name': feedback.chosenName,
        'kind': feedback.kind.name,
        'chosen_source': feedback.chosenSource.name,
        'local_top5': [for (final c in feedback.local.take(5)) _candidate(c)],
        'remote_top1': feedback.remoteTop == null ? null : _candidate(feedback.remoteTop!),
        'model_version': feedback.modelVersion,
        'app_version': appVersion,
      });
    } catch (_) {
      // Un retour perdu n'est qu'un retour perdu.
    }
  }

  static Map<String, Object?> _candidate(IdentificationCandidate c) =>
      {'id': c.internalId, 'name': c.scientificName, 'score': c.score};

  /// Dans un isolat : décoder, redresser, retirer le GPS, réduire, réencoder.
  static Uint8List? _reduce(Uint8List bytes) {
    var image = img.decodeImage(bytes);
    if (image == null) return null;
    image = img.bakeOrientation(image);
    image.exif.gpsIfd.data.clear();
    if (image.width > maxSide || image.height > maxSide) {
      image = image.width >= image.height ? img.copyResize(image, width: maxSide) : img.copyResize(image, height: maxSide);
    }
    return img.encodeJpg(image, quality: 85);
  }
}
