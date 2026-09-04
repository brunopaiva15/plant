import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/observability/observability.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

const _icons = ['🛋️', '🍳', '🛏️', '🖥️', '🛁', '🌤️', '🌳', '🏡', '🪟', '🚪', '🧺', '🌿'];
const _lights = ['low', 'medium', 'high'];

/// Création ou édition d'un emplacement. Retourne l'emplacement enregistré.
Future<Location?> showLocationEditSheet(BuildContext context, {Location? existing, String? parentId}) {
  return showFloraSheet<Location>(
    context,
    scrollable: true,
    builder: (ctx) => _LocationEditBody(existing: existing, initialParentId: parentId),
  );
}

class _LocationEditBody extends ConsumerStatefulWidget {
  const _LocationEditBody({this.existing, this.initialParentId});

  final Location? existing;
  final String? initialParentId;

  @override
  ConsumerState<_LocationEditBody> createState() => _LocationEditBodyState();
}

class _LocationEditBodyState extends ConsumerState<_LocationEditBody> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _orientation = TextEditingController(text: widget.existing?.orientation ?? '');
  late String _icon = widget.existing?.icon ?? _icons.first;
  late String? _parentId = widget.existing?.parentId ?? widget.initialParentId;
  late String? _light = widget.existing?.light;
  late bool _outdoor = widget.existing?.isOutdoor ?? false;
  bool _more = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _orientation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(locationRepositoryProvider);
    final orientation = _orientation.text.trim().isEmpty ? null : _orientation.text.trim();
    final Location result;
    if (widget.existing == null) {
      result = await repo.create(name: name, icon: _icon, parentId: _parentId, light: _light, orientation: orientation, isOutdoor: _outdoor);
      ref.read(analyticsProvider).track(AnalyticsEvents.locationCreated);
    } else {
      result = widget.existing!.copyWith(name: name, icon: _icon, parentId: () => _parentId, light: () => _light, orientation: () => orientation, isOutdoor: _outdoor);
      await repo.update(result);
    }
    Haptics.success();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final candidates = (ref.watch(locationsProvider).value ?? const <Location>[])
        .where((l) => l.id != widget.existing?.id && l.parentId == null)
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: widget.existing == null ? l10n.newLocationTitle : l10n.editLocation),
          Row(
            children: [
              EmojiTile(emoji: _icon, size: 52, background: c.sageSoft),
              const SizedBox(width: Space.sm),
              Expanded(
                child: FloraTextField(
                  controller: _name,
                  hint: l10n.locationNameHint,
                  autofocus: widget.existing == null,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final icon in _icons)
                Pressable(
                  onTap: () => setState(() => _icon = icon),
                  scale: 0.9,
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.micro),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: icon == _icon ? c.sageSoft : c.surfaceMuted,
                      borderRadius: Radii.mediumAll,
                      border: Border.all(color: icon == _icon ? c.sage : Colors.transparent, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          FloraGroup(
            children: [
              FloraListRow(leading: const Text('🌤️', style: TextStyle(fontSize: 18)), title: l10n.outdoor, subtitle: l10n.outdoorHint, trailing: AdaptiveSwitch(value: _outdoor, onChanged: (v) => setState(() => _outdoor = v))),
            ],
          ),
          if (candidates.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Text(l10n.parentLocation, style: context.text.caption),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                FloraChip(label: l10n.noParent, selected: _parentId == null, onTap: () => setState(() => _parentId = null)),
                for (final l in candidates)
                  FloraChip(emoji: l.icon, label: l.name, selected: _parentId == l.id, onTap: () => setState(() => _parentId = l.id)),
              ],
            ),
          ],
          const SizedBox(height: Space.md),
          Pressable(
            onTap: () => setState(() => _more = !_more),
            scale: 1,
            child: Row(
              children: [
                Text(l10n.moreOptions, style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _more ? 0.5 : 0,
                  duration: Motion.of(context, Motion.standard),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: c.sage),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.easeOut,
            alignment: Alignment.topCenter,
            child: !_more
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Space.md),
                      Text(l10n.light, style: context.text.caption),
                      const SizedBox(height: Space.xs),
                      Wrap(
                        spacing: Space.xs,
                        children: [
                          for (final v in _lights)
                            FloraChip(
                              label: switch (v) { 'low' => l10n.lightLow, 'medium' => l10n.lightMedium, _ => l10n.lightHigh },
                              selected: _light == v,
                              onTap: () => setState(() => _light = _light == v ? null : v),
                            ),
                        ],
                      ),
                      const SizedBox(height: Space.md),
                      Text(l10n.orientation, style: context.text.caption),
                      const SizedBox(height: Space.xs),
                      FloraTextField(controller: _orientation, hint: l10n.orientationHint, textCapitalization: TextCapitalization.words),
                    ],
                  ),
          ),
          const SizedBox(height: Space.xl),
          FloraButton(label: widget.existing == null ? l10n.add : l10n.save, expand: true, loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
