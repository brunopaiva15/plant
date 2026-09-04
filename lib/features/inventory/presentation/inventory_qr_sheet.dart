import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../qr/application/plant_links.dart';
import '../application/inventory_export.dart';

/// QR code d'un article : à coller sur la boîte, scanné pour l'ouvrir.
Future<void> showInventoryQrSheet(BuildContext context, InventoryItem item) =>
    showFloraSheet<void>(context, builder: (_) => _ItemQrBody(item: item));

class _ItemQrBody extends ConsumerWidget {
  const _ItemQrBody({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.itemQr),
          Center(
            child: Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: Radii.largeAll),
              child: QrImageView(
                data: PlantLinks.encodeItem(item.id),
                size: 200,
                backgroundColor: CupertinoColors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: CupertinoColors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: CupertinoColors.black),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          Text(item.name, style: context.text.title3, textAlign: TextAlign.center),
          Text(l10n.formatQuantity(item.quantity, item.unit), style: context.text.caption.copyWith(color: c.inkSecondary), textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          FloraButton(label: l10n.labels, icon: CupertinoIcons.printer, expand: true, onPressed: () => shareInventoryLabels(context, [item])),
        ],
      ),
    );
  }
}
