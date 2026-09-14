import 'weather.dart';

/// Ce que la semaine du lieu fait à la terre d'un pot.
///
/// Une semaine de canicule sèche vide un pot en trois jours là où la fiche
/// en annonce sept ; une semaine fraîche et pluvieuse le garde humide deux
/// fois plus longtemps. La saison ne voit ni l'une ni l'autre : elle ne
/// connaît que le mois.
///
/// La fenêtre regarde des deux côtés — les jours passés disent l'état de la
/// terre maintenant, les jours à venir ce qu'elle deviendra d'ici au prochain
/// arrosage.
enum WeatherTrendKind {
  /// Chaud et sec : la terre sèche vite.
  dryHeat,

  /// Chaud, sans plus.
  warm,

  /// Pluvieux : la terre reste humide.
  wet,

  /// Froid : l'évaporation s'arrête presque.
  cold,

  /// Rien qui sorte de l'ordinaire.
  mild,
}

class WeatherTrend {
  const WeatherTrend({required this.meanMaxC, required this.rainMm, required this.days});

  /// Moyenne des maximums de la fenêtre (°C).
  final double meanMaxC;

  /// Cumul de pluie sur la fenêtre (mm).
  final double rainMm;

  /// Nombre de jours observés.
  final int days;

  double get rainPerDayMm => days == 0 ? 0 : rainMm / days;

  /// Deux millimètres par jour suffisent à garder une terre humide ; en
  /// dessous d'un demi, l'arrosage est la seule eau que la plante voit.
  bool get isWet => rainPerDayMm >= 2;
  bool get isDry => rainPerDayMm < 0.5;

  WeatherTrendKind get kind {
    if (meanMaxC <= 10) return WeatherTrendKind.cold;
    if (isWet) return WeatherTrendKind.wet;
    if (meanMaxC >= 28 && isDry) return WeatherTrendKind.dryHeat;
    if (meanMaxC >= 25) return WeatherTrendKind.warm;
    return WeatherTrendKind.mild;
  }

  /// Multiplicateur d'intervalle : en dessous de 1, on arrose plus souvent ;
  /// au-dessus, on espace.
  ///
  /// Les deux effets se multiplient — une pluie de fin d'été compense une
  /// partie de la chaleur, elle ne l'annule pas —, et le résultat reste entre
  /// 0,6 et 1,6 : la météo corrige la fiche de l'espèce, elle ne la remplace
  /// pas, et un intervalle qui doublerait d'une semaine à l'autre ne serait
  /// plus une routine.
  double get wateringFactor {
    final heat = switch (meanMaxC) {
      >= 32 => 0.7,
      >= 28 => 0.8,
      >= 24 => 0.9,
      <= 5 => 1.4,
      <= 12 => 1.2,
      _ => 1.0,
    };
    final water = switch (rainPerDayMm) {
      >= 6 => 1.35,
      >= 2 => 1.15,
      < 0.5 when meanMaxC >= 20 => 0.9,
      _ => 1.0,
    };
    return (heat * water).clamp(0.6, 1.6);
  }

  /// La tendance d'une fenêtre de prévisions. `null` sans jour exploitable :
  /// hors ligne, l'intervalle reste celui de la saison.
  static WeatherTrend? of(Iterable<DailyWeather> window) {
    final days = window.toList();
    if (days.isEmpty) return null;
    return WeatherTrend(
      meanMaxC: days.fold(0.0, (sum, d) => sum + d.temperatureMax) / days.length,
      rainMm: days.fold(0.0, (sum, d) => sum + d.precipitationMm),
      days: days.length,
    );
  }
}
