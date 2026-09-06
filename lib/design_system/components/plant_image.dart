import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../theme/flora_theme.dart';

/// Photo d'une plante (chemin relatif) ou placeholder doux avec emoji.
class PlantImage extends ConsumerWidget {
  const PlantImage({super.key, this.relativePath, this.remoteUrl, this.fit = BoxFit.cover, this.cacheWidth, this.placeholderEmoji = '🪴', this.heroTag, this.heroRadius = BorderRadius.zero});

  final String? relativePath;

  /// Photo hébergée ailleurs : chargée depuis le réseau, jamais copiée.
  final String? remoteUrl;
  final BoxFit fit;
  final int? cacheWidth;
  final String placeholderEmoji;
  final Object? heroTag;

  /// Les coins de l'image à cet endroit : pendant le vol d'un écran à
  /// l'autre, ils s'interpolent vers ceux de l'arrivée au lieu de sauter.
  final BorderRadius heroRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    Widget child;
    if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      child = Image.network(
        remoteUrl!,
        fit: fit,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        loadingBuilder: (context, w, progress) => progress == null ? w : ColoredBox(color: c.surfaceMuted),
        errorBuilder: (_, _, _) => Container(
          color: c.surfaceMuted,
          alignment: Alignment.center,
          child: const Text('🔗', style: TextStyle(fontSize: 24)),
        ),
      );
    } else if (relativePath == null || relativePath!.isEmpty) {
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
    if (heroTag != null) child = PlantHero(tag: heroTag!, radius: heroRadius, child: child);
    return child;
  }
}

/// Un [Hero] dont les coins suivent le vol : une vignette arrondie qui
/// devient l'en-tête carré d'une fiche s'arrondit ou se redresse en route,
/// au lieu de voler en rectangle et de ne s'arrondir qu'à l'atterrissage.
class PlantHero extends StatelessWidget {
  const PlantHero({super.key, required this.tag, required this.child, this.radius = BorderRadius.zero});

  final Object tag;
  final Widget child;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: _shuttle,
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }

  static Widget _shuttle(BuildContext context, Animation<double> animation, HeroFlightDirection direction, BuildContext fromContext, BuildContext toContext) {
    final from = (fromContext.widget as Hero).child;
    final to = (toContext.widget as Hero).child;
    final fromRadius = from is ClipRRect ? from.borderRadius as BorderRadius? ?? BorderRadius.zero : BorderRadius.zero;
    final toRadius = to is ClipRRect ? to.borderRadius as BorderRadius? ?? BorderRadius.zero : BorderRadius.zero;
    final image = to is ClipRRect ? to.child! : to;
    // À l'aller, l'animation va de 0 (départ) à 1 (arrivée) ; au retour,
    // elle revient de 1 à 0, le départ étant alors la route qu'on quitte.
    final start = direction == HeroFlightDirection.push ? fromRadius : toRadius;
    final end = direction == HeroFlightDirection.push ? toRadius : fromRadius;
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => ClipRRect(borderRadius: BorderRadius.lerp(start, end, animation.value)!, child: image),
    );
  }
}
