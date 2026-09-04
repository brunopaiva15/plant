import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

/// Timelapse : les photos défilent en fondu, de la plus ancienne à la plus récente.
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

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_playing) return;
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _ordered.length);
      _schedule();
    });
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
      body: GestureDetector(
        onTap: () => setState(() {
          _playing = !_playing;
          _schedule();
        }),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: Motion.of(context, Motion.slow),
              child: PlantImage(key: ValueKey(photo.id), relativePath: photo.filePath, fit: BoxFit.contain, cacheWidth: 1400),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Space.sm),
                    child: Row(
                      children: [
                        FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.close, onPressed: () => Navigator.of(context).pop(), background: Colors.white24, color: Colors.white),
                        const Spacer(),
                        Text(Dates.dayYear(context, photo.takenAt), style: context.text.callout.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(Space.xl),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _ordered.length; i++)
                              AnimatedContainer(
                                duration: Motion.of(context, Motion.standard),
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: i == _index ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(color: i == _index ? Colors.white : Colors.white38, borderRadius: Radii.fullAll),
                              ),
                          ],
                        ),
                        const SizedBox(height: Space.sm),
                        Text(_playing ? l10n.timelapseHint : l10n.play, style: context.text.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
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
