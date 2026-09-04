import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../archive/presentation/archive_screen.dart' show archiveTitle, editArchiveName;
import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Profil : prénom, apparence, notifications, données, à propos.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final prefs = ref.watch(preferencesProvider);
    final user = ref.watch(currentUserProvider).value;
    final count = ref.watch(activePlantCountProvider).value ?? 0;
    final themeLabel = switch (prefs.themeMode) { ThemeMode.system => l10n.themeSystem, ThemeMode.light => l10n.themeLight, ThemeMode.dark => l10n.themeDark };
    final languageLabel = prefs.locale == null ? l10n.languageSystem : _languageName(prefs.locale!.languageCode);

    Widget value(String text) => Text(text, style: context.text.callout);

    return LargeTitlePage(
      title: l10n.profileTitle,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          sliver: SliverList.list(
            children: [
              FloraCard(
                onTap: () => _editName(context, ref, prefs.displayName),
                child: Row(
                  children: [
                    FloraAvatar(name: prefs.displayName, size: 52),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(prefs.displayName.isEmpty ? l10n.yourName : prefs.displayName, style: context.text.title3),
                          const SizedBox(height: 2),
                          Text(l10n.plantCount(count), style: context.text.caption),
                        ],
                      ),
                    ),
                    Icon(CupertinoIcons.pencil, size: 18, color: c.inkTertiary),
                  ],
                ),
              ),
              const SizedBox(height: Space.xl),
              FloraGroup(
                children: [
                  FloraListRow(leading: const Text('🎨', style: TextStyle(fontSize: 18)), title: l10n.appearance, trailing: value(themeLabel), chevron: true, onTap: () => context.push(Routes.appearance)),
                  FloraListRow(leading: const Text('🔔', style: TextStyle(fontSize: 18)), title: l10n.notifications, trailing: value(prefs.notificationsEnabled ? _time(context, prefs.notificationTime) : l10n.none), chevron: true, onTap: () => context.push(Routes.notifications)),
                  FloraListRow(
                    leading: const Text('📏', style: TextStyle(fontSize: 18)),
                    title: l10n.units,
                    trailing: value(prefs.metricUnits ? l10n.metric : l10n.imperial),
                    chevron: true,
                    onTap: () => showAdaptiveActionSheet(
                      context,
                      title: l10n.units,
                      cancelLabel: l10n.cancel,
                      actions: [
                        SheetAction(label: l10n.metric, onPressed: () => ref.read(preferencesProvider.notifier).setMetricUnits(true)),
                        SheetAction(label: l10n.imperial, onPressed: () => ref.read(preferencesProvider.notifier).setMetricUnits(false)),
                      ],
                    ),
                  ),
                  FloraListRow(leading: const Text('🌍', style: TextStyle(fontSize: 18)), title: l10n.language, trailing: value(languageLabel), chevron: true, onTap: () => _pickLanguage(context, ref)),
                  FloraListRow(leading: const Text('🌤️', style: TextStyle(fontSize: 18)), title: l10n.weather, trailing: value(prefs.weatherPlace?.name.split(',').first ?? l10n.none), chevron: true, onTap: () => context.push(Routes.weather)),
                ],
              ),
              const SizedBox(height: Space.lg),
              FloraGroup(
                children: [
                  FloraListRow(leading: const Text('✨', style: TextStyle(fontSize: 18)), title: l10n.actionTypes, onTap: () => context.push(Routes.actionTypes)),
                  FloraListRow(
                    leading: const Text('🔬', style: TextStyle(fontSize: 18)),
                    title: l10n.identificationSettings,
                    trailing: value(ref.watch(plantIdentifierProvider).isConfigured ? l10n.identificationEnabled : l10n.identificationDisabled),
                    chevron: true,
                    onTap: () => context.push(Routes.identification),
                  ),
                  FloraListRow(
                    leading: const Text('🩺', style: TextStyle(fontSize: 18)),
                    title: l10n.diagnosisSettings,
                    trailing: value(ref.watch(plantDiagnoserProvider).isConfigured ? l10n.diagnosisEnabled : l10n.identificationDisabled),
                    chevron: true,
                    onTap: () => context.push(Routes.diagnosis),
                  ),
                  FloraListRow(leading: const Text('🏷️', style: TextStyle(fontSize: 18)), title: l10n.tags, onTap: () => context.push(Routes.tags)),
                  FloraListRow(leading: const Text('🗒️', style: TextStyle(fontSize: 18)), title: l10n.fieldTemplates, onTap: () => context.push(Routes.fieldTemplates)),
                  FloraListRow(leading: const Text('🔗', style: TextStyle(fontSize: 18)), title: l10n.sharedLinks, onTap: () => context.push(Routes.sharedLinks)),
                  FloraListRow(
                    leading: const Text('🍂', style: TextStyle(fontSize: 18)),
                    title: archiveTitle(context, prefs.archiveName),
                    onTap: () => context.push(Routes.archive),
                  ),
                  // Sans valeur en regard : la ligne au-dessus porte déjà le
                  // nom, et le titre y perdrait sa fin.
                  FloraListRow(
                    leading: const Text('✏️', style: TextStyle(fontSize: 18)),
                    title: l10n.archiveNameTitle,
                    chevron: true,
                    onTap: () => editArchiveName(context, ref),
                  ),
                  FloraListRow(leading: const Text('📜', style: TextStyle(fontSize: 18)), title: l10n.activityLogTitle, onTap: () => context.push(Routes.activityLog)),
                ],
              ),
              const SizedBox(height: Space.lg),
              FloraGroup(
                header: l10n.dataSection,
                footer: l10n.exportHint,
                children: [
                  FloraListRow(leading: Icon(CupertinoIcons.square_arrow_up, size: 20, color: c.inkSecondary), title: l10n.exportData, onTap: () => _export(context, ref)),
                  FloraListRow(leading: const Text('💾', style: TextStyle(fontSize: 18)), title: l10n.backupTitle, onTap: () => context.push(Routes.backup)),
                  FloraListRow(leading: const Text('🔌', style: TextStyle(fontSize: 18)), title: l10n.apiTitle, onTap: () => context.push(Routes.api)),
                ],
              ),
              const SizedBox(height: Space.lg),
              FloraGroup(
                footer: ref.watch(authRepositoryProvider).supportsRemote ? l10n.signInHint : l10n.localAccountHint,
                children: [
                  FloraListRow(
                    leading: Icon(user != null && !user.isLocal ? CupertinoIcons.person_crop_circle_fill : CupertinoIcons.lock, size: 20, color: user != null && !user.isLocal ? c.sage : c.inkSecondary),
                    title: l10n.account,
                    subtitle: user != null && !user.isLocal ? (user.email ?? l10n.signedInAs) : l10n.localAccount,
                    onTap: () => context.push(Routes.account),
                  ),
                  FloraListRow(
                    leading: Icon(CupertinoIcons.sparkles, size: 20, color: c.sun),
                    title: l10n.premium,
                    subtitle: l10n.premiumPlantCount(count, AppConfig.freePlantLimit),
                    onTap: () => showAdaptiveConfirm(context, title: l10n.premium, message: l10n.premiumBody, confirmLabel: l10n.ok, cancelLabel: l10n.close),
                  ),
                  FloraListRow(leading: const Text('✨', style: TextStyle(fontSize: 18)), title: l10n.replayOnboarding, onTap: () => context.push(Routes.onboarding)),
                  FloraListRow(leading: Icon(CupertinoIcons.info, size: 20, color: c.inkSecondary), title: l10n.about, onTap: () => context.push(Routes.about)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = ref.read(toastProvider.notifier);
    toast.show(ToastData(message: l10n.exporting, emoji: '⏳'));
    try {
      final file = await ref.read(exportServiceProvider).buildZip();
      toast.dismiss();
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: l10n.exportData));
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'export');
      toast.show(ToastData(message: l10n.exportError, emoji: '!'));
    }
  }

  String _time(BuildContext context, TimeOfDay t) => MaterialLocalizations.of(context).formatTimeOfDay(t, alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));

  String _languageName(String code) => switch (code) { 'fr' => 'Français', 'de' => 'Deutsch', 'it' => 'Italiano', _ => 'English' };

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: current);
    await showFloraSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: l10n.yourName),
            FloraTextField(controller: controller, hint: l10n.yourNameHint, autofocus: true, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.done, onSubmitted: (_) => Navigator.of(ctx).pop()),
            const SizedBox(height: Space.md),
            FloraButton(label: l10n.save, expand: true, onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      ),
    );
    await ref.read(preferencesProvider.notifier).setDisplayName(controller.text);
    controller.dispose();
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    await showAdaptiveActionSheet(
      context,
      title: l10n.language,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(label: l10n.languageSystem, onPressed: () => ref.read(preferencesProvider.notifier).setLocale(null)),
        for (final locale in AppLocalizations.supportedLocales)
          SheetAction(label: _languageName(locale.languageCode), onPressed: () => ref.read(preferencesProvider.notifier).setLocale(locale)),
      ],
    );
  }
}
