import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../actions/application/care_actions.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../application/plant_providers.dart';
import '../../attributes/presentation/bulk_attribute_sheet.dart';
import 'plant_tags_sheet.dart';
import '../../qr/application/label_pdf.dart';
import '../../qr/presentation/plant_qr_sheet.dart';

/// Barre flottante en mode sélection : « 6 sélectionnées · 💧 📍 🏷 🗑 ».
class SelectionBar extends ConsumerWidget {
  const SelectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final ids = ref.watch(selectionProvider).toList();
    final ctrl = ref.read(selectionProvider.notifier);

    Future<void> logKind(String typeKey) async {
      await ref.read(careActionsProvider).logMany(context, plantIds: ids, typeKey: typeKey);
      ctrl.clear();
    }

    Future<void> water() => logKind(CareKind.watering.key);

    Future<void> move() async {
      final choice = await showLocationPicker(context);
      if (choice == null) return;
      await ref.read(plantRepositoryProvider).moveToLocation(ids, choice.id);
      Haptics.success();
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.movedCount(ids.length), emoji: '📍'));
      ctrl.clear();
    }

    Future<void> tag() async {
      final tagId = await showTagPickerSheet(context);
      if (tagId == null) return;
      await ref.read(tagRepositoryProvider).addTagToPlants(ids, tagId);
      Haptics.success();
      ctrl.clear();
    }

    Future<void> labels() async {
      final repo = ref.read(plantRepositoryProvider);
      final data = <LabelData>[];
      for (final id in ids) {
        final p = await repo.getPlant(id);
        if (p != null) data.add(LabelData(plantId: p.id, name: p.name, species: p.speciesName, number: p.number));
      }
      if (!context.mounted) return;
      await shareLabels(context, data);
      ctrl.clear();
    }

    Future<void> setField() async {
      final applied = await showBulkAttributeSheet(context, plantIds: ids);
      if (applied != true) return;
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.bulkFieldApplied(ids.length), emoji: '🏷️'));
      ctrl.clear();
    }

    Future<void> archive() async {
      final ok = await showAdaptiveConfirm(context, title: l10n.archive, message: l10n.archivedCount(ids.length), confirmLabel: l10n.archive, cancelLabel: l10n.cancel, destructive: true);
      if (!ok) return;
      await ref.read(plantRepositoryProvider).archive(ids);
      Haptics.warning();
      ref.read(toastProvider.notifier).show(ToastData(
        message: l10n.archivedCount(ids.length),
        emoji: '🗂',
        undoLabel: l10n.undo,
        onUndo: () => ref.read(plantRepositoryProvider).restore(ids),
      ));
      ctrl.clear();
    }

    return Container(
      decoration: BoxDecoration(borderRadius: Radii.fullAll, boxShadow: Shadows.floating(c.isDark ? const Color(0x55000000) : c.shadow)),
      child: FrostedSurface(
        borderRadius: Radii.fullAll,
        opacity: 0.9,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: Space.xs),
          decoration: BoxDecoration(borderRadius: Radii.fullAll, border: Border.all(color: c.line.withValues(alpha: 0.7))),
          child: Row(
            children: [
              FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.cancel, onPressed: ctrl.clear, filled: false),
              Expanded(child: Text(l10n.selectedCount(ids.length), style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600))),
              _Action(emoji: '💧', label: l10n.verbWatering, onTap: water),
              _Action(emoji: '📍', label: l10n.move, onTap: move),
              _Action(emoji: '🏷️', label: l10n.addTag, onTap: tag),
              _Action(
                emoji: '···',
                label: l10n.moreOptions,
                onTap: () => showAdaptiveActionSheet(
                  context,
                  cancelLabel: l10n.cancel,
                  actions: [
                    SheetAction(label: l10n.verbFertilizing, icon: CupertinoIcons.drop_triangle, onPressed: () => logKind(CareKind.fertilizing.key)),
                    SheetAction(label: l10n.verbRepotting, icon: CupertinoIcons.arrow_2_squarepath, onPressed: () => logKind(CareKind.repotting.key)),
                    SheetAction(label: l10n.bulkSetField, icon: CupertinoIcons.tag, onPressed: setField),
                    SheetAction(label: l10n.labels, icon: CupertinoIcons.qrcode, onPressed: labels),
                    SheetAction(label: l10n.archive, icon: CupertinoIcons.archivebox, destructive: true, onPressed: archive),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.emoji, required this.label, required this.onTap});

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      semanticLabel: label,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(color: context.colors.surfaceMuted, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 18, height: 1)),
      ),
    );
  }
}
