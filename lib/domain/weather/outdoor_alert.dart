import '../care/care_profile.dart';
import 'weather.dart';

/// Ce dont on prévient avant que ça arrive, pour les plantes qui vivent
/// dehors : la nuit qui gèle, le jour qui brûle.
enum OutdoorAlertKind { frost, heat }

/// Une plante du jardin qui vit dehors, et ce que sa fiche supporte.
class OutdoorPlant {
  const OutdoorPlant({required this.name, required this.profile});

  final String name;
  final CareProfile profile;
}

/// L'avertissement : ce qui vient, quel jour, et pour qui.
class OutdoorAlert {
  const OutdoorAlert({
    required this.kind,
    required this.temperatureC,
    required this.day,
    required this.plantNames,
    required this.plantCount,
  });

  final OutdoorAlertKind kind;

  /// Le minimum de la nuit, ou le maximum du jour, selon l'avertissement.
  final double temperatureC;

  /// Le jour où il tombe.
  final DateTime day;

  /// Les plantes menacées, dans l'ordre du jardin, quatre au plus.
  final List<String> plantNames;

  /// Combien elles sont en tout, [plantNames] pouvant être tronquée.
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
          if (coldest.temperatureMin < (p.profile.minTempC ?? p.profile.idealTempMinC ?? genericFrostC)) p.name,
      ];
      if (threatened.isNotEmpty) {
        alerts.add(OutdoorAlert(
          kind: OutdoorAlertKind.frost,
          temperatureC: coldest.temperatureMin,
          day: coldest.date,
          plantNames: threatened.take(maxNames).toList(),
          plantCount: threatened.length,
        ));
      }
    }

    final hottest = window.reduce((a, b) => a.temperatureMax >= b.temperatureMax ? a : b);
    if (hottest.temperatureMax >= heatC) {
      final threatened = [
        for (final p in plants)
          if (hottest.temperatureMax > (p.profile.idealTempMaxC ?? genericHeatC)) p.name,
      ];
      if (threatened.isNotEmpty) {
        alerts.add(OutdoorAlert(
          kind: OutdoorAlertKind.heat,
          temperatureC: hottest.temperatureMax,
          day: hottest.date,
          plantNames: threatened.take(maxNames).toList(),
          plantCount: threatened.length,
        ));
      }
    }
    return alerts;
  }

  static int _offset(DateTime day, DateTime now) =>
      DateTime(day.year, day.month, day.day).difference(DateTime(now.year, now.month, now.day)).inDays;
}
