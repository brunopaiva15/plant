import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/plant_providers.dart';

/// Choix d'un tag existant ou création. Retourne l'id du tag.
Future<String?> showTagPickerSheet(BuildContext context) => showFloraSheet<String>(context, scrollable: true, builder: (_) => const _TagPickerBody());

class _TagPickerBody extends ConsumerStatefulWidget {
  const _TagPickerBody();

  @override
  ConsumerState<_TagPickerBody> createState() => _TagPickerBodyState();
}

class _TagPickerBodyState extends ConsumerState<_TagPickerBody> {
  final _new = TextEditingController();

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_new.text.trim().isEmpty) return;
    final tag = await ref.read(tagRepositoryProvider).create(_new.text);
    if (mounted) Navigator.of(context).pop(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: l10n.addTag),
          if (tags.isNotEmpty) ...[
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [for (final t in tags) FloraChip(label: t.name, onTap: () => Navigator.of(context).pop(t.id))],
            ),
            const SizedBox(height: Space.lg),
          ],
          Row(
            children: [
              Expanded(child: FloraTextField(controller: _new, hint: l10n.tagNameHint, autofocus: tags.isEmpty, textInputAction: TextInputAction.done, onSubmitted: (_) => _create())),
              const SizedBox(width: Space.xs),
              FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.newTag, onPressed: _create, size: 48, background: context.colors.sage, color: context.colors.onSage),
            ],
          ),
        ],
      ),
    );
  }
}

/// Édition des tags d'une plante (multi-sélection).
Future<void> showPlantTagsSheet(BuildContext context, {required String plantId}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _PlantTagsBody(plantId: plantId));

class _PlantTagsBody extends ConsumerStatefulWidget {
  const _PlantTagsBody({required this.plantId});

  final String plantId;

  @override
  ConsumerState<_PlantTagsBody> createState() => _PlantTagsBodyState();
}

class _PlantTagsBodyState extends ConsumerState<_PlantTagsBody> {
  final _new = TextEditingController();
  Set<String>? _selected;

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  Future<void> _toggle(String id) async {
    setState(() => _selected!.contains(id) ? _selected!.remove(id) : _selected!.add(id));
    await ref.read(tagRepositoryProvider).setPlantTags(widget.plantId, _selected!.toList());
  }

  Future<void> _create() async {
    if (_new.text.trim().isEmpty) return;
    final tag = await ref.read(tagRepositoryProvider).create(_new.text);
    _new.clear();
    await _toggle(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final current = ref.watch(plantTagsProvider(widget.plantId)).value;
    if (current == null) return const SizedBox(height: 120, child: Center(child: AdaptiveProgress()));
    _selected ??= current.map((t) => t.id).toSet();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: l10n.tags),
          if (tags.isEmpty) Padding(padding: const EdgeInsets.only(bottom: Space.md), child: Text(l10n.noTags, style: context.text.callout)),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [for (final t in tags) FloraChip(label: t.name, selected: _selected!.contains(t.id), onTap: () => _toggle(t.id))],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(child: FloraTextField(controller: _new, hint: l10n.tagNameHint, textInputAction: TextInputAction.done, onSubmitted: (_) => _create())),
              const SizedBox(width: Space.xs),
              FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.newTag, onPressed: _create, size: 48, background: context.colors.sage, color: context.colors.onSage),
            ],
          ),
        ],
      ),
    );
  }
}
