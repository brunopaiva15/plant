import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../application/plant_providers.dart';

/// Résultat du sélecteur : `id == null` signifie « sans plante ».
class PlantChoice {
  const PlantChoice(this.id);

  final String? id;
}

/// Sheet de choix d'une plante (recherche instantanée).
Future<PlantChoice?> showPlantPicker(BuildContext context, {String? selectedId, bool allowNone = true}) =>
    showFloraSheet<PlantChoice>(context, scrollable: true, builder: (_) => _PlantPickerBody(selectedId: selectedId, allowNone: allowNone));

class _PlantPickerBody extends ConsumerStatefulWidget {
  const _PlantPickerBody({required this.selectedId, required this.allowNone});

  final String? selectedId;
  final bool allowNone;

  @override
  ConsumerState<_PlantPickerBody> createState() => _PlantPickerBodyState();
}

class _PlantPickerBodyState extends ConsumerState<_PlantPickerBody> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final q = _search.text.trim().toLowerCase();
    final plants = (ref.watch(plantSummariesProvider(const PlantFilter())).value ?? const <PlantSummary>[])
        .where((p) => q.isEmpty || p.plant.name.toLowerCase().contains(q) || (p.plant.speciesName?.toLowerCase().contains(q) ?? false) || (p.locationName?.toLowerCase().contains(q) ?? false))
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.choosePlant),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
          child: isCupertino(context)
              ? CupertinoSearchTextField(controller: _search, placeholder: l10n.searchPlants, onChanged: (_) => setState(() {}))
              : FloraTextField(controller: _search, hint: l10n.searchPlants, onChanged: (_) => setState(() {}), prefix: Icon(CupertinoIcons.search, size: 20, color: c.inkTertiary)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
          child: FloraGroup(
            children: [
              if (widget.allowNone && q.isEmpty)
                FloraListRow(
                  leading: const Text('—', style: TextStyle(fontSize: 18)),
                  title: l10n.taskNoPlant,
                  chevron: false,
                  trailing: widget.selectedId == null ? Icon(CupertinoIcons.checkmark_alt, size: 18, color: c.sage) : null,
                  onTap: () => Navigator.of(context).pop(const PlantChoice(null)),
                ),
              for (final p in plants)
                FloraListRow(
                  leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 32, height: 32, child: PlantImage(relativePath: p.thumbPath, cacheWidth: 96))),
                  title: p.plant.name,
                  subtitle: p.locationName,
                  dense: true,
                  chevron: false,
                  trailing: widget.selectedId == p.plant.id ? Icon(CupertinoIcons.checkmark_alt, size: 18, color: c.sage) : null,
                  onTap: () => Navigator.of(context).pop(PlantChoice(p.plant.id)),
                ),
              if (plants.isEmpty) Padding(padding: const EdgeInsets.all(Space.md), child: Text(l10n.noResultsTitle, style: context.text.caption, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ],
    );
  }
}
