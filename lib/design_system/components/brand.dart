import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'clay.dart';
import 'pressable.dart';

/// La tête verte d'un écran : le vert de l'icône, deux grands disques pâles
/// qui sortent du cadre, et tout ce qu'on y pose en blanc.
///
/// Ce qu'elle contient hérite d'un texte et d'icônes en `onBrand` : un titre,
/// un grand chiffre ([HeroNumber]), des pastilles de verre ([GlassChip]).
/// Elle se prolonge sous la feuille qui la suit ([BrandSheet]), pour que le
/// coin arrondi de la feuille se découpe sur du vert et non sur du vide.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xl),
    this.underlap = Radii.xl,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Ce que le vert descend sous la feuille suivante.
  final double underlap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.brand),
      child: ClipRect(
        clipper: const _OpenTop(),
        child: CustomPaint(
          painter: _Discs(Colors.white),
          child: Padding(
            padding: padding.add(EdgeInsets.only(bottom: underlap)),
            child: OnBrand(
              child: DefaultTextStyle.merge(
                style: TextStyle(color: c.onBrand),
                child: IconTheme.merge(data: IconThemeData(color: c.onBrand), child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Coupe les disques sur les côtés et en bas, mais pas en haut.
///
/// Quand on tire la liste vers le bas, la tête descend et laisse voir le vert
/// du fond au-dessus d'elle. Coupés au bord haut, les disques s'y arrêtaient
/// net sur une ligne droite ; ouverts, ils continuent dans ce vert. Au repos,
/// ce qui dépasse tombe hors de l'écran, et la liste le coupe.
class _OpenTop extends CustomClipper<Rect> {
  const _OpenTop();

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, -size.width, size.width, size.height);

  @override
  bool shouldReclip(_OpenTop oldClipper) => false;
}

/// Dit à ce qu'il enveloppe qu'il est posé sur le vert de la marque.
///
/// Les pièces ordinaires — une pilule, un bouton rond — s'y font de verre :
/// blanc à 14 %, filet blanc, encre blanche. Un écran n'a donc pas à choisir
/// une autre pièce pour sa tête verte ; il pose la même, et elle s'accorde.
class OnBrand extends InheritedWidget {
  const OnBrand({super.key, required super.child});

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<OnBrand>() != null;

  /// Le fond et le filet d'une pièce de verre.
  static const Color glass = Color(0x24FFFFFF);
  static const Color glassLine = Color(0x42FFFFFF);

  @override
  bool updateShouldNotify(OnBrand oldWidget) => false;
}

/// Deux disques très pâles en haut à droite : le décor de la tête verte.
/// Ils ne portent rien, ils cassent l'aplat.
class _Discs extends CustomPainter {
  const _Discs(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final big = size.width * 0.54;
    canvas.drawCircle(Offset(size.width + big * 0.12, big * 0.2), big, Paint()..color = color.withValues(alpha: 0.06));
    final small = size.width * 0.33;
    canvas.drawCircle(Offset(size.width - small * 0.15, small * 0.55), small, Paint()..color = color.withValues(alpha: 0.05));
  }

  @override
  bool shouldRepaint(_Discs old) => old.color != color;
}

/// La feuille crème qui recouvre le bas d'une [BrandHeader] : coins hauts
/// arrondis, remontée de [overlap] sur le vert.
class BrandSheet extends StatelessWidget {
  const BrandSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.xl),
    this.overlap = Radii.xl,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Transform.translate(
      offset: Offset(0, -overlap),
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.canvas, borderRadius: Radii.sheetTop),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Le grand chiffre d'une tête d'écran et ce qu'il compte : « 3 » puis
/// « soins aujourd'hui ». Lu d'un seul tenant par VoiceOver.
class HeroNumber extends StatelessWidget {
  const HeroNumber({super.key, required this.value, required this.label, this.size = 112});

  final String value;
  final String label;

  /// La taille du chiffre ; celle du style `hero` par défaut n'est qu'un
  /// point de départ.
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = DefaultTextStyle.of(context).style.color ?? c.ink;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: context.text.hero.copyWith(fontSize: size, letterSpacing: -size / 22, color: ink)),
          const SizedBox(height: Space.xxs),
          Text(label, style: context.text.title3.copyWith(color: ink, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Une pastille de verre posée sur le vert : la météo, la pièce, un filtre.
/// Blanche et pleine quand elle est choisie.
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.label, this.icon, this.iconColor, this.selected = false, this.onTap});

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onPop : c.onBrand;
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(
        color: selected ? Colors.white : OnBrand.glass,
        borderRadius: Radii.fullAll,
        border: selected ? null : Border.all(color: OnBrand.glassLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: iconColor ?? fg), const SizedBox(width: Space.xs)],
          Flexible(
            child: Text(
              label,
              style: context.text.callout.copyWith(color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return MergeSemantics(child: Semantics(selected: selected, child: Pressable(onTap: onTap, scale: 0.95, child: chip)));
  }
}

/// Une carte d'accent vif : la carte du prochain soin, en orange plein.
///
/// L'encre `onPop` y est posée d'office. [art], s'il y en a un, déborde du
/// coin droit — un objet de la maison, posé sur la carte.
class PopCard extends StatelessWidget {
  const PopCard({super.key, required this.color, required this.child, this.art, this.onTap, this.padding = const EdgeInsets.all(Space.lg)});

  final Color color;
  final Widget child;
  final Widget? art;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget body = DefaultTextStyle.merge(
      style: TextStyle(color: c.onPop),
      child: IconTheme.merge(data: IconThemeData(color: c.onPop), child: child),
    );
    if (art != null) {
      body = Row(
        children: [
          Expanded(child: body),
          const SizedBox(width: Space.sm),
          ExcludeSemantics(child: art!),
        ],
      );
    }
    final card = ClayBox(
      color: color,
      shape: const ClayShape.rounded(Radii.large + 2),
      depth: ClayDepth.deep,
      clip: true,
      padding: padding,
      child: body,
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap, scale: 0.98, child: card);
  }
}

/// Un chiffre de carte : un libellé, une valeur, son unité, et une ligne de
/// plus si besoin. Sur `brand`, il passe en blanc ; sinon il prend la carte
/// crème.
class StatBlock extends StatelessWidget {
  const StatBlock({super.key, required this.label, required this.value, this.unit, this.detail, this.brand = false, this.large = false});

  final String label;
  final String value;
  final String? unit;
  final String? detail;

  /// Sur le vert de la marque plutôt que sur la carte crème.
  final bool brand;

  /// Le chiffre principal d'une rangée, deux fois plus grand.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = brand ? c.onBrand : c.ink;
    final soft = brand ? c.onBrand : c.inkSecondary;
    final number = context.text.stat.copyWith(color: ink, fontSize: large ? 56 : 34, letterSpacing: large ? -2 : -1);
    return MergeSemantics(
      child: ClayBox(
        color: brand ? c.brand : c.surface,
        shape: const ClayShape.rounded(Radii.large),
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: context.text.caption.copyWith(color: soft, fontWeight: FontWeight.w700, fontSize: 14)),
            // Un chiffre ne se coupe pas : dans une case étroite, il rapetisse.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text.rich(
                TextSpan(
                  text: value,
                  children: [if (unit != null) TextSpan(text: ' $unit', style: number.copyWith(fontSize: number.fontSize! * 0.5, letterSpacing: 0))],
                ),
                style: number,
                maxLines: 1,
              ),
            ),
            if (detail != null) Text(detail!, style: context.text.caption.copyWith(color: soft, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
