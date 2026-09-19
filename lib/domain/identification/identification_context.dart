/// Le lieu d'où vient la photo, tel que l'application le connaît déjà.
///
/// Ce n'est pas une taxonomie. Une même espèce peut vivre aux deux endroits —
/// un monstera passe l'été sur un balcon — et le § 8 de `docs/14` est
/// explicite : **le contexte donne un a priori, jamais une interdiction**.
///
/// Concrètement, le contexte choisit sur quelles classes du modèle le softmax
/// est renormalisé (§ 14.2 de `docs/09`). Les autres continuent d'être
/// calculées — le réseau les a produites de toute façon — et restent
/// proposables : couper une classe rendrait la bonne réponse *impossible*,
/// pas seulement improbable, et c'est exactement la panne que décrit le
/// § 3.2.
enum IdentificationContext {
  /// Un emplacement intérieur.
  indoor,

  /// Un emplacement extérieur.
  outdoor,

  /// Aucun lieu connu : une photo prise hors d'une plante enregistrée, ou un
  /// emplacement dont on ne sait pas s'il est dedans ou dehors. Le modèle
  /// répond alors sur toutes ses sorties, sans masque.
  unknown;

  /// Le nom du masque à chercher dans `model.json`, `null` quand il n'y a
  /// rien à chercher.
  String? get maskName => switch (this) {
        IdentificationContext.indoor => 'indoor',
        IdentificationContext.outdoor => 'outdoor',
        IdentificationContext.unknown => null,
      };
}
