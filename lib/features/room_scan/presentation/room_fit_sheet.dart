import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/home/home_climate_advisor.dart';
import '../../../domain/room/placement.dart';
import '../../../domain/room/room_fit_advisor.dart';
import '../../../domain/room/room_scan.dart';
import '../../home_climate/application/home_climate_providers.dart';
import '../../home_climate/presentation/home_climate_widgets.dart';
import '../application/room_scan_providers.dart';
import 'room_plan_painter.dart';
import 'room_scan_labels.dart';

/// « Où la poser » : les places d'une fiche dans les pièces relevées. Les
/// pièces classées d'abord, quand il y en a plusieurs ; puis la pièce
/// choisie, son plan, trois places nommées, et ce qu'elle vaut en une
/// phrase. Pour une plante du jardin, la place d'aujourd'hui si elle est
/// posée sur le plan, et « Choisir cette place ».
Future<void> showRoomFit(BuildContext context, {required CareProfile profile, required bool generic, String? plantId, String? plantName}) =>
    showFloraScrollableFlow<void>(
      context,
      builder: (ctx, controller) => _RoomFitBody(profile: profile, generic: generic, plantId: plantId, plantName: plantName, controller: controller),
    );

class _RoomFitBody extends ConsumerStatefulWidget {
  const _RoomFitBody({required this.profile, required this.generic, this.plantId, this.plantName, this.controller});

  final CareProfile profile;

  /// Une fiche générique ne demande aucune lumière précise : pas de place.
  final bool generic;
  final String? plantId;
  final String? plantName;
  final ScrollController? controller;

  @override
  ConsumerState<_RoomFitBody> createState() => _RoomFitBodyState();
}

class _RoomFitBodyState extends ConsumerState<_RoomFitBody> {
  String? _scanId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scans = ref.watch(roomScansProvider).value ?? const <RoomScan>[];
    if (scans.isEmpty) return const SizedBox.shrink();
    // Les pièces, classées par ce qu'elles valent pour la fiche : la
    // meilleure s'ouvre d'elle-même.
    final ranked = widget.generic ? <(RoomScan, RoomFit?)>[for (final s in scans) (s, null)] : _ranked(scans);
    final scan = scans.where((s) => s.id == _scanId).firstOrNull ?? ranked.first.$1;
    final side = Space.page + readableInset(context);
    // La sheet d'iOS prête son contrôleur à la vue qui défile : sans lui,
    // elle remporte tous les gestes verticaux (voir showFloraScrollableFlow).
    return FloraPage(
      title: l10n.placementTitle,
      scrollable: false,
      child: SingleChildScrollView(
        controller: widget.controller,
        physics: floraScrollPhysics,
        padding: EdgeInsets.fromLTRB(side, Space.md, side, Space.huge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.placementHint, style: context.text.callout),
            const SizedBox(height: Space.md),
            if (widget.generic)
              FloraCard(color: context.colors.sunSoft, child: Text(l10n.placementGeneric, style: context.text.callout))
            else ...[
              if (scans.length > 1) ...[
                FloraGroup(
                  header: l10n.placementAllRooms,
                  children: [
                    for (final (s, fit) in ranked)
                      FloraListRow(
                        leading: Text(
                          switch (fit?.verdict) {
                            RoomFitVerdict.good => '🌿',
                            RoomFitVerdict.acceptable => '🌤️',
                            _ => '🚫',
                          },
                          style: const TextStyle(fontSize: 18),
                        ),
                        title: s.name,
                        subtitle: fit == null
                            ? null
                            : fit.placements.isEmpty
                                ? (fit.shortfall == null ? l10n.verdictLine(fit.verdict) : l10n.shortfallLine(fit.shortfall!))
                                : l10n.placementLine(fit.placements.first),
                        subtitleColor: fit?.verdict == RoomFitVerdict.unsuitable ? context.colors.danger : null,
                        chevron: s.id != scan.id,
                        trailing: s.id == scan.id ? Icon(CupertinoIcons.checkmark, size: 16, color: context.colors.sage) : null,
                        onTap: () => setState(() => _scanId = s.id),
                      ),
                  ],
                ),
                const SizedBox(height: Space.md),
              ],
              _RoomFitResult(profile: widget.profile, scan: scan, plantId: widget.plantId, plantName: widget.plantName),
            ],
          ],
        ),
      ),
    );
  }

  List<(RoomScan, RoomFit?)> _ranked(List<RoomScan> scans) {
    final out = <(RoomScan, RoomFit?)>[
      for (final s in scans)
        (s, switch (ref.watch(roomSurveyProvider(s.id))) { final survey? => RoomFitAdvisor.placeIn(widget.profile, survey), null => null }),
    ];
    out.sort((a, b) => (b.$2?.all.firstOrNull?.score ?? -1).compareTo(a.$2?.all.firstOrNull?.score ?? -1));
    return out;
  }
}

class _RoomFitResult extends ConsumerWidget {
  const _RoomFitResult({required this.profile, required this.scan, this.plantId, this.plantName});

  final CareProfile profile;
  final RoomScan scan;
  final String? plantId;
  final String? plantName;

  Future<void> _choose(BuildContext context, WidgetRef ref, Placement p) async {
    final l10n = context.l10n;
    await ref.read(roomScanControllerProvider.notifier).placePlant(scan.id, plantId!, p.point, locationId: scan.locationId);
    if (!context.mounted) return;
    Haptics.success();
    ref.read(toastProvider.notifier).show(ToastData(message: l10n.placementChosen(l10n.placementLine(p)), emoji: '🌿'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final loading = ref.watch(scannedRoomProvider(scan.id)).isLoading;
    final judged = ref.watch(roomForFitProvider(scan.id));
    final survey = ref.watch(roomSurveyProvider(scan.id));
    final markers = ref.watch(roomMarkersProvider(scan.id)).value ?? const [];
    final heaters = heaterPoints(markers);
    final plants = plantPoints(markers);
    // La place d'aujourd'hui de cette plante, si elle est posée sur ce plan.
    final currentSpot = plantId == null ? null : ref.watch(roomPlantSpotsProvider(scan.id))[plantId!];
    return switch ((judged, survey)) {
      (final value?, final survey?) => Builder(
        builder: (context) {
          final fit = RoomFitAdvisor.placeIn(profile, survey);
          final current = currentSpot == null ? null : RoomFitAdvisor.judge(profile, currentSpot, humidRoom: survey.humidRoom);
          final tint = switch (fit.verdict) {
            RoomFitVerdict.good => c.sageSoft,
            RoomFitVerdict.acceptable => c.sunSoft,
            RoomFitVerdict.unsuitable => c.roseSoft,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: l10n.placementPlanSemantics(fit.placements.length),
                child: FloraCard(
                  padding: EdgeInsets.zero,
                  clip: true,
                  child: AspectRatio(
                    aspectRatio: 1.25,
                    child: CustomPaint(
                      painter: RoomPlanPainter(
                        room: value,
                        fit: fit,
                        heaters: heaters,
                        plants: plants.values.toList(),
                        current: current?.point,
                        colors: c,
                        numberStyle: context.text.caption.copyWith(color: c.onSage, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              FloraCard(
                color: tint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.verdictLine(fit.verdict), style: context.text.title3),
                    if (fit.shortfall case final s?) ...[const SizedBox(height: 2), Text(l10n.shortfallLine(s), style: context.text.callout)],
                    if (current != null) ...[
                      const SizedBox(height: 2),
                      Text(l10n.placementCurrent(l10n.placementLine(current), l10n.lightName(current.light)), style: context.text.callout),
                    ],
                  ],
                ),
              ),
              if (fit.placements.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                FloraGroup(children: [for (var i = 0; i < fit.placements.length; i++) _placementRow(context, ref, i, fit.placements[i])]),
              ],
              if (fit.all.isNotEmpty && fit.all.first.humidRoom) ...[
                const SizedBox(height: Space.sm),
                Text(l10n.placementHumidRoomNote, style: context.text.caption),
              ],
              _HomeReadingLine(profile: profile, scan: scan),
            ],
          );
        },
      ),
      _ when loading => const Padding(padding: EdgeInsets.all(Space.xl), child: Center(child: AdaptiveProgress())),
      _ => EmptyState(emoji: '📐', title: l10n.roomScanFailed, compact: true),
    };
  }

  Widget _placementRow(BuildContext context, WidgetRef ref, int i, Placement p) {
    final l10n = context.l10n;
    final c = context.colors;
    return FloraListRow(
      leading: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.terracotta, shape: BoxShape.circle),
        child: Text('${i + 1}', style: context.text.caption.copyWith(color: c.onSage, fontWeight: FontWeight.w700)),
      ),
      title: l10n.placementLine(p),
      titleMaxLines: 2,
      subtitle: [l10n.lightName(p.light), ...l10n.placementNotes(p)].join(' · '),
      // Une plante du jardin peut prendre la place : elle se pose sur le
      // plan, et déménage dans l'emplacement du relevé s'il en a un.
      trailing: plantId == null ? null : FloraButton(label: l10n.placementChoose, size: FloraButtonSize.small, style: FloraButtonStyle.tonal, onPressed: () => _choose(context, ref, p)),
      chevron: false,
    );
  }
}

/// La mesure du capteur de la maison, quand il est dans cette pièce : le
/// capteur porte le nom de sa pièce, le relevé le sien ou celui de son
/// emplacement, et c'est le nom qui les rapproche — comme pour les conseils
/// du jour. Rien sans capteur, rien dans une autre pièce.
class _HomeReadingLine extends ConsumerWidget {
  const _HomeReadingLine({required this.profile, required this.scan});

  final CareProfile profile;
  final RoomScan scan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final reading = ref.watch(homeReadingProvider).value;
    if (reading == null || reading.isEmpty) return const SizedBox.shrink();
    final sensorRoom = reading.sensor?.roomName?.trim().toLowerCase();
    if (sensorRoom == null || sensorRoom.isEmpty) return const SizedBox.shrink();
    final location = (ref.watch(locationsProvider).value ?? const []).where((l) => l.id == scan.locationId).firstOrNull;
    final names = {scan.name.trim().toLowerCase(), ?location?.name.trim().toLowerCase()};
    if (!names.contains(sensorRoom)) return const SizedBox.shrink();
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final fit = homeFit(reading, profile);
    return Padding(
      padding: const EdgeInsets.only(top: Space.md),
      child: FloraCard(
        color: fit == null ? c.sageSoft : c.sunSoft,
        child: Row(
          children: [
            const EmojiTile(emoji: '🏠'),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.placementAtHome} · ${homeReadingLabel(reading, metric: metric)}', style: context.text.title3),
                  const SizedBox(height: 2),
                  Text(
                    switch (fit) {
                      null => l10n.homeClimateFits,
                      HomeClimateTipKind.cold => l10n.homeClimateTooCold,
                      HomeClimateTipKind.hot => l10n.homeClimateTooHot,
                      HomeClimateTipKind.dryAir => l10n.homeClimateTooDry,
                      HomeClimateTipKind.humidAir => l10n.homeClimateTooHumid,
                    },
                    style: context.text.callout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
