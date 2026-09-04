import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../theme/flora_theme.dart';

/// Photo d'une plante (chemin relatif) ou placeholder doux avec emoji.
class PlantImage extends ConsumerWidget {
  const PlantImage({super.key, this.relativePath, this.fit = BoxFit.cover, this.cacheWidth, this.placeholderEmoji = '🪴', this.heroTag});

  final String? relativePath;
  final BoxFit fit;
  final int? cacheWidth;
  final String placeholderEmoji;
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    Widget child;
    if (relativePath == null) {
      child = Container(
        color: c.sageSoft,
        alignment: Alignment.center,
        child: Text(placeholderEmoji, style: const TextStyle(fontSize: 40)),
      );
    } else {
      final storage = ref.watch(photoStorageProvider);
      child = FutureBuilder<String>(
        future: storage.absolutePath(relativePath!),
        builder: (context, snap) {
          if (!snap.hasData) return ColoredBox(color: c.surfaceMuted);
          return Image.file(
            File(snap.data!),
            fit: fit,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => ColoredBox(color: c.surfaceMuted),
          );
        },
      );
    }
    if (heroTag != null) child = Hero(tag: heroTag!, child: child);
    return child;
  }
}
