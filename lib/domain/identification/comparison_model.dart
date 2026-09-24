/// Un modèle qu'on mesure contre Iris, sur les mêmes photos (§ 15 de
/// `docs/09`).
///
/// Un banc d'essai, pas une source : chacun se branche par un réglage, passe
/// après Iris, et ce qu'il rend s'affiche sous ses propositions sans jamais
/// entrer dans la décision de la cascade. L'ordre de l'énumération est celui
/// dans lequel ils passent, et celui des sections de la feuille.
enum ComparisonModel {
  plantNet300k(
    displayName: 'Pl@ntNet-300K',
    key: 'plantnet300k',
    timeout: Duration(seconds: 12),
  ),
  plantClef2024(
    displayName: 'PlantCLEF 2024',
    key: 'plantclef2024',
    // Un ViT-B de 86 millions de paramètres, à 518 px, en int8 dynamique
    // que le TensorFlow Lite 2.12 d'iOS n'accélère pas : une dizaine de
    // secondes par photo, et le premier appel charge en plus 97 Mo de poids
    // (docs/09 § 15.1). Un délai fait pour MobileNet le couperait en plein
    // calcul.
    timeout: Duration(seconds: 60),
  ),
  ;

  const ComparisonModel({required this.displayName, required this.key, required this.timeout});

  /// Le nom propre, écrit comme ses auteurs l'écrivent. Il ne se traduit pas
  /// plus qu'« Iris ».
  final String displayName;

  /// Le dossier de ses assets sous `assets/model/`, et la racine de la clé de
  /// son réglage.
  final String key;

  /// Le délai de chaque inférence, chargement compris au premier appel.
  final Duration timeout;
}
