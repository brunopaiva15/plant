import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/sync/sync_service.dart';
import '../../../design_system/design_system.dart';

/// Les données de Flora sont accessibles par l'API REST du projet Supabase.
/// Cet écran documente l'adresse, les ressources et l'authentification :
/// aucun serveur n'est lancé sur le téléphone.
class ApiScreen extends ConsumerWidget {
  const ApiScreen({super.key});

  static String get baseUrl => '${SupabaseConfig.url}/rest/v1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final user = ref.watch(currentUserProvider).value;
    final connected = SupabaseConfig.isConfigured && user != null && !user.isLocal;

    return FloraPage(
      title: l10n.apiTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.apiExplain, style: context.text.callout.copyWith(color: c.inkSecondary)),
          const SizedBox(height: Space.lg),
          if (!connected)
            FloraCard(
              child: Row(
                children: [
                  const EmojiTile(emoji: '🔌', size: 40),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text(l10n.apiNotConnected, style: context.text.callout)),
                ],
              ),
            )
          else ...[
            FloraGroup(
              header: l10n.apiCopyBase,
              children: [
                FloraListRow(
                  leading: const Text('🌐', style: TextStyle(fontSize: 18)),
                  title: baseUrl,
                  titleMaxLines: 2,
                  subtitle: l10n.apiOnlyYourGarden,
                  chevron: false,
                  onTap: () => _copy(context, ref, baseUrl, l10n.apiCopied),
                ),
                FloraListRow(
                  leading: const Text('🔑', style: TextStyle(fontSize: 18)),
                  title: l10n.apiCopyToken,
                  subtitle: l10n.apiTokenWarning,
                  chevron: false,
                  onTap: () {
                    final token = Supabase.instance.client.auth.currentSession?.accessToken;
                    if (token != null) _copy(context, ref, token, l10n.apiTokenCopied);
                  },
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Text(l10n.apiTokenHint, style: context.text.caption.copyWith(color: c.inkSecondary)),
            const SizedBox(height: Space.lg),
            SectionHeader(title: l10n.apiExample, padding: const EdgeInsets.only(bottom: Space.sm)),
            FloraCard(
              color: c.surfaceMuted,
              child: SelectableText(
                'curl "$baseUrl/plants?select=*" \\\n'
                '  -H "apikey: <anon key>" \\\n'
                '  -H "Authorization: Bearer <token>"',
                style: context.text.caption.copyWith(fontFamily: 'monospace', color: c.ink),
              ),
            ),
          ],
          const SizedBox(height: Space.lg),
          SectionHeader(title: l10n.apiEndpoints, padding: const EdgeInsets.only(bottom: Space.sm)),
          FloraGroup(
            children: [
              for (final table in SyncService.tables)
                FloraListRow(
                  leading: Text(_emojiFor(table), style: const TextStyle(fontSize: 16)),
                  title: '/$table',
                  subtitle: l10n.apiReadWrite,
                  chevron: false,
                  dense: true,
                  onTap: connected ? () => _copy(context, ref, '$baseUrl/$table', l10n.apiCopied) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, WidgetRef ref, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    Haptics.success();
    ref.read(toastProvider.notifier).show(ToastData(message: message, emoji: '📋'));
  }

  static String _emojiFor(String table) => switch (table) {
        'gardens' => '🏡',
        'locations' => '📍',
        'plants' => '🪴',
        'plant_photos' => '📷',
        'plant_actions' || 'care_schedules' => '💧',
        'tags' || 'plant_tags' || 'inventory_tags' => '🏷️',
        'measurements' => '📏',
        'inventory_items' || 'inventory_groups' => '🧰',
        'tasks' => '📋',
        'plant_attributes' || 'attribute_schemas' => '🗒️',
        'plant_attachments' => '📎',
        'location_logs' => '📝',
        'event_categories' || 'calendar_entries' => '🗓️',
        _ => '📄',
      };
}
