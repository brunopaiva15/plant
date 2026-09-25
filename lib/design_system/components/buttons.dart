import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';
import 'adaptive.dart';
import 'brand.dart';
import 'clay.dart';
import 'clay_loader.dart';
import 'pressable.dart';

enum FloraButtonStyle { primary, secondary, tonal, ghost, destructive }

enum FloraButtonSize { regular, small }

/// Bouton en pilule pleine. Une seule famille de boutons pour toute l'app :
/// vert pour le geste principal, crème ou pastel pour les autres, sans
/// matière pour le bouton discret. [pop] le passe sur un accent vif
/// (`waterPop` pour « Arroser »), avec l'encre `onPop` dessus.
class FloraButton extends StatelessWidget {
  const FloraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = FloraButtonStyle.primary,
    this.size = FloraButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
    this.pop,
  });

  final String label;
  final VoidCallback? onPressed;
  final FloraButtonStyle style;
  final FloraButtonSize size;
  final IconData? icon;

  /// Icône placée après le libellé — une flèche qui pousse vers la suite.
  final IconData? trailingIcon;
  final bool loading;
  final bool expand;

  /// Un accent vif de la palette, qui remplace le fond du style.
  final Color? pop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = pop != null ? (pop!, c.onPop) : switch (style) {
      FloraButtonStyle.primary => (c.sage, c.onSage),
      FloraButtonStyle.secondary => (c.surface, c.ink),
      FloraButtonStyle.tonal => (c.sageSoft, c.sage),
      FloraButtonStyle.ghost => (Colors.transparent, c.sage),
      FloraButtonStyle.destructive => (c.danger, c.onAccent),
    };
    final small = size == FloraButtonSize.small;
    final textStyle = (small ? context.text.callout : context.text.body).copyWith(color: fg, fontWeight: FontWeight.w700);
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.standard),
          child: loading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  height: 22,
                  child: ClayLoader(size: 14, color: fg),
                )
              : icon != null
              ? Padding(
                  key: ValueKey(icon),
                  padding: const EdgeInsets.only(right: Space.xs),
                  child: Icon(icon, size: small ? 18 : 20, color: fg),
                )
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
        Flexible(
          // Deux lignes autorisées : à 200 % de Dynamic Type, « Enregistrer le
          // soin » doit plier, pas se faire couper au milieu d'un mot.
          child: Text(label, style: textStyle, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
        if (trailingIcon != null) ...[const SizedBox(width: Space.xs), Icon(trailingIcon, size: small ? 18 : 20, color: fg)],
      ],
    );
    final padding = EdgeInsets.symmetric(horizontal: small ? Space.md : Space.xl);
    final height = small ? 44.0 : 56.0;
    final child = style == FloraButtonStyle.ghost
        ? Container(constraints: BoxConstraints(minHeight: height), padding: padding, child: row)
        : ClayBox(
            color: bg,
            shape: const ClayShape.pill(),
            depth: style == FloraButtonStyle.primary || style == FloraButtonStyle.destructive ? ClayDepth.deep : ClayDepth.light,
            minHeight: height,
            padding: padding,
            child: row,
          );
    return Pressable(onTap: loading ? null : onPressed, enabled: onPressed != null && !loading, semanticLabel: label, child: child);
  }
}

/// Bouton icône circulaire (barres de navigation, cartes).
class FloraIconButton extends StatelessWidget {
  const FloraIconButton({super.key, required this.icon, required this.onPressed, required this.semanticLabel, this.size = 40, this.filled = true, this.color, this.background, this.menu});

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;
  final bool filled;
  final Color? color;
  final Color? background;

  /// Ce que le bouton déplie **quand le système tient la barre**.
  ///
  /// iOS fait sortir un menu du bouton touché, à sa place, en floutant ce
  /// qu'il recouvre : c'est un `UIMenu`, et seul UIKit sait le dessiner.
  /// `components/native_actions.dart` traduit cette liste pour lui.
  ///
  /// Le bouton en argile, lui, ne change pas : là où le natif n'est pas —
  /// Android, ou une barre qu'il a refusée —, c'est [onPressed] qui répond,
  /// et une feuille d'actions reste la bonne réponse de cette plateforme-là.
  /// Les deux disent la même chose ; ce n'est pas la même façon de la dire.
  final List<SheetAction>? menu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Sur la tête verte, le bouton se fait de verre.
    final verre = OnBrand.of(context) && background == null;
    return Pressable(
      onTap: onPressed,
      enabled: onPressed != null,
      scale: 0.9,
      semanticLabel: semanticLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? (verre ? OnBrand.glass : background ?? c.surface) : Colors.transparent,
          shape: BoxShape.circle,
          border: filled && background == null ? Border.all(color: verre ? OnBrand.glassLine : c.line.withValues(alpha: 0.6)) : null,
        ),
        child: Icon(icon, size: size * 0.5, color: color ?? (verre ? c.onBrand : c.ink)),
      ),
    );
  }
}
