import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'clay.dart';
import 'pressable.dart';

/// Carte d'argile crème, très arrondie : bord clair, ombre logée, ombre portée
/// dans sa teinte. [depth] passe au relief franc pour une carte de couleur.
class FloraCard extends StatelessWidget {
  const FloraCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(Space.md),
    this.radius = Radii.large,
    this.color,
    this.clip = false,
    this.depth = ClayDepth.light,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool clip;
  final ClayDepth depth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = ClayBox(
      color: color ?? c.surface,
      shape: ClayShape.rounded(radius),
      depth: depth,
      clip: clip,
      padding: padding,
      child: child,
    );
    if (onTap == null && onLongPress == null) return box;
    return Pressable(onTap: onTap, onLongPress: onLongPress, scale: 0.98, child: box);
  }
}

/// Groupe de lignes (réglages, informations) : équivalent visuel de la liste
/// « inset grouped » d'iOS, partagé sur les deux plateformes.
class FloraGroup extends StatelessWidget {
  const FloraGroup({super.key, required this.children, this.header, this.footer});

  final List<Widget> children;
  final String? header;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.only(left: Space.md, bottom: Space.xs),
            child: Text(header!.toUpperCase(), style: context.text.caption.copyWith(letterSpacing: 0.4)),
          ),
        FloraCard(
          padding: EdgeInsets.zero,
          clip: true,
          child: Column(
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0) Divider(height: 1, thickness: 0.5, indent: Space.md, color: c.line),
                child,
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(left: Space.md, top: Space.xs, right: Space.md),
            child: Text(footer!, style: context.text.caption),
          ),
      ],
    );
  }
}

/// Une option pratique : une icône teintée dans un rond pastel, un libellé,
/// sur une carte d'argile. Deux côte à côte disent « voici les outils »
/// sans qu'on ait à deviner ce que cache une icône seule dans une barre.
class FloraActionTile extends StatelessWidget {
  const FloraActionTile({super.key, required this.icon, required this.label, required this.tint, required this.onTap});

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloraCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.sm),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: tint.withValues(alpha: c.isDark ? 0.22 : 0.14), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: Space.xs),
          Expanded(child: Text(label, style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
