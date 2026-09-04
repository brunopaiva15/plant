import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../tokens/motion.dart';

/// Surface tactile qui se rétracte légèrement à la pression (sensation iOS).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    return Semantics(
      button: interactive,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: interactive ? (_) => _set(true) : null,
        onTapUp: interactive ? (_) => _set(false) : null,
        onTapCancel: interactive ? () => _set(false) : null,
        onTap: interactive && widget.onTap != null
            ? () {
                if (widget.haptic) Haptics.light();
                widget.onTap!();
              }
            : null,
        onLongPress: interactive && widget.onLongPress != null
            ? () {
                _set(false);
                Haptics.success();
                widget.onLongPress!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Motion.of(context, Motion.micro),
          curve: Motion.easeOut,
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.45,
            duration: Motion.of(context, Motion.micro),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
