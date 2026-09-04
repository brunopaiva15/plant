import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/models.dart';

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
