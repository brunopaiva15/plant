import 'care_profile.dart';

/// Ce qu'il faut d'une lampe pour tenir un besoin de lumière à l'intérieur.
///
/// Les chiffres sont ceux que la plante reçoit — le PPFD, en µmol/m²/s, mesuré
/// au niveau des feuilles —, pas ceux annoncés sur la boîte : une lampe se
/// règle en hauteur jusqu'à les atteindre. [dliMin] et [dliMax] donnent la
/// même chose en dose du jour, la grandeur avec laquelle se raisonne une serre.
///
/// Le matériel est toujours le même : une LED horticole à spectre complet,
/// blanche. Les barres roses des premières générations éclairaient moins bien
/// pour la même consommation et rendent la plante illisible à l'œil.
class GrowLight {
  const GrowLight({required this.ppfdMin, required this.ppfdMax, required this.hours});

  /// Intensité reçue par le feuillage, en µmol/m²/s.
  final int ppfdMin;
  final int ppfdMax;

  /// Heures d'éclairage par jour, minuterie comprise.
  final int hours;

  /// Dose journalière, en mol/m²/jour : le PPFD multiplié par la durée.
  int get dliMin => _dli(ppfdMin);
  int get dliMax => _dli(ppfdMax);

  int _dli(int ppfd) => (ppfd * hours * 3600 / 1000000).round();

  /// La lampe qui remplace la fenêtre qu'on n'a pas.
  static GrowLight forNeed(LightNeed need) => switch (need) {
        LightNeed.shade => const GrowLight(ppfdMin: 50, ppfdMax: 100, hours: 10),
        LightNeed.lowLight => const GrowLight(ppfdMin: 80, ppfdMax: 150, hours: 12),
        LightNeed.indirect => const GrowLight(ppfdMin: 120, ppfdMax: 200, hours: 12),
        LightNeed.brightIndirect => const GrowLight(ppfdMin: 150, ppfdMax: 250, hours: 12),
        LightNeed.someSun => const GrowLight(ppfdMin: 250, ppfdMax: 400, hours: 14),
        LightNeed.fullSun => const GrowLight(ppfdMin: 400, ppfdMax: 700, hours: 14),
      };
}
