import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

/// Ouvre le timelapse en plein écran, en fondu sur le noir.
Future<void> showTimelapse(BuildContext context, List<PlantPhoto> photos) {
  Haptics.light();
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: Motion.of(context, Motion.emphasis),
      pageBuilder: (_, anim, _) => FadeTransition(opacity: anim, child: TimelapseScreen(photos: photos)),
    ),
  );
}

/// Timelapse : les photos défilent en fondu, de la plus ancienne à la plus
/// récente, la date et le titre au-dessus.
///
/// Le curseur remplace la rangée de points : il tient trente photos comme
/// trois, et il se tire — on peut revenir à un mois précis au lieu d'attendre
/// que la boucle y repasse. Le bouton dit s'il joue ; toucher la photo fait
/// la même chose, pour la main qui tient le téléphone.
class TimelapseScreen extends StatefulWidget {
  const TimelapseScreen({super.key, required this.photos});

  /// Photos de la plante, de la plus récente à la plus ancienne.
  final List<PlantPhoto> photos;

  @override
  State<TimelapseScreen> createState() => _TimelapseScreenState();
}

class _TimelapseScreenState extends State<TimelapseScreen> {
  late final _ordered = widget.photos.reversed.toList();
  int _index = 0;
  bool _playing = true;
  Timer? _timer;

  static const _frame = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_playing) return;
    _timer = Timer(_frame, () {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _ordered.length);
      _schedule();
    });
  }

  void _toggle() {
    Haptics.selection();
    setState(() => _playing = !_playing);
    _schedule();
  }

  /// Tirer le curseur, c'est reprendre la main : la lecture s'arrête là où
  /// le doigt s'est posé.
  void _seek(double v) {
    final i = v.round().clamp(0, _ordered.length - 1);
    if (i == _index && !_playing) return;
    setState(() {
      _index = i;
      _playing = false;
    });
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final photo = _ordered[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.slow),
              child: PlantImage(key: ValueKey(photo.id), relativePath: photo.filePath, remoteUrl: photo.remoteUrl, fit: BoxFit.contain, cacheWidth: 1400),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.close, onPressed: () => Navigator.of(context).pop(), background: Colors.white24, color: Colors.white),
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: Space.xs),
                            Text(Dates.dayYear(context, photo.takenAt), style: context.text.callout.copyWith(color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                            if (photo.label != null)
                              Text(photo.label!, style: context.text.caption.copyWith(color: Colors.white70), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
                  child: Column(
                    children: [
                      Pressable(
                        onTap: _toggle,
                        scale: 0.9,
                        semanticLabel: _playing ? l10n.pause : l10n.play,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                          child: Icon(_playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      AdaptiveSlider(
                        value: _index.toDouble(),
                        max: (_ordered.length - 1).toDouble(),
                        divisions: _ordered.length - 1,
                        onChanged: _seek,
                        color: Colors.white,
                      ),
                      Row(
                        children: [
                          Text(Dates.monthYear(context, _ordered.first.takenAt), style: context.text.caption.copyWith(color: Colors.white70)),
                          const Spacer(),
                          Text(Dates.monthYear(context, _ordered.last.takenAt), style: context.text.caption.copyWith(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(l10n.timelapseHint, style: context.text.caption.copyWith(color: Colors.white54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
