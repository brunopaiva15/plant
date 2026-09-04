import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/label_pdf.dart';
import '../application/plant_links.dart';

/// QR code d'une plante, à coller sur le pot.
Future<void> showPlantQrSheet(BuildContext context, {required Plant plant}) => showFloraSheet<void>(context, builder: (_) => _QrBody(plant: plant));

class _QrBody extends StatelessWidget {
  const _QrBody({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: l10n.qrCode),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.largeAll, border: Border.all(color: c.line)),
            child: QrImageView(data: PlantLinks.encode(plant.id), size: 200, padding: EdgeInsets.zero, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A1F1B)), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1F1B))),
          ),
          const SizedBox(height: Space.sm),
          Text(plant.name, style: context.text.title3),
          const SizedBox(height: Space.xxs),
          Text(l10n.qrHint, style: context.text.callout, textAlign: TextAlign.center),
          const SizedBox(height: Space.lg),
          FloraButton(
            label: l10n.printLabels,
            icon: CupertinoIcons.printer,
            expand: true,
            onPressed: () => shareLabels(context, [LabelData(plantId: plant.id, name: plant.name, species: plant.speciesName)]),
          ),
        ],
      ),
    );
  }
}

/// Génère la planche PDF et ouvre la feuille de partage / impression native.
Future<void> shareLabels(BuildContext context, List<LabelData> labels) async {
  Haptics.light();
  final bytes = await LabelPdf.build(labels, appName: AppConfig.appName);
  await Printing.sharePdf(bytes: bytes, filename: '${AppConfig.appName.toLowerCase()}-labels.pdf');
}
