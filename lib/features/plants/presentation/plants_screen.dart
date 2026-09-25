import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../account/application/membership_providers.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../application/plant_providers.dart';
import 'create_plant_flow.dart';
import 'plant_card.dart';
import 'plant_filter_sheet.dart';
import 'selection_bar.dart';

/// La collection : recherche, grille / liste, filtres discrets, multi-sélection.
class PlantsScreen extends ConsumerStatefulWidget {
  const PlantsScreen({super.key});

  @override
  ConsumerState<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends ConsumerState<PlantsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(PlantSummary s) {
    final selection = ref.read(selectionProvider.notifier);
    if (ref.read(selectionProvider).isNotEmpty) {
      selection.toggle(s.plant.id);
    } else {
      context.push(Routes.plant(s.plant.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final plants = ref.watch(filteredPlantsProvider);
    final filter = ref.watch(plantFilterProvider);
    final grid = ref.watch(preferencesProvider).gridView;
    final selection = ref.watch(selectionProvider);
    final selecting = selection.isNotEmpty;
    final total = ref.watch(activePlantCountProvider).value ?? 0;

    final searchField = isCupertino(context)
        ? CupertinoSearchTextField(
            controller: _search,
            placeholder: l10n.searchPlants,
            // Posé sur la tête verte : un champ de verre, encre blanche.
            backgroundColor: OnBrand.glass,
            style: context.text.body.copyWith(color: c.onBrand),
            placeholderStyle: context.text.body.copyWith(color: c.onBrand.withValues(alpha: 0.8)),
            itemColor: c.onBrand,
            onChanged: ref.read(plantFilterProvider.notifier).setQuery,
          )
        : FloraTextField(
            controller: _search,
            hint: l10n.searchPlants,
            prefix: Icon(CupertinoIcons.search, size: 20, color: c.inkTertiary),
            onChanged: ref.read(plantFilterProvider.notifier).setQuery,
            textCapitalization: TextCapitalization.none,
          );

    final list = plants.value ?? const <PlantSummary>[];
    Widget item(PlantSummary s) => grid
        ? PlantGridCard(
            key: ValueKey(s.plant.id),
            summary: s,
            caption: sortCaption(context, s, filter.sort),
            selected: selection.contains(s.plant.id),
            selecting: selecting,
            onTap: () => _open(s),
            onLongPress: () => ref.read(selectionProvider.notifier).start(s.plant.id),
          )
        : PlantListRow(
            key: ValueKey(s.plant.id),
            summary: s,
            caption: sortCaption(context, s, filter.sort),
            selected: selection.contains(s.plant.id),
            selecting: selecting,
            onTap: () => _open(s),
            onLongPress: () => ref.read(selectionProvider.notifier).start(s.plant.id),
          );

    return Stack(
      children: [
        LargeTitlePage(
          title: l10n.plantsTitle,
          searchField: searchField,
          brand: true,
          hero: total == 0
              ? null
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: HeroNumber(
                        value: '$total',
                        label: l10n.plantCount(total).replaceFirst(RegExp(r'^\d+\s*'), ''),
                        size: 104,
                      ),
                    ),
                    const ExcludeSemantics(child: Image(image: AssetImage('assets/onboarding/collection_ronde.webp'), width: 112)),
                  ],
                ),
          // Une liste, pas une `Row` : le haut de page les met côte à côte,
          // et le menu debout du pliable les reprend en colonne.
          actions: [
            FloraIconButton(icon: CupertinoIcons.qrcode_viewfinder, semanticLabel: l10n.scan, onPressed: () => context.push(Routes.scan)),
            FloraIconButton(
              icon: filter.hasActiveFilters ? CupertinoIcons.line_horizontal_3_decrease_circle_fill : CupertinoIcons.line_horizontal_3_decrease,
              semanticLabel: l10n.filters,
              color: filter.hasActiveFilters ? c.sage : null,
              onPressed: () => showPlantFilterSheet(context),
            ),
            // « Trouver une plante » vit à côté du « + » : c'est ici qu'on
            // vient quand on veut une plante de plus, en sachant laquelle
            // ou non.
            FloraIconButton(icon: CupertinoIcons.lightbulb, semanticLabel: l10n.finderTitle, onPressed: () => context.push(Routes.finder)),
            if (ref.watch(canEditProvider))
              FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.addPlant, onPressed: () => startCreatePlantFlow(context, ref)),
          ],
          slivers: [
            if (plants.hasValue && list.isEmpty)
              SliverCentered(
                child: total == 0
                    ? EmptyState(emoji: '🪴', title: l10n.emptyPlantsTitle, subtitle: l10n.emptyPlantsSubtitle, actionLabel: l10n.addPlant, onAction: () => startCreatePlantFlow(context, ref), secondaryLabel: l10n.finderTitle, onSecondary: () => context.push(Routes.finder))
                    : EmptyState(emoji: '🔍', title: l10n.noResultsTitle, subtitle: l10n.noResultsSubtitle, compact: true),
              )
            else if (grid)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.xs, Space.page, 0),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, mainAxisSpacing: Space.sm, crossAxisSpacing: Space.sm, childAspectRatio: 0.72),
                  itemCount: list.length,
                  itemBuilder: (context, i) => item(list[i]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.xs, Space.page, 0),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
                  itemBuilder: (context, i) => item(list[i]),
                ),
              ),
          ],
        ),
        Positioned(
          // Les marges du système s'ajoutent aux nôtres, bord par bord : sur
          // un pliable, la bande de la caméra passe sur un côté.
          left: Space.xl + MediaQuery.paddingOf(context).left,
          right: Space.xl + MediaQuery.paddingOf(context).right,
          // Sous extendBody, le padding bas du body correspond déjà à la hauteur de la tab bar.
          bottom: MediaQuery.paddingOf(context).bottom + Space.sm,
          child: AnimatedSwitcher(
            duration: Motion.of(context, Motion.emphasis),
            switchInCurve: Motion.spring,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(anim), child: child),
            ),
            child: selecting ? const SelectionBar() : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// Ce que le tri regarde, écrit sous le nom : la date du dernier arrosage
/// quand on trie par dernier arrosage, l'état quand on trie par santé. Les
/// autres tris laissent la carte telle quelle.
String? sortCaption(BuildContext context, PlantSummary s, PlantSort sort) {
  final l10n = context.l10n;
  String? dated(CareKind kind, DateTime? at) => at == null ? null : '${kind.emoji} ${l10n.kindName(kind.key)} · ${Dates.day(context, at)}';
  return switch (sort) {
    PlantSort.lastWatered => dated(CareKind.watering, s.lastWateredAt),
    PlantSort.lastFertilized => dated(CareKind.fertilizing, s.lastFertilizedAt),
    PlantSort.lastRepotted => dated(CareKind.repotting, s.lastRepottedAt),
    PlantSort.health => l10n.healthLabel(s.plant),
    PlantSort.acquired => s.plant.acquiredAt == null ? null : l10n.sinceDate(Dates.monthYear(context, s.plant.acquiredAt!)),
    _ => null,
  };
}
