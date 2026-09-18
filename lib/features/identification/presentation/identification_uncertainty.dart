import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// État produit affiché quand le pipeline a décidé qu'aucune espèce ne peut
/// être présentée comme conclusion fiable.
class IdentificationUncertaintyNotice extends StatelessWidget {
  const IdentificationUncertaintyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return FloraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.identificationUncertainTitle, style: context.text.title3),
          const SizedBox(height: Space.xs),
          Text(
            l10n.identificationUncertainBody,
            style: context.text.callout.copyWith(color: c.inkSecondary),
          ),
        ],
      ),
    );
  }
}
