enum LabelSheetKind { a4, a5, letter, fourBySix, custom }

class LabelSheetSize {
  const LabelSheetSize(this.widthMm, this.heightMm);
  final double widthMm;
  final double heightMm;
}

extension LabelSheetKindSize on LabelSheetKind {
  LabelSheetSize size({double customWidthMm = 210, double customHeightMm = 297}) => switch (this) {
        LabelSheetKind.a4 => const LabelSheetSize(210, 297),
        LabelSheetKind.a5 => const LabelSheetSize(148, 210),
        LabelSheetKind.letter => const LabelSheetSize(215.9, 279.4),
        LabelSheetKind.fourBySix => const LabelSheetSize(101.6, 152.4),
        LabelSheetKind.custom => LabelSheetSize(customWidthMm, customHeightMm),
      };
}

class LabelPreset {
  const LabelPreset({
    required this.id,
    required this.name,
    required this.labelWidthMm,
    required this.labelHeightMm,
    this.sheetKind,
    this.columns,
    this.rows,
    this.leftMm,
    this.topMm,
    this.pitchXmm,
    this.pitchYmm,
  });

  final String id;
  final String name;
  final double labelWidthMm;
  final double labelHeightMm;
  final LabelSheetKind? sheetKind;
  final int? columns;
  final int? rows;
  final double? leftMm;
  final double? topMm;
  final double? pitchXmm;
  final double? pitchYmm;

  bool get hasExactSheetGeometry =>
      sheetKind != null && columns != null && rows != null && leftMm != null && topMm != null && pitchXmm != null && pitchYmm != null;
}

abstract final class LabelPresets {
  static const averyL7651 = LabelPreset(
    id: 'avery-l7651',
    name: 'Avery L7651',
    labelWidthMm: 38.1,
    labelHeightMm: 21.2,
    sheetKind: LabelSheetKind.a4,
    columns: 5,
    rows: 13,
    leftMm: 4.75,
    topMm: 11.6,
    pitchXmm: 40.6,
    pitchYmm: 21.2,
  );

  static const averyL7160 = LabelPreset(
    id: 'avery-l7160',
    name: 'Avery L7160',
    labelWidthMm: 63.5,
    labelHeightMm: 38.1,
    sheetKind: LabelSheetKind.a4,
    columns: 3,
    rows: 7,
    leftMm: 8.6,
    topMm: 15.1,
    pitchXmm: 66.4,
    pitchYmm: 38.1,
  );

  static const all = <LabelPreset>[
    averyL7651,
    averyL7160,
    LabelPreset(id: '40x20', name: '40 × 20 mm', labelWidthMm: 40, labelHeightMm: 20),
    LabelPreset(id: '50x25', name: '50 × 25 mm', labelWidthMm: 50, labelHeightMm: 25),
    LabelPreset(id: '60x30', name: '60 × 30 mm', labelWidthMm: 60, labelHeightMm: 30),
    LabelPreset(id: '70x37', name: '70 × 37 mm', labelWidthMm: 70, labelHeightMm: 37),
  ];

  static LabelPreset? byId(String? id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

class LabelPrintSettings {
  const LabelPrintSettings({
    this.presetId = 'avery-l7651',
    this.sheetKind = LabelSheetKind.a4,
    this.customSheetWidthMm = 210,
    this.customSheetHeightMm = 297,
    this.labelWidthMm = 38.1,
    this.labelHeightMm = 21.2,
    this.copiesPerItem = 1,
    this.marginMm = 5,
    this.gapXmm = 2,
    this.gapYmm = 2,
    this.showName = true,
    this.showSpecies = true,
    this.showNumber = true,
    this.customText = '',
    this.showCutLines = false,
  });

  final String? presetId;
  final LabelSheetKind sheetKind;
  final double customSheetWidthMm;
  final double customSheetHeightMm;
  final double labelWidthMm;
  final double labelHeightMm;
  final int copiesPerItem;
  final double marginMm;
  final double gapXmm;
  final double gapYmm;
  final bool showName;
  final bool showSpecies;
  final bool showNumber;
  final String customText;
  final bool showCutLines;

  LabelPreset? get preset => LabelPresets.byId(presetId);
  LabelSheetSize get sheetSize => sheetKind.size(customWidthMm: customSheetWidthMm, customHeightMm: customSheetHeightMm);
  bool get hasText => showName || showSpecies || showNumber || customText.trim().isNotEmpty;

  LabelPrintSettings copyWith({
    String? Function()? presetId,
    LabelSheetKind? sheetKind,
    double? customSheetWidthMm,
    double? customSheetHeightMm,
    double? labelWidthMm,
    double? labelHeightMm,
    int? copiesPerItem,
    double? marginMm,
    double? gapXmm,
    double? gapYmm,
    bool? showName,
    bool? showSpecies,
    bool? showNumber,
    String? customText,
    bool? showCutLines,
  }) =>
      LabelPrintSettings(
        presetId: presetId == null ? this.presetId : presetId(),
        sheetKind: sheetKind ?? this.sheetKind,
        customSheetWidthMm: customSheetWidthMm ?? this.customSheetWidthMm,
        customSheetHeightMm: customSheetHeightMm ?? this.customSheetHeightMm,
        labelWidthMm: labelWidthMm ?? this.labelWidthMm,
        labelHeightMm: labelHeightMm ?? this.labelHeightMm,
        copiesPerItem: copiesPerItem ?? this.copiesPerItem,
        marginMm: marginMm ?? this.marginMm,
        gapXmm: gapXmm ?? this.gapXmm,
        gapYmm: gapYmm ?? this.gapYmm,
        showName: showName ?? this.showName,
        showSpecies: showSpecies ?? this.showSpecies,
        showNumber: showNumber ?? this.showNumber,
        customText: customText ?? this.customText,
        showCutLines: showCutLines ?? this.showCutLines,
      );

  LabelPrintSettings applyPreset(LabelPreset preset) => copyWith(
        presetId: () => preset.id,
        sheetKind: preset.sheetKind ?? sheetKind,
        labelWidthMm: preset.labelWidthMm,
        labelHeightMm: preset.labelHeightMm,
        showCutLines: preset.hasExactSheetGeometry ? false : showCutLines,
      );

  LabelPrintSettings asCustomSize() => copyWith(presetId: () => null);
}

class LabelGridGeometry {
  const LabelGridGeometry({required this.columns, required this.rows, required this.leftMm, required this.topMm, required this.pitchXmm, required this.pitchYmm});
  final int columns;
  final int rows;
  final double leftMm;
  final double topMm;
  final double pitchXmm;
  final double pitchYmm;
  int get capacity => columns * rows;
}

abstract final class LabelLayout {
  static LabelGridGeometry geometry(LabelPrintSettings settings) {
    final preset = settings.preset;
    if (preset != null && preset.hasExactSheetGeometry) {
      return LabelGridGeometry(
        columns: preset.columns!,
        rows: preset.rows!,
        leftMm: preset.leftMm!,
        topMm: preset.topMm!,
        pitchXmm: preset.pitchXmm!,
        pitchYmm: preset.pitchYmm!,
      );
    }

    final sheet = settings.sheetSize;
    final availableWidth = sheet.widthMm - settings.marginMm * 2;
    final availableHeight = sheet.heightMm - settings.marginMm * 2;
    final pitchX = settings.labelWidthMm + settings.gapXmm;
    final pitchY = settings.labelHeightMm + settings.gapYmm;
    final calculatedColumns = ((availableWidth + settings.gapXmm) / pitchX).floor();
    final calculatedRows = ((availableHeight + settings.gapYmm) / pitchY).floor();
    final columns = calculatedColumns < 1 ? 1 : calculatedColumns;
    final rows = calculatedRows < 1 ? 1 : calculatedRows;
    return LabelGridGeometry(columns: columns, rows: rows, leftMm: settings.marginMm, topMm: settings.marginMm, pitchXmm: pitchX, pitchYmm: pitchY);
  }

  static bool fits(LabelPrintSettings settings) {
    if (settings.labelWidthMm <= 0 || settings.labelHeightMm <= 0) return false;
    final sheet = settings.sheetSize;
    final grid = geometry(settings);
    final right = grid.leftMm + (grid.columns - 1) * grid.pitchXmm + settings.labelWidthMm;
    final bottom = grid.topMm + (grid.rows - 1) * grid.pitchYmm + settings.labelHeightMm;
    return right <= sheet.widthMm + 0.01 && bottom <= sheet.heightMm + 0.01;
  }
}
