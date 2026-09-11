import 'dart:typed_data';
import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Résultat d'un import de photo : chemins relatifs + dimensions.
class StoredPhoto {
  const StoredPhoto({required this.filePath, required this.thumbPath, required this.width, required this.height, this.takenAt});

  final String filePath;
  final String thumbPath;
  final int width;
  final int height;

  /// Date de prise de vue lue dans l'EXIF, quand la photo en portait une.
  /// `null` pour une image sans métadonnées : l'appelant retombe alors sur
  /// l'heure courante.
  final DateTime? takenAt;
}

enum PhotoSource { camera, gallery }

/// Import, compression et stockage local des photos.
///
/// - Original recompressé en JPEG (max 2048 px, qualité 85).
/// - Miniature 480 px pour les grilles.
/// - Traitement dans un isolate pour ne jamais bloquer l'UI.
class PhotoStorageService {
  PhotoStorageService();

  final _picker = ImagePicker();
  Directory? _root;

  static const _maxSide = 2048;
  static const _thumbSide = 480;

  Future<Directory> _photosDir() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return _root = dir;
  }

  /// Chemin absolu d'un chemin relatif stocké en base.
  Future<String> absolutePath(String relative) async => p.join((await _photosDir()).path, relative);

  /// Ouvre le picker natif ; retourne `null` si l'utilisateur annule.
  Future<StoredPhoto?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      // Une photo de la galerie peut dater d'il y a deux ans. Sans ses
      // métadonnées elle arriverait datée d'aujourd'hui : au mauvais mois de
      // la galerie, au mauvais bout du timelapse et du avant / après.
      // L'appareil photo, lui, n'a rien à raconter que l'instant présent.
      requestFullMetadata: source == PhotoSource.gallery,
    );
    if (file == null) return null;
    return importFile(File(file.path));
  }

  Future<StoredPhoto> importFile(File source) async {
    final dir = await _photosDir();
    final id = const Uuid().v4();
    final fileName = '$id.jpg';
    final thumbName = '${id}_thumb.jpg';
    final bytes = await source.readAsBytes();
    final result = await Isolate.run(() => _process(bytes, p.join(dir.path, fileName), p.join(dir.path, thumbName)));
    return StoredPhoto(filePath: fileName, thumbPath: thumbName, width: result.width, height: result.height, takenAt: result.takenAt);
  }

  Future<void> deleteFiles(String filePath, String thumbPath) async {
    for (final rel in [filePath, thumbPath]) {
      if (rel.isEmpty) continue;
      final f = File(await absolutePath(rel));
      if (await f.exists()) await f.delete();
    }
  }

  /// Efface les fichiers que plus aucune ligne ne réclame ; retourne leur nombre.
  ///
  /// [keep] : les chemins relatifs encore référencés. [minAge] épargne les
  /// fichiers tout frais : pendant une création, la photo existe à l'écran
  /// avant d'avoir sa ligne, et un ménage mal tombé la ferait disparaître
  /// sous les yeux de l'utilisateur.
  Future<int> sweepOrphans(Set<String> keep, {Duration minAge = const Duration(hours: 12)}) async {
    final dir = await _photosDir();
    final cutoff = DateTime.now().subtract(minAge);
    var removed = 0;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      if (keep.contains(p.basename(entity.path))) continue;
      try {
        if ((await entity.stat()).modified.isAfter(cutoff)) continue;
        await entity.delete();
        removed++;
      } catch (_) {
        // Fichier verrouillé ou déjà parti : le prochain passage réessaiera.
      }
    }
    return removed;
  }

  static ({int width, int height, DateTime? takenAt}) _process(Uint8List bytes, String outPath, String thumbPath) {
    var image = img.decodeImage(bytes);
    if (image == null) throw const FormatException('unreadable image');
    final takenAt = _exifDate(image);
    image = img.bakeOrientation(image);
    // L'encodeur réécrit l'EXIF tel quel : les coordonnées GPS suivraient la
    // photo dans l'export, la synchronisation et le partage par lien. Le
    // jardin de quelqu'un n'a pas à dire où il habite ; elles s'arrêtent ici.
    image.exif.gpsIfd.data.clear();
    if (image.width > _maxSide || image.height > _maxSide) {
      image = image.width >= image.height ? img.copyResize(image, width: _maxSide) : img.copyResize(image, height: _maxSide);
    }
    File(outPath).writeAsBytesSync(img.encodeJpg(image, quality: 85));
    final thumb = image.width >= image.height ? img.copyResize(image, width: _thumbSide) : img.copyResize(image, height: _thumbSide);
    File(thumbPath).writeAsBytesSync(img.encodeJpg(thumb, quality: 80));
    return (width: image.width, height: image.height, takenAt: takenAt);
  }

  /// Date de prise de vue de l'EXIF, si elle est lisible et plausible.
  ///
  /// `DateTimeOriginal` est l'instant du déclenchement ; `DateTime` (IFD0)
  /// est la dernière écriture du fichier et ne sert que de repli. Le format
  /// est `2024:05:12 09:31:22`, sans fuseau : c'est l'heure locale de
  /// l'appareil qui a pris la photo, et on la garde telle quelle.
  static DateTime? _exifDate(img.Image image) {
    try {
      final exif = image.exif;
      final raw = exif.exifIfd['DateTimeOriginal']?.toString() ?? exif.imageIfd['DateTime']?.toString();
      if (raw == null || raw.length < 19) return null;
      final parsed = DateTime.tryParse('${raw.substring(0, 4)}-${raw.substring(5, 7)}-${raw.substring(8, 10)}T${raw.substring(11, 19)}');
      if (parsed == null) return null;
      // Une date absurde — horloge jamais réglée, EXIF abîmé — rangerait la
      // photo en 1970 dans la galerie : mieux vaut ne rien savoir.
      if (parsed.isBefore(DateTime(1990)) || parsed.isAfter(DateTime.now().add(const Duration(days: 1)))) return null;
      return parsed;
    } catch (_) {
      // Métadonnées illisibles : la photo vaut mieux que sa date.
      return null;
    }
  }
}
