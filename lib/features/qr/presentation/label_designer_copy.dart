import '../../../l10n/generated/app_localizations.dart';

extension LabelDesignerCopy on AppLocalizations {
  String get _labelLanguage => localeName.split(RegExp('[-_]')).first;

  String get labelDesignerTitle => switch (_labelLanguage) {
        'fr' => 'Créer les étiquettes',
        'de' => 'Etiketten erstellen',
        'it' => 'Crea etichette',
        _ => 'Create labels',
      };

  String get labelPreset => switch (_labelLanguage) {
        'fr' => 'Format d’étiquette',
        'de' => 'Etikettenformat',
        'it' => 'Formato etichetta',
        _ => 'Label format',
      };

  String get labelCustom => switch (_labelLanguage) {
        'fr' => 'Personnalisé',
        'de' => 'Benutzerdefiniert',
        'it' => 'Personalizzato',
        _ => 'Custom',
      };

  String get labelSheetFormat => switch (_labelLanguage) {
        'fr' => 'Format de la feuille',
        'de' => 'Blattformat',
        'it' => 'Formato foglio',
        _ => 'Sheet format',
      };

  String get labelSize => switch (_labelLanguage) {
        'fr' => 'Dimensions de l’étiquette',
        'de' => 'Etikettengröße',
        'it' => 'Dimensioni etichetta',
        _ => 'Label size',
      };

  String get labelSheetSize => switch (_labelLanguage) {
        'fr' => 'Dimensions de la feuille',
        'de' => 'Blattgröße',
        'it' => 'Dimensioni foglio',
        _ => 'Sheet size',
      };

  String get labelWidth => switch (_labelLanguage) {
        'fr' => 'Largeur (mm)',
        'de' => 'Breite (mm)',
        'it' => 'Larghezza (mm)',
        _ => 'Width (mm)',
      };

  String get labelHeight => switch (_labelLanguage) {
        'fr' => 'Hauteur (mm)',
        'de' => 'Höhe (mm)',
        'it' => 'Altezza (mm)',
        _ => 'Height (mm)',
      };

  String get labelCopies => switch (_labelLanguage) {
        'fr' => 'Exemplaires par entrée',
        'de' => 'Exemplare pro Eintrag',
        'it' => 'Copie per voce',
        _ => 'Copies per item',
      };

  String labelTotal(int count) => switch (_labelLanguage) {
        'fr' => '$count étiquette${count > 1 ? 's' : ''} au total',
        'de' => '$count Etikett${count == 1 ? '' : 'en'} insgesamt',
        'it' => '$count etichett${count == 1 ? 'a' : 'e'} in totale',
        _ => '$count label${count == 1 ? '' : 's'} total',
      };

  String labelPerSheet(int count) => switch (_labelLanguage) {
        'fr' => '$count par feuille',
        'de' => '$count pro Blatt',
        'it' => '$count per foglio',
        _ => '$count per sheet',
      };

  String get labelContent => switch (_labelLanguage) {
        'fr' => 'Contenu',
        'de' => 'Inhalt',
        'it' => 'Contenuto',
        _ => 'Content',
      };

  String get labelShowName => switch (_labelLanguage) {
        'fr' => 'Nom',
        'de' => 'Name',
        'it' => 'Nome',
        _ => 'Name',
      };

  String get labelShowSpecies => switch (_labelLanguage) {
        'fr' => 'Espèce',
        'de' => 'Art',
        'it' => 'Specie',
        _ => 'Species',
      };

  String get labelShowNumber => switch (_labelLanguage) {
        'fr' => 'Numéro',
        'de' => 'Nummer',
        'it' => 'Numero',
        _ => 'Number',
      };

  String get labelQrOnly => switch (_labelLanguage) {
        'fr' => 'QR uniquement',
        'de' => 'Nur QR-Code',
        'it' => 'Solo QR',
        _ => 'QR only',
      };

  String get labelCustomText => switch (_labelLanguage) {
        'fr' => 'Texte personnalisé (facultatif)',
        'de' => 'Eigener Text (optional)',
        'it' => 'Testo personalizzato (facoltativo)',
        _ => 'Custom text (optional)',
      };

  String get labelAdvanced => switch (_labelLanguage) {
        'fr' => 'Mise en page',
        'de' => 'Layout',
        'it' => 'Impaginazione',
        _ => 'Layout',
      };

  String get labelMargin => switch (_labelLanguage) {
        'fr' => 'Marge (mm)',
        'de' => 'Rand (mm)',
        'it' => 'Margine (mm)',
        _ => 'Margin (mm)',
      };

  String get labelGap => switch (_labelLanguage) {
        'fr' => 'Espacement (mm)',
        'de' => 'Abstand (mm)',
        'it' => 'Spaziatura (mm)',
        _ => 'Gap (mm)',
      };

  String get labelCutLines => switch (_labelLanguage) {
        'fr' => 'Afficher les contours de découpe',
        'de' => 'Schnittlinien anzeigen',
        'it' => 'Mostra linee di taglio',
        _ => 'Show cut lines',
      };

  String get labelPreview => switch (_labelLanguage) {
        'fr' => 'Aperçu',
        'de' => 'Vorschau',
        'it' => 'Anteprima',
        _ => 'Preview',
      };

  String get labelGeneratePdf => switch (_labelLanguage) {
        'fr' => 'Créer le PDF',
        'de' => 'PDF erstellen',
        'it' => 'Crea PDF',
        _ => 'Create PDF',
      };

  String get labelDoesNotFit => switch (_labelLanguage) {
        'fr' => 'Ces dimensions ne tiennent pas sur la feuille choisie.',
        'de' => 'Diese Abmessungen passen nicht auf das gewählte Blatt.',
        'it' => 'Queste dimensioni non entrano nel foglio scelto.',
        _ => 'These dimensions do not fit on the selected sheet.',
      };

  String get labelPresetExact => switch (_labelLanguage) {
        'fr' => 'Disposition pré-découpée exacte',
        'de' => 'Exaktes vorgestanztes Layout',
        'it' => 'Layout pretagliato esatto',
        _ => 'Exact pre-cut layout',
      };
}
