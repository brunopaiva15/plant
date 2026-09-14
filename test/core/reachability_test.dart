import 'dart:io';

import 'package:flora/core/network/connectivity.dart';
import 'package:flutter_test/flutter_test.dart';

/// La sonde de joignabilité, sur de vraies connexions.
///
/// Elle a d'abord résolu des noms, et c'était faux : un résolveur répond de
/// son cache, si bien qu'un appareil en mode avion se croyait joignable, que
/// la requête partait quand même, et que l'écran attendait son délai
/// d'expiration devant un tourniquet. Ouvrir une connexion ne se cache pas.
void main() {
  test('un hôte qui écoute rend « en ligne »', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((socket) => socket.destroy());

    final probe = SocketReachability(port: server.port, timeout: const Duration(seconds: 2));
    // Les littéraux publics ne sont pas joignables depuis un test : c'est la
    // boucle locale, seule, qui doit répondre.
    expect(await _probeOnly(probe, ['127.0.0.1']), isTrue);
  });

  test('personne au bout : « hors ligne »', () async {
    // Un port fermé sur la boucle locale : le refus est immédiat, comme
    // l'« réseau injoignable » d'un appareil sans route.
    final probe = SocketReachability(port: await _closedPort(), timeout: const Duration(seconds: 2));
    expect(await _probeOnly(probe, ['127.0.0.1']), isFalse);
  });

  test('une seule destination joignable suffit', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((socket) => socket.destroy());

    // Deux adresses mortes et une vivante : la sonde ne doit pas conclure sur
    // la première venue. Se tromper en disant « hors ligne » éteindrait des
    // fonctions qui marchent.
    final probe = SocketReachability(port: server.port, timeout: const Duration(seconds: 2));
    expect(await _probeOnly(probe, ['192.0.2.1', '127.0.0.1']), isTrue);
  });

  test('le serveur de l\'application passe avant les adresses en clair', () {
    // Sans backend configuré, il reste les deux littéraux, qui ne demandent
    // aucun DNS — le cache d'un résolveur ne peut donc pas répondre pour eux.
    expect(const SocketReachability().hosts, SocketReachability.literals);
  });
}

/// La sonde restreinte à des hôtes choisis par le test.
Future<bool> _probeOnly(SocketReachability probe, List<String> hosts) => _Scoped(probe, hosts).probe();

class _Scoped extends SocketReachability {
  _Scoped(SocketReachability base, this._hosts) : super(port: base.port, timeout: base.timeout);

  final List<String> _hosts;

  @override
  List<String> get hosts => _hosts;
}

/// Un port que personne n'écoute : on en ouvre un, on le referme.
Future<int> _closedPort() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close();
  return port;
}
