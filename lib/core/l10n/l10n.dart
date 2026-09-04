import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../domain/care/care_engine.dart';
import '../../domain/models/models.dart';
import '../../domain/weather/weather.dart';
import '../../l10n/generated/app_localizations.dart';
import '../utils/dates.dart';

export '../../l10n/generated/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeTag => Localizations.localeOf(this).toLanguageTag();
}

/// Libellés localisés des types d'action (intégrés et personnalisés).
extension ActionTypeLabels on AppLocalizations {
  String kindName(String typeKey, {ActionType? custom}) {
    final kind = CareKind.fromKey(typeKey);
    if (kind == null) return custom?.label ?? typeKey;
    return switch (kind) {
      CareKind.watering => kindWatering,
      CareKind.fertilizing => kindFertilizing,
      CareKind.repotting => kindRepotting,
      CareKind.pruning => kindPruning,
      CareKind.cleaning => kindCleaning,
      CareKind.treatment => kindTreatment,
      CareKind.measurement => kindMeasurement,
      CareKind.photo => kindPhoto,
      CareKind.note => kindNote,
    };
  }

  String kindVerb(String typeKey, {ActionType? custom}) {
    final kind = CareKind.fromKey(typeKey);
    if (kind == null) return custom?.label ?? typeKey;
    return switch (kind) {
      CareKind.watering => verbWatering,
      CareKind.fertilizing => verbFertilizing,
      CareKind.repotting => verbRepotting,
      CareKind.pruning => verbPruning,
      CareKind.cleaning => verbCleaning,
      CareKind.treatment => verbTreatment,
      CareKind.measurement => verbMeasurement,
      CareKind.photo => verbPhoto,
      CareKind.note => verbNote,
    };
  }

  String kindDone(String typeKey, {ActionType? custom}) {
    final kind = CareKind.fromKey(typeKey);
    if (kind == null) return custom?.label ?? doneCustom;
    return switch (kind) {
      CareKind.watering => doneWatering,
      CareKind.fertilizing => doneFertilizing,
      CareKind.repotting => doneRepotting,
      CareKind.pruning => donePruning,
      CareKind.cleaning => doneCleaning,
      CareKind.treatment => doneTreatment,
      CareKind.measurement => doneMeasurement,
      CareKind.photo => donePhoto,
      CareKind.note => doneNote,
    };
  }

  /// « Aujourd'hui », « Demain », « Dans 3 jours », « En retard de 2 jours ».
  String dueLabel(DateTime? dueAt, DateTime now) {
    final days = CareEngine.daysUntil(dueAt, now);
    if (days == null) return dueNone;
    if (days < 0) return dueOverdue(-days);
    if (days == 0) return dueToday;
    if (days == 1) return dueTomorrow;
    return dueInDays(days);
  }

  String strategyName(CareStrategy strategy) => switch (strategy) {
        CareStrategy.fixed => strategyFixed,
        CareStrategy.seasonal => strategySeasonal,
        CareStrategy.manual => strategyManual,
      };

  String healthName(PlantHealth health) => switch (health) {
        PlantHealth.healthy => healthHealthy,
        PlantHealth.watch => healthWatch,
        PlantHealth.sick => healthSick,
      };

  String categoryName(InventoryCategory c) => switch (c) {
        InventoryCategory.fertilizer => catFertilizer,
        InventoryCategory.soil => catSoil,
        InventoryCategory.substrate => catSubstrate,
        InventoryCategory.pot => catPot,
        InventoryCategory.tool => catTool,
        InventoryCategory.treatment => catTreatment,
        InventoryCategory.seed => catSeed,
        InventoryCategory.accessory => catAccessory,
      };

  String measurementKindName(MeasurementKind k) => switch (k) {
        MeasurementKind.height => measureHeight,
        MeasurementKind.width => measureWidth,
        MeasurementKind.leaves => measureLeaves,
        MeasurementKind.pot => measurePot,
      };

  String conditionName(WeatherCondition c) => switch (c) {
        WeatherCondition.clear => condClear,
        WeatherCondition.partlyCloudy => condPartlyCloudy,
        WeatherCondition.cloudy => condCloudy,
        WeatherCondition.fog => condFog,
        WeatherCondition.drizzle => condDrizzle,
        WeatherCondition.rain => condRain,
        WeatherCondition.snow => condSnow,
        WeatherCondition.thunderstorm => condThunderstorm,
        WeatherCondition.unknown => '',
      };

  /// « 42 cm », « 9 » (sans unité), « 1,5 L ».
  String formatQuantity(double value, String unit) {
    final text = value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
    return unit.isEmpty ? text : '$text $unit';
  }

  /// Joint des noms : « Monstera, Pilea et Ficus ».
  String joinNames(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    final head = names.sublist(0, names.length - 1).join(listSeparator);
    return andJoin(head, names.last);
  }
}

/// Formats de dates locaux.
abstract final class Dates {
  static String day(BuildContext context, DateTime date) => DateFormat.MMMMd(context.localeTag).format(date);
  static String dayYear(BuildContext context, DateTime date) => DateFormat.yMMMMd(context.localeTag).format(date);
  static String monthYear(BuildContext context, DateTime date) => DateFormat.yMMMM(context.localeTag).format(date);
  static String time(BuildContext context, DateTime date) => DateFormat.Hm(context.localeTag).format(date);
  static String weekdayShort(BuildContext context, DateTime date) => DateFormat.E(context.localeTag).format(date);

  /// « Aujourd'hui », « Hier », sinon la date.
  static String relativeDay(BuildContext context, DateTime date) {
    final now = DateTime.now();
    if (date.isSameDay(now)) return context.l10n.timelineToday;
    if (date.isSameDay(now.subtract(const Duration(days: 1)))) return context.l10n.timelineYesterday;
    return date.year == now.year ? day(context, date) : dayYear(context, date);
  }

  /// « Vendredi 4 septembre » (avec majuscule initiale).
  static String longDate(BuildContext context, DateTime date) {
    final s = DateFormat.MMMMEEEEd(context.localeTag).format(date);
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }
}

/// Localisations hors arbre de widgets (démarrage, notifications).
/// Préférence utilisateur, puis langue de l'appareil, puis anglais.
AppLocalizations resolveLocalizations(Locale? preferred) {
  final device = WidgetsBinding.instance.platformDispatcher.locale;
  for (final candidate in [preferred, device]) {
    if (candidate == null) continue;
    final match = AppLocalizations.supportedLocales.where((l) => l.languageCode == candidate.languageCode);
    if (match.isNotEmpty) return lookupAppLocalizations(match.first);
  }
  return lookupAppLocalizations(const Locale('en'));
}
