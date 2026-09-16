import 'care_profile.dart';

/// Ce qu'une feuille montre, dit comme on le voit : elle s'éclaircit, elle
/// brûle, elle se tache au milieu, elle ne grandit plus.
///
/// C'est l'autre entrée de la fiche d'entretien. On y arrive avec la plante
/// sous les yeux et une inquiétude, pas avec un nom de champignon ; le nom
/// vient après, s'il vient. Le diagnostic par photo répond à la même question
/// et demande le réseau — ceci tient sur l'appareil, sans rien envoyer.
enum LeafSign {
  paling,
  yellowing,
  scorched,
  spots,
  brownTips,
  stunted,
  drooping,
  falling,
  sticky,
}

/// Ce qui peut expliquer un signe. Une cause sert à plusieurs signes — l'eau
/// en excès jaunit, ramollit et fait tomber —, et c'est bien ainsi : deux
/// signes qui mènent à la même cause la désignent mieux qu'un seul.
enum LeafCause {
  tooMuchSun,
  notEnoughLight,
  overwatering,
  underwatering,
  dryAir,
  coldDraught,
  hardWater,
  poorSoil,
  potBound,
  damagedRoots,
  leafPests,
  honeydewPests,
  sootyMould,
  leafFungus,
  wetLeaves,
  recentMove,
  oldLeaves,
  winterRest,
}

/// Un signe et ce qui l'explique sur cette plante-là.
typedef LeafReading = ({LeafSign sign, List<LeafCause> causes});

/// La table des signes, filtrée par la fiche de l'espèce.
///
/// Les causes sont rangées de la plus fréquente à la moins, telles qu'on les
/// vérifierait : la lumière et l'eau avant le champignon. Une cause que
/// l'espèce ne connaît pas est retirée plutôt que nuancée — un cactus ne
/// souffre pas d'un excès de soleil, une plante qui aime l'air sec ne brunit
/// pas des pointes pour cela, un tillandsia n'a pas de terreau à épuiser — et
/// un signe qui n'a plus de cause disparaît.
abstract final class LeafSigns {
  static const table = <LeafSign, List<LeafCause>>{
    LeafSign.paling: [LeafCause.tooMuchSun, LeafCause.poorSoil, LeafCause.leafPests],
    LeafSign.yellowing: [LeafCause.overwatering, LeafCause.poorSoil, LeafCause.oldLeaves],
    LeafSign.scorched: [LeafCause.tooMuchSun, LeafCause.underwatering, LeafCause.hardWater],
    LeafSign.spots: [LeafCause.leafFungus, LeafCause.wetLeaves, LeafCause.coldDraught],
    LeafSign.brownTips: [LeafCause.dryAir, LeafCause.hardWater, LeafCause.underwatering],
    LeafSign.stunted: [LeafCause.notEnoughLight, LeafCause.poorSoil, LeafCause.potBound, LeafCause.winterRest],
    LeafSign.drooping: [LeafCause.underwatering, LeafCause.overwatering, LeafCause.damagedRoots],
    LeafSign.falling: [LeafCause.recentMove, LeafCause.coldDraught, LeafCause.overwatering],
    LeafSign.sticky: [LeafCause.honeydewPests, LeafCause.sootyMould],
  };

  /// Les signes à lire sur une plante dont la fiche est [profile].
  static List<LeafReading> forProfile(CareProfile profile) {
    final out = <LeafReading>[];
    for (final entry in table.entries) {
      final causes = [
        for (final cause in entry.value)
          if (_applies(cause, profile)) cause,
      ];
      if (causes.isNotEmpty) out.add((sign: entry.key, causes: causes));
    }
    return out;
  }

  /// Cette cause a-t-elle un sens pour cette espèce ?
  static bool _applies(LeafCause cause, CareProfile profile) => switch (cause) {
        // Une espèce de plein soleil ne brûle pas au soleil.
        LeafCause.tooMuchSun => profile.light != LightNeed.fullSun,
        // Ni une espèce qui préfère l'air sec ne brunit des pointes.
        LeafCause.dryAir => profile.humidity != HumidityNeed.low,
        // Le repos hivernal n'explique un arrêt que chez celles qui l'ont.
        LeafCause.winterRest => profile.dormantInWinter,
        // Une plante qui pousse sans substrat — un tillandsia sur son support —
        // n'a ni terreau épuisé ni racines à l'étroit dans un pot.
        LeafCause.poorSoil || LeafCause.potBound => profile.soil != SoilKind.none,
        _ => true,
      };
}
