import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/observability/observability.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/components/toast.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../today/application/completed_tasks.dart';
import '../../today/application/reminder_scheduler.dart';

/// Cas d'usage « enregistrer un soin » : optimiste, haptique, toast avec Undo,
/// analytics et replanification des rappels. Utilisé par tous les écrans.
class CareActions {
  CareActions(this._ref);

  final Ref _ref;

  ActionRepository get _actions => _ref.read(actionRepositoryProvider);
  ToastController get _toast => _ref.read(toastProvider.notifier);
  Analytics get _analytics => _ref.read(analyticsProvider);

  /// Action rapide (1 tap) : le type suffit.
  Future<PlantAction> logQuick(BuildContext context, {required String plantId, required String plantName, required String typeKey}) {
    final l10n = context.l10n;
    final custom = _ref.read(actionTypeByKeyProvider)[typeKey];
    return log(
      NewAction(plantId: plantId, typeKey: typeKey),
      message: l10n.actionDoneToast(plantName, l10n.kindDone(typeKey, custom: custom)),
      undoLabel: l10n.undo,
      emoji: custom?.emoji ?? '✓',
    );
  }

  Future<PlantAction> log(NewAction data, {required String message, required String undoLabel, String emoji = '✓'}) async {
    final action = await _actions.log(data);
    Haptics.success();
    _analytics.track(data.typeKey == CareKind.watering.key ? AnalyticsEvents.wateringLogged : AnalyticsEvents.actionLogged, {'type': data.typeKey});
    _toast.show(ToastData(
      message: message,
      emoji: emoji,
      undoLabel: undoLabel,
      onUndo: () async {
        await _actions.undo(action);
        _ref.read(completedTasksProvider.notifier).forgetPlant(action.plantId, action.typeKey);
        await _reschedule();
      },
    ));
    await _reschedule();
    return action;
  }

  /// Multi-sélection : un seul toast, un seul Undo pour tout le lot.
  Future<void> logMany(BuildContext context, {required List<String> plantIds, required String typeKey}) async {
    final l10n = context.l10n;
    final custom = _ref.read(actionTypeByKeyProvider)[typeKey];
    final logged = await _actions.logMany(plantIds, typeKey);
    Haptics.success();
    _analytics.track(AnalyticsEvents.actionLogged, {'type': typeKey, 'count': plantIds.length});
    _toast.show(ToastData(
      message: l10n.multiActionDone(plantIds.length, l10n.kindName(typeKey, custom: custom)),
      emoji: custom?.emoji ?? '✓',
      undoLabel: l10n.undo,
      onUndo: () async {
        for (final a in logged) {
          await _actions.undo(a);
        }
        await _reschedule();
      },
    ));
    await _reschedule();
  }

  Future<void> snooze(BuildContext context, {required String scheduleId, required String plantName}) async {
    final message = context.l10n.snoozed(plantName);
    await _ref.read(careRepositoryProvider).snooze(scheduleId, DateTime.now());
    Haptics.light();
    _toast.show(ToastData(message: message, emoji: '⏰'));
    await _reschedule();
  }

  /// Import d'une photo : stockage, entrée d'historique, toast.
  Future<PlantPhoto?> addPhoto(BuildContext context, {required String plantId, required PhotoSource source}) async {
    final l10n = context.l10n;
    final storage = _ref.read(photoStorageProvider);
    try {
      final stored = await storage.pick(source);
      if (stored == null) return null;
      final photo = await _ref.read(photoRepositoryProvider).add(
            plantId: plantId,
            filePath: stored.filePath,
            thumbPath: stored.thumbPath,
            width: stored.width,
            height: stored.height,
          );
      await _actions.log(NewAction(plantId: plantId, typeKey: CareKind.photo.key, photoId: photo.id));
      Haptics.success();
      _analytics.track(AnalyticsEvents.photoAdded);
      _toast.show(ToastData(message: l10n.photoAddedToast, emoji: '📷'));
      return photo;
    } catch (e, st) {
      _ref.read(crashReporterProvider).report(e, st, context: 'addPhoto');
      _toast.show(ToastData(message: l10n.photoError, emoji: '!'));
      return null;
    }
  }

  Future<void> _reschedule() => _ref.read(reminderSchedulerProvider).reschedule();
}

final careActionsProvider = Provider<CareActions>((ref) => CareActions(ref));
