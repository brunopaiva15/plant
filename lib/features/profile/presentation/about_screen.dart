import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const version = '0.1.0';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return FloraPage(
      title: l10n.about,
      child: Column(
        children: [
          const SizedBox(height: Space.xl),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.xlAll),
            alignment: Alignment.center,
            child: const Text('🌿', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: Space.md),
          Text(AppConfig.appName, style: context.text.title1),
          const SizedBox(height: 4),
          Text(l10n.version(version), style: context.text.caption),
          const SizedBox(height: Space.md),
          Text(l10n.onboardingSubtitle, style: context.text.callout, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
