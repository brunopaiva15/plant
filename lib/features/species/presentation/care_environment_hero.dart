import 'package:flutter/material.dart';

import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../application/care_environment_visual.dart';

/// Résumé spatial de la fiche : le décor encode où placer la plante avant que
/// les cartes détaillées expliquent chaque besoin.
class CareEnvironmentHero extends StatelessWidget {
  const CareEnvironmentHero({super.key, required this.profile, this.speciesName});

  final CareProfile profile;
  final String? speciesName;

  @override
  Widget build(BuildContext context) {
    final spec = CareEnvironmentVisualResolver.resolve(profile, speciesName: speciesName);
    final l10n = context.l10n;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final overlayLabels = scale <= 1.6;
    final labels = _labels(context, spec);

    final semantics = [
      l10n.lightName(spec.light),
      l10n.careHumidityRange(spec.humidityMin, spec.humidityMax),
      if (spec.temperatureMin != null && spec.temperatureMax != null)
        l10n.careTempIdeal(spec.temperatureMin!, spec.temperatureMax!),
    ].join(', ');

    return Semantics(
      image: true,
      label: semantics,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              child: AspectRatio(
                aspectRatio: 1.18,
                child: ClayBox(
                  color: context.colors.surfaceMuted,
                  shape: const ClayShape.rounded(24),
                  depth: ClayDepth.light,
                  clip: true,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        spec.backgroundAsset,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => ColoredBox(color: context.colors.surfaceMuted),
                      ),
                      if (spec.humidity == HumidityNeed.high)
                        IgnorePointer(child: CustomPaint(painter: _HumidityMistPainter(context.colors.water))),
                      _PlantLayer(spec: spec),
                      if (overlayLabels)
                        Positioned(
                          left: Space.sm,
                          right: Space.sm,
                          bottom: Space.sm,
                          child: Wrap(spacing: Space.xs, runSpacing: Space.xs, children: labels),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (!overlayLabels) ...[
              const SizedBox(height: Space.sm),
              Wrap(spacing: Space.xs, runSpacing: Space.xs, children: labels),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _labels(BuildContext context, CareEnvironmentVisualSpec spec) {
    final l10n = context.l10n;
    return [
      FloraChip(label: l10n.lightName(spec.light), emoji: '☀️'),
      FloraChip(label: l10n.careHumidityRange(spec.humidityMin, spec.humidityMax), emoji: '💧'),
      if (spec.temperatureMin != null && spec.temperatureMax != null)
        FloraChip(label: l10n.careTempIdeal(spec.temperatureMin!, spec.temperatureMax!), emoji: '🌡️'),
    ];
  }
}

class _PlantLayer extends StatelessWidget {
  const _PlantLayer({required this.spec});

  final CareEnvironmentVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    final placement = _placement(spec.light);
    return Align(
      alignment: placement.$1,
      child: FractionallySizedBox(
        widthFactor: placement.$2,
        heightFactor: placement.$3,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Space.xl),
          child: Image.asset(
            spec.plantAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Icon(
              Icons.local_florist_rounded,
              size: 72,
              color: context.colors.sage,
            ),
          ),
        ),
      ),
    );
  }

  /// La position fait partie de l'information. La fenêtre des scènes indoor
  /// est à gauche : plus la plante demande de lumière, plus elle s'en approche.
  static (Alignment, double, double) _placement(LightNeed light) => switch (light) {
        LightNeed.shade => (const Alignment(0.58, 0.18), 0.35, 0.58),
        LightNeed.lowLight => (const Alignment(0.38, 0.16), 0.37, 0.60),
        LightNeed.indirect => (const Alignment(0.08, 0.16), 0.40, 0.63),
        LightNeed.brightIndirect => (const Alignment(-0.22, 0.16), 0.43, 0.66),
        LightNeed.someSun => (const Alignment(-0.40, 0.16), 0.44, 0.67),
        LightNeed.fullSun => (const Alignment(-0.53, 0.14), 0.45, 0.68),
      };
}

class _HumidityMistPainter extends CustomPainter {
  const _HumidityMistPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (size.shortestSide * 0.006).clamp(1.5, 3.5)
      ..color = color.withValues(alpha: 0.18);
    final baseX = size.width * 0.76;
    final baseY = size.height * 0.68;
    for (var i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(baseX + i * size.width * 0.025, baseY)
        ..cubicTo(
          baseX - size.width * 0.025 + i * size.width * 0.02,
          baseY - size.height * 0.08,
          baseX + size.width * 0.05 + i * size.width * 0.015,
          baseY - size.height * 0.13,
          baseX + i * size.width * 0.02,
          baseY - size.height * 0.21,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_HumidityMistPainter oldDelegate) => oldDelegate.color != color;
}
