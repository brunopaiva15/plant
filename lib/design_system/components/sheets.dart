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
    builder: (ctx) => Padding(
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
  );
}

/// Sheet plein écran pour un flow (création de plante) : sur iOS, la sheet
/// native qui repousse l'écran précédent ; sur Android, un dialogue plein écran.
Future<T?> showFloraFlow<T>(BuildContext context, {required WidgetBuilder builder}) {
  Haptics.light();
  if (isCupertino(context)) {
    return showCupertinoSheet<T>(
      context: context,
      useNestedNavigation: true,
      scrollableBuilder: (ctx, _) => builder(ctx),
    );
  }
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(fullscreenDialog: true, builder: builder),
  );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

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
