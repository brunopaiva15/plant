import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_failure.dart';

/// Ce que l'application sait du réseau.
enum NetworkStatus { online, offline }

/// « Quelque chose sort-il de cet appareil ? »
abstract class Reachability {
  Future<bool> probe();
}

/// Une résolution DNS : la question la plus courte qui sépare un appareil
/// sans réseau d'un serveur lent.
///
/// Deux hôtes plutôt qu'un : le premier peut être filtré par un réseau
/// d'entreprise sans que la connexion soit coupée. Une seule réponse suffit.
class DnsReachability implements Reachability {
  const DnsReachability({this.hosts = defaultHosts, this.timeout = const Duration(seconds: 5)});

  /// Deux noms qui existent partout et ne renvoient rien d'autre qu'une adresse.
  static const defaultHosts = ['cloudflare.com', 'apple.com'];

  final List<String> hosts;
  final Duration timeout;

  @override
  Future<bool> probe() async {
    // Sur le web, le navigateur ne résout pas de noms pour l'application :
    // faute de sonde, on la croit en ligne et ce sont les appels qui
    // tranchent.
    if (kIsWeb) return true;
    for (final host in hosts) {
      try {
        final addresses = await InternetAddress.lookup(host).timeout(timeout);
        if (addresses.isNotEmpty) return true;
      } on Object {
        continue;
      }
    }
    return false;
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

/// Comment l'application constate la présence du réseau.
///
/// Par défaut elle ne constate rien et se croit en ligne : c'est `main` qui
/// branche [DnsReachability], comme il branche la base et les préférences.
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
