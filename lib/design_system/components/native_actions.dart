import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../core/native_shell.dart';
import '../../core/sf_symbols.dart';
import 'buttons.dart';

/// Les boutons d'une page, dessinés par UIKit plutôt que par Flutter.
///
/// La page ne change rien à sa façon de les déclarer : elle donne toujours des
/// [FloraIconButton] à `LargeTitlePage`. C'est ici qu'ils sont traduits en
/// `UIBarButtonItem` — l'icône par [SfSymbols], le libellé par
/// `semanticLabel`, et l'action par un identifiant que le natif renvoie.
///
/// Tout ou rien : si une seule icône manque à la table, la page garde ses
/// boutons en argile. Une rangée moitié système moitié argile serait pire que
/// l'une ou l'autre, et le nom manquant s'écrit dans la console en debug.
class NativeActions extends StatefulWidget {
  const NativeActions({
    super.key,
    required this.title,
    required this.leading,
    required this.actions,
    required this.child,
    this.titleListenable,
  });

  final String title;

  /// Un titre qui change en cours de route : celui qui apparaît dans la barre
  /// quand le grand titre d'une page s'en va en défilant. Prend le pas sur
  /// [title] quand il est là.
  final ValueListenable<String>? titleListenable;

  /// Le bouton de tête de la page, s'il en a un : le tableau de bord sur
  /// « Aujourd'hui ». Il va à gauche de la barre, là où iOS met la
  /// navigation.
  final List<NativeActionEntry> leading;

  final List<NativeActionEntry> actions;
  final Widget child;

  /// Ce que le natif saura dessiner, ou `null` si un bouton lui échappe.
  ///
  /// Les deux côtés d'un coup : une page qui céderait sa droite mais garderait
  /// sa gauche mélangerait le système et l'argile dans la même barre.
  static ({List<NativeActionEntry> leading, List<NativeActionEntry> actions})? describe(
    List<Widget> leading,
    List<Widget> actions,
  ) {
    final aGauche = _decrire(leading, 'L');
    final aDroite = _decrire(actions, 'R');
    if (aGauche == null || aDroite == null) return null;
    return (leading: aGauche, actions: aDroite);
  }

  static List<NativeActionEntry>? _decrire(List<Widget> boutons, String prefixe) {
    final decrits = <NativeActionEntry>[];
    for (final (i, bouton) in boutons.indexed) {
      if (bouton is! FloraIconButton) return null;
      final symbole = SfSymbols.of(bouton.icon);
      if (symbole == null) {
        assert(() {
          debugPrint('[auxine:natif] pas de SF Symbol pour ${bouton.semanticLabel} '
              '(0x${bouton.icon.codePoint.toRadixString(16)}) — voir core/sf_symbols.dart');
          return true;
        }());
        return null;
      }
      decrits.add((
        action: NativeAction(
          id: '$prefixe$i',
          symbol: symbole,
          title: bouton.semanticLabel,
          enabled: bouton.onPressed != null,
          // L'ajout est l'action principale d'Auxine, partout où elle est
          // offerte : c'est elle qu'iOS doit garder visible quand la bande
          // déborde, plutôt que de la replier dans le menu.
          prominent: bouton.icon.codePoint == CupertinoIcons.plus.codePoint,
        ),
        onPressed: bouton.onPressed,
      ));
    }
    return decrits;
  }

  @override
  State<NativeActions> createState() => _NativeActionsState();
}

typedef NativeActionEntry = ({NativeAction action, VoidCallback? onPressed});

class _NativeActionsState extends State<NativeActions> {
  /// Les pages qui prétendent à la barre, la dernière étant celle qu'on voit.
  ///
  /// Une page poussée par-dessus une autre prend la barre ; quand elle s'en
  /// va, celle qu'elle recouvrait la reprend sans avoir à se redessiner. Sans
  /// cette pile, une page revenue au premier plan se retrouvait sans boutons
  /// — rien ne la force à se reconstruire quand la page du dessus se ferme.
  static final List<_NativeActionsState> _pile = <_NativeActionsState>[];

  @override
  void initState() {
    super.initState();
    _pile.add(this);
    widget.titleListenable?.addListener(_publier);
    NativeShell.overlay.addListener(_reconsiderer);
  }

  @override
  void didUpdateWidget(NativeActions old) {
    super.didUpdateWidget(old);
    if (old.titleListenable != widget.titleListenable) {
      old.titleListenable?.removeListener(_publier);
      widget.titleListenable?.addListener(_publier);
    }
  }

  @override
  void dispose() {
    NativeShell.overlay.removeListener(_reconsiderer);
    widget.titleListenable?.removeListener(_publier);
    _pile.remove(this);
    _publier();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se promouvoir, mais seulement en étant visible : une page enfouie sous
    // une autre, ou dans une branche d'onglet en sommeil, se reconstruit
    // aussi, et elle volerait la barre à celle qu'on regarde.
    final route = ModalRoute.of(context);
    // `isCurrent` ne vaut que dans le navigateur de la route. Une page de la
    // coquille vit dans celui de son onglet : une feuille poussée sur le
    // navigateur racine la couvre sans que sa branche en sache rien, et elle
    // se croyait encore visible. Elle redemandait alors la barre — que
    // l'observateur venait d'effacer —, et la feuille se retrouvait coiffée
    // des boutons de la page d'en dessous.
    //
    // D'où la seconde condition : une page qui n'est pas posée sur le
    // navigateur racine ne prétend à la barre que si rien ne couvre la
    // coquille. Celles qui y sont posées — une fiche, une page secondaire —
    // y prétendent à tout étage, puisqu'elles sont cet étage.
    final navigateur = Navigator.maybeOf(context);
    final racine = Navigator.maybeOf(context, rootNavigator: true);
    final surLaRacine = navigateur != null && identical(navigateur, racine);
    final visible = TickerMode.valuesOf(context).enabled &&
        (route == null || route.isCurrent) &&
        (surLaRacine || NativeShell.overlayDepth == 0);
    if (visible && (_pile.isEmpty || _pile.last != this)) {
      _pile
        ..remove(this)
        ..add(this);
    }
    // Publié depuis le rendu, et non depuis `initState` : c'est le seul
    // endroit qui voit les boutons à jour quand la page change d'état — un
    // bouton qui s'éteint, une sélection qui en ajoute un. Le service écarte
    // les déclarations identiques, si bien qu'un rendu ordinaire ne traverse
    // pas le canal.
    if (visible) {
      // Une page empilée n'a pas la barre de droit : l'observateur l'a
      // effacée au moment de la poussée, et c'est à elle de la redemander.
      // Celles qui ne savent pas la remplir — un scanner, une feuille — ne
      // passent pas par ici et la laissent effacée.
      NativeShell.requestBar();
      _publier();
    }
    return widget.child;
  }

  /// Rend à la barre ce que montre la page du sommet, ou rien s'il n'y en a
  /// plus. Appelé au rendu et au départ d'une page.
  static void _publier() {
    final actuelle = _pile.isEmpty ? null : _pile.last;
    NativeShell.onAction = actuelle?._toucher;
    NativeShell.publishActions(
      title: actuelle?.widget.titleListenable?.value ?? actuelle?.widget.title ?? '',
      leading: [for (final e in actuelle?.widget.leading ?? const <NativeActionEntry>[]) e.action],
      actions: [for (final e in actuelle?.widget.actions ?? const <NativeActionEntry>[]) e.action],
    );
  }

  /// Ce qui couvre la coquille a changé : la page reconsidère sa prétention
  /// à la barre, qu'elle vienne de la perdre ou de la retrouver.
  void _reconsiderer() {
    if (mounted) setState(() {});
  }

  void _toucher(String id) {
    final liste = id.startsWith('L') ? widget.leading : widget.actions;
    final i = int.tryParse(id.substring(1));
    if (i == null || i < 0 || i >= liste.length) return;
    liste[i].onPressed?.call();
  }
}
