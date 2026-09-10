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

/// Barre d'onglets flottante en pilule, fond flouté, bulle active animée —
/// dans l'esprit des barres iOS récentes.
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

  /// Le blanc sous la pilule quand le système n'en réserve aucun.
  ///
  /// C'est le seul chiffre à toucher pour poser la barre plus haut ou plus
  /// bas sur un appareil sans encart. Ailleurs, c'est l'encart qui commande.
  static const double _bottomGap = Space.xs;

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
      // L'encart réservé par le système — 34 pt sous un iPhone à indicateur
      // d'accueil, la hauteur des trois boutons sous Android — *est* la marge
      // du bas. L'empiler avec la nôtre laissait 46 pt de vide sous la
      // pilule, bien plus haut que les barres du système. On s'y installe, on
      // ne s'y ajoute pas ; et sous une barre à boutons, la garder entière est
      // ce qui empêche la pilule de passer dessous.
      padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, math.max(_bottomGap, MediaQuery.paddingOf(context).bottom)),
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
              child: Row(
                children: [
                  for (final (i, tab) in tabs.indexed)
                    Expanded(
                      child: _TabItem(
                        tab: tab,
                        selected: i == index,
                        labelLines: lines,
                        onTap: () {
                          if (i != index) Haptics.selection();
                          onSelect(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.selected, required this.onTap, this.labelLines = 1});

  final FloraTab tab;
  final bool selected;
  final VoidCallback onTap;
  final int labelLines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.standard),
          curve: Motion.emphasized,
          decoration: BoxDecoration(color: selected ? c.sage : Colors.transparent, borderRadius: Radii.fullAll),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.micro),
                child: Icon(
                  selected ? tab.activeIcon : tab.icon,
                  key: ValueKey(selected),
                  size: FloraTabBar._iconSize,
                  color: selected ? c.onSage : c.inkSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                style: context.text.caption.copyWith(
                  fontSize: FloraTabBar._labelSize,
                  color: selected ? c.onSage : c.inkSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: labelLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
