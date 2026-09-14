import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';
import 'adaptive.dart';
import 'buttons.dart';


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
  if (!(ModalRoute.of(context)?.canPop ?? false)) return null;
  return FloraIconButton(
    icon: isCupertino(context) ? CupertinoIcons.chevron_left : Icons.arrow_back_rounded,
    semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

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
    this.searchField,
    this.controller,
    this.bottomPadding = 132,
  });

  final String title;

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
  final Widget? searchField;
  final ScrollController? controller;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lead = leading ?? _impliedBackButton(context);
    final Widget header;
    if (isCupertino(context)) {
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
        trailing: trailing,
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
                child: Padding(padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs), child: searchField),
              ),
      );
    } else {
      header = SliverAppBar.large(
        title: collapsedTitle == null ? Text(title) : _SwappedTitle(large: title, collapsed: collapsedTitle!),
        leading: lead,
        automaticallyImplyLeading: false,
        actions: trailing == null ? null : [Padding(padding: const EdgeInsets.only(right: Space.xs), child: trailing)],
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: context.text.display.copyWith(fontSize: 30),
        bottom: searchField == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs), child: searchField),
              ),
      );
    }
    // La barre garde toute la largeur — c'est ce que fait iOS —, seul le
    // contenu se recentre. Sur téléphone l'encart vaut zéro et la liste de
    // slivers reste exactement celle d'avant.
    final inset = readableInset(context);
    return Scaffold(
      backgroundColor: c.canvas,
      body: CustomScrollView(
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
          if (inset == 0)
            ...slivers
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
          SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
        ],
      ),
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
  /// Le repli du grand titre, en points de défilement.
  static const double _collapse = 52;

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
  const FloraPage({super.key, required this.title, required this.child, this.trailing, this.scrollable = true, this.bottom});

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool scrollable;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final side = Space.page + readableInset(context);
    Widget body(double topInset) => scrollable
        ? SingleChildScrollView(
            physics: floraScrollPhysics,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(side, topInset + Space.md, side, Space.huge),
            child: child,
          )
        : Padding(padding: EdgeInsets.only(top: topInset), child: child);
    if (isCupertino(context)) {
      return CupertinoPageScaffold(
        backgroundColor: c.canvas,
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          trailing: trailing,
          backgroundColor: c.canvas.withValues(alpha: 0.82),
          border: null,
          transitionBetweenRoutes: false,
          heroTag: 'page-$title',
        ),
        // La barre est translucide : le contenu défile dessous, décalé de sa hauteur.
        child: Builder(
          builder: (ctx) => SafeArea(
            top: false,
            bottom: false,
            child: Column(children: [Expanded(child: body(MediaQuery.paddingOf(ctx).top)), ?bottom]),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: Text(title), actions: trailing == null ? null : [trailing!]),
      body: Column(children: [Expanded(child: body(0)), ?bottom]),
    );
  }
}
