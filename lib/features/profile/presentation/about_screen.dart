import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// D'où viennent les données de l'application.
///
/// L'écran ne parle plus de l'application elle-même : son nom, sa version et
/// son éditeur sont au pied des réglages, là où on les cherche. Ici il n'y a
/// que les sources, et ce qu'elles pèsent.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Le catalogue étendu ne se charge qu'à la demande : ici on affiche son
    // volume seulement s'il est déjà en mémoire, sans le charger pour ça.
    final species = ref.watch(speciesIndexProvider).value?.records.length;
    return FloraPage(
      title: l10n.aboutSources,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FloraGroup(
            footer: species == null ? null : l10n.aboutSpeciesCount('$species'),
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
