import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/identification/plant_identifier.dart';

/// La candidate qu'un deuxième regard sur la photo a désignée, au-dessus de
/// la liste et distincte d'elle.
///
/// Ce n'est pas une candidate de plus : c'est une des cinq, celle qu'Iris ne
/// mettait pas en tête. Iris a raison quatre fois sur dix quand il hésite,
/// mais la bonne espèce est dans ses trois premières deux fois sur trois
/// (§ 3.9 de docs/09-plant-recognition.md) : ce qui manque n'est pas un nom
/// de plus, c'est de savoir laquelle de ces trois regarder.
///
/// La ligne ne s'affiche que lorsque l'avis **déplace** la tête de liste. Un
/// arbitre qui confirme la première candidate n'a rien à ajouter à un écran
/// qui la montre déjà en premier, et la répéter inviterait à choisir deux
/// fois la même plante.
///
/// Le sous-titre porte le caractère qui a décidé — « fenestrations », « feuille
/// charnue » — quand le service en a donné un. C'est la seule chose qui rend
/// l'avis vérifiable : la personne a la plante devant elle, et un caractère
/// qu'elle peut aller regarder vaut mieux qu'un nom de plus.
class ArbitrationRow extends StatelessWidget {
  const ArbitrationRow({super.key, required this.candidate, required this.onUse, this.trait});

  final IdentificationCandidate candidate;

  /// Le caractère visible qui a décidé, ou `null` : la ligne dit alors
  /// simplement d'où vient l'avis.
  final String? trait;

  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final commun = candidate.commonName;
    final note = (trait == null || trait!.trim().isEmpty) ? l10n.identifyArbitratedRow : trait!.trim();
    return FloraGroup(
      children: [
        FloraListRow(
          title: commun == null || commun.isEmpty ? candidate.scientificName : commun,
          // Sous le nom commun, le nom scientifique puis la raison ; sans nom
          // commun, le nom scientifique est déjà le titre et se répéterait.
          subtitle: commun == null || commun.isEmpty ? note : '${candidate.scientificName} · $note',
          onTap: onUse,
          chevron: true,
        ),
      ],
    );
  }
}
