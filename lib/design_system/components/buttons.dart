import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'pressable.dart';

enum FloraButtonStyle { primary, secondary, tonal, ghost, destructive }

enum FloraButtonSize { regular, small }

/// Bouton en pilule. Une seule famille de boutons pour toute l'app.
class FloraButton extends StatelessWidget {
  const FloraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = FloraButtonStyle.primary,
    this.size = FloraButtonSize.regular,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FloraButtonStyle style;
  final FloraButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (style) {
      FloraButtonStyle.primary => (c.sage, c.onSage),
      FloraButtonStyle.secondary => (c.surface, c.ink),
      FloraButtonStyle.tonal => (c.sageSoft, c.sage),
      FloraButtonStyle.ghost => (Colors.transparent, c.sage),
      FloraButtonStyle.destructive => (c.danger, Colors.white),
    };
    final small = size == FloraButtonSize.small;
    final textStyle = (small ? context.text.callout : context.text.body).copyWith(
      color: fg,
      fontWeight: FontWeight.w600,
    );
    final child = Container(
      height: small ? 40 : 52,
      padding: EdgeInsets.symmetric(horizontal: small ? Space.md : Space.xl),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: Radii.fullAll,
        border: style == FloraButtonStyle.secondary ? Border.all(color: c.line) : null,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.standard),
            child: loading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 18,
                    height: 18,
                    child: CupertinoActivityIndicator(color: fg, radius: 8),
                  )
                : icon != null
                    ? Padding(
                        key: ValueKey(icon),
                        padding: const EdgeInsets.only(right: Space.xs),
                        child: Icon(icon, size: small ? 18 : 20, color: fg),
                      )
                    : const SizedBox.shrink(key: ValueKey('none')),
          ),
          Flexible(child: Text(label, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return Pressable(
      onTap: loading ? null : onPressed,
      enabled: onPressed != null && !loading,
      semanticLabel: label,
      child: child,
    );
  }
}

/// Bouton icône circulaire (barres de navigation, cartes).
class FloraIconButton extends StatelessWidget {
  const FloraIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 40,
    this.filled = true,
    this.color,
    this.background,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;
  final bool filled;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onPressed,
      enabled: onPressed != null,
      scale: 0.9,
      semanticLabel: semanticLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? (background ?? c.surface) : Colors.transparent,
          shape: BoxShape.circle,
          border: filled && background == null ? Border.all(color: c.line.withValues(alpha: 0.6)) : null,
        ),
        child: Icon(icon, size: size * 0.5, color: color ?? c.ink),
      ),
    );
  }
}
