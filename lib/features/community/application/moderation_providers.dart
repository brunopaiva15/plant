import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/network/network_failure.dart';
import '../../../domain/community/species_tip.dart';

/// Ce compte modère-t-il les conseils de la communauté ?
///
/// La réponse vient du serveur, jamais du profil : la liste des modérateurs
/// est une table que rien ne laisse écrire depuis l'application. Un drapeau
/// posé sur `profiles` se donnerait à soi-même — la politique « profiles
/// write » laisse chacun écrire sa propre ligne (docs/04).
///
/// Hors ligne, `false` : l'écran de modération ne peut rien faire sans
/// réseau, et une ligne de réglages n'a pas à porter une erreur.
final tipModeratorProvider = FutureProvider<bool>(retry: noRetry, (ref) async {
  ref.watch(connectivityProvider);
  final service = ref.watch(communityTipsServiceProvider);
  if (!service.canPublish) return false;
  try {
    return await ref.online(service.isModerator);
  } on OfflineException {
    return false;
  }
});

/// Les conseils signalés, les plus signalés d'abord. Vide pour qui ne modère
/// pas — le serveur ne rend rien plutôt que de refuser.
final reportedTipsProvider = FutureProvider.autoDispose<List<SpeciesTip>>(retry: noRetry, (ref) {
  ref.watch(connectivityProvider);
  final service = ref.watch(communityTipsServiceProvider);
  if (!service.canPublish) return Future.value(const <SpeciesTip>[]);
  return ref.online(service.reported);
});
