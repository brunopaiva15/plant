import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/haptics.dart';
import '../core/l10n/l10n.dart';
import '../design_system/design_system.dart';
import '../features/account/presentation/join_garden_sheet.dart';
import '../features/inventory/presentation/inventory_item_sheet.dart';
import '../features/qr/application/plant_links.dart';
import 'providers.dart';
import 'router.dart';

/// Ouvre un lien `flora://…` livré par le système : QR scanné depuis
/// l'appareil photo, étiquette partagée, plus tard tag NFC.
///
/// La cible s'ouvre par-dessus l'accueil plutôt qu'à sa place — sinon le
/// bouton retour de la fiche n'aurait nulle part où revenir au démarrage à
/// froid. Et comme le scanner de l'application, on vérifie que la cible
/// existe encore : une étiquette survit à la plante qu'elle désignait.
Future<void> openFloraLink(Ref ref, GoRouter router, FloraLink link) async {
  switch (link.kind) {
    case FloraLinkKind.plant:
      final plant = await ref.read(plantRepositoryProvider).getPlant(link.id);
      if (plant == null) return _unknown(ref);
      Haptics.success();
      router.push(Routes.plant(link.id));
    case FloraLinkKind.item:
      final item = await ref.read(inventoryRepositoryProvider).get(link.id);
      if (item == null) return _unknown(ref);
      final context = rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      Haptics.success();
      await showInventoryItemSheet(context, existing: item);
    case FloraLinkKind.join:
      // Invitation reçue par lien : la feuille dit qui invite et dans quel
      // jardin avant que l'utilisateur accepte quoi que ce soit.
      final inviteContext = rootNavigatorKey.currentContext;
      if (inviteContext == null || !inviteContext.mounted) return;
      await showJoinGardenSheet(inviteContext, code: link.id);
  }
}

void _unknown(Ref ref) {
  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  Haptics.warning();
  ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.unknownQr, emoji: '!'));
}
