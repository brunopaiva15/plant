import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Délai au-delà duquel un appel réseau est tenu pour perdu.
///
/// Sans lui, un appareil privé de réseau ne reçoit ni réponse ni erreur : la
/// requête reste en l'air et l'écran tourne indéfiniment. Vingt secondes
/// laissent passer une connexion lente et coupent court au reste.
///
/// Les services HTTP de l'application bornent déjà leurs appels un par un ;
/// cette durée est celle des clients qui ne le font pas d'eux-mêmes —
/// Supabase et ses requêtes Postgrest.
const Duration networkTimeout = Duration(seconds: 20);

/// Le réseau est hors de portée : l'appel n'a pas été tenté, ou n'est jamais
/// sorti de l'appareil.
///
/// Distincte des erreurs du serveur, qui, elles, demandent de réessayer plus
/// tard ou de corriger quelque chose : ici il n'y a rien à corriger, il n'y a
/// qu'à retrouver du réseau.
class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() => 'OfflineException';
}

/// Vrai quand l'échec vient du réseau et non du serveur.
///
/// Les deux ne se disent pas la même chose : un serveur qui refuse a une
/// raison que l'interface traduit, un réseau absent n'en a pas. Les clients
/// HTTP jettent des exceptions reconnaissables ; Supabase, lui, enveloppe la
/// panne dans les siennes, et il ne reste que le message pour la retrouver.
bool isNetworkFailure(Object error) {
  if (error is SocketException || error is TimeoutException || error is HandshakeException || error is http.ClientException) {
    return true;
  }
  final text = error.toString().toLowerCase();
  return _networkMarkers.any(text.contains);
}

/// Ce qu'écrivent `dart:io`, `package:http` et les clients Supabase quand la
/// route ne sort pas de l'appareil.
const _networkMarkers = [
  'failed host lookup',
  'network is unreachable',
  'no address associated with hostname',
  'connection refused',
  'connection reset',
  'connection closed',
  'connection terminated',
  'software caused connection abort',
  'operation timed out',
  'os error: host is down',
  'authretryablefetchexception',
  'clientexception',
  'socketexception',
];
