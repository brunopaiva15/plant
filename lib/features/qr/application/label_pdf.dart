import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'label_layout.dart';
import 'plant_links.dart';

/// Une étiquette : nom, espèce éventuelle, QR code.
class LabelData {
  const LabelData({required this.plantId, required this.name, this.species, this.number = 0, this.link});

  final String plantId;
  final String name;
  final String? species;

  /// Numéro court « #42 », imprimé pour retrouver la plante d'un coup d'œil.
  final int number;

  /// Lien encodé dans le QR. Par défaut, celui de la plante.
  final String? link;
}

/// Générateur PDF d'étiquettes à dimensions physiques exactes.
abstract final class LabelPdf {
  static Future<Uint8List> build(
    List<LabelData> labels, {
    required String appName,
    LabelPrintSettings settings = const LabelPrintSettings(),
  }) async {
    final doc = pw.Document(title: '$appName · labels');
    final expanded = <LabelData>[
      for (final label in labels)
        for (var i = 0; i < settings.copiesPerItem; i++) label,
    ];
    if (expanded.isEmpty) return doc.save();

    final sheet = settings.sheetSize;
    final grid = LabelLayout.geometry(settings);
    final pageFormat = PdfPageFormat(
      sheet.widthMm * PdfPageFormat.mm,
      sheet.heightMm * PdfPageFormat.mm,
      marginTop: 0,
      marginBottom: 0,
      marginLeft: 0,
      marginRight: 0,
    );

    for (var start = 0; start < expanded.length; start += grid.capacity) {
      final end = start + grid.capacity < expanded.length ? start + grid.capacity : expanded.length;
      final page = expanded.sublist(start, end);
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) => pw.Stack(
            children: [
              for (var i = 0; i < page.length; i++)
                pw.Positioned(
                  left: (grid.leftMm + (i % grid.columns) * grid.pitchXmm) * PdfPageFormat.mm,
                  top: (grid.topMm + (i ~/ grid.columns) * grid.pitchYmm) * PdfPageFormat.mm,
                  child: pw.SizedBox(
                    width: settings.labelWidthMm * PdfPageFormat.mm,
                    height: settings.labelHeightMm * PdfPageFormat.mm,
                    child: _label(page[i], settings),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }

  static pw.Widget _label(LabelData label, LabelPrintSettings settings) {
    final hasName = settings.showName && label.name.trim().isNotEmpty;
    final hasSpecies = settings.showSpecies && (label.species?.trim().isNotEmpty ?? false);
    final hasNumber = settings.showNumber && label.number > 0;
    final custom = settings.customText.trim();
    final hasText = hasName || hasSpecies || hasNumber || custom.isNotEmpty;
    final minSide = settings.labelWidthMm < settings.labelHeightMm ? settings.labelWidthMm : settings.labelHeightMm;
    final paddingMm = minSide < 24 ? 1.2 : 2.0;
    final innerWidth = settings.labelWidthMm - paddingMm * 2;
    final innerHeight = settings.labelHeightMm - paddingMm * 2;
    final horizontal = hasText && settings.labelWidthMm >= settings.labelHeightMm * 1.35;
    final qrSideMm = hasText
        ? (horizontal
            ? _min(innerHeight, innerWidth * 0.43)
            : _min(innerWidth, innerHeight * 0.55))
        : _min(innerWidth, innerHeight);
    final titleSize = settings.labelHeightMm >= 35 ? 9.0 : settings.labelHeightMm >= 25 ? 8.0 : 6.5;
    final secondarySize = titleSize - 1.2;

    final qr = pw.BarcodeWidget(
      data: label.link ?? PlantLinks.encode(label.plantId),
      barcode: pw.Barcode.qrCode(),
      width: qrSideMm * PdfPageFormat.mm,
      height: qrSideMm * PdfPageFormat.mm,
    );

    final text = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (hasName)
          pw.Text(
            label.name,
            style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold),
            maxLines: 2,
          ),
        if (hasSpecies)
          pw.Text(
            label.species!.trim(),
            style: pw.TextStyle(fontSize: secondarySize, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
            maxLines: 2,
          ),
        if (hasNumber)
          pw.Text('#${label.number}', style: pw.TextStyle(fontSize: secondarySize, color: PdfColors.grey600)),
        if (custom.isNotEmpty)
          pw.Text(custom, style: pw.TextStyle(fontSize: secondarySize, color: PdfColors.grey700), maxLines: 2),
      ],
    );

    return pw.Container(
      padding: pw.EdgeInsets.all(paddingMm * PdfPageFormat.mm),
      decoration: settings.showCutLines
          ? pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500, width: 0.35), borderRadius: pw.BorderRadius.circular(3))
          : null,
      child: hasText
          ? horizontal
              ? pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    qr,
                    pw.SizedBox(width: 1.8 * PdfPageFormat.mm),
                    pw.Expanded(child: text),
                  ],
                )
              : pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    qr,
                    pw.SizedBox(height: 1.2 * PdfPageFormat.mm),
                    pw.Expanded(child: text),
                  ],
                )
          : pw.Center(child: qr),
    );
  }

  static double _min(double a, double b) => a < b ? a : b;
}
