import 'dart:ui' show DisplayFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'orientation_lock.dart';

/// Ce que la fenêtre dit d'elle-même, écrit dans la console à chaque
/// changement.
///
/// Sert à relever les cotes d'un appareil qu'on n'a pas sous la main : sur
/// iPhone Duo, une même application passe de l'écran extérieur à l'écran
/// intérieur, se replie à demi, cohabite avec une autre, et chacune de ces
/// poses a ses points, ses marges sûres et peut-être son pli. Le simulateur
/// les donne toutes ; encore faut-il les lire.
///
/// Elle écrit en debug, et nulle part ailleurs — il n'y a rien à demander au
/// lancement. Un relevé qui répète le précédent n'est pas réécrit : la console
/// ne voit un bloc que quand la fenêtre change vraiment.
///
/// Elle ne s'est d'abord pas vue du tout : écrite depuis `main()`, avant que
/// l'application ait ouvert sa fenêtre, et derrière un `--dart-define` qu'une
/// faute de frappe rendait silencieux. Les deux sont corrigés — le premier
/// relevé attend la première image, et il n'y a plus de drapeau à passer.
abstract final class WindowProbe {
  /// La sonde écrit en debug seulement. Rien en profil, rien en production.
  static bool get enabled => kDebugMode;

  static _WindowProbeObserver? _observer;

  /// Branche la sonde et écrit la fenêtre de départ après la première image.
  static void attach() {
    if (!enabled || _observer != null) return;
    final observer = _WindowProbeObserver();
    _observer = observer;
    WidgetsBinding.instance.addObserver(observer);
    // Le premier relevé attend la première image. Écrit depuis `main()`, il
    // part dans le journal de l'appareil avant que `flutter run` ne s'y
    // branche : sur un simulateur, il n'arrive jamais jusqu'à la console.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(_entete);
      observer.report();
    });
  }

  /// Débranche la sonde. Réservé aux tests.
  @visibleForTesting
  static void detach() {
    final observer = _observer;
    if (observer == null) return;
    WidgetsBinding.instance.removeObserver(observer);
    _observer = null;
  }

  static const String _entete = '[auxine:fenêtre] sonde branchée — un relevé par changement de fenêtre.';
}

class _WindowProbeObserver with WidgetsBindingObserver {
  int _count = 0;
  String? _last;

  @override
  void didChangeMetrics() => report();

  /// Écrit la fenêtre courante, sauf si elle répète mot pour mot la
  /// précédente : un clavier qui monte et redescend n'apprend rien.
  void report() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = dispatcher.implicitView ?? (dispatcher.views.isEmpty ? null : dispatcher.views.first);
    if (view == null) {
      debugPrint('[auxine:fenêtre] aucune vue.');
      return;
    }

    final mq = MediaQueryData.fromView(view);
    final display = view.display;
    final corps = <String>[
      _ligne('taille', '${_pt(mq.size.width)} × ${_pt(mq.size.height)} pt · dpr ${_nb(mq.devicePixelRatio)} '
          '· physique ${_pt(view.physicalSize.width)} × ${_pt(view.physicalSize.height)} px'),
      _ligne('orientation', '${mq.orientation.name} · côté le plus court ${_pt(mq.size.shortestSide)} pt'),
      _ligne('verrou portrait', isCompactWindow() ? 'posé (fenêtre compacte)' : 'retiré'),
      _ligne('marges sûres', _bords(mq.padding)),
      _ligne('marges vues', _bords(mq.viewPadding)),
      _ligne('clavier', _bords(mq.viewInsets)),
      _ligne('écran', 'n° ${display.id} · ${_pt(display.size.width)} × ${_pt(display.size.height)} px '
          '· ${_nb(display.refreshRate)} Hz'),
      _ligne('vues ouvertes', '${dispatcher.views.length}'),
      _ligne('pli', _pli(mq.displayFeatures)),
      _ligne('colonne de lecture', mq.size.width <= 700
          ? 'pleine largeur (${_pt(mq.size.width)} ≤ 700)'
          : 'recentrée, ${_pt((mq.size.width - 700) / 2)} pt de marge de chaque côté'),
    ].join('\n');

    if (corps == _last) return;
    _last = corps;
    _count += 1;
    debugPrint('[auxine:fenêtre] relevé $_count — ${DateTime.now().toIso8601String()}\n$corps');
  }

  static String _ligne(String nom, String valeur) => '  ${nom.padRight(19, '.')} $valeur';

  static String _pt(double v) => v.toStringAsFixed(1);

  static String _nb(double v) => v.toStringAsFixed(2);

  static String _bords(EdgeInsets m) =>
      'haut ${_pt(m.top)} · bas ${_pt(m.bottom)} · gauche ${_pt(m.left)} · droite ${_pt(m.right)}';

  /// Le pli, s'il est là. Flutter ne remplit `displayFeatures` que sur
  /// Android : sur iOS la liste est vide, et c'est précisément ce qu'on
  /// cherche à vérifier ici.
  static String _pli(List<DisplayFeature> features) {
    if (features.isEmpty) return 'aucun — displayFeatures est vide';
    return features
        .map((f) => '${f.type.name} · ${f.state.name} · '
            '${_pt(f.bounds.left)},${_pt(f.bounds.top)} → ${_pt(f.bounds.right)},${_pt(f.bounds.bottom)}')
        .join('\n${' ' * 22}');
  }
}
