import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/models.dart';
import '../../actions/application/care_actions.dart';

/// Phase d'une tâche qui vient d'être complétée sur l'écran Aujourd'hui.
enum LingerPhase { done, leaving }

class LingeringTask {
  const LingeringTask({required this.task, required this.phase});

  final CareTask task;
  final LingerPhase phase;
}

/// Garde une tâche complétée visible ~1 s en état « ✓ Fait », puis la fait
/// glisser hors de la liste. Sans cela, la carte disparaîtrait à l'instant
/// même où la base est mise à jour et l'animation de validation serait invisible.
class CompletedTasksController extends Notifier<Map<String, LingeringTask>> {
  final _timers = <String, Timer>{};

  static const showDuration = Duration(milliseconds: 1100);
  static const leaveDuration = Duration(milliseconds: 450);

  @override
  Map<String, LingeringTask> build() {
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
    });
    return const {};
  }

  void markDone(CareTask task) {
    final id = task.schedule.id;
    _timers[id]?.cancel();
    state = {...state, id: LingeringTask(task: task, phase: LingerPhase.done)};
    _timers[id] = Timer(showDuration, () {
      if (!state.containsKey(id)) return;
      state = {...state, id: LingeringTask(task: task, phase: LingerPhase.leaving)};
      _timers[id] = Timer(leaveDuration, () => forget(id));
    });
  }

  /// Retire les entrées d'une plante pour un type donné (Undo).
  void forgetPlant(String plantId, String typeKey) {
    for (final entry in state.values.toList()) {
      if (entry.task.plantId == plantId && entry.task.typeKey == typeKey) forget(entry.task.schedule.id);
    }
  }

  /// Retire immédiatement (Undo ou tâche redevenue due).
  void forget(String scheduleId) {
    _timers.remove(scheduleId)?.cancel();
    if (!state.containsKey(scheduleId)) return;
    state = {...state}..remove(scheduleId);
  }
}

final completedTasksProvider = NotifierProvider<CompletedTasksController, Map<String, LingeringTask>>(CompletedTasksController.new);

/// Ce que le registre dit de [task] : `null` quand elle est active, sinon la
/// phase de sa sortie. À lire depuis un `build`.
///
/// L'état « ✓ Fait » ne vit pas dans la carte mais ici : un soin enregistré
/// repousse l'échéance, donc la carte change de section dans la seconde — la
/// confirmation, elle, doit tenir le temps de l'undo, où qu'elle atterrisse.
LingerPhase? watchCarePhase(WidgetRef ref, CareTask task) =>
    ref.watch(completedTasksProvider.select((m) => m[task.schedule.id]?.phase));

/// Enregistre le soin, et garde la tâche en « ✓ Fait » le temps de l'undo.
Future<void> completeCareTask(BuildContext context, WidgetRef ref, CareTask task) async {
  // Un second tap pendant l'animation ne doit pas enregistrer deux fois.
  if (ref.read(completedTasksProvider).containsKey(task.schedule.id)) return;
  ref.read(completedTasksProvider.notifier).markDone(task);
  await ref.read(careActionsProvider).logQuick(context, plantId: task.plantId, plantName: task.summary.plant.name, typeKey: task.typeKey);
}

/// « Plus tard » : l'échéance glisse à demain.
Future<void> snoozeCareTask(BuildContext context, WidgetRef ref, CareTask task) =>
    ref.read(careActionsProvider).snooze(context, scheduleId: task.schedule.id, plantName: task.summary.plant.name);
