import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/species/species_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../../domain/repositories/repositories.dart';
import '../../plants/application/plant_providers.dart';

/// Les deux sections que la page d'un problème et celle d'un phénomène
/// naturel ont en commun : les hôtes que la base cite, et les plantes du
/// jardin qui en font partie.
///
/// Les deux bases déclarent leurs hôtes de la même façon — une espèce, un
/// genre, une famille, ou l'embranchement entier — et la même règle dit si
/// une plante en est ([hostsCover]). Les sections ne savent donc pas de quelle
/// base elles parlent, et n'ont pas à le savoir.

/// Les hôtes cités par la base, dans son ordre à elle.
class HostsSection extends StatelessWidget {
  const HostsSection({super.key, required this.hosts});

  final List<String> hosts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        Text(l10n.problemHosts, style: context.text.title3),
        const SizedBox(height: Space.sm),
        FloraGroup(
          footer: l10n.problemHostsNote,
          children: [for (final host in hosts) _HostRow(host: host)],
        ),
      ],
    );
  }
}

/// Un hôte : une espèce (deux mots), une famille (en -aceae), un genre, ou
/// l'embranchement entier.
///
/// Seule une espèce que l'un des deux catalogues connaît mène quelque part :
/// d'un genre ou d'une famille, il n'y a pas de fiche à ouvrir.
class _HostRow extends ConsumerWidget {
  const _HostRow({required this.host});

  final String host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (host == 'Tracheophyta') {
      return FloraListRow(
        leading: const Text('🌍', style: TextStyle(fontSize: 18)),
        title: l10n.problemHostsAll,
        dense: true,
        chevron: false,
      );
    }
    final lang = Localizations.localeOf(context).languageCode;
    final species = host.contains(' ');
    final curated = species ? SpeciesCatalog.find(host) : null;
    final record = species && curated == null ? ref.watch(speciesIndexProvider).value?.find(host) : null;
    // La fiche s'ouvre dès que l'un des deux catalogues connaît l'espèce. Le
    // nom courant, lui, ne paraît que dans la langue de l'application : le
    // titre porte déjà le nom scientifique.
    final known = curated != null || record != null;
    final common = curated?.vernacularName(lang) ?? record?.vernacularName(lang);
    return FloraListRow(
      leading: Text(species ? '🌿' : '🗂️', style: const TextStyle(fontSize: 18)),
      title: host,
      titleMaxLines: 2,
      subtitle: species ? common : (host.endsWith('aceae') ? l10n.speciesFamily : l10n.speciesGenus),
      dense: true,
      chevron: known,
      onTap: known ? () => context.push(Routes.encyclopediaSpecies(host)) : null,
    );
  }
}

/// Les plantes du jardin que la base range parmi les hôtes.
///
/// Absente des entrées universelles : y aligner toute la collection ne dirait
/// rien — un manque d'eau concerne tout le monde, la guttation aussi, et la
/// base le déclare ainsi.
class InGardenSection extends ConsumerWidget {
  const InGardenSection({super.key, required this.scope, required this.hosts});

  final ProblemScope scope;
  final List<String> hosts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scope == ProblemScope.general) return const SizedBox.shrink();
    final l10n = context.l10n;
    final familyOf = speciesFamilyLookup(ref);
    final plants = ref.watch(plantSummariesProvider(const PlantFilter())).value ?? const <PlantSummary>[];
    final concerned = [
      for (final s in plants)
        if (s.plant.speciesName != null && hostsCover(hosts, species: s.plant.speciesName, family: familyOf(s.plant.speciesName))) s,
    ];
    if (concerned.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        Text(l10n.problemInGarden, style: context.text.title3),
        const SizedBox(height: Space.sm),
        FloraGroup(
          children: [
            for (final s in concerned)
              FloraListRow(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 36, height: 36, child: PlantImage(relativePath: s.thumbPath, remoteUrl: s.thumbUrl, cacheWidth: 108)),
                ),
                leadingWidth: 36,
                title: s.plant.name,
                subtitle: s.plant.speciesName,
                dense: true,
                onTap: () => context.push(Routes.plant(s.plant.id)),
              ),
          ],
        ),
      ],
    );
  }
}
