import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../backup_sections.dart';
import '../import_service.dart';

String sectionLabel(AppLocalizations l10n, BackupSection s) => switch (s) {
      BackupSection.garden => l10n.sectionGarden,
      BackupSection.plants => l10n.sectionPlants,
      BackupSection.photos => l10n.sectionPhotos,
      BackupSection.care => l10n.sectionCare,
      BackupSection.inventory => l10n.sectionInventory,
      BackupSection.tasks => l10n.sectionTasks,
      BackupSection.calendar => l10n.sectionCalendar,
    };

String sectionEmoji(BackupSection s) => switch (s) {
      BackupSection.garden => '🏡',
      BackupSection.plants => '🪴',
      BackupSection.photos => '📷',
      BackupSection.care => '💧',
      BackupSection.inventory => '🧰',
      BackupSection.tasks => '📋',
      BackupSection.calendar => '🗓️',
    };

/// Sauvegarde et restauration, section par section.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _selected = {...BackupSection.values};
  bool _busy = false;

  /// Sections finalement écrites : celles cochées, plus leurs dépendances.
  Set<BackupSection> get _effective => withDependencies(_selected);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final effective = _effective;
    return FloraPage(
      title: l10n.backupTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.backupExplain, style: context.text.callout.copyWith(color: c.inkSecondary)),
          const SizedBox(height: Space.lg),
          FloraGroup(
            header: l10n.backupWhatToExport,
            children: [
              for (final section in BackupSection.values)
                FloraListRow(
                  leading: Text(sectionEmoji(section), style: const TextStyle(fontSize: 18)),
                  title: sectionLabel(l10n, section),
                  trailing: AdaptiveSwitch(
                    value: effective.contains(section),
                    // Une section entraînée par une autre reste cochée : la
                    // décocher laisserait des lignes sans leur parent.
                    onChanged: (on) => setState(() => on ? _selected.add(section) : _selected.remove(section)),
                  ),
                  chevron: false,
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          FloraButton(
            label: l10n.exportData,
            icon: CupertinoIcons.square_arrow_up,
            expand: true,
            loading: _busy,
            onPressed: _selected.isEmpty ? null : _export,
          ),
          const SizedBox(height: Space.xl),
          SectionHeader(title: l10n.importBackup, padding: const EdgeInsets.only(bottom: Space.sm)),
          Text(l10n.importConfirm, style: context.text.caption.copyWith(color: c.inkSecondary)),
          const SizedBox(height: Space.sm),
          FloraButton(
            label: l10n.chooseBackupFile,
            icon: CupertinoIcons.square_arrow_down,
            style: FloraButtonStyle.secondary,
            expand: true,
            loading: _busy,
            onPressed: _import,
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    final l10n = context.l10n;
    final toast = ref.read(toastProvider.notifier);
    setState(() => _busy = true);
    toast.show(ToastData(message: l10n.exporting, emoji: '⏳'));
    try {
      final file = await ref.read(exportServiceProvider).buildZip(sections: _effective);
      toast.dismiss();
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: l10n.exportData));
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'export');
      toast.show(ToastData(message: l10n.exportError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final l10n = context.l10n;
    final toast = ref.read(toastProvider.notifier);
    final picked = await FilePicker.pickFile(dialogTitle: l10n.chooseBackupFile);
    final path = picked?.path;
    if (path == null || !mounted) return;

    final service = ref.read(importServiceProvider);
    setState(() => _busy = true);
    try {
      final file = File(path);
      final manifest = await service.inspect(file);
      if (!mounted) return;
      final ok = await showAdaptiveConfirm(
        context,
        title: manifest.exportedAt == null ? l10n.importBackup : l10n.backupFrom(Dates.dayYear(context, manifest.exportedAt!)),
        message: '${l10n.backupContains(manifest.totalRows)}\n${l10n.importConfirm}',
        confirmLabel: l10n.importBackup,
        cancelLabel: l10n.cancel,
      );
      if (!ok || !mounted) return;

      toast.show(ToastData(message: l10n.importing, emoji: '⏳'));
      final report = await service.import(file, sections: _effective);
      toast.dismiss();
      Haptics.success();
      if (!mounted) return;
      final parts = [
        l10n.importDone(report.totalImported),
        if (report.totalSkipped > 0) l10n.importSkipped(report.totalSkipped),
      ];
      toast.show(ToastData(message: parts.join(' · '), emoji: '✅'));
    } on ImportException catch (e) {
      toast.show(ToastData(
        message: switch (e.reason) {
          ImportFailure.notAZip || ImportFailure.noData => l10n.importErrorNotAZip,
          ImportFailure.wrongApp => l10n.importErrorWrongApp,
          ImportFailure.tooRecent => l10n.importErrorTooRecent,
        },
        emoji: '!',
      ));
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'import');
      toast.show(ToastData(message: l10n.importErrorGeneric, emoji: '!'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
