import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../theme/flora_theme.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// Composants qui suivent les conventions de la plateforme tout en gardant
/// l'identité visuelle Flora. Sur iOS : composants Cupertino natifs.

bool isCupertino(BuildContext context) => Theme.of(context).platform == TargetPlatform.iOS;

/// Interrupteur natif (CupertinoSwitch sur iOS, Switch Material 3 sur Android).
class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    void change(bool v) {
      Haptics.selection();
      onChanged?.call(v);
    }

    if (isCupertino(context)) {
      return CupertinoSwitch(value: value, onChanged: onChanged == null ? null : change, activeTrackColor: context.colors.sage);
    }
    return Switch(value: value, onChanged: onChanged == null ? null : change);
  }
}

/// Indicateur d'activité natif.
class AdaptiveProgress extends StatelessWidget {
  const AdaptiveProgress({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) return CupertinoActivityIndicator(color: color);
    return SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: color));
  }
}

/// Contrôle segmenté (CupertinoSlidingSegmentedControl sur iOS, SegmentedButton sur Android).
class AdaptiveSegmented<T extends Object> extends StatelessWidget {
  const AdaptiveSegmented({super.key, required this.segments, required this.value, required this.onChanged});

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    void change(T? v) {
      if (v == null || v == value) return;
      Haptics.selection();
      onChanged(v);
    }

    if (isCupertino(context)) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        backgroundColor: c.surfaceMuted,
        thumbColor: c.surface,
        children: {
          for (final e in segments.entries)
            e.key: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xxs, vertical: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(e.value, style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600), maxLines: 1),
              ),
            ),
        },
        onValueChanged: change,
      );
    }
    return SegmentedButton<T>(
      segments: [
        for (final e in segments.entries)
          ButtonSegment(value: e.key, label: FittedBox(fit: BoxFit.scaleDown, child: Text(e.value, maxLines: 1, softWrap: false))),
      ],
      selected: {value},
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      onSelectionChanged: (s) => change(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
        textStyle: WidgetStatePropertyAll(context.text.callout.copyWith(fontWeight: FontWeight.w600)),
        side: WidgetStatePropertyAll(BorderSide(color: c.line)),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.sageSoft : c.surface),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.sage : c.ink),
      ),
    );
  }
}

/// Une action d'un action sheet.
class SheetAction {
  const SheetAction({required this.label, required this.onPressed, this.destructive = false, this.icon});

  final String label;
  final VoidCallback onPressed;
  final bool destructive;
  final IconData? icon;
}

/// Action sheet natif : CupertinoActionSheet sur iOS, bottom sheet liste sur Android.
Future<void> showAdaptiveActionSheet(
  BuildContext context, {
  String? title,
  String? message,
  required List<SheetAction> actions,
  required String cancelLabel,
}) async {
  Haptics.light();
  if (isCupertino(context)) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: title == null ? null : Text(title),
        message: message == null ? null : Text(message),
        actions: [
          for (final a in actions)
            CupertinoActionSheetAction(
              isDestructiveAction: a.destructive,
              onPressed: () {
                Navigator.of(ctx).pop();
                a.onPressed();
              },
              child: Text(a.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(cancelLabel),
        ),
      ),
    );
    return;
  }
  final c = context.colors;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Space.xs),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.md, Space.xl, Space.xs),
              child: Text(title, style: ctx.text.title3, textAlign: TextAlign.center),
            ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xl),
              child: Text(message, style: ctx.text.callout, textAlign: TextAlign.center),
            ),
          const SizedBox(height: Space.xs),
          for (final a in actions)
            ListTile(
              leading: a.icon == null ? null : Icon(a.icon, color: a.destructive ? c.danger : c.ink),
              title: Text(a.label, style: ctx.text.body.copyWith(color: a.destructive ? c.danger : c.ink)),
              onTap: () {
                Navigator.of(ctx).pop();
                a.onPressed();
              },
            ),
          const SizedBox(height: Space.xs),
        ],
      ),
    ),
  );
}

/// Dialogue de confirmation natif. Retourne `true` si confirmé.
Future<bool> showAdaptiveConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  if (isCupertino(context)) {
    final r = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: message == null ? null : Padding(padding: const EdgeInsets.only(top: 6), child: Text(message)),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            isDefaultAction: !destructive,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return r ?? false;
  }
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel, style: TextStyle(color: destructive ? ctx.colors.danger : ctx.colors.sage)),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Sélecteur de date natif (roue Cupertino sur iOS, calendrier Material sur Android).
Future<DateTime?> showAdaptiveDatePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
  required String doneLabel,
}) async {
  final firstDate = first ?? DateTime(2000);
  final lastDate = last ?? DateTime.now().add(const Duration(days: 365 * 5));
  if (isCupertino(context)) {
    var value = initial;
    final r = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (ctx) => _CupertinoPickerFrame(
        doneLabel: doneLabel,
        onDone: () => Navigator.of(ctx).pop(value),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: initial,
          minimumDate: firstDate,
          maximumDate: lastDate,
          onDateTimeChanged: (d) => value = d,
        ),
      ),
    );
    return r;
  }
  return showDatePicker(context: context, initialDate: initial, firstDate: firstDate, lastDate: lastDate);
}

/// Sélecteur d'heure natif.
Future<TimeOfDay?> showAdaptiveTimePicker(BuildContext context, {required TimeOfDay initial, required String doneLabel}) async {
  if (isCupertino(context)) {
    var value = initial;
    final now = DateTime.now();
    final r = await showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (ctx) => _CupertinoPickerFrame(
        doneLabel: doneLabel,
        onDone: () => Navigator.of(ctx).pop(value),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          initialDateTime: DateTime(now.year, now.month, now.day, initial.hour, initial.minute),
          onDateTimeChanged: (d) => value = TimeOfDay(hour: d.hour, minute: d.minute),
        ),
      ),
    );
    return r;
  }
  return showTimePicker(context: context, initialTime: initial);
}

class _CupertinoPickerFrame extends StatelessWidget {
  const _CupertinoPickerFrame({required this.child, required this.doneLabel, required this.onDone});

  final Widget child;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 300,
      decoration: BoxDecoration(color: c.surface, borderRadius: Radii.sheetTop),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(onPressed: onDone, child: Text(doneLabel, style: TextStyle(color: c.sage, fontWeight: FontWeight.w600))),
            ),
            Expanded(child: CupertinoTheme(data: CupertinoThemeData(brightness: c.brightness), child: child)),
          ],
        ),
      ),
    );
  }
}

/// Fond translucide flouté (barres, tab bar), façon « materials » iOS.
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({super.key, required this.child, this.borderRadius, this.opacity = 0.78});

  final Widget child;
  final BorderRadius? borderRadius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.surface.withValues(alpha: opacity), borderRadius: borderRadius),
          child: child,
        ),
      ),
    );
  }
}
