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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, MediaQuery.paddingOf(context).bottom + Space.sm),
      // Une barre d'argile crème, opaque : la matière de l'app, posée sur le
      // contenu qui défile dessous.
      child: ClayBox(
        color: c.surface,
        shape: const ClayShape.pill(),
        height: 64,
        padding: const EdgeInsets.all(6),
        child: Row(
              children: [
                for (final (i, tab) in tabs.indexed)
                  Expanded(
                    child: _TabItem(
                      tab: tab,
                      selected: i == index,
                      onTap: () {
                        if (i != index) Haptics.selection();
                        onSelect(i);
                      },
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.selected, required this.onTap});

  final FloraTab tab;
  final bool selected;
  final VoidCallback onTap;

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
                  size: 22,
                  color: selected ? c.onSage : c.inkSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                style: context.text.caption.copyWith(
                  fontSize: 11,
                  color: selected ? c.onSage : c.inkSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
