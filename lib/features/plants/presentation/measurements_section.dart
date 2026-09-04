import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../actions/presentation/add_action_sheet.dart';

final measurementSeriesProvider = StreamProvider.autoDispose.family<List<MeasurementSeries>, String>(
  (ref, id) => ref.watch(measurementRepositoryProvider).watchSeries(id),
);

/// « Hauteur · 42 cm · +8 cm depuis juin » avec une courbe minimale. Jamais un dashboard.
class MeasurementsSection extends ConsumerWidget {
  const MeasurementsSection({super.key, required this.plantId, required this.plantName});

  final String plantId;
  final String plantName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final series = ref.watch(measurementSeriesProvider(plantId)).value ?? const <MeasurementSeries>[];
    if (series.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.measurementsTitle,
            actionLabel: l10n.add,
            onAction: () => showAddActionSheet(context, plantId: plantId, plantName: plantName, initialTypeKey: CareKind.measurement.key),
          ),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              itemCount: series.length,
              separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
              itemBuilder: (context, i) => _SeriesCard(series: series[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.series});

  final MeasurementSeries series;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final latest = series.latest;
    final delta = series.delta;
    final sign = delta > 0 ? '+' : '';
    return FloraCard(
      padding: const EdgeInsets.all(Space.md),
      child: SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.measurementKindName(series.kind), style: context.text.caption),
            const SizedBox(height: 2),
            Text(l10n.formatQuantity(latest.value, latest.unit), style: context.text.title2),
            const Spacer(),
            if (series.hasTrend)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.sinceFirst('$sign${l10n.formatQuantity(delta, latest.unit)}', Dates.monthYear(context, series.first.measuredAt)),
                      style: context.text.caption.copyWith(color: delta >= 0 ? c.sage : c.terracotta, fontWeight: FontWeight.w600),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  SizedBox(width: 48, height: 24, child: CustomPaint(painter: _SparklinePainter(series.points.map((m) => m.value).toList(), c.sage))),
                ],
              )
            else
              Text(Dates.day(context, latest.measuredAt), style: context.text.caption),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1 : (max - min);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - min) / range) * (size.height - 4) - 2;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values || old.color != color;
}
