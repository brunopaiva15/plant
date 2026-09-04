import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'plant_links.dart';

/// Une étiquette : nom, espèce éventuelle, QR code.
class LabelData {
  const LabelData({required this.plantId, required this.name, this.species, this.number = 0});

  final String plantId;
  final String name;
  final String? species;

  /// Numéro court « #42 », imprimé pour retrouver la plante d'un coup d'œil.
  final int number;
}

/// Planche d'étiquettes A4 (3 colonnes × 8 lignes), prêtes à découper.
abstract final class LabelPdf {
  static Future<Uint8List> build(List<LabelData> labels, {required String appName}) async {
    final doc = pw.Document(title: '$appName · labels');
    const perPage = 24;
    for (var i = 0; i < labels.length; i += perPage) {
      final page = labels.sublist(i, (i + perPage).clamp(0, labels.length));
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(12 * PdfPageFormat.mm),
          build: (ctx) => pw.GridView(
            crossAxisCount: 3,
            childAspectRatio: 0.5,
            crossAxisSpacing: 4 * PdfPageFormat.mm,
            mainAxisSpacing: 4 * PdfPageFormat.mm,
            children: [for (final l in page) _label(l)],
          ),
        ),
      );
    }
    return doc.save();
  }

  static pw.Widget _label(LabelData l) => pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5), borderRadius: pw.BorderRadius.circular(6)),
        padding: const pw.EdgeInsets.all(6),
        child: pw.Row(
          children: [
            pw.BarcodeWidget(data: PlantLinks.encode(l.plantId), barcode: pw.Barcode.qrCode(), width: 22 * PdfPageFormat.mm, height: 22 * PdfPageFormat.mm),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(l.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), maxLines: 2),
                  if (l.species != null) pw.Text(l.species!, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic), maxLines: 1),
                  if (l.number > 0) pw.Text('#${l.number}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                ],
              ),
            ),
          ],
        ),
      );
}
