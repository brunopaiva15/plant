import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/room/room_scan.dart';
import '../../../domain/room/scanned_room.dart';
import 'room_plan_painter.dart';

/// Ce qu'on pose sur le plan.
enum RoomMarkerPlacement { heater, plant }

/// Le glissement du plan, qui ne cède pas la main à la feuille.
///
/// La feuille arme son propre glissement vertical — c'est sa fermeture —, et
/// il se déclare au bout de dix-huit points ; un glissement en tous sens en
/// demande trente-six. L'arène donnait donc le doigt à la feuille, qui
/// descendait, et le repère ne bougeait pas d'un pouce : « il se déplace tant
/// qu'on n'a pas validé » était vrai partout sauf sur le plan, c'est-à-dire
/// nulle part.
///
/// Celui-ci s'adjuge le doigt au premier déplacement. Le toucher reste
/// intact — un doigt qui ne bouge pas ne déclenche aucun glissement —, et la
/// feuille garde tout ce qui ne commence pas sur le plan : la poignée,
/// l'en-tête, les boutons.
class _GlissementDuPlan extends PanGestureRecognizer {
  @override
  bool hasSufficientGlobalDistanceToAccept(PointerDeviceKind kind, double? deviceTouchSlop) => true;
}

/// La feuille qui pose un repère : le plan en grand, la consigne au-dessus,
/// le repère sous le doigt — il se déplace tant qu'on n'a pas validé —, puis
/// « Poser ». Rend le point choisi, ou rien.
///
/// Un radiateur se colle au mur le plus proche du doigt ; une plante reste
/// là où on l'a posée.
Future<RoomPoint?> showRoomMarkerPlacer(
  BuildContext context, {
  required ScannedRoom room,
  required List<RoomMarker> markers,
  required RoomMarkerPlacement kind,
  String? plantName,
}) =>
    showFloraSheet<RoomPoint>(
      context,
      builder: (ctx) => _PlacerBody(room: room, markers: markers, kind: kind, plantName: plantName),
    );

class _PlacerBody extends StatefulWidget {
  const _PlacerBody({required this.room, required this.markers, required this.kind, this.plantName});

  final ScannedRoom room;
  final List<RoomMarker> markers;
  final RoomMarkerPlacement kind;
  final String? plantName;

  @override
  State<_PlacerBody> createState() => _PlacerBodyState();
}

class _PlacerBodyState extends State<_PlacerBody> {
  RoomPoint? _pending;

  void _tap(RoomPoint at) {
    final p = widget.kind == RoomMarkerPlacement.heater ? widget.room.snapToWall(at) : at;
    if (!widget.room.contains(p)) return;
    Haptics.light();
    setState(() => _pending = p);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final heater = widget.kind == RoomMarkerPlacement.heater;
    final title = heater ? l10n.roomScanAddHeater : l10n.roomScanAddPlant;
    final hint = heater ? l10n.roomScanTapForHeater : l10n.roomScanTapForPlant(widget.plantName ?? '·');
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: title),
          Text(hint, style: context.text.callout),
          const SizedBox(height: Space.md),
          // Le plan tient dans la feuille, et garde ses proportions.
          //
          // Il prenait la largeur du texte et se donnait la hauteur qui va
          // avec : sur une fenêtre large — un iPad, un iPhone Duo ouvert —,
          // cela faisait sept cents points de plan dans une feuille qui n'en
          // a que la hauteur de l'écran, et la colonne débordait par le bas.
          // Le bouton « Poser » se retrouvait hors de l'écran, sans rien pour
          // défiler jusqu'à lui.
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.42),
              child: FloraCard(
                padding: EdgeInsets.zero,
                clip: true,
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      final geometry = RoomPlanGeometry(room: widget.room, size: size);
                      return RawGestureDetector(
                        behavior: HitTestBehavior.opaque,
                        gestures: {
                          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                            TapGestureRecognizer.new,
                            (r) {
                              r.onTapUp = (d) => _tap(geometry.toRoom(d.localPosition));
                            },
                          ),
                          _GlissementDuPlan: GestureRecognizerFactoryWithHandlers<_GlissementDuPlan>(
                            _GlissementDuPlan.new,
                            (r) {
                              r.onStart = (d) => _tap(geometry.toRoom(d.localPosition));
                              r.onUpdate = (d) => _tap(geometry.toRoom(d.localPosition));
                            },
                          ),
                        },
                        child: CustomPaint(
                          size: size,
                          painter: RoomPlanPainter(
                            room: widget.room,
                            heaters: [...heaterPoints(widget.markers), if (heater && _pending != null) _pending!],
                            plants: plantPoints(widget.markers).values.toList(),
                            current: !heater ? _pending : null,
                            colors: c,
                            numberStyle: context.text.caption,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          FloraButton(
            label: l10n.roomScanPlace,
            icon: heater ? CupertinoIcons.flame : CupertinoIcons.leaf_arrow_circlepath,
            expand: true,
            onPressed: _pending == null ? null : () => Navigator.of(context).pop(_pending),
          ),
          const SizedBox(height: Space.xs),
          FloraButton(label: l10n.cancel, style: FloraButtonStyle.ghost, expand: true, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
