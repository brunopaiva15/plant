import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../archive/presentation/archive_screen.dart' show archiveTitle, editArchiveName;
import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../account/application/membership_providers.dart';
import '../../account/presentation/gardens_screen.dart' show gardenLabel;
import '../../whats_new/application/release_notes.dart';
import '../../whats_new/presentation/whats_new_sheet.dart';

/// Profil : prénom, apparence, notifications, données, sources.
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
    // La dernière nouveauté livrée, relisible à volonté : elle ne s'ouvre
    // d'elle-même qu'une fois, au lancement qui suit la mise à jour.
    final latestNote = ref.watch(whatsNewProvider).latest(releaseNotes(l10n));

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
                  // L'export vit dans la sauvegarde, avec le choix des
                  // sections : deux portes vers le même ZIP n'en font qu'une.
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
                  if (user != null && !user.isLocal) const _GardensRow(),
                  FloraListRow(
                    leading: Icon(CupertinoIcons.heart_fill, size: 20, color: c.rose),
                    title: l10n.supportSettings,
                    subtitle: prefs.hasSupported ? l10n.supportAlready : l10n.supportFreeForever,
                    onTap: () => context.push(Routes.support),
                  ),
                  if (latestNote != null)
                    FloraListRow(
                      leading: Icon(CupertinoIcons.sparkles, size: 20, color: c.terracotta),
                      title: l10n.whatsNewTitle,
                      subtitle: latestNote.title,
                      onTap: () => showWhatsNew(context, latestNote),
                    ),
                  FloraListRow(leading: const Text('✨', style: TextStyle(fontSize: 18)), title: l10n.replayOnboarding, onTap: () => context.push(Routes.onboarding)),
                  FloraListRow(leading: Icon(CupertinoIcons.info, size: 20, color: c.inkSecondary), title: l10n.aboutSources, onTap: () => context.push(Routes.about)),
                ],
              ),
              const SizedBox(height: Space.xl),
              const _AppFooter(),
              const SizedBox(height: Space.lg),
            ],
          ),
        ),
      ],
    );
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

/// Le pied des réglages : qui édite l'application, où lire sa politique de
/// confidentialité, et quelle version tourne.
///
/// Tout en bas et sans le nom de l'application : on ne vient pas ici pour
/// apprendre comment elle s'appelle, mais pour retrouver un numéro de version
/// avant d'écrire au support.
class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final style = context.text.caption.copyWith(color: c.inkTertiary);
    return Column(
      children: [
        // L'année suit l'horloge de l'appareil : un millésime figé dans le
        // code se périme au premier janvier, sans que personne le voie.
        Text('© ${DateTime.now().year} ${AppConfig.publisher}', style: style),
        const SizedBox(height: Space.xs),
        Pressable(
          onTap: () => launchUrl(Uri.parse(AppConfig.privacyUrl), mode: LaunchMode.externalApplication),
          scale: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              l10n.privacyPolicy,
              style: context.text.caption.copyWith(color: c.sage, decoration: TextDecoration.underline, decorationColor: c.sage),
            ),
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(l10n.version('${AppConfig.version} (${AppConfig.build})'), style: style),
      ],
    );
  }
}

/// Le jardin ouvert, et le chemin vers les autres. N'apparaît qu'avec un
/// compte : sans lui, il n'y a qu'un jardin, celui de l'appareil.
class _GardensRow extends ConsumerWidget {
  const _GardensRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final role = ref.watch(currentRoleProvider);
    final subtitle = [
      gardenLabel(context, ref.watch(activeGardenNameProvider).value ?? '', isMine: role.canManageMembers),
      if (!role.canManageMembers) role.canEdit ? l10n.roleMember : l10n.roleViewer,
    ].join(' · ');
    return FloraListRow(
      leading: const Text('🏡', style: TextStyle(fontSize: 18)),
      title: l10n.gardensTitle,
      subtitle: subtitle,
      onTap: () => context.push(Routes.gardens),
    );
  }
}
