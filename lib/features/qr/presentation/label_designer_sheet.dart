import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../application/label_layout.dart';
import '../application/label_pdf.dart';
import '../application/plant_links.dart';
import 'label_designer_copy.dart';

Future<LabelPrintSettings?> showLabelDesignerSheet(
  BuildContext context, {
  required List<LabelData> labels,
}) =>
    showFloraSheet<LabelPrintSettings>(
      context,
      scrollable: true,
      builder: (_) => _LabelDesignerBody(labels: labels),
    );

class _LabelDesignerBody extends StatefulWidget {
  const _LabelDesignerBody({required this.labels});

  final List<LabelData> labels;

  @override
  State<_LabelDesignerBody> createState() => _LabelDesignerBodyState();
}

class _LabelDesignerBodyState extends State<_LabelDesignerBody> {
  LabelPrintSettings _settings = const LabelPrintSettings();
  late final _labelWidth = TextEditingController(text: _fmt(_settings.labelWidthMm));
  late final _labelHeight = TextEditingController(text: _fmt(_settings.labelHeightMm));
  late final _sheetWidth = TextEditingController(text: _fmt(_settings.customSheetWidthMm));
  late final _sheetHeight = TextEditingController(text: _fmt(_settings.customSheetHeightMm));
  late final _copies = TextEditingController(text: '${_settings.copiesPerItem}');
  late final _margin = TextEditingController(text: _fmt(_settings.marginMm));
  late final _gap = TextEditingController(text: _fmt(_settings.gapXmm));
  late final _customText = TextEditingController();

  static String _fmt(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);

  @override
  void dispose() {
    _labelWidth.dispose();
    _labelHeight.dispose();
    _sheetWidth.dispose();
    _sheetHeight.dispose();
    _copies.dispose();
    _margin.dispose();
    _gap.dispose();
    _customText.dispose();
    super.dispose();
  }

  double? _number(String value) => double.tryParse(value.trim().replaceAll(',', '.'));

  void _selectPreset(LabelPreset preset) {
    setState(() {
      _settings = _settings.applyPreset(preset);
      _labelWidth.text = _fmt(preset.labelWidthMm);
      _labelHeight.text = _fmt(preset.labelHeightMm);
    });
  }

  void _customizeSize() {
    final width = _number(_labelWidth.text);
    final height = _number(_labelHeight.text);
    setState(() {
      _settings = _settings.asCustomSize().copyWith(
            labelWidthMm: width != null && width > 0 ? width : _settings.labelWidthMm,
            labelHeightMm: height != null && height > 0 ? height : _settings.labelHeightMm,
          );
    });
  }

  void _setSheet(LabelSheetKind kind) {
    setState(() {
      _settings = _settings.copyWith(
        presetId: _settings.preset?.hasExactSheetGeometry == true ? () => null : null,
        sheetKind: kind,
      );
    });
  }

  void _syncNumericSettings() {
    final width = _number(_labelWidth.text);
    final height = _number(_labelHeight.text);
    final sheetWidth = _number(_sheetWidth.text);
    final sheetHeight = _number(_sheetHeight.text);
    final margin = _number(_margin.text);
    final gap = _number(_gap.text);
    final copies = int.tryParse(_copies.text.trim());
    setState(() {
      _settings = _settings.copyWith(
        labelWidthMm: width != null && width > 0 ? width : _settings.labelWidthMm,
        labelHeightMm: height != null && height > 0 ? height : _settings.labelHeightMm,
        customSheetWidthMm: sheetWidth != null && sheetWidth > 0 ? sheetWidth : _settings.customSheetWidthMm,
        customSheetHeightMm: sheetHeight != null && sheetHeight > 0 ? sheetHeight : _settings.customSheetHeightMm,
        marginMm: margin != null && margin >= 0 ? margin : _settings.marginMm,
        gapXmm: gap != null && gap >= 0 ? gap : _settings.gapXmm,
        gapYmm: gap != null && gap >= 0 ? gap : _settings.gapYmm,
        copiesPerItem: copies != null && copies > 0 ? copies.clamp(1, 999) : _settings.copiesPerItem,
        customText: _customText.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final first = widget.labels.firstOrNull;
    final preset = _settings.preset;
    final grid = LabelLayout.geometry(_settings);
    final total = widget.labels.length * _settings.copiesPerItem;
    final fits = LabelLayout.fits(_settings);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.labelDesignerTitle),
          if (first != null) ...[
            Text(l10n.labelPreview, style: context.text.caption),
            const SizedBox(height: Space.xs),
            _LabelPreview(data: first, settings: _settings),
            const SizedBox(height: Space.lg),
          ],
          Text(l10n.labelPreset, style: context.text.caption),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final p in LabelPresets.all)
                FloraChip(
                  label: '${p.name} · ${_fmt(p.labelWidthMm)} × ${_fmt(p.labelHeightMm)}',
                  selected: _settings.presetId == p.id,
                  onTap: () => _selectPreset(p),
                ),
              FloraChip(
                label: l10n.labelCustom,
                selected: _settings.presetId == null,
                onTap: () => setState(() => _settings = _settings.asCustomSize()),
              ),
            ],
          ),
          if (preset?.hasExactSheetGeometry == true) ...[
            const SizedBox(height: Space.xs),
            Text('${l10n.labelPresetExact} · ${l10n.labelPerSheet(grid.capacity)}', style: context.text.caption),
          ],
          const SizedBox(height: Space.lg),
          Text(l10n.labelSheetFormat, style: context.text.caption),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              FloraChip(label: 'A4', selected: _settings.sheetKind == LabelSheetKind.a4, onTap: () => _setSheet(LabelSheetKind.a4)),
              FloraChip(label: 'A5', selected: _settings.sheetKind == LabelSheetKind.a5, onTap: () => _setSheet(LabelSheetKind.a5)),
              FloraChip(label: 'Letter', selected: _settings.sheetKind == LabelSheetKind.letter, onTap: () => _setSheet(LabelSheetKind.letter)),
              FloraChip(label: '4 × 6 in', selected: _settings.sheetKind == LabelSheetKind.fourBySix, onTap: () => _setSheet(LabelSheetKind.fourBySix)),
              FloraChip(label: l10n.labelCustom, selected: _settings.sheetKind == LabelSheetKind.custom, onTap: () => _setSheet(LabelSheetKind.custom)),
            ],
          ),
          if (_settings.sheetKind == LabelSheetKind.custom) ...[
            const SizedBox(height: Space.md),
            Text(l10n.labelSheetSize, style: context.text.caption),
            const SizedBox(height: Space.xs),
            _DimensionsRow(
              widthController: _sheetWidth,
              heightController: _sheetHeight,
              widthHint: l10n.labelWidth,
              heightHint: l10n.labelHeight,
              onChanged: _syncNumericSettings,
            ),
          ],
          const SizedBox(height: Space.lg),
          Text(l10n.labelSize, style: context.text.caption),
          const SizedBox(height: Space.xs),
          _DimensionsRow(
            widthController: _labelWidth,
            heightController: _labelHeight,
            widthHint: l10n.labelWidth,
            heightHint: l10n.labelHeight,
            onChanged: () {
              _customizeSize();
              _syncNumericSettings();
            },
          ),
          const SizedBox(height: Space.lg),
          Text(l10n.labelCopies, style: context.text.caption),
          const SizedBox(height: Space.xs),
          FloraTextField(
            controller: _copies,
            keyboardType: TextInputType.number,
            onChanged: (_) => _syncNumericSettings(),
          ),
          const SizedBox(height: Space.xs),
          Text('${l10n.labelTotal(total)} · ${l10n.labelPerSheet(grid.capacity)}', style: context.text.caption),
          const SizedBox(height: Space.lg),
          Text(l10n.labelContent, style: context.text.caption),
          const SizedBox(height: Space.xs),
          FloraCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ToggleRow(label: l10n.labelShowName, value: _settings.showName, onChanged: (v) => setState(() => _settings = _settings.copyWith(showName: v))),
                _ToggleRow(label: l10n.labelShowSpecies, value: _settings.showSpecies, onChanged: (v) => setState(() => _settings = _settings.copyWith(showSpecies: v))),
                _ToggleRow(label: l10n.labelShowNumber, value: _settings.showNumber, onChanged: (v) => setState(() => _settings = _settings.copyWith(showNumber: v))),
                _ToggleRow(
                  label: l10n.labelQrOnly,
                  value: !_settings.hasText,
                  onChanged: (v) => setState(() {
                    if (v) {
                      _customText.clear();
                      _settings = _settings.copyWith(showName: false, showSpecies: false, showNumber: false, customText: '');
                    } else {
                      _settings = _settings.copyWith(showName: true);
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          FloraTextField(
            controller: _customText,
            hint: l10n.labelCustomText,
            onChanged: (_) => _syncNumericSettings(),
          ),
          const SizedBox(height: Space.lg),
          Text(l10n.labelAdvanced, style: context.text.caption),
          const SizedBox(height: Space.xs),
          if (preset?.hasExactSheetGeometry != true) ...[
            Row(
              children: [
                Expanded(
                  child: FloraTextField(
                    controller: _margin,
                    hint: l10n.labelMargin,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _syncNumericSettings(),
                  ),
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: FloraTextField(
                    controller: _gap,
                    hint: l10n.labelGap,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _syncNumericSettings(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
          ],
          FloraCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
            child: Row(
              children: [
                Expanded(child: Text(l10n.labelCutLines, style: context.text.body)),
                AdaptiveSwitch(value: _settings.showCutLines, onChanged: (v) => setState(() => _settings = _settings.copyWith(showCutLines: v))),
              ],
            ),
          ),
          if (!fits) ...[
            const SizedBox(height: Space.sm),
            Text(l10n.labelDoesNotFit, style: context.text.callout.copyWith(color: c.terracotta)),
          ],
          const SizedBox(height: Space.xl),
          FloraButton(
            label: l10n.labelGeneratePdf,
            icon: CupertinoIcons.doc,
            expand: true,
            onPressed: fits && widget.labels.isNotEmpty
                ? () {
                    _syncNumericSettings();
                    Navigator.of(context).pop(_settings);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _DimensionsRow extends StatelessWidget {
  const _DimensionsRow({
    required this.widthController,
    required this.heightController,
    required this.widthHint,
    required this.heightHint,
    required this.onChanged,
  });

  final TextEditingController widthController;
  final TextEditingController heightController;
  final String widthHint;
  final String heightHint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: FloraTextField(
              controller: widthController,
              hint: widthHint,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: FloraTextField(
              controller: heightController,
              hint: heightHint,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
        child: Row(
          children: [
            Expanded(child: Text(label, style: context.text.body)),
            AdaptiveSwitch(value: value, onChanged: onChanged),
          ],
        ),
      );
}

class _LabelPreview extends StatelessWidget {
  const _LabelPreview({required this.data, required this.settings});

  final LabelData data;
  final LabelPrintSettings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratio = (settings.labelWidthMm / settings.labelHeightMm).clamp(1.0, 4.5);
    final hasSpecies = settings.showSpecies && (data.species?.isNotEmpty ?? false);
    final hasNumber = settings.showNumber && data.number > 0;
    final custom = settings.customText.trim();
    final hasText = (settings.showName && data.name.isNotEmpty) || hasSpecies || hasNumber || custom.isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: AspectRatio(
          aspectRatio: ratio,
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: Radii.mediumAll,
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                Flexible(
                  flex: hasText ? 4 : 1,
                  child: Center(
                    child: QrImageView(
                      data: data.link ?? PlantLinks.encode(data.plantId),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (hasText) ...[
                  const SizedBox(width: Space.sm),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (settings.showName && data.name.isNotEmpty) Text(data.name, style: context.text.callout.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (hasSpecies) Text(data.species!, style: context.text.caption.copyWith(fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (hasNumber) Text('#${data.number}', style: context.text.caption),
                        if (custom.isNotEmpty) Text(custom, style: context.text.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
