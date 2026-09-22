import 'dart:io';

import '../../data/services/photo_storage_service.dart';
import 'demo_seed.dart';

/// Le magasin de photos du jeu de démo : le vrai, sauf que l'appareil photo
/// et la photothèque rendent une plante connue.
///
/// Un simulateur n'a pas de caméra, et sa photothèque ne contient que les
/// images d'Apple. L'étape photo de la création n'aurait donc jamais de
/// plante à lire, et le visuel du magasin qui la montre — les noms qu'Iris
/// pose sur la photo — ne pourrait pas se prendre. Ici les deux sources
/// rendent le Ficus lyrata de la démo, la photo que les autres écrans
/// montrent déjà.
///
/// Jamais en release : [DemoSeed.requested] est faux, et `main` n'installe
/// ce magasin que lorsque le jeu de démo est demandé.
class DemoPhotoStorage extends PhotoStorageService {
  DemoPhotoStorage({this.slug = 'ficus', this.base});

  /// La photo rendue, parmi celles de `store/demo-photos`.
  final String slug;

  /// D'où elle vient, quand ce n'est pas l'adresse du jeu de démo. Pour les
  /// tests, qui servent la photo depuis un port libre.
  final String? base;

  @override
  Future<File?> pickSource(PhotoSource source) => DemoSeed.photoFile(slug, base: base);
}
