import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

/// Création d'un type d'action personnalisé (emoji + nom).
Future<ActionType?> showNewActionTypeSheet(BuildContext context) {
  return showFloraSheet<ActionType>(context, builder: (ctx) => const _NewActionTypeBody());
}

class _NewActionTypeBody extends ConsumerStatefulWidget {
  const _NewActionTypeBody();

  @override
  ConsumerState<_NewActionTypeBody> createState() => _NewActionTypeBodyState();
}

class _NewActionTypeBodyState extends ConsumerState<_NewActionTypeBody> {
  final _label = TextEditingController();
  final _emoji = TextEditingController(text: '✨');

  @override
  void dispose() {
    _label.dispose();
    _emoji.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    final emoji = _emoji.text.trim().isEmpty ? '✨' : _emoji.text.trim().characters.first;
    if (label.isEmpty) return;
    final type = await ref.read(actionTypeRepositoryProvider).createCustom(label: label, emoji: emoji);
    if (mounted) Navigator.of(context).pop(type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: l10n.newActionType),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: FloraTextField(controller: _emoji, hint: '✨', textCapitalization: TextCapitalization.none, keyboardType: TextInputType.text),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: FloraTextField(
                  controller: _label,
                  hint: l10n.actionTypeLabelHint,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          FloraButton(label: l10n.add, expand: true, onPressed: _save),
        ],
      ),
    );
  }
}
