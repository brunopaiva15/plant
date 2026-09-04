import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'adaptive.dart';

/// Champ de texte Flora : fond doux, coins arrondis, pas de bordure.
/// CupertinoTextField sur iOS (menu contextuel et sélection natifs).
class FloraTextField extends StatelessWidget {
  const FloraTextField({
    super.key,
    this.controller,
    this.hint,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.prefix,
    this.suffix,
    this.textCapitalization = TextCapitalization.sentences,
    this.focusNode,
    this.large = false,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? minLines;
  final Widget? prefix;
  final Widget? suffix;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final bool large;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = (large ? context.text.title2 : context.text.body).copyWith(color: c.ink);
    final hintStyle = style.copyWith(color: c.inkTertiary, fontWeight: FontWeight.w400);
    if (isCupertino(context)) {
      return CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: hint,
        placeholderStyle: hintStyle,
        style: style,
        autofocus: autofocus,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        minLines: minLines,
        cursorColor: c.sage,
        padding: EdgeInsets.symmetric(horizontal: Space.md, vertical: large ? Space.md : 13),
        prefix: prefix == null ? null : Padding(padding: const EdgeInsets.only(left: Space.sm), child: prefix),
        suffix: suffix == null ? null : Padding(padding: const EdgeInsets.only(right: Space.sm), child: suffix),
        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: Radii.mediumAll),
      );
    }
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      minLines: minLines,
      style: style,
      cursorColor: c.sage,
      decoration: InputDecoration(hintText: hint, hintStyle: hintStyle, prefixIcon: prefix, suffixIcon: suffix),
    );
  }
}
