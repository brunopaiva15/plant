import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../application/care_actions.dart';

/// Note libre, éditeur minimal.
Future<void> showAddNoteSheet(BuildContext context, {required String plantId, required String plantName}) {
  return showFloraSheet<void>(context, builder: (ctx) => _AddNoteBody(plantId: plantId, plantName: plantName));
}

class _AddNoteBody extends ConsumerStatefulWidget {
  const _AddNoteBody({required this.plantId, required this.plantName});

  final String plantId;
  final String plantName;

  @override
  ConsumerState<_AddNoteBody> createState() => _AddNoteBodyState();
}

class _AddNoteBodyState extends ConsumerState<_AddNoteBody> {
  final _text = TextEditingController();
  bool _canSave = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = context.l10n;
    await ref.read(careActionsProvider).log(
          NewAction(plantId: widget.plantId, typeKey: CareKind.note.key, notes: _text.text),
          message: l10n.actionDoneToast(widget.plantName, l10n.doneNote),
          undoLabel: l10n.undo,
          emoji: '📝',
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: l10n.addNote),
          FloraTextField(
            controller: _text,
            hint: l10n.noteHint,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            onChanged: (v) => setState(() => _canSave = v.trim().isNotEmpty),
          ),
          const SizedBox(height: Space.md),
          FloraButton(label: l10n.save, expand: true, onPressed: _canSave ? _save : null),
        ],
      ),
    );
  }
}
