/// Saison météorologique, avec prise en compte de l'hémisphère.
enum Season {
  winter,
  spring,
  summer,
  autumn;

  static Season of(DateTime date, {bool southernHemisphere = false}) {
    final m = date.month;
    var season = switch (m) {
      12 || 1 || 2 => Season.winter,
      3 || 4 || 5 => Season.spring,
      6 || 7 || 8 => Season.summer,
      _ => Season.autumn,
    };
    if (southernHemisphere) {
      season = switch (season) {
        Season.winter => Season.summer,
        Season.summer => Season.winter,
        Season.spring => Season.autumn,
        Season.autumn => Season.spring,
      };
    }
    return season;
  }
}
