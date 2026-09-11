import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Les photos parties au moteur, et la place qui reste.
///
/// Deux photos valent **13,7 points de top-1** et trois en valent 22,4
/// (docs/09 § 6.7) : c'est le geste le plus rentable de toute l'application,
/// gratuit, hors ligne et instantané. Il était pourtant écrit en légende —
/// « Iris · 2 photos » —, c'est-à-dire un **état**, jamais un geste, et un
/// bouton « Ajouter une photo » au singulier sous la liste des candidats,
/// qui ne laissait rien deviner d'une suite.
///
/// Une bande d'emplacements dit les deux sans phrase : on voit ses photos,
/// on voit celle qui manque, on touche. La place vide est l'invitation, et
/// elle se renouvelle d'elle-même tant qu'il en reste une.
///
/// **L'invitation continue d'être décidée ailleurs** — `secondPhotoOffer`,
/// à côté de `FallbackPolicy`. [onAdd] nul, aucun emplacement libre ne
/// s'affiche : c'est ainsi qu'une réponse venue de Pl@ntNet n'en propose
/// pas, une photo de plus ne la rejouant pas sans un nouvel appel.
class IdentificationPhotoStrip extends StatelessWidget {
  const IdentificationPhotoStrip({
    super.key,
    required this.paths,
    required this.maxPhotos,
    this.onAdd,
    this.onRemove,
    this.size = 64,
  });

  /// Les photos soumises, en chemins absolus. La première vient de
  /// l'appelant : c'est celle qui a ouvert la feuille, ou la photo de la
  /// plante en cours de création.
  final List<String> paths;

  /// Au-delà, le moteur n'est plus mesuré (le § 6.7 s'arrête à trois) et la
  /// recherche en ligne est le meilleur recours.
  final int maxPhotos;

  /// Nul quand une photo de plus n'est pas proposée : la bande se contente
  /// alors de montrer ce qui est parti.
  final VoidCallback? onAdd;

  /// Retirer la photo d'un rang. Jamais le premier — il appartient à
  /// l'appelant, et la bande ne lui met pas de croix.
  final ValueChanged<int>? onRemove;

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    // Les emplacements libres ne se montrent que si l'on peut les remplir :
    // trois cases vides après une réponse distante promettraient un geste
    // qui n'aurait pas lieu.
    final slots = onAdd == null ? paths.length : maxPhotos;
    if (slots == 0) return const SizedBox.shrink();
    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < slots; i++)
            Padding(
              padding: EdgeInsets.only(right: i == slots - 1 ? 0 : Space.xs),
              child: _slot(i, c, l10n),
            ),
        ],
      ),
    );
  }

  /// Le rang [i] de la bande : une photo, le déclencheur, ou la place qui
  /// reste.
  Widget _slot(int i, FloraColors c, AppLocalizations l10n) {
    if (i < paths.length) {
      return _Photo(
        path: paths[i],
        size: size,
        // Le premier rang n'appartient pas à cette bande.
        onRemove: i > 0 && onRemove != null ? () => onRemove!(i) : null,
      );
    }
    // La première case libre est le déclencheur ; celles d'après ne sont que
    // la place qui reste, et ne s'écoutent pas — deux cibles côte à côte pour
    // le même geste n'en font pas un plus clair.
    if (i == paths.length) {
      return Pressable(
        onTap: onAdd,
        scale: 0.95,
        semanticLabel: l10n.identifyAnotherPhoto,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.mediumAll),
          child: Icon(CupertinoIcons.camera_fill, color: c.sage, size: 22),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(borderRadius: Radii.mediumAll, border: Border.all(color: c.line)),
      child: Icon(CupertinoIcons.plus, size: 14, color: c.inkTertiary),
    );
  }
}

/// Une photo de la bande, avec sa croix quand elle peut partir.
class _Photo extends StatelessWidget {
  const _Photo({required this.path, required this.size, this.onRemove});

  final String path;
  final double size;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final image = ClipRRect(
      borderRadius: Radii.mediumAll,
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => SizedBox(width: size, height: size, child: ColoredBox(color: c.surfaceMuted)),
      ),
    );
    if (onRemove == null) return image;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          image,
          Positioned(
            top: 0,
            right: 0,
            // La vignette elle-même n'écoute pas le doigt : la croix est
            // seule sur la tuile, et sa zone d'écoute s'arrête à son coin
            // plutôt que de s'élargir aux 44 points réglementaires — une
            // suppression déclenchée au milieu d'une photo serait pire que
            // la cible un peu juste qu'on évite ainsi.
            child: Pressable(
              onTap: onRemove,
              scale: 0.9,
              minTapTarget: false,
              semanticLabel: context.l10n.deletePhoto,
              child: Padding(
                padding: const EdgeInsets.all(Space.xxs),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.92), shape: BoxShape.circle),
                  child: Icon(CupertinoIcons.xmark, size: 11, color: c.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
