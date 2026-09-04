import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
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
            backgroundColor: c.surfaceMuted,
            style: context.text.body,
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
            selected: selection.contains(s.plant.id),
            selecting: selecting,
            onTap: () => _open(s),
            onLongPress: () => ref.read(selectionProvider.notifier).start(s.plant.id),
          )
        : PlantListRow(
            key: ValueKey(s.plant.id),
            summary: s,
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloraIconButton(icon: CupertinoIcons.qrcode_viewfinder, semanticLabel: l10n.scan, onPressed: () => context.push(Routes.scan)),
              const SizedBox(width: Space.xs),
              FloraIconButton(
                icon: filter.hasActiveFilters ? CupertinoIcons.line_horizontal_3_decrease_circle_fill : CupertinoIcons.line_horizontal_3_decrease,
                semanticLabel: l10n.filters,
                color: filter.hasActiveFilters ? c.sage : null,
                onPressed: () => showPlantFilterSheet(context),
              ),
              const SizedBox(width: Space.xs),
              FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.addPlant, onPressed: () => startCreatePlantFlow(context, ref)),
            ],
          ),
          slivers: [
            if (plants.hasValue && list.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: total == 0
                      ? EmptyState(emoji: '🪴', title: l10n.emptyPlantsTitle, subtitle: l10n.emptyPlantsSubtitle, actionLabel: l10n.addPlant, onAction: () => startCreatePlantFlow(context, ref))
                      : EmptyState(emoji: '🔍', title: l10n.noResultsTitle, subtitle: l10n.noResultsSubtitle, compact: true),
                ),
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
          left: Space.xl,
          right: Space.xl,
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
