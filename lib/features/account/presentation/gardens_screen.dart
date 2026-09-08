import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/db/database.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/sharing/garden_collaboration.dart';
import '../../attachments/presentation/attachments_section.dart' show showRenameSheet;
import '../application/membership_providers.dart';
import 'join_garden_sheet.dart';

/// Mes jardins : le sien, ceux qu'on lui a partagés, et de quoi en rejoindre
/// un nouveau. Ouvrir un jardin change tout ce que montre l'application —
/// plantes, emplacements, tâches, journal.
class GardensScreen extends ConsumerWidget {
  const GardensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final service = ref.watch(collaborationServiceProvider);
    final user = ref.watch(currentUserProvider).value;
    final signedIn = user != null && !user.isLocal;
    final current = ref.watch(gardenIdProvider);
    final gardens = ref.watch(myGardensProvider);

    return FloraPage(
      title: l10n.gardensTitle,
      trailing: signedIn
          ? FloraIconButton(
              icon: CupertinoIcons.arrow_2_circlepath,
              semanticLabel: l10n.retry,
              filled: false,
              onPressed: () => ref.invalidate(myGardensProvider),
            )
          : null,
      child: !service.isAvailable || !signedIn
          ? EmptyState(emoji: '🌱', title: l10n.collaborationNeedsAccount, subtitle: l10n.signInHint, actionLabel: l10n.signIn, onAction: () => context.push(Routes.account))
          : gardens.when(
              loading: () => const Padding(padding: EdgeInsets.all(Space.xxl), child: Center(child: AdaptiveProgress())),
              error: (_, _) => EmptyState(emoji: '📡', title: l10n.genericError, compact: true),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.gardensHint, style: context.text.callout),
                  const SizedBox(height: Space.lg),
                  FloraGroup(
                    children: [
                      for (final g in items)
                        FloraListRow(
                          leading: Text(g.isMine ? '🏡' : '🤝', style: const TextStyle(fontSize: 18)),
                          title: gardenLabel(context, g.name, isMine: g.isMine),
                          subtitle: _subtitle(context, g),
                          trailing: g.id == current
                              ? Icon(CupertinoIcons.checkmark_alt, size: 18, color: c.sage)
                              : FloraIconButton(
                                  icon: CupertinoIcons.ellipsis,
                                  semanticLabel: l10n.moreOptions,
                                  size: 32,
                                  filled: false,
                                  onPressed: () => _menu(context, ref, g),
                                ),
                          chevron: false,
                          onTap: g.id == current ? () => _menu(context, ref, g) : () => _open(context, ref, g),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  FloraButton(
                    label: l10n.joinGarden,
                    icon: CupertinoIcons.add,
                    style: FloraButtonStyle.secondary,
                    expand: true,
                    onPressed: () async {
                      if (await showJoinGardenSheet(context)) ref.invalidate(myGardensProvider);
                    },
                  ),
                  const SizedBox(height: Space.md),
                  Text(l10n.joinGardenHint, style: context.text.caption),
                  const SizedBox(height: Space.xl),
                  FloraGroup(
                    children: [
                      FloraListRow(
                        leading: Icon(CupertinoIcons.person_2, size: 20, color: c.inkSecondary),
                        title: l10n.membersTitle,
                        subtitle: l10n.shareGarden,
                        onTap: () => context.push(Routes.members),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  static String _subtitle(BuildContext context, GardenAccess garden) {
    final l10n = context.l10n;
    return [
      if (garden.isMine) l10n.gardenMine else l10n.gardenSharedBy(garden.ownerName.isEmpty ? l10n.someone : garden.ownerName),
      if (!garden.isMine && garden.role == GardenRole.viewer) l10n.roleViewer,
      l10n.plantCount(garden.plantCount),
      if (garden.isShared) l10n.memberCount(garden.memberCount),
    ].join(' · ');
  }

  Future<void> _open(BuildContext context, WidgetRef ref, GardenAccess garden) async {
    final message = context.l10n.gardenOpened(gardenLabel(context, garden.name, isMine: garden.isMine));
    await ref.read(activeGardenProvider.notifier).select(garden.id);
    Haptics.success();
    ref.read(toastProvider.notifier).show(ToastData(message: message, emoji: garden.isMine ? '🏡' : '🤝'));
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, GardenAccess garden) async {
    final l10n = context.l10n;
    final name = gardenLabel(context, garden.name, isMine: garden.isMine);
    await showAdaptiveActionSheet(
      context,
      title: name,
      cancelLabel: l10n.cancel,
      actions: [
        if (garden.isMine)
          SheetAction(
            label: l10n.renameGarden,
            icon: CupertinoIcons.pencil,
            onPressed: () => _rename(context, ref, garden),
          )
        else
          SheetAction(
            label: l10n.leaveGarden,
            icon: CupertinoIcons.square_arrow_left,
            destructive: true,
            onPressed: () => leaveGarden(context, ref, garden.id, name),
          ),
      ],
    );
  }

  /// Renommer son jardin : c'est ce nom que verront les invités.
  Future<void> _rename(BuildContext context, WidgetRef ref, GardenAccess garden) async {
    final l10n = context.l10n;
    final name = await showRenameSheet(
      context,
      title: l10n.renameGarden,
      hint: l10n.gardenNameHint,
      initial: garden.name == _defaultGardenName ? '' : garden.name,
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      await (db.update(db.gardens)..where((g) => g.id.equals(garden.id)))
          .write(GardensCompanion(name: Value(trimmed), updatedAt: Value(DateTime.now())));
      await db.enqueueSync('gardens', garden.id, 'upsert', const {});
    });
    Haptics.success();
    ref.invalidate(myGardensProvider);
  }
}

/// Nom interne du jardin créé au premier lancement : jamais choisi par
/// quelqu'un, donc jamais montré tel quel.
const _defaultGardenName = 'home';

/// Le nom du jardin tel qu'on l'affiche, avec un repli quand personne ne l'a
/// encore nommé.
String gardenLabel(BuildContext context, String name, {required bool isMine}) {
  final trimmed = name.trim();
  if (trimmed.isNotEmpty && trimmed != _defaultGardenName) return trimmed;
  return isMine ? context.l10n.gardenMine : context.l10n.gardenUnnamed;
}

/// Quitte un jardin partagé, après confirmation, et revient au sien.
Future<void> leaveGarden(BuildContext context, WidgetRef ref, String gardenId, String name) async {
  final l10n = context.l10n;
  final ok = await showAdaptiveConfirm(
    context,
    title: l10n.leaveGarden,
    message: l10n.leaveGardenConfirm(name),
    confirmLabel: l10n.leaveGarden,
    cancelLabel: l10n.cancel,
    destructive: true,
  );
  if (!ok) return;
  try {
    await ref.read(collaborationServiceProvider).leaveGarden(gardenId);
    if (ref.read(gardenIdProvider) == gardenId) await ref.read(activeGardenProvider.notifier).reset();
    ref.invalidate(myGardensProvider);
    Haptics.warning();
    if (context.mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.leftGarden(name), emoji: '👋'));
  } catch (e, st) {
    ref.read(crashReporterProvider).report(e, st, context: 'leave-garden');
    if (context.mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.genericError, emoji: '!'));
  }
}
