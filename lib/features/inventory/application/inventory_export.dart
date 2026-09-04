import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/models/models.dart';
import '../../qr/application/label_pdf.dart';
import '../../qr/application/plant_links.dart';
import '../../qr/presentation/plant_qr_sheet.dart';

/// Export CSV d'une sélection d'articles, partagé par la feuille native.
Future<void> shareInventoryCsv(BuildContext context, List<InventoryItem> items) async {
  final csv = buildInventoryCsv(items);
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, 'inventaire.csv'));
  // BOM UTF-8 : sans lui, Excel abîme les accents.
  await file.writeAsString('﻿$csv');
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]));
}

/// CSV séparé par des points-virgules, comme l'attendent les tableurs
/// européens. Tous les champs sont entre guillemets.
String buildInventoryCsv(List<InventoryItem> items) {
  String cell(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
  final rows = <String>[
    ['nom', 'categorie', 'quantite', 'unite', 'seuil_bas', 'tags', 'notes'].map(cell).join(';'),
    for (final i in items)
      [
        i.name,
        i.category.key,
        formatNumber(i.quantity),
        i.unit,
        i.lowThreshold == null ? '' : formatNumber(i.lowThreshold!),
        i.tags.join(', '),
        i.notes ?? '',
      ].map(cell).join(';'),
  ];
  return rows.join('\r\n');
}

/// « 1,5 » plutôt que « 1.5 », et « 2 » plutôt que « 2.0 ».
String formatNumber(double v) => (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString()).replaceAll('.', ',');

/// Planche d'étiquettes QR pour une sélection d'articles.
Future<void> shareInventoryLabels(BuildContext context, List<InventoryItem> items) async {
  final labels = [
    for (final i in items)
      LabelData(
        plantId: i.id,
        name: i.name,
        species: i.tags.isEmpty ? null : i.tags.join(', '),
        link: PlantLinks.encodeItem(i.id),
      ),
  ];
  await shareLabels(context, labels);
}
