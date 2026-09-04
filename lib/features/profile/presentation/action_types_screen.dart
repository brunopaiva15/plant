import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../actions/presentation/action_type_sheet.dart';

class ActionTypesScreen extends ConsumerWidget {
  const ActionTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final types = ref.watch(actionTypesProvider).value ?? const <ActionType>[];
    final custom = types.where((t) => !t.isBuiltin).toList();
    final builtin = types.where((t) => t.isBuiltin).toList();
    return FloraPage(
      title: l10n.actionTypes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.actionTypesHint, style: context.text.callout),
          const SizedBox(height: Space.lg),
          if (custom.isNotEmpty) ...[
            FloraGroup(
              children: [
                for (final t in custom)
                  FloraListRow(
                    leading: Text(t.emoji, style: const TextStyle(fontSize: 20)),
                    title: t.label ?? t.key,
                    trailing: FloraIconButton(
                      icon: CupertinoIcons.trash,
                      semanticLabel: l10n.deleteActionType,
                      filled: false,
                      color: c.danger,
                      onPressed: () async {
                        final ok = await showAdaptiveConfirm(context, title: l10n.deleteActionType, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
                        if (!ok) return;
                        await ref.read(actionTypeRepositoryProvider).deleteCustom(t.key);
                        Haptics.warning();
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
          ],
          FloraButton(label: l10n.newActionType, icon: CupertinoIcons.plus, style: FloraButtonStyle.tonal, onPressed: () => showNewActionTypeSheet(context)),
          const SizedBox(height: Space.xl),
          FloraGroup(
            header: l10n.builtin,
            children: [
              for (final t in builtin) FloraListRow(leading: Text(t.emoji, style: const TextStyle(fontSize: 20)), title: l10n.kindName(t.key), dense: true),
            ],
          ),
        ],
      ),
    );
  }
}
