import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/connectivity.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/sharing/garden_collaboration.dart';
import '../application/garden_deletion.dart';
import '../application/membership_providers.dart';
import 'gardens_screen.dart' show gardenLabel, gardenSummary;

/// Les jardins que le compte connaît déjà, proposés au retour d'une connexion.
///
/// Réinstaller l'application crée un jardin neuf sur l'appareil ; les plantes,
/// elles, sont restées dans celui d'avant, sous le compte. Sans ce choix, il
/// faudrait savoir aller le rouvrir dans Mes jardins, et le jardin neuf
/// resterait là, vide, à côté du vrai.
///
/// Rien ne s'ouvre quand il n'y a rien à proposer : derrière une première
/// connexion, il n'y a aucun jardin.
Future<void> proposeExistingGardens(BuildContext context, WidgetRef ref) async {
  final service = ref.read(collaborationServiceProvider);
  final user = ref.read(authRepositoryProvider).currentUser;
  if (!service.isAvailable || user == null || user.isLocal) return;
  final device = ref.read(preferencesServiceProvider).gardenId;
  final List<GardenAccess> gardens;
  try {
    gardens = (await ref.online(service.gardens)).where((g) => g.id != device).toList();
  } catch (_) {
    // Pas de liste, pas de choix : l'application s'ouvre sur le jardin de
    // l'appareil, et Mes jardins reste là pour le reste.
    return;
  }
  if (gardens.isEmpty || !context.mounted) return;
  final chosen = await showFloraSheet<GardenAccess>(context, scrollable: true, builder: (_) => _OpenGardenSheet(gardens: gardens));
  if (chosen == null || !context.mounted) return;
  await _open(context, ref, chosen);
}

/// Ouvre le jardin choisi, et efface celui que l'installation venait de créer
/// quand il est vide et que le choix nous appartient : c'est lui, sinon, qui
/// resterait en double dans Mes jardins, sans rien dedans.
Future<void> _open(BuildContext context, WidgetRef ref, GardenAccess garden) async {
  final l10n = context.l10n;
  final label = gardenLabel(context, garden.name, isMine: garden.isMine);
  final device = ref.read(preferencesServiceProvider).gardenId;
  await ref.read(activeGardenProvider.notifier).select(garden.id);
  Haptics.success();
  ref.read(toastProvider.notifier).show(ToastData(message: l10n.gardenOpened(label), emoji: garden.isMine ? '🏡' : '🤝'));
  ref.invalidate(myGardensProvider);
  // Un jardin partagé ne peut pas devenir celui de l'appareil : sa ligne
  // appartient à quelqu'un d'autre, et ne partirait pas d'ici.
  if (device == null || device == garden.id || !garden.isMine) return;
  if (!await gardenIsEmpty(ref.read(databaseProvider), device)) return;
  try {
    await deleteGarden(ref, gardenId: device, openInstead: garden.id, ownInstead: garden.id);
  } catch (e, st) {
    // Le jardin vide reste : il se supprime à la main depuis Mes jardins.
    ref.read(crashReporterProvider).report(e, st, context: 'adopt-garden');
  }
}

class _OpenGardenSheet extends StatelessWidget {
  const _OpenGardenSheet({required this.gardens});

  final List<GardenAccess> gardens;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.openGardenTitle),
          Text(l10n.openGardenHint, style: context.text.callout),
          const SizedBox(height: Space.md),
          FloraGroup(
            children: [
              for (final g in gardens)
                FloraListRow(
                  leading: Text(g.isMine ? '🏡' : '🤝', style: const TextStyle(fontSize: 18)),
                  title: gardenLabel(context, g.name, isMine: g.isMine),
                  subtitle: gardenSummary(context, g),
                  onTap: () => Navigator.of(context).pop(g),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          FloraButton(
            label: l10n.later,
            style: FloraButtonStyle.secondary,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
