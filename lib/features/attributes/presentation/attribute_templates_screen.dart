import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/attribute_providers.dart';
import 'attribute_sheet.dart';

/// Réglages : modèles de champs réutilisables sur toutes les plantes.
class AttributeTemplatesScreen extends ConsumerWidget {
  const AttributeTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schemas = ref.watch(attributeSchemasProvider).value ?? const <AttributeSchema>[];
    return FloraPage(
      title: l10n.fieldTemplates,
      trailing: FloraIconButton(
        icon: CupertinoIcons.plus,
        semanticLabel: l10n.newFieldTemplate,
        onPressed: () => _showTemplateSheet(context, ref),
        size: 32,
        filled: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.fieldTemplatesHint, style: context.text.callout),
          const SizedBox(height: Space.lg),
          if (schemas.isEmpty)
            EmptyState(emoji: '🏷️', title: l10n.noFieldTemplates, actionLabel: l10n.newFieldTemplate, onAction: () => _showTemplateSheet(context, ref), compact: true)
          else
            FloraGroup(
              children: [
                for (final s in schemas)
                  FloraListRow(
                    leading: Text(_emojiFor(s.type), style: const TextStyle(fontSize: 18)),
                    title: s.label,
                    subtitle: s.active ? attributeTypeName(l10n, s.type) : '${attributeTypeName(l10n, s.type)} · ${l10n.fieldTemplateInactive}',
                    onTap: () => _showTemplateSheet(context, ref, existing: s),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static String _emojiFor(AttributeType t) => switch (t) {
        AttributeType.boolean => '☑️',
        AttributeType.integer => '🔢',
        AttributeType.decimal => '📐',
        AttributeType.text => '📝',
        AttributeType.date => '📅',
      };
}

Future<void> _showTemplateSheet(BuildContext context, WidgetRef ref, {AttributeSchema? existing}) =>
    showFloraSheet<void>(context, builder: (_) => _TemplateBody(existing: existing));

class _TemplateBody extends ConsumerStatefulWidget {
  const _TemplateBody({this.existing});

  final AttributeSchema? existing;

  @override
  ConsumerState<_TemplateBody> createState() => _TemplateBodyState();
}

class _TemplateBodyState extends ConsumerState<_TemplateBody> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late AttributeType _type = widget.existing?.type ?? AttributeType.text;
  late bool _active = widget.existing?.active ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(attributeRepositoryProvider);
    if (widget.existing == null) {
      await repo.createSchema(label: _label.text, type: _type);
    } else {
      await repo.updateSchema(widget.existing!.copyWith(label: _label.text, type: _type, active: _active));
    }
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.confirmDeleteTemplate, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok || !mounted) return;
    await ref.read(attributeRepositoryProvider).deleteSchema(widget.existing!.id);
    Haptics.warning();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: widget.existing == null ? l10n.newFieldTemplate : l10n.editCustomField),
          FloraTextField(controller: _label, hint: l10n.fieldLabelHint, autofocus: widget.existing == null, onChanged: (_) => setState(() {})),
          const SizedBox(height: Space.md),
          Text(l10n.fieldType, style: context.text.caption),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final t in AttributeType.values) FloraChip(label: attributeTypeName(l10n, t), selected: _type == t, onTap: () => setState(() => _type = t)),
            ],
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: Space.md),
            FloraCard(
              padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.fieldTemplateInactive, style: context.text.body)),
                  AdaptiveSwitch(value: !_active, onChanged: (v) => setState(() => _active = !v)),
                ],
              ),
            ),
          ],
          const SizedBox(height: Space.xl),
          FloraButton(label: widget.existing == null ? l10n.add : l10n.save, expand: true, loading: _saving, onPressed: _label.text.trim().isEmpty ? null : _save),
          if (widget.existing != null) ...[
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.delete, style: FloraButtonStyle.ghost, expand: true, onPressed: _delete),
          ],
        ],
      ),
    );
  }
}
