import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../../species/presentation/species_field.dart';

/// Édition d'une plante : l'essentiel d'abord, le reste sous « Plus d'options ».
Future<void> showEditPlantSheet(BuildContext context, {required Plant plant}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _EditPlantBody(plant: plant));

class _EditPlantBody extends ConsumerStatefulWidget {
  const _EditPlantBody({required this.plant});

  final Plant plant;

  @override
  ConsumerState<_EditPlantBody> createState() => _EditPlantBodyState();
}

class _EditPlantBodyState extends ConsumerState<_EditPlantBody> {
  late final _name = TextEditingController(text: widget.plant.name);
  late final _species = TextEditingController(text: widget.plant.speciesName ?? '');
  late final _source = TextEditingController(text: widget.plant.source ?? '');
  late final _price = TextEditingController(text: widget.plant.price?.toString() ?? '');
  late final _pot = TextEditingController(text: widget.plant.potSize?.toString() ?? '');
  late final _notes = TextEditingController(text: widget.plant.notes ?? '');
  late String? _locationId = widget.plant.locationId;
  late DateTime? _acquiredAt = widget.plant.acquiredAt;
  late PlantHealth _health = widget.plant.health;
  bool _more = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _species, _source, _price, _pot, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final savedLabel = context.l10n.saved;
    double? parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
    await ref.read(plantRepositoryProvider).update(widget.plant.copyWith(
          name: _name.text,
          speciesName: () => _species.text,
          locationId: () => _locationId,
          acquiredAt: () => _acquiredAt,
          source: () => _source.text,
          price: () => parse(_price.text),
          potSize: () => parse(_pot.text),
          notes: () => _notes.text,
          health: _health,
        ));
    Haptics.success();
    ref.read(toastProvider.notifier).show(ToastData(message: savedLabel));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final locations = ref.watch(locationsProvider).value ?? const <Location>[];
    final location = locations.where((l) => l.id == _locationId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.editPlant),
          FloraTextField(controller: _name, hint: l10n.plantNameHint, textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: Space.xs),
          SpeciesField(controller: _species),
          const SizedBox(height: Space.md),
          FloraGroup(
            children: [
              FloraListRow(
                leading: Text(location?.icon ?? '📍', style: const TextStyle(fontSize: 18)),
                title: l10n.filterLocation,
                trailing: Text(location?.name ?? l10n.noLocation, style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                chevron: false,
                onTap: () async {
                  final choice = await showLocationPicker(context, selectedId: _locationId);
                  if (choice != null) setState(() => _locationId = choice.id);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, Space.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.health, style: context.text.caption),
                    const SizedBox(height: 6),
                    AdaptiveSegmented<PlantHealth>(
                      segments: {for (final h in PlantHealth.values) h: l10n.healthName(h)},
                      value: _health,
                      onChanged: (v) => setState(() => _health = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Pressable(
            onTap: () => setState(() => _more = !_more),
            scale: 1,
            child: Row(
              children: [
                Text(l10n.moreOptions, style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                AnimatedRotation(turns: _more ? 0.5 : 0, duration: Motion.of(context, Motion.standard), child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: c.sage)),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.easeOut,
            alignment: Alignment.topCenter,
            child: !_more
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.md),
                    child: FloraGroup(
                      children: [
                        FloraListRow(
                          leading: Icon(CupertinoIcons.calendar, size: 20, color: c.inkSecondary),
                          title: l10n.acquiredAt,
                          trailing: Text(_acquiredAt == null ? l10n.none : Dates.dayYear(context, _acquiredAt!), style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                          chevron: false,
                          onTap: () async {
                            final d = await showAdaptiveDatePicker(context, initial: _acquiredAt ?? DateTime.now(), last: DateTime.now(), doneLabel: l10n.done);
                            if (d != null) setState(() => _acquiredAt = d);
                          },
                        ),
                        _Field(label: l10n.source, child: FloraTextField(controller: _source, hint: l10n.sourceHint)),
                        _Field(label: l10n.price, child: FloraTextField(controller: _price, hint: '0', keyboardType: const TextInputType.numberWithOptions(decimal: true), textCapitalization: TextCapitalization.none)),
                        _Field(label: '${l10n.potSize} (cm)', child: FloraTextField(controller: _pot, hint: '0', keyboardType: const TextInputType.numberWithOptions(decimal: true), textCapitalization: TextCapitalization.none)),
                        _Field(label: l10n.notes, child: FloraTextField(controller: _notes, hint: l10n.notesHint, minLines: 2, maxLines: 6)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: Space.xl),
          FloraButton(label: l10n.save, expand: true, loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(label, style: context.text.caption), const SizedBox(height: 6), child],
      ),
    );
  }
}
