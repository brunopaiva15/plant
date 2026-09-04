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
  const StoredPhoto({required this.filePath, required this.thumbPath, required this.width, required this.height});

  final String filePath;
  final String thumbPath;
  final int width;
  final int height;
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
      requestFullMetadata: false,
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
    return StoredPhoto(filePath: fileName, thumbPath: thumbName, width: result.$1, height: result.$2);
  }

  Future<void> deleteFiles(String filePath, String thumbPath) async {
    for (final rel in [filePath, thumbPath]) {
      final f = File(await absolutePath(rel));
      if (await f.exists()) await f.delete();
    }
  }

  static (int, int) _process(Uint8List bytes, String outPath, String thumbPath) {
    var image = img.decodeImage(bytes);
    if (image == null) throw const FormatException('unreadable image');
    image = img.bakeOrientation(image);
    if (image.width > _maxSide || image.height > _maxSide) {
      image = image.width >= image.height ? img.copyResize(image, width: _maxSide) : img.copyResize(image, height: _maxSide);
    }
    File(outPath).writeAsBytesSync(img.encodeJpg(image, quality: 85));
    final thumb = image.width >= image.height ? img.copyResize(image, width: _thumbSide) : img.copyResize(image, height: _thumbSide);
    File(thumbPath).writeAsBytesSync(img.encodeJpg(thumb, quality: 80));
    return (image.width, image.height);
  }
}
