import 'package:flutter/material.dart';

import '../../../core/network/external_service_status.dart';
import '../../../design_system/design_system.dart';

class ServiceStatusScreen extends StatefulWidget {
  const ServiceStatusScreen({super.key});

  @override
  State<ServiceStatusScreen> createState() => _ServiceStatusScreenState();
}

class _ServiceStatusScreenState extends State<ServiceStatusScreen> {
  final _service = ExternalServiceStatusService();
  List<ExternalServiceStatus>? _statuses;
  bool _loading = false;
  DateTime? _checkedAt;

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
      _checkedAt = DateTime.now();
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
          Text(
            'Diagnostic technique caché. Les vérifications sont de simples '
            'probes HTTPS : aucune photo, plante ou donnée personnelle n’est '
            'envoyée, et aucun appel IA payant n’est déclenché.',
            style: context.text.callout,
          ),
          const SizedBox(height: Space.sm),
          Text(
            '« Joignable » signifie que le service répond. Cela ne remplace '
            'pas un test fonctionnel complet de chaque API.',
            style: context.text.caption.copyWith(
              color: context.colors.inkSecondary,
            ),
          ),
          const SizedBox(height: Space.lg),
          if (statuses == null && _loading)
            const Center(child: AdaptiveProgress(size: 28))
          else if (statuses != null)
            FloraGroup(
              children: [
                for (final status in statuses)
                  _StatusRow(status: status),
              ],
            ),
          const SizedBox(height: Space.md),
          FloraButton(
            label: _loading ? 'Vérification…' : 'Actualiser',
            expand: true,
            style: FloraButtonStyle.secondary,
            onPressed: _loading ? null : _refresh,
          ),
          if (_checkedAt != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              'Dernière vérification · ${_time(_checkedAt!)}',
              textAlign: TextAlign.center,
              style: context.text.caption.copyWith(
                color: context.colors.inkTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});

  final ExternalServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, icon, color) = switch (status.state) {
      ExternalServiceState.operational => ('Joignable', '●', c.sage),
      ExternalServiceState.degraded => ('Limité', '●', c.sun),
      ExternalServiceState.unavailable => ('Indisponible', '●', c.rose),
      ExternalServiceState.unconfigured => ('Non configuré', '○', c.inkTertiary),
    };

    final details = <String>[
      if (status.httpStatus != null) 'HTTP ${status.httpStatus}',
      if (status.latency != null) '${status.latency!.inMilliseconds} ms',
    ];

    return FloraListRow(
      leading: Text(
        icon,
        style: context.text.callout.copyWith(color: color),
      ),
      title: status.name,
      subtitle: details.isEmpty ? label : '${label} · ${details.join(' · ')}',
      chevron: false,
    );
  }
}
