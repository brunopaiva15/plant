import 'package:flora/features/qr/application/label_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LabelLayout', () {
    test('Avery L7651 uses its exact 65-label geometry', () {
      final settings = const LabelPrintSettings().applyPreset(LabelPresets.averyL7651);
      final grid = LabelLayout.geometry(settings);

      expect(settings.sheetKind, LabelSheetKind.a4);
      expect(grid.columns, 5);
      expect(grid.rows, 13);
      expect(grid.capacity, 65);
      expect(grid.leftMm, 4.75);
      expect(grid.topMm, 11.6);
      expect(LabelLayout.fits(settings), isTrue);
    });

    test('Avery L7160 uses its exact 21-label geometry', () {
      final settings = const LabelPrintSettings().applyPreset(LabelPresets.averyL7160);
      final grid = LabelLayout.geometry(settings);

      expect(grid.columns, 3);
      expect(grid.rows, 7);
      expect(grid.capacity, 21);
      expect(LabelLayout.fits(settings), isTrue);
    });

    test('custom sizes are packed from physical dimensions', () {
      final settings = const LabelPrintSettings().copyWith(
        presetId: () => null,
        labelWidthMm: 50,
        labelHeightMm: 25,
        marginMm: 5,
        gapXmm: 2,
        gapYmm: 2,
      );
      final grid = LabelLayout.geometry(settings);

      expect(grid.columns, 3);
      expect(grid.rows, 10);
      expect(grid.capacity, 30);
      expect(LabelLayout.fits(settings), isTrue);
    });

    test('rejects a label larger than its sheet', () {
      final settings = const LabelPrintSettings().copyWith(
        presetId: () => null,
        sheetKind: LabelSheetKind.a5,
        labelWidthMm: 200,
        labelHeightMm: 250,
      );

      expect(LabelLayout.fits(settings), isFalse);
    });
  });
}
