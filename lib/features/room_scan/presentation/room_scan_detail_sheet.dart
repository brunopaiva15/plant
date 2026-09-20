import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/room/placement.dart';
import '../../../domain/room/room_scan.dart';
import '../../../domain/room/scanned_room.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../../plants/application/plant_providers.dart';
import '../application/room_scan_providers.dart';
import 'location_room_section.dart';
import 'room_marker_placer_sheet.dart';
import 'room_plan_painter.dart';
import 'room_scan_labels.dart';

/// La feuille d'un relevé : son plan, son nom, l'emplacement qu'il décrit,
/// l'orientation de ses fenêtres, ses radiateurs, qui serait bien ici, et
/// de quoi le supprimer.
Future<void> showRoomScanDetail(BuildContext context, {required String scanId}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (ctx) => _RoomScanDetailBody(scanId: scanId));

class _RoomScanDetailBody extends ConsumerStatefulWidget {
  const _RoomScanDetailBody({required this.scanId});

  final String scanId;

  @override
  ConsumerState<_RoomScanDetailBody> createState() => _RoomScanDetailBodyState();
}

class _RoomScanDetailBodyState extends ConsumerState<_RoomScanDetailBody> {
  final _name = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _rename(RoomScan scan) async {
    final name = _name.text.trim();
    if (name.isEmpty || name == scan.name) return;
    await ref.read(roomScanRepositoryProvider).update(scan.copyWith(name: name));
  }

  Future<void> _pickLocation(RoomScan scan) async {
    final choice = await showLocationPicker(context, selectedId: scan.locationId);
    if (choice == null) return;
    await ref.read(roomScanRepositoryProvider).update(scan.copyWith(locationId: () => choice.id));
    Haptics.light();
  }

  /// Huit points cardinaux dans une feuille d'actions : la boussole propose,
  /// la main confirme.
  Future<void> _pickOrientation(RoomScan scan, ScannedRoom room, int index) async {
    final l10n = context.l10n;
    final w = room.windows[index];
    await showAdaptiveActionSheet(
      context,
      title: l10n.roomScanWindowN(index + 1),
      cancelLabel: l10n.cancel,
      actions: [
        for (final d in CardinalDirection.values)
          SheetAction(
            label: l10n.directionName(d),
            onPressed: () async {
              await ref.read(roomScanRepositoryProvider).setWindowOrientation(scan.id, index, d, x: w.center.x, z: w.center.z);
              Haptics.success();
            },
          ),
      ],
    );
  }

  /// Un toucher sur un repère du plan propose de le retirer.
  Future<void> _tapPlan(RoomScan scan, ScannedRoom room, List<RoomMarker> markers, RoomPoint at) async {
    final l10n = context.l10n;
    final hit = markers.where((m) => (m.kind == RoomMarkerKind.heater || m.kind == RoomMarkerKind.plant) && RoomPoint(m.x, m.z).distanceTo(at) < 0.5).firstOrNull;
    if (hit == null) return;
    final plantName = hit.kind == RoomMarkerKind.plant
        ? (ref.read(plantSummariesProvider(const PlantFilter())).value ?? const <PlantSummary>[]).where((p) => p.plant.id == hit.plantId).firstOrNull?.plant.name
        : null;
    await showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(
          label: hit.kind == RoomMarkerKind.plant ? l10n.roomScanRemovePlant(plantName ?? '·') : l10n.roomScanRemoveHeater,
          destructive: true,
          onPressed: () => ref.read(roomScanControllerProvider.notifier).removeMarker(hit.id),
        ),
      ],
    );
  }

  /// Un radiateur : la feuille qui le pose, puis le repère en base.
  Future<void> _placeHeater(RoomScan scan, ScannedRoom room, List<RoomMarker> markers) async {
    final at = await showRoomMarkerPlacer(context, room: room, markers: markers, kind: RoomMarkerPlacement.heater);
    if (at == null || !mounted) return;
    await ref.read(roomScanControllerProvider.notifier).addHeater(scan.id, room, at);
    Haptics.success();
  }

  /// Quelle plante poser : celles de l'emplacement lié d'abord, sinon
  /// toutes celles du jardin ; puis la feuille qui la pose.
  Future<void> _pickPlantToPlace(RoomScan scan, ScannedRoom room, List<RoomMarker> markers) async {
    final l10n = context.l10n;
    final all = ref.read(plantSummariesProvider(const PlantFilter())).value ?? const <PlantSummary>[];
    final here = scan.locationId == null ? const <PlantSummary>[] : all.where((p) => p.plant.locationId == scan.locationId).toList();
    final choices = here.isNotEmpty ? here : all;
    if (choices.isEmpty) {
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.roomScanNoPlantToPlace, emoji: '🌿'));
      return;
    }
    await showAdaptiveActionSheet(
      context,
      title: l10n.roomScanAddPlant,
      cancelLabel: l10n.cancel,
      actions: [for (final p in choices) SheetAction(label: p.plant.name, onPressed: () => _placePlant(scan, room, markers, p))],
    );
  }

  Future<void> _placePlant(RoomScan scan, ScannedRoom room, List<RoomMarker> markers, PlantSummary plant) async {
    final at = await showRoomMarkerPlacer(context, room: room, markers: markers, kind: RoomMarkerPlacement.plant, plantName: plant.plant.name);
    if (at == null || !mounted) return;
    await ref.read(roomScanControllerProvider.notifier).placePlant(scan.id, plant.plant.id, at);
    Haptics.success();
  }

  Future<void> _delete(RoomScan scan) async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.roomScanDelete, message: l10n.roomScanDeleteConfirm, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok || !mounted) return;
    await ref.read(roomScanControllerProvider.notifier).delete(scan);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final scan = (ref.watch(roomScansProvider).value ?? const <RoomScan>[]).where((s) => s.id == widget.scanId).firstOrNull;
    if (scan == null) return const SizedBox.shrink();
    if (!_seeded) {
      _name.text = scan.name;
      _seeded = true;
    }
    final room = ref.watch(roomForFitProvider(scan.id));
    final markers = ref.watch(roomMarkersProvider(scan.id)).value ?? const <RoomMarker>[];
    final heaters = heaterPoints(markers);
    final plants = plantPoints(markers).values.toList();
    final location = (ref.watch(locationsProvider).value ?? const []).where((l) => l.id == scan.locationId).firstOrNull;
    final suggestion = ref.watch(roomFillSuggestionProvider(scan.id));
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: scan.name),
          if (room != null) _plan(scan, room, markers, heaters, plants),
          const SizedBox(height: Space.md),
          FloraGroup(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
                child: FloraTextField(
                  controller: _name,
                  hint: l10n.roomScanName,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _rename(scan),
                ),
              ),
              FloraListRow(
                leading: const Text('📍', style: TextStyle(fontSize: 18)),
                title: l10n.roomScanLinkedLocation,
                trailing: Text(location?.name ?? l10n.none, style: context.text.callout.copyWith(color: c.inkSecondary)),
                chevron: true,
                onTap: () => _pickLocation(scan),
              ),
              if (location != null && suggestion != null) RoomFillLocationRow(scan: scan, location: location, suggestion: suggestion),
            ],
          ),
          if (room != null && room.windows.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            FloraGroup(
              header: l10n.roomScanWindows,
              footer: l10n.roomScanOrientationHelp,
              children: [for (var i = 0; i < room.windows.length; i++) _windowRow(scan, room, markers, i)],
            ),
          ],
          if (room != null) ...[
            const SizedBox(height: Space.lg),
            FloraGroup(
              header: l10n.roomScanHeaters,
              footer: l10n.roomScanHeatersHelp,
              children: [
                FloraListRow(
                  leading: const Text('♨️', style: TextStyle(fontSize: 18)),
                  title: l10n.roomScanAddHeater,
                  subtitle: l10n.roomScanHeatersCount(heaters.length),
                  chevron: true,
                  onTap: () => _placeHeater(scan, room, markers),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            FloraGroup(
              header: l10n.roomScanPlantsOnPlan,
              footer: l10n.roomScanPlantsHelp,
              children: [
                FloraListRow(
                  leading: const Text('🌿', style: TextStyle(fontSize: 18)),
                  title: l10n.roomScanAddPlant,
                  subtitle: l10n.plantCount(plantPoints(markers).length),
                  chevron: true,
                  onTap: () => _pickPlantToPlace(scan, room, markers),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            _WhoFitsHere(scanId: scan.id),
          ],
          const SizedBox(height: Space.lg),
          FloraGroup(
            children: [
              FloraListRow(title: l10n.roomScanDelete, destructive: true, chevron: false, onTap: () => _delete(scan)),
            ],
          ),
        ],
      ),
    );
  }

  /// Le plan, et le doigt dessus : la géométrie du peintre rend le point de
  /// la pièce qu'on a touché.
  Widget _plan(RoomScan scan, ScannedRoom room, List<RoomMarker> markers, List<RoomPoint> heaters, List<RoomPoint> plants) {
    final c = context.colors;
    return FloraCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: AspectRatio(
        aspectRatio: 1.25,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _tapPlan(scan, room, markers, RoomPlanGeometry(room: room, size: size).toRoom(d.localPosition)),
              child: CustomPaint(
                size: size,
                painter: RoomPlanPainter(room: room, heaters: heaters, plants: plants, colors: c, numberStyle: context.text.caption),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _windowRow(RoomScan scan, ScannedRoom room, List<RoomMarker> markers, int i) {
    final l10n = context.l10n;
    final confirmed = markers.where((m) => m.kind == RoomMarkerKind.windowOrientation && m.windowIndex == i).firstOrNull?.orientation;
    final compass = room.windowDirection(room.windows[i]);
    final direction = confirmed ?? compass;
    final dressing = windowDressings(room, markers)[i];
    return FloraListRow(
      leading: const Text('🪟', style: TextStyle(fontSize: 18)),
      title: l10n.roomScanWindowN(i + 1),
      subtitle: [
        direction == null ? l10n.roomScanWindowUnknown : '${l10n.directionName(direction)} · ${confirmed != null ? l10n.roomScanWindowConfirmed : l10n.roomScanWindowFromCompass}',
        if (dressing != WindowDressing.none) l10n.dressingName(dressing),
      ].join(' · '),
      // Le rideau a son bouton : RoomPlan ne le voit pas, et il change la
      // lumière autant que l'orientation.
      trailing: FloraButton(label: l10n.roomScanCurtain, size: FloraButtonSize.small, style: FloraButtonStyle.tonal, onPressed: () => _pickDressing(scan, room, i)),
      chevron: false,
      onTap: () => _pickOrientation(scan, room, i),
    );
  }

  Future<void> _pickDressing(RoomScan scan, ScannedRoom room, int index) async {
    final l10n = context.l10n;
    final w = room.windows[index];
    await showAdaptiveActionSheet(
      context,
      title: l10n.roomScanWindowN(index + 1),
      message: l10n.roomScanCurtainHelp,
      cancelLabel: l10n.cancel,
      actions: [
        for (final d in WindowDressing.values)
          SheetAction(
            label: l10n.dressingName(d),
            onPressed: () async {
              await ref.read(roomScanControllerProvider.notifier).setWindowDressing(scan.id, index, d, x: w.center.x, z: w.center.z);
              Haptics.success();
            },
          ),
      ],
    );
  }
}

/// « Qui serait bien ici » : les plantes du jardin classées par ce que la
/// pièce leur donne, et la fiche d'entretien à un toucher.
class _WhoFitsHere extends ConsumerWidget {
  const _WhoFitsHere({required this.scanId});

  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final fits = ref.watch(roomPlantFitsProvider(scanId));
    return FloraGroup(
      header: l10n.roomScanWhoFitsHere,
      footer: fits.isEmpty ? l10n.roomScanNoPlantsToRank : l10n.roomScanWhoFitsHint,
      children: [
        for (final f in fits)
          FloraListRow(
            leading: Text(
              switch (f.fit.verdict) {
                RoomFitVerdict.good => '🌿',
                RoomFitVerdict.acceptable => '🌤️',
                RoomFitVerdict.unsuitable => '🚫',
              },
              style: const TextStyle(fontSize: 18),
            ),
            title: f.plant.plant.name,
            // Une plante posée sur le plan est jugée là où elle est ; les
            // autres, à leur meilleure place.
            subtitle: switch ((f.current, f.fit.verdict)) {
              (final now?, _) when f.betterElsewhere => l10n.roomScanPlantBetterAt(l10n.lightName(now.light), l10n.placementLine(f.fit.placements.first)),
              (final now?, _) => l10n.roomScanPlantWellPlaced(l10n.lightName(now.light)),
              (null, RoomFitVerdict.unsuitable) => f.fit.shortfall == null ? l10n.verdictLine(f.fit.verdict) : l10n.shortfallLine(f.fit.shortfall!),
              (null, _) => f.fit.placements.isEmpty ? l10n.verdictLine(f.fit.verdict) : l10n.placementLine(f.fit.placements.first),
            },
            subtitleColor: f.fit.verdict == RoomFitVerdict.unsuitable ? c.danger : null,
            chevron: true,
            onTap: () => context.push(Routes.plantCare(f.plant.plant.id)),
          ),
      ],
    );
  }
}
