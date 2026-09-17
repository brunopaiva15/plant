import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import 'species_sheet.dart';

/// La vignette d'une espèce dans une liste de recherche : sa photo GBIF quand
/// il en existe une libre de droits, sinon l'emoji de la section.
///
/// Toucher la photo ouvre la fiche espèce — on y voit son crédit et d'autres
/// clichés —, tandis que toucher la ligne choisit l'espèce. Comme la vignette
/// des candidats d'une identification, elle ne prend la place de rien : sans
/// photo, l'emoji reste, et la ligne garde sa hauteur.
///
/// [photo] à `false` n'interroge jamais le réseau : les longues listes du
/// parcours par catégorie gardent leur emoji sans demander une photo par
/// ligne.
class SpeciesThumbnail extends ConsumerWidget {
  const SpeciesThumbnail({super.key, required this.scientificName, required this.emoji, this.photo = true});

  /// Place réservée dans une ligne : la cible tactile de 44 points, un peu
  /// plus large que la vignette elle-même.
  static const double leadingWidth = 44;

  /// Côté de la photo.
  static const double side = 40;

  final String scientificName;
  final String emoji;
  final bool photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = Text(emoji, style: const TextStyle(fontSize: 18));
    if (!photo) return fallback;
    final image = ref.watch(speciesThumbnailProvider(scientificName)).asData?.value;
    if (image == null) return fallback;
    return Pressable(
      semanticLabel: scientificName,
      semanticHint: context.l10n.speciesInfo,
      onTap: () => showSpeciesSheet(context, scientificName: scientificName),
      child: ClipRRect(
        borderRadius: Radii.smallAll,
        child: SizedBox.square(
          dimension: side,
          child: PlantImage(remoteUrl: image.url, cacheWidth: (side * 3).round(), placeholderEmoji: emoji),
        ),
      ),
    );
  }
}
