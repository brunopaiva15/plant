import 'package:flora/features/qr/application/label_layout.dart';
import 'package:flora/features/qr/application/label_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a PDF with repeated configurable labels', () async {
    final settings = const LabelPrintSettings().copyWith(
      presetId: () => null,
      sheetKind: LabelSheetKind.a4,
      labelWidthMm: 50,
      labelHeightMm: 25,
      copiesPerItem: 3,
      showName: true,
      showSpecies: false,
      showNumber: false,
      customText: 'Auxine',
      showCutLines: true,
    );

    final bytes = await LabelPdf.build(
      const [
        LabelData(
          plantId: 'plant-1',
          name: 'Monstera',
          species: 'Monstera deliciosa',
          number: 42,
        ),
      ],
      appName: 'Auxine',
      settings: settings,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('builds an exact Avery L7160 sheet', () async {
    final settings = const LabelPrintSettings().applyPreset(LabelPresets.averyL7160);

    final bytes = await LabelPdf.build(
      const [LabelData(plantId: 'plant-1', name: 'Pothos')],
      appName: 'Auxine',
      settings: settings,
    );

    expect(bytes, isNotEmpty);
  });
}
