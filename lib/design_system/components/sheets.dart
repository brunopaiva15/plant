import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../theme/flora_theme.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'adaptive.dart';

/// Bottom sheet Flora à hauteur de contenu (« detent medium ») : poignée,
/// coins très arrondis, clavier géré. Utilisé pour toute action courte.
Future<T?> showFloraSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool scrollable = false,
}) {
  Haptics.light();
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: c.surface,
    barrierColor: c.ink.withValues(alpha: c.isDark ? 0.55 : 0.25),
    shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTop),
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
    builder: (ctx) => _MargesLaterales(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              Flexible(child: scrollable ? SingleChildScrollView(child: builder(ctx)) : builder(ctx)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Sheet plein écran pour un flow (création de plante) : sur iOS, la sheet
/// native qui repousse l'écran précédent ; sur Android, un dialogue plein écran.
///
/// **Elle porte sa poignée**, comme [showFloraSheet]. Une feuille d'iOS se
/// referme d'un glissement vers le bas, et c'est la poignée qui le dit : sans
/// elle, une feuille dont le contenu n'offre rien pour sortir n'a l'air de
/// rien — ni page, ni fenêtre. Voir [_AvecPoignee], qui la pose et lui fait
/// sa place.
///
/// Pour un contenu qui défile d'un seul tenant, prendre
/// [showFloraScrollableFlow] : cette version-ci laisse tomber le
/// `ScrollController` de la sheet, et le contenu ne défilerait pas.
Future<T?> showFloraFlow<T>(BuildContext context, {required WidgetBuilder builder}) {
  Haptics.light();
  if (isCupertino(context)) {
    return showCupertinoSheet<T>(
      context: context,
      useNestedNavigation: true,
      scrollableBuilder: (ctx, _) => _MargesLaterales(child: _AvecPoignee(child: builder(ctx))),
    );
  }
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(fullscreenDialog: true, builder: builder),
  );
}

/// [showFloraFlow] pour un contenu qui défile sur toute sa hauteur.
///
/// La sheet d'iOS pose un `Listener` translucide **par-dessus tout son
/// contenu**, qui arme un `VerticalDragGestureRecognizer` à chaque doigt posé :
/// c'est son glissement de fermeture. Une vue défilante ordinaire lui dispute
/// donc chaque geste vertical dans l'arène, et c'est la sheet qui gagne — elle
/// descend, le contenu ne bouge pas d'un pixel.
///
/// Le `ScrollController` qu'elle fournit est ce qui les réconcilie : il donne
/// à la vue une `_CupertinoSheetScrollPosition` qui arbitre les deux. Tant que
/// la liste n'est pas en haut, le geste la fait défiler ; une fois en haut, il
/// referme la sheet. C'est le comportement d'une sheet iOS native, et il n'y a
/// pas moyen de l'obtenir autrement.
///
/// Le contrôleur ne vaut que pour **une** vue défilante : un flow à plusieurs
/// pages qui défilent chacune de leur côté ne peut pas s'en servir (un même
/// contrôleur ne s'attache qu'à une vue à la fois) — c'est pourquoi
/// [showFloraFlow] existe toujours à côté.
///
/// Sur Android il n'y a pas de sheet : le contrôleur vaut `null` et la vue
/// défilante garde le sien.
Future<T?> showFloraScrollableFlow<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, ScrollController? controller) builder,
}) {
  Haptics.light();
  if (isCupertino(context)) {
    return showCupertinoSheet<T>(context: context, useNestedNavigation: true, scrollableBuilder: (ctx, controller) => _MargesLaterales(child: _AvecPoignee(child: builder(ctx, controller))));
  }
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(fullscreenDialog: true, builder: (ctx) => builder(ctx, null)),
  );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  /// Ce que la poignée prend en hauteur, marges comprises. Une feuille qui la
  /// pose par-dessus son contenu doit lui rendre autant.
  static const double height = Space.xs + 5 + Space.xs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs, bottom: Space.xs),
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(color: context.colors.line, borderRadius: Radii.fullAll),
      ),
    );
  }
}

/// La poignée d'une feuille plein écran, et la place qu'elle prend.
///
/// [showFloraSheet] pose la sienne dans une colonne, au-dessus du contenu :
/// sa feuille est à hauteur de contenu, et une ligne de plus ne gêne personne.
/// Une feuille de flow, elle, donne toute sa hauteur à une page — un
/// `Scaffold`, une [FloraPage] — qui la remplit du haut jusqu'en bas. La
/// poignée se pose donc **par-dessus**, et c'est la marge sûre qui lui fait
/// sa place : la page s'écarte d'elle-même, comme elle s'écarte de l'heure et
/// du wifi, sans rien savoir de cette poignée.
///
/// `showCupertinoSheet` sait le faire lui-même — `showDragHandle` —, mais ne
/// transmet pas le drapeau à sa route quand on lui demande la navigation
/// imbriquée, et nos flows la demandent tous. Le drapeau restait donc sans
/// effet, et la feuille sans poignée.
class _AvecPoignee extends StatelessWidget {
  const _AvecPoignee({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final heritee = MediaQuery.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaQuery(
          data: heritee.copyWith(padding: heritee.padding.copyWith(top: heritee.padding.top + SheetHandle.height)),
          child: child,
        ),
        // Sous les doigts de personne : le glissement qui referme la feuille
        // est déjà pris par la route, sur toute sa surface.
        const Align(alignment: Alignment.topCenter, child: IgnorePointer(child: SheetHandle())),
      ],
    );
  }
}

/// En-tête standard d'une sheet : titre centré, action à droite optionnelle.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.trailing, this.leading});

  final String title;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, Space.md),
      child: Row(
        children: [
          SizedBox(width: 64, child: Align(alignment: Alignment.centerLeft, child: leading)),
          Expanded(child: Text(title, style: context.text.title3, textAlign: TextAlign.center)),
          SizedBox(width: 64, child: Align(alignment: Alignment.centerRight, child: trailing)),
        ],
      ),
    );
  }
}

/// Rend à une feuille les marges que le système réserve sur les côtés.
///
/// `CupertinoSheetRoute` **remplace** la marge de son contenu par
/// `EdgeInsets.only(top: 15)` — celle de sa poignée. Tout ce que le système
/// réservait sur les côtés disparaît donc, et un `SafeArea` posé dans la
/// feuille n'écarte plus rien. Sur un téléphone ordinaire cela ne se voit pas ;
/// sur l'iPhone Duo, la bande de la caméra occupe quatre-vingt-quatre points
/// d'un bord, et le contenu passait dessous.
///
/// On relit donc les marges à la source — la vue —, et on garde la plus
/// grande des deux de chaque côté. Seulement les côtés : le haut et le bas
/// d'une feuille sont sa propre affaire, et les lui rendre la décalerait.
///
/// Et la feuille s'écarte **pour de bon**, au lieu de se contenter de rentrer
/// son contenu : c'est sa surface elle-même qui s'arrête avant la bande,
/// comme le font les autres fenêtres de l'application. Une feuille dont le
/// fond passait sous l'heure se voyait tout de suite, même avec un contenu
/// bien rangé. Le `MediaQuery` rendu aux enfants repart donc à zéro de ces
/// côtés-là : la marge a déjà été prise, la reprendre la compterait deux fois.
class _MargesLaterales extends StatelessWidget {
  const _MargesLaterales({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final heritee = MediaQuery.of(context);
    final vue = MediaQueryData.fromView(View.of(context));
    final marges = heritee.padding;
    final gauche = math.max(marges.left, vue.padding.left);
    final droite = math.max(marges.right, vue.padding.right);
    if (gauche == 0 && droite == 0) return child;
    return Padding(
      padding: EdgeInsets.only(left: gauche, right: droite),
      child: MediaQuery(
        data: heritee.copyWith(padding: marges.copyWith(left: 0, right: 0)),
        child: child,
      ),
    );
  }
}
