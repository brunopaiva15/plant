import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/native_shell.dart';
import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'adaptive.dart';
import 'brand.dart';
import 'buttons.dart';
import 'collapsed_title.dart';
import 'native_actions.dart';
import 'rail_actions.dart';
import 'scroll_fade.dart';
import 'tab_bar.dart';

/// La physique de défilement de toutes les pages : le rebond d'iOS, et rien
/// d'autre.
///
/// Surtout pas `AlwaysScrollableScrollPhysics` : elle accepte le geste même
/// quand le contenu tient à l'écran, et une page vide se laissait alors
/// pousser, grand titre replié dans la barre comme s'il y avait quelque
/// chose dessous. Sur iOS, une page qui tient ne bouge pas. La règle par
/// défaut de Flutter fait exactement cela ; il suffisait de ne pas la
/// contourner. Elle n'aurait de raison d'être qu'avec un « tirer pour
/// rafraîchir », que l'application n'a pas.
const ScrollPhysics floraScrollPhysics = BouncingScrollPhysics();

/// Marge qui recentre le contenu quand l'écran dépasse une colonne de lecture.
///
/// Depuis qu'iPadOS fait tourner et cohabiter les applications, une fiche peut
/// s'ouvrir sur mille points de large : une ligne de texte y traverse l'écran
/// et devient pénible à suivre. Au-delà de [maxWidth], on rend le surplus en
/// marges plutôt qu'en longueur de ligne.
///
/// Sur téléphone, la fonction rend zéro et rien ne bouge.
double readableInset(BuildContext context, {double maxWidth = 700}) {
  final width = MediaQuery.sizeOf(context).width;
  return width <= maxWidth ? 0 : (width - maxWidth) / 2;
}

/// Ce que le système réserve sur les côtés, à ajouter à toute marge de page.
///
/// Sur un pliable, la bande de la caméra et de l'heure occupe un bord entier
/// — quatre-vingt-quatre points sur l'iPhone Duo — et change de côté avec la
/// rotation. Une page qui pose sa marge à la main passe donc dessous, et
/// c'est arrivé partout où on l'a oublié : les pages secondaires, la fiche
/// d'une plante, les feuilles.
///
/// D'où cette fonction plutôt qu'un `MediaQuery.paddingOf` recopié : un seul
/// endroit à corriger, et un nom qui dit à quoi elle sert quand on lit une
/// page. Elle s'ajoute aux marges de lecture, elle ne les remplace pas.
EdgeInsets systemSideInsets(BuildContext context) {
  final marges = MediaQuery.paddingOf(context);
  return EdgeInsets.only(left: marges.left, right: marges.right);
}

/// Un état vide posé au milieu de ce que l'œil voit : entre le bas de
/// l'en-tête et le haut de la barre d'onglets.
///
/// `SliverFillRemaining` seul centre dans tout ce qui reste du viewport — or
/// le contenu passe sous la barre flottante, et le Scaffold signale cette
/// bande dans le padding bas du MediaQuery. On la retire du calcul, sans
/// quoi le bloc tombe trop bas, comme aimanté par la barre.
class SliverCentered extends StatelessWidget {
  const SliverCentered({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Center(child: child),
      ),
    );
  }
}

/// Le bouton de retour d'une page à grand titre, quand il y a où revenir.
///
/// Les quatre onglets sont des racines : rien à dépiler, et la barre reste
/// nue. Mais le même gabarit sert aussi à des pages poussées — « Anciennes
/// plantes », ouverte depuis les réglages —, qui n'offraient alors aucun
/// retour visible : seuls le glissement d'iOS et le geste système d'Android
/// ramenaient en arrière. Le bouton apparaît donc de lui-même là où la pile
/// le permet, sans que la page ait à y penser.
///
/// Le libellé vient des localisations de Flutter — « Retour », « Back »,
/// « Zurück », « Indietro » —, comme pour le retour natif de [FloraPage] : le
/// design system ne lit pas les ARB, ses textes lui sont passés.
Widget? _impliedBackButton(BuildContext context) {
  if (ModalRoute.of(context)?.canPop ?? false) {
    return FloraIconButton(
      icon: isCupertino(context) ? CupertinoIcons.chevron_left : Icons.arrow_back_rounded,
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
  return _fermetureDeFeuille(context);
}

/// La croix qui referme la feuille, pour la page posée à sa racine.
///
/// Cette page-là n'a rien à dépiler — mais la feuille, si. Sans ce bouton,
/// « Où la poser » ne se refermait qu'au glissement : pas de retour, puisqu'il
/// n'y a rien derrière, et pas de croix, puisque personne ne l'avait posée.
/// `null` partout ailleurs, pour que le retour d'iOS reste celui d'iOS.
Widget? _fermetureDeFeuille(BuildContext context) {
  if (ModalRoute.of(context)?.canPop ?? false) return null;
  if (!_dansUneFeuille(context)) return null;
  return FloraIconButton(
    icon: CupertinoIcons.xmark,
    semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip,
    onPressed: () => CupertinoSheetRoute.popSheet(context),
  );
}

/// La page est-elle posée dans une feuille d'iOS ?
///
/// **Ce qui en dépend : à qui va la barre.** Les boutons d'une page partent à
/// UIKit, qui les dessine dans la barre de son contrôleur de navigation. Mais
/// cette barre est celle de la coquille, et une feuille de Flutter passe
/// par-dessus la coquille — l'observateur l'efface au moment de la poussée,
/// et la page qui s'ouvre dedans ne peut pas la reprendre : elle vit dans le
/// navigateur de la feuille, pas dans celui de la racine.
///
/// La page cédait quand même, et se retrouvait sans rien : ni titre, ni
/// retour, ni croix — « Où la poser » s'ouvrait sur son contenu nu. Dans une
/// feuille, elle garde donc sa barre, comme là où le natif n'est pas.
bool _dansUneFeuille(BuildContext context) => CupertinoSheetRoute.hasParentSheet(context);

/// Page à grand titre (onglets) : CupertinoSliverNavigationBar natif sur iOS,
/// SliverAppBar.large sur Android. Le contenu est une liste de slivers.
class LargeTitlePage extends StatelessWidget {
  const LargeTitlePage({
    super.key,
    required this.title,
    required this.slivers,
    this.collapsedTitle,
    this.trailing,
    this.leading,
    this.actions,
    this.searchField,
    this.controller,
    this.bottomPadding = 132,
    this.brand = false,
    this.hero,
  });

  final String title;

  /// La page s'ouvre sur la tête verte : le grand titre en blanc sur le vert
  /// de l'icône, puis [hero], puis la feuille crème qui remonte dessus.
  ///
  /// La barre du système reste celle d'iOS ; elle se fait transparente tant
  /// que le vert est dessous, et reprend son flou ordinaire une fois qu'il est
  /// passé. Voir `NativeShell.publishActions`.
  final bool brand;

  /// Ce que la tête verte montre sous le titre : un grand chiffre, des
  /// pastilles. Ignoré sans [brand].
  final Widget? hero;

  /// Le titre qui reste dans la barre quand le grand titre est parti.
  ///
  /// Par défaut c'est le grand titre lui-même qui s'y replie, et c'est ce
  /// qu'on veut d'un titre qui est un nom — « Jardin », « Profil ». L'écran
  /// du matin, lui, salue la personne : une fois replié, « Bonsoir Paul »
  /// n'est plus un repère, il ne dit pas où l'on est. Il passe donc le nom
  /// de l'application, qui le dit.
  final String? collapsedTitle;

  final List<Widget> slivers;
  final Widget? trailing;
  final Widget? leading;

  /// Plusieurs boutons à droite du titre, plutôt qu'un seul [trailing].
  ///
  /// C'est une liste et non une `Row` toute faite parce qu'elle se range
  /// aussi bien debout : quand le menu passe sur le bord droit, ces
  /// boutons-là le rejoignent, en colonne (voir [RailActions]).
  final List<Widget>? actions;

  final Widget? searchField;
  final ScrollController? controller;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    // Le titre replié a besoin d'un porteur qui survive aux reconstructions :
    // c'est lui qui monte dans la barre du système quand le grand titre s'en
    // va. Inutile là où la barre est celle de Flutter.
    if (!NativeShell.isSupported && !brand) return _construire(context, null, null);
    return _AvecTitreReplie(
      brand: brand,
      builder: (context, replie, marque) => _construire(context, NativeShell.isSupported ? replie : null, brand ? marque : null),
    );
  }

  Widget _construire(BuildContext context, ValueNotifier<String>? replie, ValueNotifier<bool>? marque) {
    final c = context.colors;

    // Quand le menu est debout à droite, les boutons du haut de page le
    // rejoignent : ils sont déjà en colonne là-bas, et le haut de page n'a
    // plus à porter deux choses. Le retour, lui, reste en haut : c'est un
    // geste de navigation, pas une commande de la page.
    //
    // Sauf là où le menu est passé au natif : il n'y a plus de colonne en
    // argile pour les recevoir, et les céder les ferait disparaître. La page
    // les garde donc jusqu'à ce que la chrome native sache les porter.
    final relais = RailActionsScope.maybeOf(context);
    final debout = relais != null && !NativeShell.isSupported && FloraTabRail.fitsIn(context);
    final boutons = <Widget>[
      ?leading,
      if (actions != null) ...actions! else ?trailing,
    ];

    // Ce que le système réserve sur les bords, et la colonne de lecture d'une
    // fenêtre large. Le contenu s'y tient ; la barre, elle, garde toute la
    // largeur, comme sur iOS.
    final marges = MediaQuery.paddingOf(context);
    final inset = readableInset(context);
    final gauche = inset + marges.left;
    final droite = inset + marges.right;

    // Le champ de recherche vit dans cette barre, et n'est donc pas couvert
    // par la marge des contenus : il lui faut la sienne. Sans elle, il
    // passait sous la bande verticale de l'iPhone Duo.
    final margeChamp = EdgeInsets.fromLTRB(
      math.max(Space.md, gauche),
      0,
      math.max(Space.md, droite),
      Space.xs,
    );

    // Sur iOS, ces mêmes boutons partent à UIKit : la barre de navigation
    // native les dessine en SF Symbols, et c'est elle qu'iOS range dans la
    // bande verticale de l'iPhone Duo. `describe` rend `null` si un bouton
    // lui échappe, et la page garde alors les siens.
    final aCeder = <Widget>[if (actions != null) ...actions! else ?trailing];
    // Le retour et le bouton de tête partent avec le reste — le tableau de
    // bord d'« Aujourd'hui », le chevron d'une fiche. Le retour est déjà un
    // `FloraIconButton` à chevron : il se décrit comme les autres, et le
    // geste de balayage reste celui de Flutter.
    final teteCedable = <Widget>[?_impliedBackButton(context), ?leading];
    final natif = NativeShell.isSupported && !debout && !_dansUneFeuille(context)
        ? NativeActions.describe(teteCedable, aCeder)
        : null;

    final Widget? lead = natif != null
        ? null
        : (debout ? _impliedBackButton(context) : (leading ?? _impliedBackButton(context)));
    final Widget? suite = debout || natif != null ? null : _headerActions();
    // Deux barres se superposaient : celle du système portait les boutons, et
    // celle de Flutter dessinait le titre une rangée plus bas. Là où UIKit
    // tient la barre, le grand titre devient donc du contenu, et c'est le
    // système qui porte le titre replié — sur la ligne des boutons.
    final aTitreNatif = natif != null && replie != null && isCupertino(context);
    final Widget header;
    if (marque != null) {
      header = _TeteDeMarque(
        title: title,
        hero: hero,
        gauche: gauche,
        droite: droite,
        searchField: searchField,
        // Là où le système ne tient pas la barre, les boutons restent dans la
        // tête verte, sur la ligne du haut.
        leading: natif == null ? lead : null,
        trailing: natif == null ? suite : null,
      );
    } else if (aTitreNatif) {
      header = _GrandTitreNatif(
        title: title,
        replie: replie,
        gauche: gauche,
        droite: droite,
        searchField: searchField,
      );
    } else if (isCupertino(context)) {
      header = CupertinoSliverNavigationBar(
        largeTitle: Text(title),
        middle: collapsedTitle == null ? null : _CollapsedTitle(text: collapsedTitle!),
        // Sans cela le gabarit natif tient le `middle` allumé en permanence :
        // le petit titre se lirait au-dessus du grand. À faux, il ne le
        // montre qu'une fois le grand titre parti, et les deux se croisent
        // dans le même fondu. Sans titre replié, on lui rend sa valeur par
        // défaut : c'est le grand titre qui occupe la case, et il doit s'y
        // replier comme avant.
        alwaysShowMiddle: collapsedTitle == null,
        leading: lead,
        trailing: suite,
        backgroundColor: c.canvas.withValues(alpha: 0.82),
        border: null,
        stretch: true,
        automaticallyImplyLeading: false,
        // Plusieurs barres coexistent dans le shell à onglets : pas de Hero partagé.
        transitionBetweenRoutes: false,
        heroTag: 'large-title-$title',
        bottom: searchField == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(padding: margeChamp, child: searchField),
              ),
      );
    } else {
      header = SliverAppBar.large(
        title: collapsedTitle == null ? Text(title) : _SwappedTitle(large: title, collapsed: collapsedTitle!),
        leading: lead,
        automaticallyImplyLeading: false,
        actions: suite == null ? null : [Padding(padding: const EdgeInsets.only(right: Space.xs), child: suite)],
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: context.text.display.copyWith(fontSize: 30),
        bottom: searchField == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(padding: margeChamp, child: searchField),
              ),
      );
    }
    // La barre garde toute la largeur — c'est ce que fait iOS —, seul le
    // contenu se recentre. Sur téléphone l'encart vaut zéro et la liste de
    // slivers reste exactement celle d'avant.
    // Ce que le système réserve sur les côtés s'ajoute à la colonne de
    // lecture. Sur un pliable, la bande de la caméra passe sur un bord — 84
    // points mesurés — et rien ne dit qu'elle soit symétrique : sans ça, une
    // liste ou un sélecteur de section court dessous. La barre de navigation,
    // elle, se protège déjà toute seule (`SafeArea` de Cupertino).
    final Widget liste = CustomScrollView(
          controller: controller,
        // Sans contrôleur à elle, la page s'attache à celui de son onglet
        // (`app/tab_scroll.dart`) — dit explicitement, et non laissé à
        // l'heuristique de plateforme de `PrimaryScrollController` : c'est ce
        // qui fait marcher le retour au sommet et le tap sur la barre d'état.
        // La physique reste la nôtre, `primary` ne la remplace que si on n'en
        // passe aucune.
          primary: controller == null ? true : null,
          physics: floraScrollPhysics,
          slivers: [
            header,
            if (marque != null) SliverToBoxAdapter(child: _BordDeFeuille(notifier: marque)),
            if (aTitreNatif)
              SliverToBoxAdapter(
                child: CollapsedTitleWatcher(
                  notifier: replie,
                  title: collapsedTitle ?? title,
                  threshold: CollapsedTitleWatcher.largeTitleCollapse,
                ),
              ),
            if (gauche == 0 && droite == 0)
              ...slivers
            else
              SliverPadding(
                padding: EdgeInsets.only(left: gauche, right: droite),
                sliver: SliverMainAxisGroup(slivers: slivers),
              ),
            SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
          ],
        );
    final coquille = RailActions(
      actions: debout ? boutons : const <Widget>[],
      child: Scaffold(
        backgroundColor: c.canvas,
        body: marque == null ? liste : _FondDeMarque(notifier: marque, child: liste),
      ),
    );

    // Le natif ne dessine que si tous les boutons lui parlent.
    if (natif == null) return coquille;
    return NativeActions(
      title: '',
      titleListenable: aTitreNatif ? replie : null,
      brandListenable: marque,
      leading: natif.leading,
      actions: natif.actions,
      child: coquille,
    );
  }

  /// Les boutons tels que le haut de page les porte : en rangée, séparés.
  /// Rendus nuls quand la page n'en a aucun, pour que la barre reste nue.
  Widget? _headerActions() {
    if (actions == null) return trailing;
    if (actions!.isEmpty) return null;
    if (actions!.length == 1) return actions!.single;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, action) in actions!.indexed) ...[
          if (i > 0) const SizedBox(width: Space.xs),
          action,
        ],
      ],
    );
  }
}

/// Le titre replié, sur iOS.
///
/// Le fondu est celui du gabarit natif : il croise exactement la disparition
/// du grand titre, à la même image et sur la même durée. S'y ajoute une
/// montée de quelques pixels, tirée du défilement lui-même : le mot arrive
/// d'en bas, poussé par le titre qui s'en va, au lieu de se poser d'un coup
/// au milieu de la barre.
///
/// La course est celle du repli — les 52 points que le gabarit donne au grand
/// titre —, dont on prend la seconde moitié : la montée se termine quand la
/// barre est repliée, et n'a pas commencé tant qu'on n'a pas vraiment quitté
/// le haut de la liste. Un point de défilement en trop ou en moins ne coûte
/// que quelques pixels de retard ; le fondu, lui, reste calé par le gabarit.
class _CollapsedTitle extends StatefulWidget {
  const _CollapsedTitle({required this.text});

  final String text;

  @override
  State<_CollapsedTitle> createState() => _CollapsedTitleState();
}

class _CollapsedTitleState extends State<_CollapsedTitle> {
  /// Le repli du grand titre, en points de défilement. Celui du guetteur qui
  /// sert la barre du système, pour que les deux chemins basculent ensemble.
  static const double _collapse = CollapsedTitleWatcher.largeTitleCollapse;

  /// De combien le mot monte pour se poser, et d'où il part.
  static const double _rise = 7;
  static const double _start = _collapse / 2;

  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position = Scrollable.maybeOf(context)?.position;
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(widget.text);
    final position = _position;
    // Sans liste sous la barre, ou quand la personne a demandé moins
    // d'animations, il ne reste que le fondu du gabarit.
    if (position == null || MediaQuery.disableAnimationsOf(context)) return text;
    return AnimatedBuilder(
      animation: position,
      builder: (context, child) {
        final pixels = position.hasPixels ? position.pixels : 0.0;
        final t = Motion.easeOut.transform(((pixels - _start) / (_collapse - _start)).clamp(0.0, 1.0));
        return Transform.translate(offset: Offset(0, (1 - t) * _rise), child: child);
      },
      child: text,
    );
  }
}

/// Le titre replié, sur Android.
///
/// Le gabarit Material n'a qu'une case pour les deux titres : il rend le même
/// widget à deux endroits — en grand dans l'en-tête déployé, en petit dans la
/// barre, où il le fait paraître en fondu une fois l'en-tête **entièrement**
/// replié. Le texte change donc à cet instant-là et pas avant : le grand
/// titre est alors rogné à zéro, la bascule ne se voit nulle part, et c'est
/// le fondu du gabarit qui l'anime.
///
/// L'instant est celui que le gabarit retient lui aussi : la course entre
/// l'en-tête déployé (152) et la barre seule (64), la marge d'état se
/// simplifiant des deux côtés.
class _SwappedTitle extends StatefulWidget {
  const _SwappedTitle({required this.large, required this.collapsed});

  final String large;
  final String collapsed;

  @override
  State<_SwappedTitle> createState() => _SwappedTitleState();
}

class _SwappedTitleState extends State<_SwappedTitle> {
  static const double _collapse = 152.0 - 64.0;

  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position = Scrollable.maybeOf(context)?.position;
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    if (position == null) return Text(widget.large);
    return AnimatedBuilder(
      animation: position,
      builder: (context, child) {
        final pixels = position.hasPixels ? position.pixels : 0.0;
        return Text(pixels >= _collapse ? widget.collapsed : widget.large);
      },
    );
  }
}

/// Page secondaire (push) à titre centré, avec retour natif.
class FloraPage extends StatelessWidget {
  const FloraPage({super.key, required this.title, required this.child, this.trailing, this.scrollable = true, this.bottom, this.bleed = false});

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool scrollable;
  final Widget? bottom;

  /// Sans marge latérale : le contenu touche les deux bords de l'écran. Pour
  /// les pages qui posent un objet pleine largeur — la fiche d'entretien et
  /// sa feuille — et non du texte courant, qui a besoin d'air.
  final bool bleed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // La marge de lecture seule : ce que le système réserve sur les bords est
    // déjà retiré par le `SafeArea` du corps, et l'ajouter ici le compterait
    // deux fois — mesuré à 188 points au lieu de 104 sur un pliable.
    final side = bleed ? 0.0 : Space.page + readableInset(context);
    Widget body(double topInset) {
      if (!scrollable) return Padding(padding: EdgeInsets.only(top: topInset), child: child);
      final scroller = SingleChildScrollView(
        physics: floraScrollPhysics,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(side, topInset + Space.md, side, Space.huge),
        child: child,
      );
      // Une barre du bas ferme la page : sans fondu, la dernière ligne visible
      // s'arrête net sur elle et la page a l'air finie, même quand la moitié
      // du formulaire attend dessous.
      return bottom == null ? scroller : ScrollFade(child: scroller);
    }
    if (isCupertino(context)) {
      // Sur iOS, la barre est celle d'UIKit : le titre au milieu, le retour à
      // gauche, l'action à droite. C'est le même titre centré qu'avant, à
      // ceci près que le système le dessine — et qu'il sait le ranger dans la
      // bande verticale de l'iPhone Duo, ce qu'une barre à nous ne peut pas.
      //
      // `describe` rend `null` dès qu'un bouton lui échappe — une action en
      // toutes lettres, par exemple —, et la page garde alors sa barre.
      final natif = NativeShell.isSupported && !_dansUneFeuille(context)
          ? NativeActions.describe(<Widget>[?_impliedBackButton(context)], <Widget>[?trailing])
          : null;
      // Sans barre à nous, le décalage du haut vient de la marge sûre, que le
      // contrôleur de navigation d'UIKit a déjà augmentée de sa hauteur.
      final corps = Builder(
        builder: (ctx) => SafeArea(
          top: false,
          bottom: false,
          child: Column(children: [Expanded(child: body(MediaQuery.paddingOf(ctx).top)), ?bottom]),
        ),
      );
      if (natif != null) {
        return NativeActions(
          title: title,
          leading: natif.leading,
          actions: natif.actions,
          child: CupertinoPageScaffold(backgroundColor: c.canvas, child: corps),
        );
      }
      return CupertinoPageScaffold(
        backgroundColor: c.canvas,
        navigationBar: CupertinoNavigationBar(
          // `null` hors d'une feuille : le retour automatique d'iOS reprend
          // alors sa place, avec le titre de la page d'avant.
          leading: _fermetureDeFeuille(context),
          middle: Text(title),
          trailing: trailing,
          backgroundColor: c.canvas.withValues(alpha: 0.82),
          border: null,
          transitionBetweenRoutes: false,
          heroTag: 'page-$title',
        ),
        // La barre est translucide : le contenu défile dessous, décalé de sa hauteur.
        child: corps,
      );
    }
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: Text(title), actions: trailing == null ? null : [trailing!]),
      body: Column(children: [Expanded(child: body(0)), ?bottom]),
    );
  }
}

/// Le grand titre d'une page dont la barre est celle d'UIKit.
///
/// Sans lui, deux barres se superposaient : celle du système portait les
/// boutons, et celle de Flutter dessinait le titre une rangée plus bas. Le
/// titre replié descendait donc d'une hauteur de barre, ce qu'aucune
/// application native ne fait.
///
/// Le grand titre devient du contenu, en tête des slivers, et c'est le
/// système qui porte le titre replié — sur la même ligne que les boutons,
/// comme partout ailleurs sur iOS.
class _GrandTitreNatif extends StatelessWidget {
  const _GrandTitreNatif({
    required this.title,
    required this.replie,
    required this.gauche,
    required this.droite,
    required this.searchField,
  });

  final String title;
  final ValueNotifier<String> replie;
  final double gauche;
  final double droite;
  final Widget? searchField;

  @override
  Widget build(BuildContext context) {
    final marge = EdgeInsets.fromLTRB(math.max(Space.md, gauche), 0, math.max(Space.md, droite), 0);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Space.xs, bottom: Space.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: marge,
              child: Text(title, style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle),
            ),
            if (searchField != null)
              Padding(padding: marge.add(const EdgeInsets.only(top: Space.sm)), child: searchField),
          ],
        ),
      ),
    );
  }
}

/// Porte le titre replié d'une page, et le fait vivre aussi longtemps qu'elle.
class _AvecTitreReplie extends StatefulWidget {
  const _AvecTitreReplie({required this.builder, this.brand = false});

  final Widget Function(BuildContext, ValueNotifier<String>, ValueNotifier<bool>) builder;

  /// La page s'ouvre sur la tête verte : la barre part au ton de la marque.
  final bool brand;

  @override
  State<_AvecTitreReplie> createState() => _AvecTitreReplieState();
}

class _AvecTitreReplieState extends State<_AvecTitreReplie> {
  final ValueNotifier<String> _replie = ValueNotifier<String>('');

  /// Vrai tant que la tête verte est sous la barre.
  late final ValueNotifier<bool> _marque = ValueNotifier<bool>(widget.brand);

  @override
  void dispose() {
    _replie.dispose();
    _marque.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _replie, _marque);
}

/// La tête verte d'une page à grand titre : la marge du haut, le titre en
/// blanc, le champ de recherche s'il y en a un, puis [hero].
///
/// Le haut de la tête passe sous la barre du système, transparente à cet
/// endroit : le vert monte jusqu'au bord de l'écran, l'heure comprise.
class _TeteDeMarque extends StatelessWidget {
  const _TeteDeMarque({
    required this.title,
    required this.hero,
    required this.gauche,
    required this.droite,
    required this.searchField,
    required this.leading,
    required this.trailing,
  });

  final String title;
  final Widget? hero;
  final double gauche;
  final double droite;
  final Widget? searchField;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final marge = EdgeInsets.fromLTRB(math.max(Space.page, gauche), 0, math.max(Space.page, droite), 0);
    final boutons = leading != null || trailing != null;
    return SliverToBoxAdapter(
      child: BrandHeader(
        underlap: 0,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Space.xs, bottom: Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (boutons)
              Padding(
                padding: marge.add(const EdgeInsets.only(bottom: Space.sm)),
                child: Row(children: [?leading, const Spacer(), ?trailing]),
              ),
            Padding(
              padding: marge,
              child: Semantics(
                header: true,
                child: Text(title, style: context.text.display.copyWith(color: c.onBrand, fontSize: 40, height: 1.05)),
              ),
            ),
            if (searchField != null) Padding(padding: marge.add(const EdgeInsets.only(top: Space.sm)), child: searchField),
            if (hero != null) Padding(padding: marge.add(const EdgeInsets.only(top: Space.md)), child: hero),
          ],
        ),
      ),
    );
  }
}

/// Le bord arrondi de la feuille crème, posé sur le vert — et le guetteur
/// qui dit quand le vert a fini de passer sous la barre.
///
/// C'est son propre bord haut qui compte : tant qu'il est plus bas que la
/// barre, il reste du vert dessous, et la barre garde le ton de la marque.
/// Une mesure sur l'écran plutôt qu'un seuil de défilement : la hauteur de la
/// tête dépend de ce qu'elle porte, du texte agrandi, d'un champ de recherche.
class _BordDeFeuille extends StatefulWidget {
  const _BordDeFeuille({required this.notifier});

  final ValueNotifier<bool> notifier;

  @override
  State<_BordDeFeuille> createState() => _BordDeFeuilleState();
}

class _BordDeFeuilleState extends State<_BordDeFeuille> {
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _position)) return;
    _position?.removeListener(_relire);
    _position = position;
    _position?.addListener(_relire);
    WidgetsBinding.instance.addPostFrameCallback((_) => _mesurer());
  }

  @override
  void dispose() {
    _position?.removeListener(_relire);
    super.dispose();
  }

  /// Où tombe le bord haut, défilement compris : sa place dans la liste.
  /// Relevée après chaque image, parce qu'au moment où la position change la
  /// liste n'a pas encore été remise en page — l'écran dirait encore où le
  /// bord *était*.
  double? _origine;

  void _mesurer() {
    if (!mounted) return;
    final boite = context.findRenderObject();
    final position = _position;
    if (boite is! RenderBox || !boite.hasSize || !boite.attached || position == null || !position.hasPixels) return;
    _origine = boite.localToGlobal(Offset.zero).dy + position.pixels;
    _relire();
  }

  void _relire() {
    final origine = _origine;
    final position = _position;
    if (!mounted || origine == null || position == null || !position.hasPixels) return;
    final haut = origine - position.pixels;
    // La barre s'arrête là où commence la marge sûre du contenu.
    final barre = MediaQuery.paddingOf(context).top;
    final dessous = haut > barre;
    if (widget.notifier.value != dessous) widget.notifier.value = dessous;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // La tête a pu changer de hauteur — du texte agrandi, une pastille de
    // plus : le bord se relève après l'image.
    WidgetsBinding.instance.addPostFrameCallback((_) => _mesurer());
    return ColoredBox(
      color: c.brand,
      child: Container(
        height: Radii.xl,
        decoration: BoxDecoration(color: c.canvas, borderRadius: Radii.sheetTop),
      ),
    );
  }
}

/// Le fond d'une page à tête verte : du vert au-dessus de la liste quand on
/// la tire vers le bas — le rebond d'iOS ne doit pas découvrir de crème au-
/// dessus du titre —, et l'heure en blanc tant que le vert est dessous.
class _FondDeMarque extends StatefulWidget {
  const _FondDeMarque({required this.notifier, required this.child});

  final ValueNotifier<bool> notifier;
  final Widget child;

  @override
  State<_FondDeMarque> createState() => _FondDeMarqueState();
}

class _FondDeMarqueState extends State<_FondDeMarque> {
  final ValueNotifier<double> _tire = ValueNotifier<double>(0);

  @override
  void dispose() {
    _tire.dispose();
    super.dispose();
  }

  bool _lire(ScrollNotification n) {
    if (n.depth == 0) _tire.value = math.max(0, -n.metrics.pixels);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder<bool>(
      valueListenable: widget.notifier,
      builder: (context, marque, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: marque || c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: child!,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _tire,
              builder: (context, tire, _) => SizedBox(height: tire + 1, child: ColoredBox(color: c.brand)),
            ),
          ),
          NotificationListener<ScrollNotification>(onNotification: _lire, child: widget.child),
        ],
      ),
    );
  }
}
