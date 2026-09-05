import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const version = '0.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    // Le catalogue étendu ne se charge qu'à la demande : ici on affiche son
    // volume seulement s'il est déjà en mémoire, sans le charger pour ça.
    final species = ref.watch(speciesIndexProvider).value?.records.length;
    return FloraPage(
      title: l10n.about,
      child: Column(
        children: [
          const SizedBox(height: Space.xl),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.xlAll),
            alignment: Alignment.center,
            child: const Text('🌿', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: Space.md),
          Text(AppConfig.appName, style: context.text.title1),
          const SizedBox(height: 4),
          Text(l10n.version(version), style: context.text.caption),
          const SizedBox(height: Space.md),
          Text(l10n.aboutTagline, style: context.text.callout, textAlign: TextAlign.center),
          if (species != null) ...[
            const SizedBox(height: Space.xs),
            Text(l10n.aboutSpeciesCount('$species'), style: context.text.caption.copyWith(color: c.inkSecondary)),
          ],
          const SizedBox(height: Space.xl),
          SectionHeader(title: l10n.aboutSources, padding: const EdgeInsets.only(bottom: Space.sm)),
          FloraGroup(
            children: [
              _SourceRow(
                emoji: '📚',
                title: 'Wikidata',
                subtitle: l10n.aboutSourceWikidata,
                url: 'https://www.wikidata.org',
              ),
              _SourceRow(
                emoji: '🌍',
                title: 'GBIF',
                subtitle: l10n.aboutSourceGbif,
                url: 'https://www.gbif.org',
              ),
              _SourceRow(
                emoji: '🌤️',
                title: 'Open-Meteo',
                subtitle: l10n.aboutSourceOpenMeteo,
                url: 'https://open-meteo.com',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.emoji, required this.title, required this.subtitle, required this.url});

  final String emoji;
  final String title;
  final String subtitle;
  final String url;

  @override
  Widget build(BuildContext context) {
    return FloraListRow(
      leading: Text(emoji, style: const TextStyle(fontSize: 18)),
      title: title,
      subtitle: subtitle,
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }
}
