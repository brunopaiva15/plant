import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/spacing.dart';
import 'pressable.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction, this.trailing, this.padding});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.title2)),
          ?trailing,
          if (actionLabel != null && onAction != null)
            Pressable(
              onTap: onAction,
              scale: 0.95,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xxs),
                child: Text(actionLabel!, style: context.text.callout.copyWith(color: context.colors.sage, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}
