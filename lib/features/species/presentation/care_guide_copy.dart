import '../../../domain/care/care_profile.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Textes longs propres à la fiche d'entretien.
///
/// Les libellés courts restent dans les ARB. Ici, on formule les mêmes données
/// comme de vrais conseils : une phrase complète, une action compréhensible et
/// le moins de jargon possible. Cela évite d'afficher des morceaux de notes
/// techniques comme « 60 % et plus » ou « bouture seulement » sans contexte.
extension CareGuidePresentationCopy on AppLocalizations {
  String get _careLanguage => localeName.split(RegExp('[-_]')).first;

  String guideWateringSeasons(int summer, int winter) => switch (_careLanguage) {
        'fr' => 'En pleine saison : tous les $summer jours. En hiver : tous les $winter jours.',
        'de' => 'In der Hauptsaison: alle $summer Tage. Im Winter: alle $winter Tage.',
        'it' => 'In piena stagione: ogni $summer giorni. In inverno: ogni $winter giorni.',
        _ => 'In peak season: every $summer days. In winter: every $winter days.',
      };

  String get guideBadgeDormant => switch (_careLanguage) {
        'fr' => 'Nécessite un repos hivernal',
        'de' => 'Braucht eine Winterruhe',
        'it' => 'Ha bisogno di un riposo invernale',
        _ => 'Needs a winter rest',
      };

  String get guideBadgeMist => switch (_careLanguage) {
        'fr' => 'Apprécie une brumisation régulière',
        'de' => 'Mag regelmäßiges Besprühen',
        'it' => 'Apprezza nebulizzazioni regolari',
        _ => 'Enjoys regular misting',
      };

  String get guideBadgeOutdoor => switch (_careLanguage) {
        'fr' => 'Peut être cultivée à l’extérieur',
        'de' => 'Kann draußen kultiviert werden',
        'it' => 'Può essere coltivata all’aperto',
        _ => 'Can be grown outdoors',
      };

  String guideSoilMix(SoilKind soil) => switch ((_careLanguage, soil)) {
        ('fr', SoilKind.standard) =>
          'Utilisez un terreau universel aéré avec environ 20 % de perlite. Le mélange doit rester léger et laisser l’excès d’eau s’écouler.',
        ('fr', SoilKind.draining) =>
          'Mélangez environ 50 % de terreau, 25 % de perlite et 25 % de sable grossier ou de pouzzolane. L’eau doit pouvoir s’évacuer rapidement.',
        ('fr', SoilKind.cactus) =>
          'Privilégiez un mélange très minéral : environ 30 % de terreau et 70 % de pouzzolane, pierre ponce ou sable grossier.',
        ('fr', SoilKind.orchid) =>
          'Utilisez principalement des écorces de pin, avec un peu de perlite et de sphaigne. Évitez le terreau classique, qui retient trop d’eau autour des racines.',
        ('fr', SoilKind.acidic) =>
          'Utilisez un substrat acide et aéré, avec environ 25 % d’écorces de pin. Évitez les mélanges calcaires.',
        ('fr', SoilKind.rich) =>
          'Utilisez un mélange riche mais aéré : environ 40 % de terreau, 40 % de compost et 20 % de perlite.',
        ('fr', SoilKind.none) =>
          'Aucun terreau n’est nécessaire. Les racines peuvent vivre dans l’eau ou sur un support adapté à la culture hors-sol.',
        ('de', SoilKind.standard) =>
          'Verwenden Sie lockere Universalblumenerde mit etwa 20 % Perlit. Die Mischung soll leicht bleiben und überschüssiges Wasser gut ablaufen lassen.',
        ('de', SoilKind.draining) =>
          'Mischen Sie etwa 50 % Blumenerde, 25 % Perlit und 25 % groben Sand oder Lavagranulat. Wasser soll schnell ablaufen können.',
        ('de', SoilKind.cactus) =>
          'Verwenden Sie eine sehr mineralische Mischung: etwa 30 % Blumenerde und 70 % Bims, Lavagranulat oder groben Sand.',
        ('de', SoilKind.orchid) =>
          'Verwenden Sie hauptsächlich mittelgrobe Pinienrinde mit etwas Perlit und Sphagnum. Normale Blumenerde hält an den Wurzeln zu viel Wasser.',
        ('de', SoilKind.acidic) =>
          'Verwenden Sie ein saures, lockeres Substrat mit etwa 25 % Pinienrinde. Kalkhaltige Mischungen sind ungeeignet.',
        ('de', SoilKind.rich) =>
          'Verwenden Sie eine nährstoffreiche, aber lockere Mischung: etwa 40 % Blumenerde, 40 % Kompost und 20 % Perlit.',
        ('de', SoilKind.none) =>
          'Blumenerde ist nicht nötig. Die Wurzeln können im Wasser oder auf einem geeigneten erdlosen Träger wachsen.',
        ('it', SoilKind.standard) =>
          'Usa un terriccio universale arioso con circa il 20 % di perlite. Il composto deve restare leggero e far defluire bene l’acqua in eccesso.',
        ('it', SoilKind.draining) =>
          'Mescola circa 50 % di terriccio, 25 % di perlite e 25 % di sabbia grossolana o lapillo. L’acqua deve defluire rapidamente.',
        ('it', SoilKind.cactus) =>
          'Preferisci un composto molto minerale: circa 30 % di terriccio e 70 % di pomice, lapillo o sabbia grossolana.',
        ('it', SoilKind.orchid) =>
          'Usa soprattutto corteccia di pino, con un po’ di perlite e sfagno. Evita il terriccio classico, che trattiene troppa acqua attorno alle radici.',
        ('it', SoilKind.acidic) =>
          'Usa un substrato acido e arioso, con circa il 25 % di corteccia di pino. Evita i composti calcarei.',
        ('it', SoilKind.rich) =>
          'Usa un composto ricco ma arioso: circa 40 % di terriccio, 40 % di compost e 20 % di perlite.',
        ('it', SoilKind.none) =>
          'Non serve terriccio. Le radici possono vivere in acqua o su un supporto adatto alla coltivazione fuori suolo.',
        (_, SoilKind.standard) =>
          'Use an airy all-purpose potting mix with about 20% perlite. It should stay light and let excess water drain freely.',
        (_, SoilKind.draining) =>
          'Mix about 50% potting mix, 25% perlite and 25% coarse sand or lava rock. Water should drain quickly.',
        (_, SoilKind.cactus) =>
          'Use a very mineral mix: about 30% potting mix and 70% pumice, lava rock or coarse sand.',
        (_, SoilKind.orchid) =>
          'Use mostly medium pine bark with a little perlite and sphagnum. Avoid regular potting soil, which holds too much water around the roots.',
        (_, SoilKind.acidic) =>
          'Use an acidic, airy mix with about 25% pine bark. Avoid lime-rich mixes.',
        (_, SoilKind.rich) =>
          'Use a rich but airy mix: about 40% potting mix, 40% compost and 20% perlite.',
        (_, SoilKind.none) =>
          'No potting soil is needed. The roots can grow in water or on a suitable soilless support.',
      };

  String? guideSoilFreeLine(CareProfile profile) {
    if (profile.inWater == SoilFreeFit.no && profile.inPon == SoilFreeFit.no) return null;
    final water = _soilFreeFit(profile.inWater);
    final pon = _soilFreeFit(profile.inPon);
    return switch (_careLanguage) {
      'fr' => 'Culture dans l’eau : $water. Culture en pon : $pon.',
      'de' => 'Wasserkultur: $water. PON: $pon.',
      'it' => 'Coltivazione in acqua: $water. PON: $pon.',
      _ => 'Water culture: $water. PON: $pon.',
    };
  }

  String _soilFreeFit(SoilFreeFit fit) => switch ((_careLanguage, fit)) {
        ('fr', SoilFreeFit.yes) => 'possible',
        ('fr', SoilFreeFit.no) => 'déconseillée',
        ('fr', SoilFreeFit.cuttings) => 'possible uniquement pour les boutures',
        ('de', SoilFreeFit.yes) => 'geeignet',
        ('de', SoilFreeFit.no) => 'nicht empfohlen',
        ('de', SoilFreeFit.cuttings) => 'nur für Stecklinge geeignet',
        ('it', SoilFreeFit.yes) => 'possibile',
        ('it', SoilFreeFit.no) => 'sconsigliata',
        ('it', SoilFreeFit.cuttings) => 'possibile solo per le talee',
        (_, SoilFreeFit.yes) => 'suitable',
        (_, SoilFreeFit.no) => 'not recommended',
        (_, SoilFreeFit.cuttings) => 'suitable for cuttings only',
      };

  String guideFertilizerKind(FertilizerKind kind) => switch ((_careLanguage, kind)) {
        ('fr', FertilizerKind.balanced) => 'Utilisez un engrais équilibré pour plantes vertes, dilué de moitié.',
        ('fr', FertilizerKind.foliage) => 'Utilisez un engrais riche en azote pour favoriser le feuillage.',
        ('fr', FertilizerKind.flowering) => 'Utilisez un engrais riche en potasse pour soutenir la floraison.',
        ('fr', FertilizerKind.cactus) => 'Utilisez un engrais pour cactus et succulentes, pauvre en azote.',
        ('fr', FertilizerKind.orchid) => 'Utilisez un engrais pour orchidées, très dilué.',
        ('fr', FertilizerKind.acidic) => 'Utilisez un engrais pour plantes de terre de bruyère, sans calcaire.',
        ('fr', FertilizerKind.citrus) => 'Utilisez un engrais pour agrumes, riche en azote et en oligo-éléments.',
        ('fr', FertilizerKind.vegetable) => 'Utilisez un engrais pour tomates ou légumes-fruits, riche en potasse.',
        ('de', FertilizerKind.balanced) => 'Verwenden Sie einen ausgewogenen Grünpflanzendünger in halber Dosierung.',
        ('de', FertilizerKind.foliage) => 'Verwenden Sie einen stickstoffreichen Dünger, um das Blattwachstum zu fördern.',
        ('de', FertilizerKind.flowering) => 'Verwenden Sie einen kaliumreichen Dünger, um die Blüte zu unterstützen.',
        ('de', FertilizerKind.cactus) => 'Verwenden Sie einen stickstoffarmen Kakteen- und Sukkulentendünger.',
        ('de', FertilizerKind.orchid) => 'Verwenden Sie stark verdünnten Orchideendünger.',
        ('de', FertilizerKind.acidic) => 'Verwenden Sie kalkfreien Dünger für Moorbeetpflanzen.',
        ('de', FertilizerKind.citrus) => 'Verwenden Sie Zitrusdünger mit viel Stickstoff und Spurenelementen.',
        ('de', FertilizerKind.vegetable) => 'Verwenden Sie kaliumreichen Tomaten- oder Gemüsedünger.',
        ('it', FertilizerKind.balanced) => 'Usa un concime equilibrato per piante verdi, diluito a metà dose.',
        ('it', FertilizerKind.foliage) => 'Usa un concime ricco di azoto per favorire il fogliame.',
        ('it', FertilizerKind.flowering) => 'Usa un concime ricco di potassio per sostenere la fioritura.',
        ('it', FertilizerKind.cactus) => 'Usa un concime per cactus e succulente, povero di azoto.',
        ('it', FertilizerKind.orchid) => 'Usa un concime per orchidee molto diluito.',
        ('it', FertilizerKind.acidic) => 'Usa un concime per acidofile, senza calcare.',
        ('it', FertilizerKind.citrus) => 'Usa un concime per agrumi ricco di azoto e microelementi.',
        ('it', FertilizerKind.vegetable) => 'Usa un concime per pomodori o ortaggi da frutto, ricco di potassio.',
        (_, FertilizerKind.balanced) => 'Use a balanced houseplant fertilizer at half strength.',
        (_, FertilizerKind.foliage) => 'Use a nitrogen-rich fertilizer to support foliage growth.',
        (_, FertilizerKind.flowering) => 'Use a potassium-rich fertilizer to support flowering.',
        (_, FertilizerKind.cactus) => 'Use a low-nitrogen cactus and succulent fertilizer.',
        (_, FertilizerKind.orchid) => 'Use a very diluted orchid fertilizer.',
        (_, FertilizerKind.acidic) => 'Use a lime-free fertilizer for acid-loving plants.',
        (_, FertilizerKind.citrus) => 'Use a citrus fertilizer rich in nitrogen and trace elements.',
        (_, FertilizerKind.vegetable) => 'Use a potassium-rich tomato or fruiting-vegetable fertilizer.',
      };

  String? guideCalciumNote(CalciumNeed need) => switch ((_careLanguage, need)) {
        (_, CalciumNeed.neutral) => null,
        ('fr', CalciumNeed.avoid) =>
          'Évitez les apports de calcium et, si possible, utilisez de l’eau de pluie : le calcaire peut faire jaunir le feuillage.',
        ('fr', CalciumNeed.welcome) =>
          'Elle tolère bien le calcium. L’eau calcaire convient généralement ; des coquilles d’œufs broyées peuvent aussi être ajoutées au rempotage.',
        ('fr', CalciumNeed.needed) =>
          'Un apport régulier en calcium aide à prévenir la nécrose apicale des fruits.',
        ('de', CalciumNeed.avoid) =>
          'Vermeiden Sie zusätzliche Calciumgaben und verwenden Sie möglichst Regenwasser: Kalk kann die Blätter vergilben lassen.',
        ('de', CalciumNeed.welcome) =>
          'Calcium wird gut vertragen. Kalkhaltiges Leitungswasser ist meist geeignet; beim Umtopfen können auch fein zerstoßene Eierschalen beigemischt werden.',
        ('de', CalciumNeed.needed) =>
          'Eine regelmäßige Calciumversorgung hilft, Blütenendfäule an den Früchten zu verhindern.',
        ('it', CalciumNeed.avoid) =>
          'Evita apporti di calcio e, se possibile, usa acqua piovana: il calcare può far ingiallire le foglie.',
        ('it', CalciumNeed.welcome) =>
          'Tollera bene il calcio. In genere va bene anche l’acqua calcarea; al rinvaso si possono aggiungere gusci d’uovo finemente tritati.',
        ('it', CalciumNeed.needed) =>
          'Un apporto regolare di calcio aiuta a prevenire il marciume apicale dei frutti.',
        (_, CalciumNeed.avoid) =>
          'Avoid extra calcium and use rainwater when possible: hard water can make the foliage turn yellow.',
        (_, CalciumNeed.welcome) =>
          'It tolerates calcium well. Hard tap water is usually suitable; finely crushed eggshells can also be added when repotting.',
        (_, CalciumNeed.needed) =>
          'A regular calcium supply helps prevent blossom-end rot on fruit.',
      };

  String guideGreenhouseTitle(HumidityNeed humidity) => switch ((_careLanguage, humidity)) {
        ('fr', HumidityNeed.low) => 'Serre chaude, lumineuse et bien aérée',
        ('fr', HumidityNeed.average) => 'Serre chaude et lumineuse',
        ('fr', HumidityNeed.high) => 'Serre chaude et humide',
        ('de', HumidityNeed.low) => 'Warmes, helles und gut belüftetes Gewächshaus',
        ('de', HumidityNeed.average) => 'Warmes und helles Gewächshaus',
        ('de', HumidityNeed.high) => 'Warmes und feuchtes Gewächshaus',
        ('it', HumidityNeed.low) => 'Serra calda, luminosa e ben ventilata',
        ('it', HumidityNeed.average) => 'Serra calda e luminosa',
        ('it', HumidityNeed.high) => 'Serra calda e umida',
        (_, HumidityNeed.low) => 'Warm, bright and well-ventilated greenhouse',
        (_, HumidityNeed.average) => 'Warm, bright greenhouse',
        (_, HumidityNeed.high) => 'Warm, humid greenhouse',
      };

  String get guideGreenhouseGrowth => switch (_careLanguage) {
        'fr' =>
          'Une serre maintient des conditions plus stables et peut prolonger la période de croissance. Si la plante continue à pousser, elle peut avoir besoin d’arrosages et d’engrais plus fréquents.',
        'de' =>
          'Ein Gewächshaus hält die Bedingungen stabiler und kann die Wachstumszeit verlängern. Wächst die Pflanze weiter aktiv, braucht sie eventuell häufiger Wasser und Dünger.',
        'it' =>
          'Una serra mantiene condizioni più stabili e può prolungare il periodo di crescita. Se la pianta continua a crescere, può richiedere annaffiature e concimazioni più frequenti.',
        _ =>
          'A greenhouse keeps conditions more stable and can extend the growing season. If the plant keeps actively growing, it may need more frequent watering and feeding.',
      };

  String get guideGreenhouseAir => switch (_careLanguage) {
        'fr' => 'Aérez régulièrement la serre pour éviter l’air stagnant et l’excès d’humidité.',
        'de' => 'Lüften Sie das Gewächshaus regelmäßig, damit die Luft nicht steht und die Feuchtigkeit nicht zu hoch wird.',
        'it' => 'Arieggia regolarmente la serra per evitare aria stagnante e umidità eccessiva.',
        _ => 'Ventilate the greenhouse regularly to avoid stagnant air and excess humidity.',
      };

  String get guideGreenhouseEarly => switch (_careLanguage) {
        'fr' =>
          'Une mini-serre ou un châssis conserve mieux la chaleur et l’humidité et permet de démarrer les semis plus tôt.',
        'de' =>
          'Ein Zimmergewächshaus oder Frühbeet hält Wärme und Feuchtigkeit besser und ermöglicht eine frühere Aussaat.',
        'it' =>
          'Una mini-serra o un cassone protetto trattiene meglio calore e umidità e permette di iniziare le semine prima.',
        _ => 'A mini greenhouse or cold frame holds heat and humidity better and lets you start seedlings earlier.',
      };
}
