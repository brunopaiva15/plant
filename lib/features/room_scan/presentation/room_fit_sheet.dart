import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/room/placement.dart';
import '../../../domain/room/room_fit_advisor.dart';
import '../../../domain/room/room_scan.dart';
import '../application/room_scan_providers.dart';
import 'room_plan_painter.dart';
import 'room_scan_labels.dart';

/// « Où la poser » : les places d'une fiche dans les pièces relevées. Une
/// pièce à la fois, son plan, trois places nommées, et ce que la pièce vaut
/// en une phrase.
Future<void> showRoomFit(BuildContext context, {required CareProfile profile, required bool generic}) => showFloraScrollableFlow<void>(
  context,
  builder: (ctx, controller) => _RoomFitBody(profile: profile, generic: generic, controller: controller),
);

class _RoomFitBody extends ConsumerStatefulWidget {
  const _RoomFitBody({required this.profile, required this.generic, this.controller});

  final CareProfile profile;

  /// Une fiche générique ne demande aucune lumière précise : pas de place.
  final bool generic;
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
    final scan = scans.where((s) => s.id == _scanId).firstOrNull ?? scans.first;
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
            if (scans.length > 1) ...[
              if (scans.length <= 3)
                AdaptiveSegmented<String>(segments: {for (final s in scans) s.id: s.name}, value: scan.id, onChanged: (id) => setState(() => _scanId = id))
              else
                FloraGroup(
                  children: [
                    FloraListRow(
                      leading: const Text('📐', style: TextStyle(fontSize: 18)),
                      title: scan.name,
                      chevron: true,
                      onTap: () => showAdaptiveActionSheet(
                        context,
                        cancelLabel: l10n.cancel,
                        actions: [for (final s in scans) SheetAction(label: s.name, onPressed: () => setState(() => _scanId = s.id))],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: Space.md),
            ],
            if (widget.generic)
              FloraCard(
                color: context.colors.sunSoft,
                child: Text(l10n.placementGeneric, style: context.text.callout),
              )
            else
              _RoomFitResult(profile: widget.profile, scan: scan),
          ],
        ),
      ),
    );
  }
}

class _RoomFitResult extends ConsumerWidget {
  const _RoomFitResult({required this.profile, required this.scan});

  final CareProfile profile;
  final RoomScan scan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final room = ref.watch(scannedRoomProvider(scan.id));
    final directions = ref.watch(roomDirectionsProvider(scan.id));
    final southern = ref.watch(southernHemisphereProvider);
    return switch (room) {
      AsyncData(:final value) when value != null => Builder(
        builder: (context) {
          final fit = RoomFitAdvisor.place(profile, value, southern: southern, directions: directions);
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
                  ],
                ),
              ),
              if (fit.placements.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                FloraGroup(children: [for (var i = 0; i < fit.placements.length; i++) _placementRow(context, i, fit.placements[i])]),
              ],
              if (fit.all.isNotEmpty && fit.all.first.humidRoom) ...[
                const SizedBox(height: Space.sm),
                Text(l10n.placementHumidRoomNote, style: context.text.caption),
              ],
            ],
          );
        },
      ),
      AsyncLoading() => const Padding(
        padding: EdgeInsets.all(Space.xl),
        child: Center(child: AdaptiveProgress()),
      ),
      _ => EmptyState(emoji: '📐', title: l10n.roomScanFailed, compact: true),
    };
  }

  Widget _placementRow(BuildContext context, int i, Placement p) {
    final l10n = context.l10n;
    final c = context.colors;
    return FloraListRow(
      leading: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.terracotta, shape: BoxShape.circle),
        child: Text(
          '${i + 1}',
          style: context.text.caption.copyWith(color: c.onSage, fontWeight: FontWeight.w700),
        ),
      ),
      title: l10n.placementLine(p),
      titleMaxLines: 2,
      subtitle: [l10n.lightName(p.light), if (p.drafty) l10n.placementDraftyNote].join(' · '),
      chevron: false,
    );
  }
}
