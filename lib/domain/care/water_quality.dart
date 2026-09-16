import 'care_profile.dart';

/// Les eaux dont on dispose pour arroser, de la plus courante à la plus
/// inattendue.
///
/// Ce ne sont pas des marques d'eau mais des origines, et chacune arrive avec
/// ce qu'elle a dissous en chemin : le calcaire du réseau, les poussières
/// d'un toit, le sodium d'une résine, le biofilm d'un bac de climatiseur.
enum WaterKind { tap, rain, filtered, osmosis, demineralized, condensate, softened }

/// Ce que vaut une eau pour une plante donnée.
enum WaterVerdict { recommended, suitable, caution, avoid }

/// Ce que vaut [kind] pour une plante de tolérance [tolerance].
///
/// Deux choses se croisent ici, et elles ne se confondent pas. Les sels
/// dissous dépendent de la plante : le calcaire du robinet passe inaperçu sur
/// un philodendron, brunit les pointes d'un calathea et tue une plante de
/// terre acide. La propreté de l'eau, elle, ne dépend d'aucune plante : le
/// condensat d'un climatiseur reste une eau de bac quelle que soit l'espèce,
/// et le sodium d'un adoucisseur abîme tous les terreaux.
///
/// Le fluor est le troisième axe : il brunit les pointes d'un dracæna qui boit
/// pourtant l'eau du robinet sans broncher. Un filtre de carafe ne le retire
/// pas — [fluorideSensitive] abaisse donc aussi le verdict de l'eau filtrée.
WaterVerdict waterVerdictFor(WaterKind kind, WaterTolerance tolerance, {bool fluorideSensitive = false}) => switch (kind) {
      // L'eau de pluie est douce, sans calcaire, légèrement acide : elle
      // convient à tout le monde.
      WaterKind.rain => WaterVerdict.recommended,

      // Le robinet est le cas ordinaire, et le calcaire décide. Le fluor le
      // retient même chez une plante qui tolère le calcaire.
      WaterKind.tap => switch (tolerance) {
          WaterTolerance.tolerant => fluorideSensitive ? WaterVerdict.caution : WaterVerdict.recommended,
          WaterTolerance.sensitive => WaterVerdict.caution,
          WaterTolerance.strict => WaterVerdict.avoid,
        },

      // Une carafe retire le chlore et une part du calcaire, jamais tout, et
      // pas le fluor : assez pour une plante sensible, trop peu pour une
      // plante de terre acide ou sensible au fluor.
      WaterKind.filtered => switch (tolerance) {
          WaterTolerance.strict => WaterVerdict.caution,
          _ when fluorideSensitive => WaterVerdict.caution,
          _ => WaterVerdict.suitable,
        },

      // Presque sans minéraux : ce qu'il faut aux plantes qui craignent le
      // calcaire comme au fluor, et une dépense sans objet pour les autres.
      WaterKind.osmosis || WaterKind.demineralized => switch (tolerance) {
          WaterTolerance.tolerant => fluorideSensitive ? WaterVerdict.recommended : WaterVerdict.suitable,
          _ => WaterVerdict.recommended,
        },

      // Le condensat est une eau distillée qui a ruisselé dans un bac : sa
      // réserve est la même pour toutes les plantes.
      WaterKind.condensate => WaterVerdict.caution,

      // Une résine échange le calcaire contre du sodium, qui s'accumule dans
      // le terreau : aucune plante n'y gagne.
      WaterKind.softened => WaterVerdict.avoid,
    };
