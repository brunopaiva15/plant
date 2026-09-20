import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/window_regions.dart';
import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'clay.dart';
import 'pressable.dart';

class FloraTab {
  const FloraTab({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Barre d'onglets flottante en pilule, avec une bulle qui glisse d'un onglet
/// à l'autre — dans l'esprit des barres iOS récentes.
///
/// La bulle est **une seule pièce** qui se déplace, et non un fond qui
/// s'allume sous chaque onglet à son tour : c'est ce qui relie le départ et
/// l'arrivée, et ce qui permet aux libellés de virer au passage plutôt que de
/// changer de couleur d'un coup. Elle suit [Springs.glide] ; l'icône qui
/// l'accueille se pose au ressort.
class FloraTabBar extends StatelessWidget {
  const FloraTabBar({super.key, required this.tabs, required this.index, required this.onSelect});

  final List<FloraTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  /// Le libellé d'onglet ne suit Dynamic Type que jusqu'ici. Au-delà, quatre
  /// mots ne tiennent plus côte à côte quelle que soit la hauteur de la
  /// barre — iOS lui-même plafonne ses barres d'onglets.
  static const double _maxLabelScale = 1.6;

  static const double _labelSize = 11;
  static const double _iconSize = 22;

  /// Le blanc laissé sous la pilule, quand le système réserve un bandeau fin :
  /// l'indicateur d'accueil d'iOS, la barre de gestes d'Android.
  ///
  /// Mesuré sur une capture de l'App Store posée à côté de l'app, à l'écran
  /// près : sa barre flottante laisse 61 px sur un iPhone 16 Pro, soit 20,7 pt.
  /// L'app en laissait 102, soit 34,7 — la totalité de l'encart iOS.
  ///
  /// Car une barre flottante ne se pose pas *au-dessus* de l'encart, elle
  /// flotte *dedans* : l'indicateur d'accueil ne fait que 5 pt de haut, posés
  /// à 8 pt du bord, et les 34 pt que réserve le système sont larges pour lui.
  /// Vingt points le dégagent, avec sept de marge.
  static const double _floatingGap = 20;

  /// Au-delà, l'encart n'est plus une réserve mais de l'interface qu'on ne
  /// peut pas recouvrir : la barre à trois boutons d'Android. On la rend
  /// entière, sans quoi la pilule passerait dessous.
  static const double _physicalNavInset = 40;

  /// Et sans aucun encart, il faut bien décoller du bord.
  static const double _bottomGap = Space.xs;

  /// Le blanc sous la pilule, selon ce que le système réserve en bas.
  static double _bottomInset(BuildContext context) {
    final reserved = MediaQuery.paddingOf(context).bottom;
    // Une barre de boutons se respecte ; un bandeau fin se traverse.
    if (reserved >= _physicalNavInset) return reserved;
    return math.max(_bottomGap, math.min(reserved, _floatingGap));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: _maxLabelScale);
    final lineHeight = scaler.scale(_labelSize) * 1.3;
    // Deux lignes dès que le texte grossit : « Aujourd'hui » à 17 pt ne tient
    // pas dans un quart d'écran, et le couper vaut moins que le plier.
    final lines = scaler.scale(_labelSize) > _labelSize * 1.2 ? 2 : 1;
    // La barre grandit avec son contenu au lieu de le rogner.
    final height = math.max(64.0, 12 + _iconSize + 2 + lineHeight * lines + 12);
    // Les marges latérales du système s'ajoutent aux nôtres. Sur un pliable,
    // la bande de la caméra passe sur un côté selon la rotation — 84 points à
    // droite, ou à gauche —, et rien ne dit qu'elle soit symétrique : chaque
    // bord est lu pour lui-même.
    final marges = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl + marges.left,
        0,
        Space.xl + marges.right,
        _bottomInset(context),
      ),
      // Une barre d'argile crème, opaque : la matière de l'app, posée sur le
      // contenu qui défile dessous. Bornée en largeur : sur un iPad en
      // paysage, une pilule de mille points serait ridicule.
      // `heightFactor: 1` n'est pas un détail : sans lui, le Center s'étire
      // dans les deux axes. Posé en `bottomNavigationBar`, il prenait toute la
      // hauteur de l'écran et la pilule se retrouvait centrée au milieu du
      // contenu. On ne centre que dans la largeur ; la hauteur épouse la barre.
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: _maxLabelScale,
            child: ClayBox(
              color: c.surface,
              shape: const ClayShape.pill(),
              height: height,
              padding: const EdgeInsets.all(6),
              child: _TabStrip(
                tabs: tabs,
                index: index,
                labelLines: lines,
                onSelect: (i) {
                  if (i != index) Haptics.selection();
                  onSelect(i);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le même menu, debout sur le bord droit.
///
/// Sur un appareil qui s'ouvre — l'iPhone Duo —, la fenêtre devient large
/// sans devenir une tablette : une pilule posée en bas traverse alors tout
/// l'écran pour quatre onglets, et le pouce qui tient l'appareil ouvert est
/// sur le côté, pas en bas. Le menu passe donc à droite, en colonne.
///
/// Rien d'autre ne change : c'est la même bulle, le même ressort, la même
/// argile. Seuls les libellés tombent — quatre mots debout doubleraient la
/// largeur de la colonne, et `Semantics` les dit toujours à VoiceOver.
class FloraTabRail extends StatelessWidget {
  const FloraTabRail({
    super.key,
    required this.tabs,
    required this.index,
    required this.onSelect,
    this.actions = const <Widget>[],
  });

  final List<FloraTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  /// Les boutons de la page ouverte, posés sous les onglets. Ils viennent du
  /// haut de page, que la colonne remplace (voir `RailActionsSlot`), et le
  /// dernier de la liste — le « + », le plus souvent — se retrouve le plus
  /// près du pouce.
  final List<Widget> actions;

  /// La place qu'un bouton de page occupe vraiment. Un [FloraIconButton] est
  /// rond de 40 points, mais [Pressable] lui garantit les 44 des HIG —
  /// `kMinTapTarget` — et c'est cette taille-là qui compte ici : la colonne
  /// doit savoir ce qu'il lui reste avant de se donner une hauteur, faute de
  /// pouvoir mesurer ses enfants.
  static const double _actionSize = kMinTapTarget;

  /// La largeur de la colonne. Avec ses 6 points de marge intérieure, chaque
  /// onglet reçoit 52 points de large : au-delà des 44 exigés.
  static const double _width = 64;

  /// La hauteur d'un onglet dans la colonne.
  static const double _slot = 56;

  /// Jusqu'où descendent les éléments du système en haut de la bande —
  /// caméra, heure et wifi empilés —, **à défaut de réponse du système**.
  ///
  /// C'est une mesure au pixel, prise sur le simulateur de l'iPhone Duo
  /// fermé, et elle ne sert que de repli : `WindowRegionsService` demande la
  /// vraie géométrie au natif (`ios/Runner/WindowRegionsChannel.swift`). Les
  /// marges sûres, elles, n'en disent rien — `padding.top` annonce 82 points
  /// dans cette pose, là où la pile descend à 140.
  ///
  /// Les 32 points d'air ne sont pas décoratifs : douze collaient la pilule
  /// au wifi, et deux pièces d'argile de 64 points de large ont besoin de
  /// plus d'écart qu'un glyphe de vingt.
  static const double _pileDuSysteme = 140;
  static const double _airSousLaPile = Space.xxl;
  static const double _sousLesElementsDuSysteme = _pileDuSysteme + _airSousLaPile;

  /// L'air sous la **région annoncée**, qui n'est pas le même. Les 32 points
  /// ci-dessus dégagent des glyphes mesurés ; ici c'est ce que le système
  /// réserve pour lui — 170 points sur l'écran extérieur du Duo, là où les
  /// glyphes s'arrêtent à 140 —, et on se pose juste dessous.
  ///
  /// Les deux chemins tombent à six points l'un de l'autre, 172 contre 178 :
  /// la mesure était bonne, l'annonce la remplace sans la démentir.
  static const double _airSousLaRegion = Space.xs;

  /// Le dégagement du haut, demandé au système quand il répond.
  static double _degagement(BuildContext context, WindowRegions regions) {
    final annonce = regions.systemStackBottom;
    final mesure = annonce == null ? _sousLesElementsDuSysteme : annonce + _airSousLaRegion;
    return math.max(mesure, MediaQuery.paddingOf(context).top + Space.sm);
  }

  /// Le blanc à droite, pour que l'axe de la colonne tombe sur celui du
  /// système. Demandé lui aussi ; à défaut, les 16 points mesurés.
  ///
  /// La colonne se pose ainsi **dans** la bande que le système réserve de ce
  /// côté, et non à côté d'elle : c'est là que le pliable met les commandes
  /// d'une application, sous l'heure et le wifi, et s'en écarter laissait une
  /// colonne vide large comme un pouce.
  ///
  /// Ce n'est pas contredire la marge sûre : elle vaut pour le **contenu**,
  /// qui s'arrête bien avant — il ne prend que ce que la colonne lui laisse
  /// (`app/shell.dart`). Le menu, lui, est du châssis, comme la barre
  /// d'outils debout d'iOS.
  static double _blancDroit(WindowRegions regions) {
    final axe = regions.systemAxisFromRight;
    if (axe == null) return _edgeGap;
    return math.max(Space.xs, axe - _width / 2);
  }

  /// Le blanc entre la pilule et le bord droit, **à défaut de réponse du
  /// système**, choisi pour que la colonne tombe sur le même axe que sa pile.
  ///
  /// iOS la pose à 47,7 points du bord droit, mesuré au pixel dans les trois
  /// poses du Duo : fermé 466, ouvert 669, couché 951. La pilule fait 64
  /// points de large, donc 16 de blanc mettent son axe à 48. Douze points la
  /// décalaient de quatre, assez pour que l'œil le voie.
  static const double _edgeGap = Space.md;

  /// La fenêtre appelle un menu debout plutôt qu'une barre en bas.
  ///
  /// Trois conditions, chacune pour une raison mesurée.
  ///
  /// **Pas une tablette** : au-delà de 700 points de côté le plus court, c'est
  /// un iPad — le plus petit fait 744 — et l'iPad garde sa barre en bas.
  ///
  /// **Assez large** pour céder les 80 points de la colonne sans étouffer le
  /// contenu. L'écran extérieur du Duo en fait 466 et lui reste 386 ; une
  /// tranche de multitâche à 445 tomberait trop bas.
  ///
  /// **Pas une colonne de téléphone** : c'est la forme qui tranche, pas la
  /// taille. Un iPhone en portrait est étroit et long — 402 × 874, soit 0,46 —
  /// et une barre en bas y est chez elle. Les fenêtres du Duo sont trapues :
  /// 0,69 fermé, 0,70 ouvert, 1,4 couché. C'est aussi ce qui règle enfin le
  /// cas de l'iPad en Split View aux deux tiers, 678 × 1133, qui vaut 0,60.
  ///
  /// Les cotes viennent de Xcode 27.1, sur un binaire bord-à-bord.
  static bool fitsIn(BuildContext context) => fitsInSize(MediaQuery.sizeOf(context));

  /// La même décision, sur une taille nue : ce dont la sonde a besoin, qui
  /// n'a pas de `BuildContext` sous la main.
  static bool fitsInSize(Size size) {
    if (size.shortestSide >= 700) return false;
    if (size.width < 460) return false;
    return size.width / size.height > 0.6;
  }

  /// La largeur que le rail prend au contenu, bord compris. Sert à ce qui
  /// flotte par-dessus l'application et doit l'éviter — le toast.
  static double reserved(BuildContext context) =>
      Space.md + _width + _blancDroit(WindowRegionsService.regions.value);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WindowRegions>(
      valueListenable: WindowRegionsService.regions,
      builder: (context, regions, _) => _colonne(context, regions),
    );
  }

  Widget _colonne(BuildContext context, WindowRegions regions) {
    final c = context.colors;
    return Padding(
      // En bas, la colonne flotte *dans* l'encart du système comme la pilule
      // du bas le fait : l'indicateur d'accueil est au milieu, la colonne au
      // bord droit, et vingt points les dégagent l'un de l'autre.
      padding: EdgeInsets.fromLTRB(
        Space.md,
        Space.md,
        _blancDroit(regions),
        math.max(Space.md, math.min(MediaQuery.paddingOf(context).bottom, FloraTabBar._floatingGap)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ce que les boutons de page prendront, l'écart compris. Les onglets
          // se contentent du reste : dans une fenêtre courte — un pliable
          // fermé et couché —, ils se resserrent plutôt que de déborder.
          final placeDesBoutons = actions.isEmpty
              ? 0.0
              : actions.length * _actionSize + (actions.length - 1) * Space.xs + Space.md;
          final voulu = 12 + _slot * tabs.length;
          final dispo = constraints.hasBoundedHeight ? constraints.maxHeight : double.infinity;
          // Tout se cale en haut, et non au milieu : c'est ce qui fait qu'une
          // pilule ne se déplace ni d'un onglet à l'autre, ni d'un pli à
          // l'autre. En bas, les boutons pendent et la place qui reste ne
          // sert qu'à eux.
          final souhaite = _degagement(context, regions) - Space.md;
          // Sauf dans une fenêtre trop courte pour ce dégagement : les
          // onglets gardent alors leurs 44 points de cible et la colonne
          // remonte de ce qu'il faut.
          final piluleMinimale = 12 + kMinTapTarget * tabs.length;
          final haut = dispo.isFinite ? math.max(0.0, math.min(souhaite, dispo - placeDesBoutons - piluleMinimale)) : 0.0;
          final hauteur = dispo.isFinite ? math.min(voulu, math.max(0.0, dispo - haut - placeDesBoutons)) : voulu;

          final colonne = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClayBox(
                color: c.surface,
                shape: const ClayShape.pill(),
                width: _width,
                height: hauteur,
                padding: const EdgeInsets.all(6),
                child: _TabStrip(
                  axis: Axis.vertical,
                  showLabels: false,
                  tabs: tabs,
                  index: index,
                  labelLines: 1,
                  onSelect: (i) {
                    if (i != index) Haptics.selection();
                    onSelect(i);
                  },
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                for (final (i, action) in actions.indexed) ...[
                  if (i > 0) const SizedBox(height: Space.xs),
                  action,
                ],
              ],
            ],
          );
          if (!dispo.isFinite) return colonne;
          // `max` n'est pas un détail : une colonne qui épouse son contenu se
          // ferait recentrer par la rangée qui la porte, et le décalage
          // calculé ici s'ajouterait à ce recentrage.
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [SizedBox(height: haut), colonne],
          );
        },
      ),
    );
  }
}

/// La rangée d'onglets et la bulle qui court dessous.
class _TabStrip extends StatefulWidget {
  const _TabStrip({
    required this.tabs,
    required this.index,
    required this.onSelect,
    required this.labelLines,
    this.axis = Axis.horizontal,
    this.showLabels = true,
  });

  final List<FloraTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;
  final int labelLines;

  /// Le sens de la course : la pilule du bas est une rangée, le rail de
  /// droite une colonne. Tout le reste — la bulle, le ressort, la couleur
  /// qui vire au passage — est commun aux deux.
  final Axis axis;

  /// Le rail se passe de libellés : quatre mots debout feraient une colonne
  /// deux fois plus large, et le lecteur d'écran les annonce de toute façon
  /// (voir la `Semantics` de [_TabItem]).
  final bool showLabels;

  @override
  State<_TabStrip> createState() => _TabStripState();
}

class _TabStripState extends State<_TabStrip> with TickerProviderStateMixin {
  /// La position de la bulle, en onglets : 1,4 veut dire « entre le deuxième
  /// et le troisième ». Sans bornes, parce qu'un ressort dépasse.
  late final AnimationController _bubble = AnimationController.unbounded(vsync: this, value: widget.index.toDouble());

  /// L'icône qui vient d'être choisie : part rentrée, se pose en dépassant.
  late final AnimationController _pop = AnimationController.unbounded(vsync: this, value: 1);

  /// D'où l'icône part quand la bulle arrive sur elle.
  static const double _popFrom = 0.78;

  bool _animate = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(_TabStrip old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _bubble.springTo(widget.index.toDouble(), spring: Springs.glide, animate: _animate);
    if (_animate) _pop.value = _popFrom;
    _pop.springTo(1, spring: Springs.release, animate: _animate);
  }

  @override
  void dispose() {
    _bubble.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final vertical = widget.axis == Axis.vertical;
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = (vertical ? constraints.maxHeight : constraints.maxWidth) / widget.tabs.length;
        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bubble,
                builder: (context, child) {
                  // Le dépassement du ressort est borné aux onglets qui
                  // existent : aux deux bouts, la bulle se poserait sinon
                  // un point ou deux en dehors de la pilule.
                  final course = _bubble.value.clamp(0, widget.tabs.length - 1) * slot;
                  return Align(
                    alignment: vertical ? Alignment.topCenter : Alignment.centerLeft,
                    child: Transform.translate(
                      offset: vertical ? Offset(0, course) : Offset(course, 0),
                      child: SizedBox(
                        width: vertical ? double.infinity : slot,
                        height: vertical ? slot : double.infinity,
                        child: child,
                      ),
                    ),
                  );
                },
                child: DecoratedBox(decoration: BoxDecoration(color: c.sage, borderRadius: Radii.fullAll)),
              ),
            ),
            Flex(
              direction: widget.axis,
              children: [
                for (final (i, tab) in widget.tabs.indexed)
                  Expanded(
                    child: _TabItem(
                      tab: tab,
                      index: i,
                      // Ce que VoiceOver annonce suit l'onglet choisi, pas la
                      // bulle : au moment où la barre se reconstruit, celle-ci
                      // est encore à son point de départ.
                      selected: i == widget.index,
                      bubble: _bubble,
                      pop: i == widget.index ? _pop : null,
                      labelLines: widget.labelLines,
                      showLabel: widget.showLabels,
                      onTap: () => widget.onSelect(i),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.index, required this.selected, required this.bubble, required this.pop, required this.onTap, this.labelLines = 1, this.showLabel = true});

  final FloraTab tab;
  final int index;

  /// L'onglet choisi — ce que le lecteur d'écran annonce.
  final bool selected;

  /// La position de la bulle, pour savoir de combien cet onglet est couvert.
  final Animation<double> bubble;

  /// Le rebond de l'icône, quand c'est cet onglet qui vient d'être choisi.
  final Animation<double>? pop;

  final VoidCallback onTap;
  final int labelLines;

  /// Le libellé sous l'icône. Éteint dans le rail, où l'icône suffit.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      // Le libellé est déjà celui de l'onglet : sans cela, le texte dessiné
      // en ajoute un second et le lecteur d'écran annonce « Jardin, Jardin ».
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedBuilder(
          animation: pop == null ? bubble : Listenable.merge([bubble, pop]),
          builder: (context, _) {
            // La part de l'onglet que la bulle recouvre : c'est elle qui
            // décide de la couleur, si bien qu'un libellé vire pendant que la
            // bulle passe dessus au lieu de basculer à l'arrivée.
            final covered = (1 - (bubble.value - index).abs()).clamp(0.0, 1.0);
            final fg = Color.lerp(c.inkSecondary, c.onSage, covered)!;
            final on = covered > 0.5;
            final icone = Transform.scale(
              scale: pop?.value ?? 1,
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.micro),
                child: Icon(
                  on ? tab.activeIcon : tab.icon,
                  key: ValueKey(on),
                  size: FloraTabBar._iconSize,
                  color: fg,
                ),
              ),
            );
            if (!showLabel) return Center(child: icone);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icone,
                const SizedBox(height: 2),
                Text(
                  tab.label,
                  style: context.text.caption.copyWith(
                    fontSize: FloraTabBar._labelSize,
                    color: fg,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: labelLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
