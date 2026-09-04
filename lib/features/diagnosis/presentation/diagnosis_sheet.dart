import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/diagnosis/plant_diagnoser.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../actions/application/care_actions.dart';

/// « Ma plante a un problème » : photos, symptômes, analyse, pistes.
Future<void> showDiagnosisSheet(BuildContext context, {required Plant plant}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _DiagnosisBody(plant: plant));

class _DiagnosisBody extends ConsumerStatefulWidget {
  const _DiagnosisBody({required this.plant});

  final Plant plant;

  @override
  ConsumerState<_DiagnosisBody> createState() => _DiagnosisBodyState();
}

class _DiagnosisBodyState extends ConsumerState<_DiagnosisBody> {
  final _photos = <StoredPhoto>[];
  final _symptoms = TextEditingController();
  bool _busy = false;
  Diagnosis? _result;

  @override
  void dispose() {
    _symptoms.dispose();
    // Les photos de diagnostic sont temporaires : on nettoie.
    final storage = ref.read(photoStorageProvider);
    for (final p in _photos) {
      storage.deleteFiles(p.filePath, p.thumbPath);
    }
    super.dispose();
  }

  Future<void> _addPhoto(PhotoSource source) async {
    final stored = await ref.read(photoStorageProvider).pick(source);
    if (stored != null && mounted) setState(() => _photos.add(stored));
  }

  Future<void> _analyze() async {
    if (_photos.isEmpty || _busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final storage = ref.read(photoStorageProvider);
    final lang = ref.read(preferencesProvider).locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    try {
      final files = [for (final p in _photos) File(await storage.absolutePath(p.filePath))];
      final result = await ref.read(plantDiagnoserProvider).diagnose(
            images: files,
            language: lang,
            plantName: widget.plant.name,
            species: widget.plant.speciesName,
            symptoms: _symptoms.text,
          );
      Haptics.success();
      if (mounted) setState(() => _result = result);
    } on DiagnosisException catch (e) {
      final message = switch (e.message) { 'refusal' => l10n.diagnosisRefused, 'unauthorized' => l10n.diagnosisUnauthorized, _ => l10n.diagnosisError };
      ref.read(toastProvider.notifier).show(ToastData(message: message, emoji: '!'));
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'diagnosis');
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.diagnosisError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final r = _result!;
    final text = [r.summary, ...r.causes.take(3).map((c) => '• ${c.title} (${(c.likelihood * 100).round()} %)')].join('\n');
    await ref.read(careActionsProvider).log(
          NewAction(plantId: widget.plant.id, typeKey: CareKind.note.key, notes: text),
          message: l10n.diagnosisSaved,
          undoLabel: l10n.undo,
          emoji: '🩺',
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _markWatch() async {
    await ref.read(plantRepositoryProvider).update(widget.plant.copyWith(health: PlantHealth.watch));
    Haptics.light();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.diagnosisTitle),
          if (_result == null) ...[
            Text(l10n.diagnosisHint, style: context.text.callout),
            const SizedBox(height: Space.md),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in _photos)
                    Padding(
                      padding: const EdgeInsets.only(right: Space.xs),
                      child: ClipRRect(borderRadius: Radii.mediumAll, child: SizedBox(width: 92, height: 92, child: PlantImage(relativePath: p.thumbPath, cacheWidth: 300))),
                    ),
                  if (_photos.length < AnthropicDiagnoserLimits.maxImages)
                    Pressable(
                      onTap: () => showAdaptiveActionSheet(
                        context,
                        cancelLabel: l10n.cancel,
                        actions: [
                          SheetAction(label: l10n.camera, icon: CupertinoIcons.camera, onPressed: () => _addPhoto(PhotoSource.camera)),
                          SheetAction(label: l10n.gallery, icon: CupertinoIcons.photo, onPressed: () => _addPhoto(PhotoSource.gallery)),
                        ],
                      ),
                      scale: 0.95,
                      semanticLabel: l10n.addPhotos,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.mediumAll),
                        child: Icon(CupertinoIcons.camera_fill, color: c.sage),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            FloraTextField(controller: _symptoms, hint: l10n.diagnosisSymptomsHint, minLines: 1, maxLines: 3),
            const SizedBox(height: Space.lg),
            if (_busy)
              Column(children: [const AdaptiveProgress(), const SizedBox(height: Space.xs), Text(l10n.analyzing, style: context.text.caption)])
            else
              FloraButton(label: l10n.analyze, icon: CupertinoIcons.sparkles, expand: true, onPressed: _photos.isEmpty ? null : _analyze),
          ] else ...[
            if (_result!.urgent) DueBadge(emoji: '⚠️', label: l10n.urgentHint, status: DueStatus.overdue),
            if (_result!.urgent) const SizedBox(height: Space.xs),
            Text(_result!.summary, style: context.text.body),
            const SizedBox(height: Space.lg),
            Text(l10n.possibleCauses, style: context.text.title3),
            const SizedBox(height: Space.xxs),
            Text(l10n.identifyHint, style: context.text.caption),
            const SizedBox(height: Space.sm),
            for (final cause in _result!.causes) _CauseCard(cause: cause),
            const SizedBox(height: Space.md),
            FloraButton(label: l10n.saveToJournal, icon: CupertinoIcons.book, expand: true, onPressed: _save),
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.markWatch, style: FloraButtonStyle.ghost, expand: true, onPressed: _markWatch),
          ],
        ],
      ),
    );
  }
}

/// Plafond de photos par analyse (aligné sur l'adaptateur).
abstract final class AnthropicDiagnoserLimits {
  static const maxImages = 3;
}

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.cause});

  final DiagnosisCause cause;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final percent = (cause.likelihood * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: FloraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(cause.title, style: context.text.title3)),
                const SizedBox(width: Space.xs),
                DueBadge(emoji: '～', label: '$percent %', status: percent >= 50 ? DueStatus.today : DueStatus.upcoming, compact: true),
              ],
            ),
            const SizedBox(height: Space.xxs),
            ClipRRect(
              borderRadius: Radii.fullAll,
              child: LinearProgressIndicator(value: cause.likelihood, minHeight: 4, backgroundColor: c.surfaceMuted, color: percent >= 50 ? c.sage : c.inkTertiary),
            ),
            const SizedBox(height: Space.xs),
            Text(cause.explanation, style: context.text.callout),
            if (cause.actions.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              for (final a in cause.actions)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('→ ', style: context.text.callout.copyWith(color: c.sage)),
                      Expanded(child: Text(a, style: context.text.callout.copyWith(color: c.ink))),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
