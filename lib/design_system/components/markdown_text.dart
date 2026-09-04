import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/markdown.dart';
import '../theme/flora_theme.dart';
import '../tokens/spacing.dart';

/// Rend une note en Markdown simple : gras, italique, code, liens cliquables,
/// listes, titres et citations.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.source, {super.key, this.style, this.maxLines});

  final String source;
  final TextStyle? style;

  /// Aperçu court : au-delà, le texte est rendu sur une seule ligne tronquée.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.text.body;
    if (maxLines != null) {
      return Text(Markdown.stripped(source), style: base, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final blocks = Markdown.parse(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, b) in blocks.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : (b.isList ? 2 : Space.sm)),
            child: _block(context, b, base),
          ),
      ],
    );
  }

  Widget _block(BuildContext context, MdBlock b, TextStyle base) {
    final c = context.colors;
    final text = RichText(text: TextSpan(children: [for (final s in b.spans) _span(context, s, _styleFor(context, b, base))]));
    return switch (b.kind) {
      MdBlockKind.bullet => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2, right: Space.xs), child: Text('•', style: base.copyWith(color: c.sage))),
            Expanded(child: text),
          ],
        ),
      MdBlockKind.numbered => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: Space.xs),
              child: Text('${b.number ?? 1}.', style: base.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: text),
          ],
        ),
      MdBlockKind.quote => Container(
          padding: const EdgeInsets.only(left: Space.sm),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: c.sage.withValues(alpha: 0.5), width: 3))),
          child: text,
        ),
      _ => text,
    };
  }

  TextStyle _styleFor(BuildContext context, MdBlock b, TextStyle base) => switch (b.kind) {
        MdBlockKind.heading1 => context.text.title2,
        MdBlockKind.heading2 => context.text.title3,
        MdBlockKind.heading3 => base.copyWith(fontWeight: FontWeight.w700),
        MdBlockKind.quote => base.copyWith(color: context.colors.inkSecondary, fontStyle: FontStyle.italic),
        _ => base,
      };

  InlineSpan _span(BuildContext context, MdSpan s, TextStyle base) {
    final c = context.colors;
    var style = base;
    if (s.bold) style = style.copyWith(fontWeight: FontWeight.w700);
    if (s.italic) style = style.copyWith(fontStyle: FontStyle.italic);
    if (s.code) {
      style = style.copyWith(fontFamily: 'monospace', backgroundColor: c.surfaceMuted, fontSize: (style.fontSize ?? 15) - 1);
    }
    if (s.link == null) return TextSpan(text: s.text, style: style);
    return TextSpan(
      text: s.text,
      style: style.copyWith(color: c.sage, decoration: TextDecoration.underline, decorationColor: c.sage.withValues(alpha: 0.4)),
      recognizer: TapGestureRecognizer()..onTap = () => _open(s.link!),
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    // Seuls http(s) et mailto sont ouverts : pas de schéma inattendu venu
    // d'une note importée.
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https') || uri.isScheme('mailto'))) return;
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
