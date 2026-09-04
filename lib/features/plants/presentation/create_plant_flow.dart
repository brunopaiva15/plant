import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/observability/observability.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../domain/identification/plant_identifier.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../locations/presentation/location_edit_sheet.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../../identification/presentation/identification_sheet.dart';
import '../../account/application/membership_providers.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../domain/care/care_guide.dart';
import '../../species/presentation/species_field.dart';

/// Lance le flow de création (3 étapes) et ouvre la fiche de la plante créée.
Future<void> startCreatePlantFlow(BuildContext context, WidgetRef ref, {String? parentPlantId, String? parentName, String? locationId}) async {
  final l10n = context.l10n;
  if (!ref.read(canEditProvider)) {
    ref.read(toastProvider.notifier).show(ToastData(message: l10n.readOnlyHint, emoji: '🔒'));
    return;
  }
  final plantId = await showFloraFlow<String>(
    context,
    builder: (ctx) => CreatePlantFlow(parentPlantId: parentPlantId, parentName: parentName, initialLocationId: locationId),
  );
  if (plantId != null && context.mounted) {
    context.push(Routes.plant(plantId));
  }
}

class CreatePlantFlow extends ConsumerStatefulWidget {
  const CreatePlantFlow({super.key, this.parentPlantId, this.parentName, this.initialLocationId});

  final String? parentPlantId;
  final String? parentName;
  final String? initialLocationId;

  @override
  ConsumerState<CreatePlantFlow> createState() => _CreatePlantFlowState();
}

class _CreatePlantFlowState extends ConsumerState<CreatePlantFlow> {
  final _page = PageController();
  int _step = 0;
  StoredPhoto? _photo;
  bool _picking = false;
  bool _saving = false;
  Future<List<IdentificationCandidate>>? _identification;

  late final _name = TextEditingController(text: widget.parentName == null ? '' : context.l10n.cuttingOf(widget.parentName!));
  final _species = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _acquiredAt;
  int _watering = AppConfig.defaultWateringInterval;
  int _fertilizing = AppConfig.defaultFertilizingInterval;

  /// Vrai dès que l'utilisateur règle un intervalle à la main : la fiche
  /// d'entretien ne doit plus écraser son choix.
  bool _intervalsTouched = false;
  bool _more = false;
  late String? _locationId = widget.initialLocationId;
  bool _noLocation = false;

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    _species.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _go(int step) {
    Haptics.selection();
    setState(() => _step = step);
    _page.animateToPage(step, duration: Motion.of(context, Motion.emphasis), curve: Motion.emphasized);
  }

  Future<void> _pick(PhotoSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final stored = await ref.read(photoStorageProvider).pick(source);
      if (stored != null) {
        if (_photo != null) await ref.read(photoStorageProvider).deleteFiles(_photo!.filePath, _photo!.thumbPath);
        setState(() => _photo = stored);
        Haptics.success();
        _startIdentification(stored);
        _go(1);
      }
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'createPlant.pick');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Identification en arrière-plan dès qu'une photo existe (si un service est configuré).
  /// Les suggestions apparaissent à l'étape du nom, sans étape supplémentaire.
  void _startIdentification(StoredPhoto photo) {
    final identifier = ref.read(plantIdentifierProvider);
    if (!identifier.isConfigured) return;
    final lang = ref.read(preferencesProvider).locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    setState(() {
      _identification = ref.read(photoStorageProvider).absolutePath(photo.filePath).then((path) => identifier.identify([File(path)], language: lang)).catchError((_) => <IdentificationCandidate>[]);
    });
  }

  /// Reprend les intervalles conseillés par la fiche d'entretien de l'espèce,
  /// tant que l'utilisateur ne les a pas réglés lui-même.
  void _applyCareProfile(String scientificName, {String? family}) {
    final care = ref.read(careGuideProvider).resolve(scientificName, family: family);
    setState(() {
      if (_intervalsTouched) return;
      _watering = care.profile.wateringDaysFor(DateTime.now().month);
      _fertilizing = care.profile.fertilizingDays ?? 0;
    });
  }

  Future<void> _cancel() async {
    if (_photo != null) await ref.read(photoStorageProvider).deleteFiles(_photo!.filePath, _photo!.thumbPath);
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _finish() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    final plant = await ref.read(plantRepositoryProvider).create(NewPlant(
          name: name,
          speciesName: _species.text,
          locationId: _noLocation ? null : _locationId,
          acquiredAt: _acquiredAt,
          notes: _notes.text,
          parentPlantId: widget.parentPlantId,
          wateringIntervalDays: _watering,
          fertilizingIntervalDays: _fertilizing,
        ));
    // Bouture : la fille hérite des champs personnalisés de la plante mère.
    if (widget.parentPlantId != null) {
      await ref.read(attributeRepositoryProvider).cloneAttributes(fromPlantId: widget.parentPlantId!, toPlantId: plant.id);
    }
    if (_photo != null) {
      final photo = await ref.read(photoRepositoryProvider).add(
            plantId: plant.id,
            filePath: _photo!.filePath,
            thumbPath: _photo!.thumbPath,
            width: _photo!.width,
            height: _photo!.height,
          );
      await ref.read(actionRepositoryProvider).log(NewAction(plantId: plant.id, typeKey: CareKind.photo.key, photoId: photo.id));
    }
    ref.read(analyticsProvider).track(AnalyticsEvents.plantCreated, {'with_photo': _photo != null});
    Haptics.success();
    ref.read(toastProvider.notifier).show(ToastData(message: l10n.plantAdded(plant.name), emoji: '🌱'));
    if (mounted) Navigator.of(context, rootNavigator: true).pop(plant.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, 0),
              child: Row(
                children: [
                  FloraIconButton(
                    icon: _step == 0 ? CupertinoIcons.xmark : CupertinoIcons.chevron_left,
                    semanticLabel: _step == 0 ? l10n.close : l10n.back,
                    onPressed: () => _step == 0 ? _cancel() : _go(_step - 1),
                  ),
                  const Spacer(),
                  _StepDots(count: 3, index: _step),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [_photoStep(), _nameStep(), _locationStep()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoStep() {
    final l10n = context.l10n;
    final c = context.colors;
    return _StepLayout(
      title: l10n.stepPhotoTitle,
      subtitle: l10n.stepPhotoSubtitle,
      body: Center(
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Pressable(
            onTap: () => _showPhotoSources(),
            scale: 0.98,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.xlAll),
              child: _photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.camera, size: 44, color: c.sage),
                        const SizedBox(height: Space.sm),
                        Text(l10n.takePhoto, style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : PlantImage(relativePath: _photo!.thumbPath, cacheWidth: 900),
            ),
          ),
        ),
      ),
      actions: _photo == null
          ? [
              FloraButton(label: l10n.takePhoto, icon: CupertinoIcons.camera_fill, expand: true, loading: _picking, onPressed: () => _pick(PhotoSource.camera)),
              const SizedBox(height: Space.xs),
              FloraButton(label: l10n.choosePhoto, style: FloraButtonStyle.secondary, expand: true, onPressed: _picking ? null : () => _pick(PhotoSource.gallery)),
              const SizedBox(height: Space.xs),
              FloraButton(label: l10n.withoutPhoto, style: FloraButtonStyle.ghost, expand: true, onPressed: () => _go(1)),
            ]
          : [
              FloraButton(label: l10n.continueLabel, expand: true, onPressed: () => _go(1)),
              const SizedBox(height: Space.xs),
              FloraButton(label: l10n.changePhoto, style: FloraButtonStyle.ghost, expand: true, onPressed: _showPhotoSources),
            ],
    );
  }

  Future<void> _showPhotoSources() {
    final l10n = context.l10n;
    return showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(label: l10n.takePhoto, icon: CupertinoIcons.camera, onPressed: () => _pick(PhotoSource.camera)),
        SheetAction(label: l10n.choosePhoto, icon: CupertinoIcons.photo, onPressed: () => _pick(PhotoSource.gallery)),
      ],
    );
  }

  Widget _nameStep() {
    final l10n = context.l10n;
    final c = context.colors;
    return _StepLayout(
      title: l10n.stepNameTitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloraTextField(
            controller: _name,
            hint: l10n.plantNameHint,
            autofocus: _step == 1,
            large: true,
            textInputAction: TextInputAction.next,
            // Une majuscule à la première lettre seulement : « Monstera du
            // salon », pas « Monstera Du Salon ».
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.sm),
          SpeciesField(
            controller: _species,
            onPicked: (s) {
              if (_name.text.trim().isEmpty) _name.text = s.commonName ?? s.scientificName.split(' ').first;
              _applyCareProfile(s.scientificName, family: s.family);
            },
          ),
          _CarePreview(speciesName: _species.text),
          if (_identification != null) _IdentificationSuggestions(future: _identification!, onPick: _applyCandidate),
          const SizedBox(height: Space.lg),
          Pressable(
            onTap: () => setState(() => _more = !_more),
            scale: 1,
            child: Row(
              children: [
                Text(l10n.moreOptions, style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                AnimatedRotation(turns: _more ? 0.5 : 0, duration: Motion.of(context, Motion.standard), child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: c.sage)),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.easeOut,
            alignment: Alignment.topCenter,
            child: !_more
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.md),
                    child: FloraGroup(
                      children: [
                        FloraListRow(
                          leading: const Text('💧', style: TextStyle(fontSize: 18)),
                          title: l10n.wateringEvery,
                          trailing: QuantityStepper(value: _watering, min: 0, max: 120, label: l10n.everyDays(_watering), onChanged: (v) => setState(() { _watering = v; _intervalsTouched = true; })),
                        ),
                        FloraListRow(
                          leading: const Text('🌱', style: TextStyle(fontSize: 18)),
                          title: l10n.fertilizingEvery,
                          trailing: QuantityStepper(value: _fertilizing, min: 0, max: 365, step: 5, label: l10n.everyDays(_fertilizing), onChanged: (v) => setState(() { _fertilizing = v; _intervalsTouched = true; })),
                        ),
                        FloraListRow(
                          leading: Icon(CupertinoIcons.calendar, size: 20, color: c.inkSecondary),
                          title: l10n.acquiredAt,
                          trailing: Text(_acquiredAt == null ? l10n.none : Dates.dayYear(context, _acquiredAt!), style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                          chevron: false,
                          onTap: () async {
                            final d = await showAdaptiveDatePicker(context, initial: _acquiredAt ?? DateTime.now(), last: DateTime.now(), doneLabel: l10n.done);
                            if (d != null) setState(() => _acquiredAt = d);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(Space.sm),
                          child: FloraTextField(controller: _notes, hint: l10n.notesHint, minLines: 2, maxLines: 5),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      actions: [
        FloraButton(label: l10n.continueLabel, expand: true, onPressed: _name.text.trim().isEmpty ? null : () => _go(2)),
      ],
    );
  }

  void _applyCandidate(IdentificationCandidate c) {
    setState(() {
      _species.text = c.scientificName;
      if (_name.text.trim().isEmpty) _name.text = c.commonName ?? c.scientificName.split(' ').first;
    });
  }

  Widget _locationStep() {
    final l10n = context.l10n;
    final locations = ref.watch(locationsProvider).value ?? const <Location>[];
    return _StepLayout(
      title: l10n.stepLocationTitle,
      scrollable: true,
      body: LocationChips(
        locations: locations,
        selectedId: _noLocation ? null : _locationId,
        noneSelected: _noLocation,
        onSelect: (id) => setState(() {
          _locationId = id;
          _noLocation = id == null;
        }),
        onCreate: () async {
          final created = await showLocationEditSheet(context);
          if (created != null) {
            setState(() {
              _locationId = created.id;
              _noLocation = false;
            });
          }
        },
      ),
      actions: [
        FloraButton(label: l10n.finish, expand: true, loading: _saving, onPressed: _finish),
      ],
    );
  }
}

class _IdentificationSuggestions extends StatelessWidget {
  const _IdentificationSuggestions({required this.future, required this.onPick});

  final Future<List<IdentificationCandidate>> future;
  final ValueChanged<IdentificationCandidate> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<IdentificationCandidate>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Row(children: [const AdaptiveProgress(), const SizedBox(width: Space.xs), Text(l10n.identifying, style: context.text.caption)]),
          );
        }
        final results = (snap.data ?? const <IdentificationCandidate>[]).take(3).toList();
        if (results.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.identifyHint, style: context.text.caption),
              const SizedBox(height: Space.xs),
              FloraGroup(children: [for (final c in results) CandidateRow(candidate: c, onUse: () => onPick(c))]),
            ],
          ),
        );
      },
    );
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.title, required this.body, required this.actions, this.subtitle, this.scrollable = false});

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Space.lg),
        Text(title, style: context.text.title1),
        if (subtitle != null) ...[const SizedBox(height: Space.xs), Text(subtitle!, style: context.text.callout)],
        const SizedBox(height: Space.xl),
      ],
    );
    final content = scrollable
        ? SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, body]),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, Expanded(child: body)]),
          );
    return Column(
      children: [
        Expanded(child: content),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
          child: Column(mainAxisSize: MainAxisSize.min, children: actions),
        ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(color: i == index ? c.sage : c.line, borderRadius: Radii.fullAll),
          ),
      ],
    );
  }
}

/// Aperçu de la fiche d'entretien pendant la création : l'utilisateur voit
/// tout de suite ce que l'app sait de son espèce.
class _CarePreview extends ConsumerWidget {
  const _CarePreview({required this.speciesName});

  final String speciesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    if (speciesName.trim().length < 3) return const SizedBox.shrink();
    final care = ref.watch(careGuideProvider).resolve(speciesName, family: speciesFamilyLookup(ref)(speciesName));
    if (care.match == CareMatch.generic) return const SizedBox.shrink();
    final p = care.profile;
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: FloraCard(
        color: c.sageSoft,
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            const Text('📖', style: TextStyle(fontSize: 18)),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.careWateringNow(p.wateringDaysFor(DateTime.now().month)), style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${l10n.lightName(p.light)} · ${l10n.careMatchLabel(care)}', style: context.text.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
