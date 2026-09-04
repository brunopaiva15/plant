import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/haptics.dart';
import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';
import 'pressable.dart';

/// Toast avec action d'annulation. Un seul toast à la fois ; le suivant
/// remplace le précédent (et déclenche son expiration).
class ToastData {
  ToastData({required this.message, this.undoLabel, this.onUndo, this.emoji = '✓'});

  final String message;
  final String? undoLabel;
  final Future<void> Function()? onUndo;
  final String emoji;
  final int id = DateTime.now().microsecondsSinceEpoch;
}

class ToastController extends Notifier<ToastData?> {
  Timer? _timer;

  @override
  ToastData? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(ToastData data) {
    _timer?.cancel();
    state = data;
    _timer = Timer(AppConfig.undoWindow, () => state = null);
  }

  void dismiss() {
    _timer?.cancel();
    state = null;
  }

  Future<void> undo() async {
    final current = state;
    dismiss();
    if (current?.onUndo != null) {
      Haptics.light();
      await current!.onUndo!();
    }
  }
}

final toastProvider = NotifierProvider<ToastController, ToastData?>(ToastController.new);

/// À placer au-dessus du contenu de l'app (dans le builder de MaterialApp).
class ToastHost extends ConsumerWidget {
  const ToastHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider);
    return Stack(
      children: [
        child,
        Positioned(
          left: Space.md,
          right: Space.md,
          bottom: MediaQuery.paddingOf(context).bottom + 96,
          child: IgnorePointer(
            ignoring: toast == null,
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.emphasis),
              switchInCurve: Motion.spring,
              switchOutCurve: Motion.easeOut,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
                  child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(anim), child: child),
                ),
              ),
              child: toast == null
                  ? const SizedBox.shrink()
                  : _ToastCard(key: ValueKey(toast.id), data: toast, onUndo: () => ref.read(toastProvider.notifier).undo()),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({super.key, required this.data, required this.onUndo});

  final ToastData data;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm),
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: Radii.fullAll,
          boxShadow: Shadows.floating(c.isDark ? const Color(0x33000000) : c.shadow),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: c.sage, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(data.emoji, style: TextStyle(fontSize: 13, color: c.onSage, fontWeight: FontWeight.w700, height: 1)),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                data.message,
                style: context.text.callout.copyWith(color: c.canvas, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (data.undoLabel != null && data.onUndo != null)
              Pressable(
                onTap: onUndo,
                scale: 0.94,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 6),
                  decoration: BoxDecoration(color: c.canvas.withValues(alpha: 0.12), borderRadius: Radii.fullAll),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.arrow_uturn_left, size: 14, color: c.canvas),
                      const SizedBox(width: 4),
                      Text(data.undoLabel!, style: context.text.caption.copyWith(color: c.canvas, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
