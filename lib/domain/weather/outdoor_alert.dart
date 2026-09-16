import '../care/care_guide.dart';
import '../care/care_profile.dart';
import 'weather.dart';

/// Ce dont on prévient avant que ça arrive, pour les plantes qui vivent
/// dehors : la nuit qui gèle, le jour qui brûle.
enum OutdoorAlertKind { frost, heat }

/// Une plante du jardin qui vit dehors, et ce que sa fiche supporte.
class OutdoorPlant {
  const OutdoorPlant({
    required this.name,
    required this.profile,
    this.match = CareMatch.species,
    this.matchedOn,
  });

  final String name;
  final CareProfile profile;

  /// Précision de la fiche d'où vient le seuil de température. Un seuil lu
  /// sur la famille n'est pas un fait de l'espèce : l'alerte le nomme par la
  /// famille plutôt que par la plante. La valeur par défaut vaut pour les
  /// appels qui n'ont qu'un profil sous la main.
  final CareMatch match;

  /// La famille trouvée, quand [match] vaut [CareMatch.family].
  final String? matchedOn;

  /// Le seuil vient-il de l'espèce ou de son genre ? Lui seul permet de
  /// nommer la plante dans un avertissement.
  bool get thresholdIsSpecific => match == CareMatch.species || match == CareMatch.genus;
}

/// L'avertissement : ce qui vient, quel jour, et pour qui.
class OutdoorAlert {
  const OutdoorAlert({
    required this.kind,
    required this.temperatureC,
    required this.day,
    required this.plantNames,
    required this.familyNames,
    required this.plantCount,
  });

  final OutdoorAlertKind kind;

  /// Le minimum de la nuit, ou le maximum du jour, selon l'avertissement.
  final double temperatureC;

  /// Le jour où il tombe.
  final DateTime day;

  /// Les plantes menacées dont la fiche nomme le seuil (espèce ou genre),
  /// dans l'ordre du jardin, quatre au plus.
  final List<String> plantNames;

  /// Les familles dont le seuil n'est qu'un repère de groupe : la plante n'y
  /// est pas nommée, parce que sa fiche ne dit pas qu'elle craint ce froid.
  final List<String> familyNames;

  /// Combien de plantes sont menacées en tout, noms et familles confondus.
  final int plantCount;

  /// Nombre de jours qui séparent [day] de [from], zéro pour aujourd'hui.
  int daysFrom(DateTime from) => DateTime(day.year, day.month, day.day).difference(DateTime(from.year, from.month, from.day)).inDays;
}

/// Lit les prévisions pour les plantes du dehors.
///
/// Deux seuils et rien d'autre : on ne prévient que de ce qui abîme, et une
/// alerte par sorte — celle du jour le plus dur de la fenêtre. Un
/// avertissement qui revient tous les matins n'est plus un avertissement.
abstract final class OutdoorAlertAdvisor {
  /// Deux degrés sous abri, c'est zéro au sol et sur les feuilles : le gel
  /// blanc se forme avant que le thermomètre l'annonce.
  static const double frostC = 2;

  /// Au-dessus, une journée entière au soleil brûle un feuillage et vide un
  /// pot, même arrosé le matin.
  static const double heatC = 32;

  /// Sans minimum connu, seul le gel franc concerne une plante ; sans
  /// maximum connu, seule la chaleur extrême.
  static const double genericFrostC = 0;
  static const double genericHeatC = 35;

  static const int maxNames = 4;

  /// Trois jours : de quoi rentrer les pots un soir, pas de quoi s'inquiéter
  /// d'une semaine à l'avance.
  static const int horizonDays = 3;

  static List<OutdoorAlert> alerts({
    required List<DailyWeather> forecast,
    required List<OutdoorPlant> plants,
    required DateTime now,
  }) {
    if (plants.isEmpty) return const [];
    final window = [
      for (final day in forecast)
        if (_offset(day.date, now) case final d when d >= 0 && d < horizonDays) day,
    ];
    if (window.isEmpty) return const [];

    final alerts = <OutdoorAlert>[];
    final coldest = window.reduce((a, b) => a.temperatureMin <= b.temperatureMin ? a : b);
    if (coldest.temperatureMin <= frostC) {
      final threatened = [
        for (final p in plants)
          if (coldest.temperatureMin < (p.profile.coldLimitC ?? genericFrostC)) p,
      ];
      final alert = _build(OutdoorAlertKind.frost, coldest.temperatureMin, coldest.date, threatened);
      if (alert != null) alerts.add(alert);
    }

    final hottest = window.reduce((a, b) => a.temperatureMax >= b.temperatureMax ? a : b);
    if (hottest.temperatureMax >= heatC) {
      final threatened = [
        for (final p in plants)
          if (hottest.temperatureMax > (p.profile.idealTempMaxC ?? genericHeatC)) p,
      ];
      final alert = _build(OutdoorAlertKind.heat, hottest.temperatureMax, hottest.date, threatened);
      if (alert != null) alerts.add(alert);
    }
    return alerts;
  }

  /// Compose l'avertissement. Une plante dont la fiche nomme le seuil est
  /// nommée ; une plante dont le seuil vient de sa famille est dite par sa
  /// famille, sans être nommée elle-même. Une plante sans famille connue
  /// n'est pas nommée : mieux vaut le silence qu'un fait inventé.
  static OutdoorAlert? _build(OutdoorAlertKind kind, double temperatureC, DateTime day, List<OutdoorPlant> threatened) {
    if (threatened.isEmpty) return null;
    final named = <String>[];
    final families = <String>[];
    for (final p in threatened) {
      if (p.thresholdIsSpecific) {
        if (named.length < maxNames) named.add(p.name);
        continue;
      }
      if (p.match != CareMatch.family) continue;
      final family = p.matchedOn;
      if (family != null && family.isNotEmpty && !families.contains(family)) families.add(family);
    }
    if (named.isEmpty && families.isEmpty) return null;
    return OutdoorAlert(
      kind: kind,
      temperatureC: temperatureC,
      day: day,
      plantNames: named,
      familyNames: families,
      plantCount: threatened.length,
    );
  }

  static int _offset(DateTime day, DateTime now) =>
      DateTime(day.year, day.month, day.day).difference(DateTime(now.year, now.month, now.day)).inDays;
}
