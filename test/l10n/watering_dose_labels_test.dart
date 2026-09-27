import 'package:flora/core/l10n/care_labels.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/pot.dart';
import 'package:flora/l10n/generated/app_localizations_en.dart';
import 'package:flora/l10n/generated/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';

/// La dose et la correction du pot, telles que la fiche d'entretien les écrit.
void main() {
  final fr = AppLocalizationsFr();
  final en = AppLocalizationsEn();

  test('la dose se dit en millilitres, puis en litres passé un litre', () {
    expect(fr.wateringDoseNote(const Pot(diameterCm: 15), DryDown.halfDry, metric: true), 'Versez 300 à 400 ml à chaque arrosage.');
    expect(fr.wateringDoseNote(const Pot(diameterCm: 30), DryDown.halfDry, metric: true), matches(RegExp(r'^Versez \d+(,\d+)? à \d+(,\d+)? L à chaque arrosage\.$')));
  });

  test('en impérial, la dose se dit en onces liquides', () {
    expect(en.wateringDoseNote(const Pot(diameterCm: 15), DryDown.halfDry, metric: false), 'Pour 10 to 14 fl oz each time you water.');
  });

  test('un pot à réserve se remplit, un pot sans diamètre ne dit rien', () {
    expect(fr.wateringDoseNote(const Pot(diameterCm: 15, material: PotMaterial.selfWatering), DryDown.halfDry, metric: true), fr.careWateringReservoir);
    expect(fr.wateringDoseNote(const Pot(material: PotMaterial.plastic), DryDown.halfDry, metric: true), isNull);
  });

  test('la correction du pot se dit dans son sens, et se tait quand elle est faible', () {
    expect(fr.wateringPotNote(const Pot(diameterCm: 15, material: PotMaterial.terracotta)), 'Votre pot raccourcit l\'intervalle de 20 %.');
    expect(fr.wateringPotNote(const Pot(diameterCm: 15, material: PotMaterial.selfWatering)), 'Votre pot allonge l\'intervalle de 60 %.');
    expect(fr.wateringPotNote(const Pot(diameterCm: 15.5)), isNull);
    expect(fr.wateringPotNote(Pot.unknown), isNull);
  });
}
