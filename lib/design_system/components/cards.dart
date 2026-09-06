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
