import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config.dart';

/// Ce que l'appareil sait faire d'un relevé.
class RoomScanSupport {
  const RoomScanSupport({required this.lidar, this.sections = false, this.structure = false});

  /// Un LiDAR, sans quoi RoomPlan ne relève rien.
  final bool lidar;

  /// Les types de pièce (iOS 17).
  final bool sections;

  /// L'assemblage de plusieurs pièces (iOS 17).
  final bool structure;

  static const none = RoomScanSupport(lidar: false);
}

/// Ce qu'un relevé rend : le fichier écrit et le nord s'il a été trouvé, ou
/// la raison pour laquelle rien n'a été écrit. Un relevé annulé ne rend
/// rien du tout.
class RoomScanResult {
  const RoomScanResult({this.paths = const [], this.northOffsetDeg, this.error});

  /// Les fichiers écrits : un par pièce, dans l'ordre du relevé.
  final List<String> paths;
  final double? northOffsetDeg;
  final String? error;

  String? get path => paths.firstOrNull;
  bool get succeeded => paths.isNotEmpty;
}

/// Le relevé d'une pièce par le téléphone (`ios/Runner/RoomScanChannel.swift`).
///
/// Trois questions : l'appareil peut-il relever, relever une pièce dans un
/// fichier, et rien d'autre. Annuler rend `null` : un relevé qu'on
/// abandonne n'est pas une panne.
abstract class RoomScanService {
  bool get isSupported;
  Future<RoomScanSupport> support();

  /// Ouvre le relevé natif et, au « Terminer », écrit le JSON à [toPath].
  Future<RoomScanResult?> scan({required String toPath});

  /// Relève l'appartement pièce après pièce, un fichier par pièce dans
  /// [toDirectory], les pièces placées les unes par rapport aux autres.
  /// [nextRoomLabel] est le bouton entre deux pièces, dans la langue de
  /// l'interface. iOS 17.
  Future<RoomScanResult?> scanStructure({required String toDirectory, required String nextRoomLabel});
}

/// Partout où RoomPlan n'existe pas : Android, le web, un build sans le drapeau.
class UnavailableRoomScanService implements RoomScanService {
  const UnavailableRoomScanService();

  @override
  bool get isSupported => false;

  @override
  Future<RoomScanSupport> support() async => RoomScanSupport.none;

  @override
  Future<RoomScanResult?> scan({required String toPath}) async => null;

  @override
  Future<RoomScanResult?> scanStructure({required String toDirectory, required String nextRoomLabel}) async => null;
}

/// Le canal natif, sur le patron de `ChannelHomeClimateService` : une
/// erreur de plateforme ou un canal absent valent la réponse vide.
class ChannelRoomScanService implements RoomScanService {
  ChannelRoomScanService({MethodChannel? channel, bool? enabled})
      : _channel = channel ?? const MethodChannel(channelName),
        _enabled = enabled ?? AppConfig.roomScanEnabled;

  static const channelName = 'ch.vergasta.plant/room_scan';

  final MethodChannel _channel;
  final bool _enabled;

  static bool get isPossible => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  bool get isSupported => _enabled && isPossible;

  @override
  Future<RoomScanSupport> support() async {
    final raw = await _ask(() => _channel.invokeMapMethod<String, Object?>('support'));
    return parseSupport(raw);
  }

  @override
  Future<RoomScanResult?> scan({required String toPath}) async {
    final raw = await _ask(() => _channel.invokeMapMethod<String, Object?>('scan', {'path': toPath}));
    return parseResult(raw);
  }

  @override
  Future<RoomScanResult?> scanStructure({required String toDirectory, required String nextRoomLabel}) async {
    final raw = await _ask(() => _channel.invokeMapMethod<String, Object?>('scanStructure', {'directory': toDirectory, 'nextRoomLabel': nextRoomLabel}));
    return parseResult(raw);
  }

  Future<T?> _ask<T>(Future<T?> Function() body) async {
    if (!isSupported) return null;
    try {
      return await body();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static RoomScanSupport parseSupport(Map<String, Object?>? raw) {
    if (raw == null) return RoomScanSupport.none;
    return RoomScanSupport(lidar: raw['lidar'] == true, sections: raw['sections'] == true, structure: raw['structure'] == true);
  }

  static RoomScanResult? parseResult(Map<String, Object?>? raw) {
    if (raw == null) return null;
    final north = raw['northOffsetDeg'];
    final error = raw['error'];
    // Plusieurs fichiers pour l'appartement, un seul pour une pièce : la
    // liste prime, le chemin seul se lit comme une liste d'un.
    final list = raw['paths'];
    final paths = <String>[
      if (list is List)
        for (final p in list)
          if (p is String && p.isNotEmpty) p,
    ];
    if (list is! List) {
      if (raw['path'] case final String p when p.isNotEmpty) paths.add(p);
    }
    if (paths.isEmpty) {
      return error is String && error.isNotEmpty ? RoomScanResult(error: error) : null;
    }
    return RoomScanResult(paths: paths, northOffsetDeg: north is num ? north.toDouble() : null, error: error is String ? error : null);
  }
}

/// Les fichiers des relevés, dans les documents de l'application, à côté
/// des photos. La base ne garde que le chemin relatif.
class RoomScanStore {
  // ignore: prefer_initializing_formals
  RoomScanStore({Directory? root}) : _root = root;

  Directory? _root;

  Future<Directory> _dir() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'rooms'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return _root = dir;
  }

  /// Le chemin absolu d'un nouveau fichier, à donner au relevé.
  Future<String> newPath(String id) async => p.join((await _dir()).path, '$id.json');

  /// Le dossier d'un relevé d'appartement : une pièce par fichier dedans.
  Future<String> newDirectory(String id) async => p.join((await _dir()).path, id);

  Future<String> absolutePath(String relative) async => p.join((await _dir()).path, relative);

  /// Le chemin relatif à garder en base : `abc.json`, ou `abc/0.json` pour
  /// une pièce d'un appartement. Le dossier est connu dès qu'un chemin a
  /// été demandé ; sinon, le nom du fichier.
  String relativeOf(String absolute) {
    final root = _root?.path;
    if (root != null && p.isWithin(root, absolute)) return p.relative(absolute, from: root);
    return p.basename(absolute);
  }

  /// Le JSON du relevé ; `null` si le fichier manque ou ne se lit pas.
  Future<Map<String, Object?>?> read(String relative) async {
    try {
      final file = File(await absolutePath(relative));
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? Map<String, Object?>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String relative) async {
    try {
      final file = File(await absolutePath(relative));
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Un fichier qui ne part pas n'empêche pas le relevé de disparaître.
    }
  }

  @visibleForTesting
  Future<void> write(String relative, Map<String, Object?> json) async => File(await absolutePath(relative)).writeAsString(jsonEncode(json));
}
