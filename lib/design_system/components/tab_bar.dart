import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'clay.dart';

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
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, _bottomInset(context)),
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

/// La rangée d'onglets et la bulle qui court dessous.
class _TabStrip extends StatefulWidget {
  const _TabStrip({required this.tabs, required this.index, required this.onSelect, required this.labelLines});

  final List<FloraTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;
  final int labelLines;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / widget.tabs.length;
        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bubble,
                builder: (context, child) => Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    // Le dépassement du ressort est borné aux onglets qui
                    // existent : aux deux bouts, la bulle se poserait sinon
                    // un point ou deux en dehors de la pilule.
                    offset: Offset(_bubble.value.clamp(0, widget.tabs.length - 1) * slot, 0),
                    child: SizedBox(width: slot, height: double.infinity, child: child),
                  ),
                ),
                child: DecoratedBox(decoration: BoxDecoration(color: c.sage, borderRadius: Radii.fullAll)),
              ),
            ),
            Row(
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
  const _TabItem({required this.tab, required this.index, required this.selected, required this.bubble, required this.pop, required this.onTap, this.labelLines = 1});

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
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
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
                ),
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
