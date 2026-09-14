import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import 'network_failure.dart';

/// Ce que l'application sait du réseau.
enum NetworkStatus { online, offline }

/// « Quelque chose sort-il de cet appareil ? »
abstract class Reachability {
  Future<bool> probe();
}

/// Une connexion réellement ouverte, plutôt qu'un nom résolu.
///
/// Résoudre un nom ne dit presque rien sur un téléphone : le résolveur répond
/// de son cache, et sur un iPhone les noms courants y sont toujours. En mode
/// avion, l'appareil se croyait donc joignable — la requête partait quand
/// même, et l'écran attendait son délai d'expiration pour rien. Ouvrir une
/// connexion tranche : sans route, le système répond « réseau injoignable »
/// sur-le-champ.
///
/// Trois destinations tentées **en même temps**, la première qui répond
/// suffit : le serveur de l'application — celui dont on a réellement besoin —
/// et deux adresses IP écrites en clair, qui ne demandent aucun DNS. Trois
/// plutôt qu'une parce que se tromper en disant « hors ligne » est la pire
/// erreur des deux : elle éteint des fonctions qui marchaient.
class SocketReachability implements Reachability {
  const SocketReachability({this.timeout = const Duration(seconds: 4), this.port = 443});

  /// Deux résolveurs publics, joignables en TCP sur 443. En chiffres : aucun
  /// DNS à interroger, donc aucun cache pour répondre à sa place.
  static const literals = ['1.1.1.1', '8.8.8.8'];

  final Duration timeout;
  final int port;

  /// Ce qu'on essaie d'atteindre : le backend d'abord, quand il est configuré.
  List<String> get hosts => [
        if (SupabaseConfig.isConfigured) Uri.parse(SupabaseConfig.url).host,
        ...literals,
      ].where((h) => h.isNotEmpty).toList();

  @override
  Future<bool> probe() async {
    // Sur le web, le navigateur n'ouvre pas de connexion pour l'application :
    // faute de sonde, on la croit en ligne et ce sont les appels qui tranchent.
    if (kIsWeb) return true;
    final targets = hosts;
    if (targets.isEmpty) return true;
    final answer = Completer<bool>();
    var left = targets.length;
    for (final host in targets) {
      unawaited(_reaches(host).then((reached) {
        left--;
        if (answer.isCompleted) return;
        if (reached) {
          answer.complete(true);
        } else if (left == 0) {
          answer.complete(false);
        }
      }));
    }
    return answer.future;
  }

  Future<bool> _reaches(String host) async {
    try {
      // Deux bornes : celle de `connect` couvre la poignée de main, la
      // seconde le nom à résoudre, qui peut traîner avant elle.
      final socket = await Socket.connect(host, port, timeout: timeout).timeout(timeout);
      socket.destroy();
      return true;
    } on Object {
      return false;
    }
  }
}

/// L'état du réseau, tenu à jour par trois signaux : une sonde au démarrage et
/// à chaque retour au premier plan, les appels qui échouent, et une nouvelle
/// sonde tant qu'on est hors ligne.
///
/// Personne ne peut promettre qu'un serveur répondra ; on peut seulement
/// constater qu'aucune route ne sort de l'appareil. C'est ce constat que
/// l'application montre, plutôt qu'un tourniquet qui ne s'arrête jamais.
class ConnectivityController extends Notifier<NetworkStatus> with WidgetsBindingObserver {
  /// Intervalle entre deux sondes, hors ligne : assez court pour qu'un écran
  /// se remplisse seul quand le réseau revient, assez long pour ne pas sonder
  /// en boucle. Rien ne tourne quand l'application est en ligne, ni quand
  /// elle est en arrière-plan.
  static const retryDelay = Duration(seconds: 8);

  Timer? _retry;
  Future<bool>? _probe;
  var _disposed = false;

  @override
  NetworkStatus build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _disposed = true;
      _retry?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });
    // On n'accuse pas le réseau avant d'avoir regardé : l'application démarre
    // en ligne, la sonde tranche juste après.
    scheduleMicrotask(refresh);
    return NetworkStatus.online;
  }

  /// Regarde si le réseau répond. Les appels concurrents partagent la sonde.
  Future<NetworkStatus> refresh() async {
    final reachable = await (_probe ??= _probeOnce());
    return reachable ? NetworkStatus.online : NetworkStatus.offline;
  }

  /// Vrai quand une sonde confirme que le réseau manque. Un appel qui échoue
  /// s'y réfère avant d'accuser la connexion : un serveur muet n'est pas un
  /// réseau coupé, et les deux ne se disent pas de la même façon.
  Future<bool> confirmOffline() async => await refresh() == NetworkStatus.offline;

  /// Un appel réseau vient d'aboutir : la question est réglée.
  void reportSuccess() => _set(NetworkStatus.online);

  Future<bool> _probeOnce() async {
    try {
      final reachable = await ref.read(reachabilityProvider).probe();
      _set(reachable ? NetworkStatus.online : NetworkStatus.offline);
      return reachable;
    } finally {
      _probe = null;
    }
  }

  void _set(NetworkStatus next) {
    if (_disposed) return;
    // Ne réécrire que ce qui change : les écrans qui suivent cet état se
    // reconstruisent, et une sonde toutes les huit secondes les relancerait
    // pour rien.
    if (state != next) state = next;
    _retry?.cancel();
    _retry = next == NetworkStatus.offline ? Timer(retryDelay, () => unawaited(refresh())) : null;
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      unawaited(refresh());
    } else if (lifecycle == AppLifecycleState.paused || lifecycle == AppLifecycleState.hidden) {
      // En arrière-plan, personne ne regarde : la sonde attend le retour.
      _retry?.cancel();
      _retry = null;
    }
  }
}

/// Sonde inerte : « en ligne », sans rien demander à personne.
class AlwaysReachable implements Reachability {
  const AlwaysReachable();

  @override
  Future<bool> probe() async => true;
}

/// Ce qu'il faut faire d'un provider réseau qui a échoué : rien de plus.
///
/// Riverpod réessaie de lui-même — dix fois, en doublant l'attente — et garde
/// l'état sur `AsyncLoading` pendant tout ce temps. La branche `error:` d'un
/// écran ne s'affichait donc qu'après plusieurs minutes : le tourniquet que
/// cette page devait supprimer, réintroduit par en dessous.
///
/// Ici la reprise est explicite et visible : la sonde rouvre le passage quand
/// le réseau revient, et le bouton « Réessayer » est à l'écran.
Duration? noRetry(int retryCount, Object error) => null;

/// Comment l'application constate la présence du réseau.
///
/// Par défaut elle ne constate rien et se croit en ligne : c'est `main` qui
/// branche [SocketReachability], comme il branche la base et les préférences.
/// Un test qui ne parle pas du réseau n'a donc ni attente ni minuteur en
/// cours ; celui qui veut jouer l'un ou l'autre passe sa propre sonde.
final reachabilityProvider = Provider<Reachability>((ref) => const AlwaysReachable());

final connectivityProvider = NotifierProvider<ConnectivityController, NetworkStatus>(ConnectivityController.new);

/// `true` tant que le réseau répond. Ce que regardent les écrans.
final isOnlineProvider = Provider<bool>((ref) => ref.watch(connectivityProvider) == NetworkStatus.online);

/// Exécute un appel qui a besoin du réseau, en tenant [connectivityProvider]
/// à jour.
///
/// Hors ligne, rien n'est tenté : [OfflineException] part tout de suite et
/// l'écran le dit, sans attendre le délai d'une requête qui ne partira pas.
/// C'est la sonde du contrôleur — au réveil, au retour au premier plan, et
/// toutes les quelques secondes tant que le réseau manque — qui rouvre le
/// passage, et l'écran se reconstruit alors de lui-même.
///
/// Sinon l'appel part : sa réussite confirme la connexion, et son échec ne
/// devient « hors ligne » que si une sonde le confirme — sans quoi une panne
/// de serveur passerait pour une coupure de réseau.
Future<T> _guarded<T>(NetworkStatus status, ConnectivityController network, Future<T> Function() call) async {
  if (status == NetworkStatus.offline) throw const OfflineException();
  try {
    final value = await call();
    network.reportSuccess();
    return value;
  } catch (error) {
    if (isNetworkFailure(error) && await network.confirmOffline()) throw const OfflineException();
    rethrow;
  }
}

extension NetworkGuardRef on Ref {
  /// Exécute [call] s'il y a du réseau, lève `OfflineException` sinon.
  ///
  /// Un provider qui s'en sert observe aussi `connectivityProvider` : le
  /// retour de la connexion le reconstruit, et l'écran se remplit seul.
  Future<T> online<T>(Future<T> Function() call) => _guarded<T>(read(connectivityProvider), read(connectivityProvider.notifier), call);
}

extension NetworkGuardWidgetRef on WidgetRef {
  /// Exécute [call] s'il y a du réseau, lève `OfflineException` sinon.
  ///
  /// Pour un geste déclenché depuis un écran : l'appelant traduit l'exception
  /// en message plutôt que de laisser un bouton tourner.
  Future<T> online<T>(Future<T> Function() call) => _guarded<T>(read(connectivityProvider), read(connectivityProvider.notifier), call);
}
