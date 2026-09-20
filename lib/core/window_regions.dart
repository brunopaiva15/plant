import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Ce que le système réserve dans la fenêtre, demandé plutôt que supposé.
///
/// Trois choses qu'aucune marge sûre n'annonce, et qui décidaient jusqu'ici
/// de constantes mesurées à la main sur des captures :
///
/// - jusqu'où descend la pile du système — caméra, heure, wifi — pour que le
///   menu debout commence dessous ;
/// - sur quel axe cette pile est posée, pour que le menu s'y aligne ;
/// - où passe le pli, que `MediaQuery.displayFeatures` ne donne pas sur iOS.
///
/// Chaque valeur peut manquer : le canal n'existe que sur iOS, la réponse
/// demande le SDK 27.1, et une valeur invraisemblable est écartée. L'appelant
/// garde alors sa mesure — c'est un raffinement, jamais une dépendance.
@immutable
class WindowRegions {
  const WindowRegions({this.systemStackBottom, this.systemAxisFromRight, this.fold});

  /// Le bas de la pile du système, en points depuis le haut de la fenêtre.
  final double? systemStackBottom;

  /// L'axe de la colonne du système, en points depuis le bord droit.
  final double? systemAxisFromRight;

  /// Le pli, quand il est actif. Vide ou absent sur un appareil à plat.
  final Rect? fold;

  bool get isEmpty => systemStackBottom == null && systemAxisFromRight == null && fold == null;

  @override
  bool operator ==(Object other) =>
      other is WindowRegions &&
      other.systemStackBottom == systemStackBottom &&
      other.systemAxisFromRight == systemAxisFromRight &&
      other.fold == fold;

  @override
  int get hashCode => Object.hash(systemStackBottom, systemAxisFromRight, fold);

  @override
  String toString() => isEmpty
      ? 'aucune région annoncée'
      : 'pile jusqu\'à ${systemStackBottom?.toStringAsFixed(1)} · '
            'axe à ${systemAxisFromRight?.toStringAsFixed(1)} du bord · '
            'pli ${fold ?? "aucun"}';
}

/// Le canal qui les demande, et les tient à jour au fil des plis.
abstract final class WindowRegionsService {
  static const MethodChannel _channel = MethodChannel('ch.vergasta.plant/window_regions');

  /// Ce que le système a répondu la dernière fois. Le menu debout l'écoute.
  static final ValueNotifier<WindowRegions> regions = ValueNotifier<WindowRegions>(const WindowRegions());

  /// La réponse du natif mot pour mot, pour la sonde de `window_probe.dart`.
  ///
  /// « Aucune région annoncée » a trop de causes pour se lire seul : pas
  /// d'iOS, un binaire sans le canal, un SDK antérieur à 27.1, une vue pas
  /// encore posée, ou une cote écartée par [parse]. Cette ligne-là les
  /// distingue, et c'est tout ce qu'elle fait.
  static final ValueNotifier<String> lastAnswer = ValueNotifier<String>('pas encore demandé');

  /// Le canal n'existe que côté iOS. Ailleurs, rien n'est demandé.
  static bool get isSupported => debugForceSupported || (!kIsWeb && Platform.isIOS);

  /// Pour qu'un test puisse répondre à la place du natif. Faux ailleurs.
  @visibleForTesting
  static bool debugForceSupported = false;

  static _RegionsObserver? _observer;

  /// Branche le service et demande une première fois. Sans effet ailleurs
  /// que sur iOS, et sans effet deux fois.
  static Future<void> attach() async {
    if (!isSupported) {
      lastAnswer.value = 'hors iOS — rien à demander';
      return;
    }
    if (_observer != null) return;
    final observer = _RegionsObserver();
    _observer = observer;
    WidgetsBinding.instance.addObserver(observer);
    // Demandé depuis `main()`, avant la première image : la scène n'est pas
    // encore active, la fenêtre pas encore clé, et la barre d'état vaut zéro.
    // La première réponse est donc souvent vide — on redemande une fois la
    // fenêtre posée, et c'est celle-là qui compte.
    await refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  /// Débranche le service. Réservé aux tests.
  @visibleForTesting
  static void detach() {
    final observer = _observer;
    if (observer == null) return;
    WidgetsBinding.instance.removeObserver(observer);
    _observer = null;
    regions.value = const WindowRegions();
    lastAnswer.value = 'pas encore demandé';
  }

  /// Redemande au système. Un échec laisse la dernière réponse en place.
  static Future<void> refresh() async {
    if (!isSupported) return;
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('read');
      if (raw == null) {
        lastAnswer.value = 'le canal a répondu sans rien';
        return;
      }
      // Les régions d'abord, la réponse ensuite, et l'ordre compte : un
      // `ValueNotifier` prévient ses auditeurs sur-le-champ, et la sonde —
      // qui écoute la réponse pour écrire son relevé — lisait des régions
      // encore vides. Une seule réponse suffisant à l'appareil, elle ne
      // repassait jamais.
      final lues = parse(raw);
      regions.value = lues;
      // Rendu à clés triées, et non `raw.toString()` : le canal rend une
      // carte dont l'ordre change d'un appel à l'autre, et la sonde croyait
      // à quatre fenêtres différentes là où il n'y en avait qu'une.
      //
      // Et une réponse pleine dont rien n'est retenu le dit : c'est la seule
      // façon de distinguer un natif qui se tait d'un natif qu'on écarte. Le
      // canal a déjà oublié d'envoyer les cotes de la vue une fois, et rien
      // dans le relevé ne le criait.
      final rendu = _rendu(raw);
      lastAnswer.value = lues.isEmpty ? '$rendu — rien retenu' : rendu;
    } on PlatformException catch (e) {
      lastAnswer.value = 'le canal a refusé : ${e.message}';
    } on MissingPluginException {
      // Le canal n'est pas là — un binaire construit sans lui. On garde les
      // mesures, et on le dit plutôt que de laisser croire à un SDK trop vieux.
      lastAnswer.value = 'canal absent du binaire — à reconstruire';
    }
  }

  /// Ce que la réponse du natif veut dire, en points.
  ///
  /// Les bornes ne sont pas de la méfiance gratuite : le cadre de la barre
  /// d'état est le seul des trois dont on ne sache pas encore ce qu'il vaut
  /// quand elle passe debout. Une valeur hors de ces bornes est écartée, et
  /// l'appelant garde sa mesure plutôt que de poser son menu n'importe où.
  @visibleForTesting
  static WindowRegions parse(Map<String, Object?> raw) {
    if (raw['available'] != true) return const WindowRegions();
    final largeur = (raw['width'] as num?)?.toDouble();
    final hauteur = (raw['height'] as num?)?.toDouble();
    if (largeur == null || hauteur == null || largeur <= 0 || hauteur <= 0) return const WindowRegions();

    final occlusions = _rects(raw['occlusions']);
    final divisions = _rects(raw['divisions']);
    final barre = _rect(raw['statusBar']);

    // Ce qui **borne** la pile, c'est la bande du système : la région qui
    // part du bord haut et descend. Sur l'iPhone Duo fermé, iOS l'annonce
    // large de 84 points — la marge sûre de ce côté — et haute de 170.
    //
    // Une caméra, elle, flotte dedans : elle est le haut de la pile, jamais
    // son bas, et prise seule elle placerait le menu au-dessus de l'heure.
    // D'où la condition sur le bord haut, et non sur le genre de région.
    //
    // Le cadre de la barre d'état y passe aussi, pour les appareils d'un seul
    // écran. Sur le Duo il ne sert à rien : il rend 466 × 2 points en haut à
    // gauche pendant que l'heure est debout contre le bord droit, et ses deux
    // points de haut le disqualifient ici.
    double? bas;
    for (final r in [?barre, ...occlusions]) {
      if (r.top > 1 || r.height < 20) continue;
      bas = bas == null ? r.bottom : math.max(bas, r.bottom);
    }
    // Une pile de plus d'un tiers de la fenêtre n'est pas une pile.
    if (bas != null && bas > hauteur / 3) bas = null;

    // L'axe se lit sur la plus étroite des régions — la caméra —, et non sur
    // la bande : les glyphes ne sont pas centrés dedans. Sur le Duo fermé, la
    // caméra donne 47,8 points depuis le bord droit là où la bande en donne
    // 42, et ce sont bien les 47,7 mesurés au pixel sur une capture.
    Rect? repere;
    for (final r in occlusions) {
      if (repere == null || r.width < repere.width) repere = r;
    }
    repere ??= barre;
    double? axe;
    if (repere != null) {
      final depuisLeBord = largeur - repere.center.dx;
      // Au-delà, ce n'est plus une colonne de bord : la barre d'état est
      // sans doute couchée, et son milieu au milieu de l'écran.
      if (depuisLeBord > 16 && depuisLeBord < largeur / 4) axe = depuisLeBord;
    }

    return WindowRegions(
      systemStackBottom: bas,
      systemAxisFromRight: axe,
      fold: divisions.isEmpty || divisions.first.isEmpty ? null : divisions.first,
    );
  }

  /// La réponse du natif, à clés triées : un texte stable pour la sonde.
  static String _rendu(Object? v) {
    if (v is Map) {
      final cles = v.keys.map((k) => '$k').toList()..sort();
      return '{${cles.map((k) => '$k: ${_rendu(v[k])}').join(', ')}}';
    }
    if (v is List) return '[${v.map(_rendu).join(', ')}]';
    return '$v';
  }

  static List<Rect> _rects(Object? raw) {
    if (raw is! List) return const <Rect>[];
    return raw.map(_rect).whereType<Rect>().toList(growable: false);
  }

  static Rect? _rect(Object? raw) {
    if (raw is! Map) return null;
    final x = (raw['x'] as num?)?.toDouble();
    final y = (raw['y'] as num?)?.toDouble();
    final w = (raw['width'] as num?)?.toDouble();
    final h = (raw['height'] as num?)?.toDouble();
    if (x == null || y == null || w == null || h == null) return null;
    return Rect.fromLTWH(x, y, w, h);
  }
}

class _RegionsObserver with WidgetsBindingObserver {
  /// Le pli, la rotation, l'ouverture : tout ce qui change la fenêtre peut
  /// déplacer ce que le système y réserve.
  @override
  void didChangeMetrics() {
    WindowRegionsService.refresh();
  }
}
