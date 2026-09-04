import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/spacing.dart';
import 'buttons.dart';

/// État vide : un emoji sur pastille douce, un titre, une phrase, une action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String emoji;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Space.xxl, vertical: compact ? Space.xl : Space.huge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 64 : 88,
            height: compact ? 64 : 88,
            decoration: BoxDecoration(color: c.sageSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(emoji, style: TextStyle(fontSize: compact ? 28 : 40, height: 1)),
          ),
          SizedBox(height: compact ? Space.md : Space.xl),
          Text(title, style: compact ? context.text.title3 : context.text.title2, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: Space.xs),
            Text(subtitle!, style: context.text.callout, textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.xl),
            FloraButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
