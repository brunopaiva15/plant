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
