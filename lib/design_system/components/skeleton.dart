import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/radius.dart';

/// Placeholder de chargement : bloc doux qui respire.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = Radii.small});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: reduce ? const AlwaysStoppedAnimation(0.7) : Tween(begin: 0.45, end: 0.9).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: context.colors.surfaceMuted, borderRadius: BorderRadius.circular(widget.radius)),
      ),
    );
  }
}
