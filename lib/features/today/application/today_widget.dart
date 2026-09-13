import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/models/models.dart';
import '../../plants/application/plant_providers.dart';
import '../../tasks/application/task_providers.dart';

/// Une ligne du widget : une plante et le soin qui l'attend, ou une tâche.
class TodayWidgetTask {
  const TodayWidgetTask({required this.plantId, required this.name, required this.emoji, required this.label, required this.due, required this.overdue});

  final String? plantId;
  final String name;
  final String emoji;

  /// Le verbe du soin (« Arroser »), ou rien pour une tâche libre.
  final String label;

  /// L'échéance, déjà écrite (« Aujourd'hui », « En retard de 2 jours »).
  final String due;
  final bool overdue;

  Map<String, Object?> toJson() => {'plantId': plantId, 'name': name, 'emoji': emoji, 'label': label, 'due': due, 'overdue': overdue};
}

/// L'écran du matin, réduit à ce qu'un widget peut montrer : le chiffre du
/// jour, les premières lignes, et les mots pour les états sans ligne.
///
/// Tout est écrit ici, dans la langue de l'interface : le widget ne
/// traduit rien et ne compte rien. C'est ce qui le garde identique à
/// l'écran Aujourd'hui, pluriels compris.
class TodayWidgetSnapshot {
  const TodayWidgetSnapshot({required this.dueCount, required this.plantCount, required this.labels, required this.tasks});

  static const int maxTasks = 8;

  /// Ce que le widget montre au plus, toutes familles confondues.
  final int dueCount;
  final int plantCount;
  final Map<String, String> labels;
  final List<TodayWidgetTask> tasks;

  /// Les soins échus d'abord, du plus en retard au plus récent, puis ceux du
  /// jour, puis les tâches libres : l'ordre de l'écran Aujourd'hui.
  factory TodayWidgetSnapshot.build({
    required DateTime now,
    required AppLocalizations l10n,
    required List<CareTask> care,
    required List<FreeTask> free,
    required int plantCount,
    required Map<String, ActionType> types,
  }) {
    final due = care.where((t) => t.status(now) != DueStatus.upcoming).toList()..sort((a, b) => (a.dueAt ?? now).compareTo(b.dueAt ?? now));
    final lines = <TodayWidgetTask>[
      for (final t in due)
        TodayWidgetTask(
          plantId: t.plantId,
          name: t.summary.plant.name,
          emoji: types[t.typeKey]?.emoji ?? CareKind.fromKey(t.typeKey)?.emoji ?? '✓',
          label: l10n.kindVerb(t.typeKey, custom: types[t.typeKey]),
          due: l10n.dueLabel(t.dueAt, now),
          overdue: t.status(now) == DueStatus.overdue,
        ),
      for (final t in free)
        TodayWidgetTask(
          plantId: t.plantId,
          name: t.title,
          emoji: '📌',
          label: '',
          due: l10n.dueLabel(t.dueAt, now),
          overdue: t.status(now) == FreeTaskStatus.overdue,
        ),
    ];
    final count = due.length + free.length;
    return TodayWidgetSnapshot(
      dueCount: count,
      plantCount: plantCount,
      labels: {
        'title': l10n.tabToday,
        // « 3 soins » sans le chiffre : le widget l'écrit en grand à côté.
        'count': l10n.careCount(count).replaceFirst(RegExp(r'^\d+\s*'), ''),
        'allDone': l10n.allDoneTitle,
        'allDoneBody': l10n.allDoneSubtitle,
        'empty': l10n.emptyGardenTitle,
      },
      tasks: lines.take(maxTasks).toList(),
    );
  }

  Map<String, Object?> toJson() => {
        'version': 1,
        'dueCount': dueCount,
        'plantCount': plantCount,
        'labels': labels,
        'tasks': [for (final t in tasks) t.toJson()],
      };

  String encode() => jsonEncode(toJson());
}

/// L'instantané du jour, recalculé à chaque changement de la base ; `null`
/// tant que les soins et le compte des plantes ne sont pas chargés, pour ne
/// pas écrire un widget vide au démarrage.
final todayWidgetSnapshotProvider = Provider<TodayWidgetSnapshot?>((ref) {
  final care = ref.watch(careTasksProvider).value;
  final plantCount = ref.watch(activePlantCountProvider).value;
  if (care == null || plantCount == null) return null;
  final locale = ref.watch(preferencesProvider.select((p) => p.locale));
  return TodayWidgetSnapshot.build(
    now: DateTime.now(),
    l10n: resolveLocalizations(locale),
    care: care,
    free: ref.watch(dueTasksProvider),
    plantCount: plantCount,
    types: ref.watch(actionTypeByKeyProvider),
  );
});
