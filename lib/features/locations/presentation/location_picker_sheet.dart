import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import 'location_edit_sheet.dart';

/// Résultat du sélecteur : `id == null` signifie « sans emplacement ».
class LocationChoice {
  const LocationChoice(this.id);

  final String? id;
}

/// Sheet de choix d'emplacement (chips), avec création inline.
Future<LocationChoice?> showLocationPicker(BuildContext context, {String? selectedId, bool allowNone = true}) {
  return showFloraSheet<LocationChoice>(
    context,
    scrollable: true,
    builder: (ctx) => _LocationPickerBody(selectedId: selectedId, allowNone: allowNone),
  );
}

class _LocationPickerBody extends ConsumerWidget {
  const _LocationPickerBody({required this.selectedId, required this.allowNone});

  final String? selectedId;
  final bool allowNone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locations = ref.watch(locationsProvider).value ?? const <Location>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetHeader(title: l10n.chooseLocation),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
          child: LocationChips(
            locations: locations,
            selectedId: selectedId,
            allowNone: allowNone,
            onSelect: (id) => Navigator.of(context).pop(LocationChoice(id)),
            onCreate: () async {
              final created = await showLocationEditSheet(context);
              if (created != null && context.mounted) Navigator.of(context).pop(LocationChoice(created.id));
            },
          ),
        ),
      ],
    );
  }
}

/// Grille de chips d'emplacements, réutilisée par la création de plante.
class LocationChips extends StatelessWidget {
  const LocationChips({
    super.key,
    required this.locations,
    required this.selectedId,
    required this.onSelect,
    required this.onCreate,
    this.allowNone = true,
    this.noneSelected = false,
  });

  final List<Location> locations;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onCreate;
  final bool allowNone;
  final bool noneSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final byParent = <String?, List<Location>>{};
    for (final l in locations) {
      byParent.putIfAbsent(l.parentId, () => []).add(l);
    }
    // Ordre d'affichage : parents puis leurs enfants, indentés visuellement par le libellé.
    final ordered = <(Location, String?)>[];
    void walk(String? parent, String? parentName) {
      for (final l in byParent[parent] ?? const <Location>[]) {
        ordered.add((l, parentName));
        walk(l.id, l.name);
      }
    }

    walk(null, null);
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final (l, parentName) in ordered)
          FloraChip(
            emoji: l.icon,
            label: parentName == null ? l.name : '$parentName · ${l.name}',
            selected: l.id == selectedId,
            onTap: () => onSelect(l.id),
          ),
        if (allowNone)
          FloraChip(label: l10n.noLocation, selected: noneSelected, onTap: () => onSelect(null)),
        FloraChip(label: l10n.newLocationChip, icon: CupertinoIcons.plus, onTap: onCreate),
      ],
    );
  }
}
