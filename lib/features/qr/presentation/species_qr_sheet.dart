import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/scientific_name.dart';
import '../../../design_system/design_system.dart';
import '../application/label_pdf.dart';
import '../application/plant_links.dart';
import 'plant_qr_sheet.dart';

/// QR code d'une entrée d'espèce, à imprimer comme étiquette depuis
/// l'encyclopédie.
Future<void> showSpeciesQrSheet(
  BuildContext context, {
  required String scientificName,
  required String displayName,
}) =>
    showFloraSheet<void>(
      context,
      builder: (_) => _SpeciesQrBody(
        scientificName: scientificName,
        displayName: displayName,
      ),
    );

class _SpeciesQrBody extends StatelessWidget {
  const _SpeciesQrBody({required this.scientificName, required this.displayName});

  final String scientificName;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final link = PlantLinks.encodeSpecies(scientificName);
    final displayScientificName = capitalizeSpeciesDisplayName(scientificName);
    final hasSeparateCommonName = displayName.trim().toLowerCase() != displayScientificName.toLowerCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: l10n.qrCode),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: Radii.largeAll,
              border: Border.all(color: c.line),
            ),
            child: QrImageView(
              data: link,
              size: 200,
              padding: EdgeInsets.zero,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1A1F1B),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1A1F1B),
              ),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(displayName, style: context.text.title3, textAlign: TextAlign.center),
          if (hasSeparateCommonName) ...[
            const SizedBox(height: Space.xxs),
            Text(
              displayScientificName,
              style: context.text.callout.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Space.lg),
          FloraButton(
            label: l10n.printLabels,
            icon: CupertinoIcons.printer,
            expand: true,
            onPressed: () => shareLabels(
              context,
              [
                LabelData(
                  plantId: scientificName,
                  name: displayName,
                  species: hasSeparateCommonName ? displayScientificName : null,
                  link: link,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
