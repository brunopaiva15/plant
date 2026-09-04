import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  final _new = TextEditingController();

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_new.text.trim().isEmpty) return;
    await ref.read(tagRepositoryProvider).create(_new.text);
    _new.clear();
    Haptics.success();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    return FloraPage(
      title: l10n.tags,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: FloraTextField(controller: _new, hint: l10n.tagNameHint, textInputAction: TextInputAction.done, onSubmitted: (_) => _create())),
              const SizedBox(width: Space.xs),
              FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.newTag, onPressed: _create, size: 48, background: c.sage, color: c.onSage),
            ],
          ),
          const SizedBox(height: Space.lg),
          if (tags.isEmpty)
            EmptyState(emoji: '🏷️', title: l10n.noTags, compact: true)
          else
            FloraGroup(
              children: [
                for (final t in tags)
                  FloraListRow(
                    title: t.name,
                    trailing: FloraIconButton(
                      icon: CupertinoIcons.trash,
                      semanticLabel: l10n.delete,
                      filled: false,
                      color: c.danger,
                      onPressed: () async {
                        final ok = await showAdaptiveConfirm(context, title: t.name, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
                        if (!ok) return;
                        await ref.read(tagRepositoryProvider).delete(t.id);
                        Haptics.warning();
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
