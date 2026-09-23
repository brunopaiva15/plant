import 'package:flutter/cupertino.dart';

import '../../core/haptics.dart';
import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'clay.dart';
import 'brand.dart';
import 'pressable.dart';

/// Chip sélectionnable en pilule (filtres, emplacements, types).
class FloraChip extends StatelessWidget {
  const FloraChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.emoji,
    this.icon,
    this.leading,
    this.dashed = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? emoji;
  final IconData? icon;

  /// Une pièce dessinée devant le libellé, quand un emoji ne suffit pas —
  /// l'illustration d'argile d'un problème, par exemple. Elle chasse la
  /// marge verticale, pour que la chip grandisse autour d'elle au lieu de la
  /// rogner.
  final Widget? leading;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              Haptics.selection();
              onTap!();
            },
      haptic: false,
      scale: 0.95,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.standard),
        curve: Motion.easeOut,
        padding: EdgeInsets.symmetric(horizontal: leading == null ? Space.md : Space.sm, vertical: leading == null ? Space.xs + 2 : 6),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.surface,
          borderRadius: Radii.fullAll,
          border: dashed ? Border.all(color: c.line) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: Space.xs)],
            if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 15)), const SizedBox(width: 6)],
            if (icon != null) ...[Icon(icon, size: 16, color: selected ? c.canvas : c.ink), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                style: context.text.callout.copyWith(color: selected ? c.canvas : c.ink, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un choix facultatif parmi quelques valeurs : des puces, une seule
/// allumée, qu'on éteint d'un second toucher. Même geste que la lumière d'un
/// emplacement ou la forme d'un engrais.
class FloraChoice<T extends Object> extends StatelessWidget {
  const FloraChoice({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.emojiOf,
    this.leadingOf,
  });

  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final String Function(T)? emojiOf;
  final Widget Function(T)? leadingOf;

  /// `null` quand la valeur allumée est touchée de nouveau : le choix
  /// facultatif redevient vide.
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.caption),
        const SizedBox(height: 6),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final v in values)
              FloraChip(
                emoji: emojiOf?.call(v),
                leading: leadingOf?.call(v),
                label: labelOf(v),
                selected: selected == v,
                onTap: () => onChanged(selected == v ? null : v),
              ),
          ],
        ),
      ],
    );
  }
}

/// Action rapide : une tuile d'argile aux coins irréguliers, l'emoji dedans,
/// le libellé dessous. [variant] varie la forme d'une tuile à l'autre.
class QuickActionChip extends StatelessWidget {
  const QuickActionChip({super.key, required this.emoji, required this.label, required this.onTap, this.background, this.variant = 0});

  final String emoji;
  final String label;
  final VoidCallback onTap;
  final Color? background;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      semanticLabel: label,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClayBox(
              width: 56,
              height: 56,
              color: background ?? c.surface,
              shape: ClayShape.blob(variant),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24, height: 1)),
            ),
            const SizedBox(height: Space.xs),
            Text(label, style: context.text.caption, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Pilule de lecture : un emoji, un libellé, un détail en retrait, et le
/// chevron quand elle mène quelque part. C'est ce qui porte, sur l'écran du
/// matin, la météo, la mesure de la maison et les emplacements du jardin :
/// une même forme pour « voici où l'on en est, touchez pour en voir plus ».
///
/// Elle fait la hauteur de la cible tactile — pas plus : sa surface est la
/// zone qui écoute, aucun vide autour.
class FloraPill extends StatelessWidget {
  const FloraPill({super.key, required this.label, this.emoji, this.detail, this.chevron = false, this.onTap});

  final String label;
  final String? emoji;

  /// Un complément en retrait, après le libellé : un compte, une pièce.
  final String? detail;
  final bool chevron;
  final VoidCallback? onTap;

  /// Largeur au-delà de laquelle le libellé se coupe.
  static const double maxWidth = 320;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Sur la tête verte, la pilule se fait de verre.
    final verre = OnBrand.of(context);
    final ink = verre ? c.onBrand : c.ink;
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      // Dans une bande qui défile, la largeur n'est pas bornée : la pilule
      // prend celle de son texte, jusqu'à un plafond. Dans une colonne, elle
      // cède la place et coupe son libellé. C'est [IntrinsicWidth] qui borne
      // la ligne dans les deux cas, pour que le libellé puisse plier.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth, minHeight: kMinTapTarget),
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
            decoration: BoxDecoration(
              color: verre ? OnBrand.glass : c.surface,
              borderRadius: Radii.fullAll,
              border: verre ? Border.all(color: OnBrand.glassLine) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 15)), const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    label,
                    style: context.text.callout.copyWith(color: ink, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (detail != null) ...[const SizedBox(width: 6), Text(detail!, style: context.text.caption.copyWith(color: verre ? ink : null))],
                if (chevron) ...[const SizedBox(width: 2), Icon(CupertinoIcons.chevron_right, size: 13, color: verre ? ink : c.inkTertiary)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Étiquette immobile posée au bout d'une ligne : un mot sur son état, quand
/// ce mot n'est pas une valeur — « Bientôt » sur une intégration écrite mais
/// pas encore ouverte. Elle ne se touche pas ; le texte porte l'information,
/// la couleur ne fait que la poser.
class FloraTag extends StatelessWidget {
  const FloraTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: Radii.fullAll),
      child: Text(
        label,
        style: context.text.caption.copyWith(color: c.inkSecondary, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
