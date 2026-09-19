import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/external_service_status.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/identification/identification_metrics.dart';

class ServiceStatusScreen extends ConsumerStatefulWidget {
  const ServiceStatusScreen({super.key});

  @override
  ConsumerState<ServiceStatusScreen> createState() =>
      _ServiceStatusScreenState();
}

class _ServiceStatusScreenState extends ConsumerState<ServiceStatusScreen> {
  final _service = ExternalServiceStatusService();
  List<ExternalServiceStatus>? _statuses;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    final statuses = await _service.checkAll();
    if (!mounted) return;
    setState(() {
      _statuses = statuses;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _statuses;
    return FloraPage(
      title: 'État des services',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (statuses == null && _loading)
            const Center(child: AdaptiveProgress(size: 28))
          else if (statuses != null)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statuses.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: Space.sm,
                mainAxisSpacing: Space.sm,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) =>
                  _StatusTile(status: statuses[index]),
            ),
          const SizedBox(height: Space.md),
          _JevDecisions(
            metrics: ref.read(identificationMetricsStoreProvider).read(),
          ),
          const SizedBox(height: Space.md),
          FloraButton(
            label: _loading ? 'Vérification…' : 'Actualiser',
            expand: true,
            style: FloraButtonStyle.secondary,
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
    );
  }
}

/// Ce que Jev a décidé, et ce que la personne en a fait.
///
/// Les deux dernières lignes sont les seules qui disent si l'arbitrage sert
/// à quelque chose : un résultat montré puis cherché en ligne était
/// insuffisant, une incertitude tranchée malgré tout était trop prudente.
/// Le reste décrit seulement l'activité.
///
/// Comme le reste de cet écran caché, les libellés ne passent pas par les
/// ARB : c'est un panneau de diagnostic, pas une surface produit.
class _JevDecisions extends StatelessWidget {
  const _JevDecisions({required this.metrics});

  final IdentificationMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final quiet = context.text.caption
        .copyWith(color: context.colors.inkSecondary);
    if (metrics.jevConsulted == 0) {
      return FloraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Décisions Jev', style: context.text.title3),
            const SizedBox(height: Space.xs),
            Text('Aucun arbitrage pour l’instant.', style: quiet),
          ],
        ),
      );
    }

    final latency = metrics.jevAverageLatencyMs.round();
    return FloraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Décisions Jev', style: context.text.title3),
          const SizedBox(height: Space.xs),
          Text(
            '${metrics.jevConsulted} arbitrages · '
            '${metrics.jevIncidents} sans réponse · '
            '$latency ms en moyenne',
            style: quiet,
          ),
          const SizedBox(height: Space.xxs),
          Text(
            'Montrer : ${metrics.jevShowResult} · '
            'Autre photo : ${metrics.jevAskAnotherPhoto} · '
            'Incertain : ${metrics.jevKeepUncertain}',
            style: quiet,
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Montrés puis cherchés en ligne : '
            '${metrics.jevShowResultThenSearched} sur ${metrics.jevShowResult}',
            style: quiet,
          ),
          const SizedBox(height: Space.xxs),
          Text(
            'Incertitudes tranchées quand même : '
            '${metrics.jevKeepUncertainThenPicked} sur ${metrics.jevKeepUncertain}',
            style: quiet,
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.status});

  final ExternalServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reachable = switch (status.state) {
      ExternalServiceState.operational ||
      ExternalServiceState.degraded => true,
      ExternalServiceState.unavailable ||
      ExternalServiceState.unconfigured => false,
    };

    final color = reachable ? c.sage : c.danger;

    return FloraCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            status.name,
            style: context.text.callout.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Space.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('●', style: context.text.callout.copyWith(color: color)),
              const SizedBox(width: Space.xxs),
              Flexible(
                child: Text(
                  reachable ? 'Joignable' : 'Pas joignable',
                  style: context.text.caption.copyWith(color: color),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
