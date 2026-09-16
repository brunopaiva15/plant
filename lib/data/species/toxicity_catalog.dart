import '../../core/utils/scientific_name.dart';
import '../../domain/care/toxicity.dart';

/// Fiches de toxicité, séparées des profils d'entretien.
///
/// Une espèce dangereuse — *Atropa bella-donna*, *Datura stramonium* — n'a
/// pas besoin d'un arrosage, d'une lumière et d'un substrat inventés pour
/// déclarer son fait : ici, un seul champ. C'est l'inverse du coût d'entrée
/// des profils, où la donnée la plus sensible était la plus chère à écrire.
///
/// La cascade est la même que celle des fiches — espèce, genre, famille —,
/// mais la règle est asymétrique : au-dessus du genre, `toxic` et `mild` se
/// transmettent, `safe` non. Une famille peut dire « toxique » ou « irritant »
/// et se tromper du côté de la prudence ; elle ne peut pas promettre l'innocuité
/// de toutes ses espèces. [resolve] le garantit même si la donnée le disait.
abstract final class ToxicityCatalog {
  /// Toxicité par espèce, quand le genre ne suffit pas.
  static const bySpecies = <String, Toxicity>{
    'Monstera deliciosa': Toxicity.toxic,
    'Dracaena trifasciata': Toxicity.mild,
    'Zamioculcas zamiifolia': Toxicity.toxic,
    'Spathiphyllum wallisii': Toxicity.toxic,
    'Pilea peperomioides': Toxicity.safe,
    'Ficus lyrata': Toxicity.mild,
    'Phalaenopsis amabilis': Toxicity.safe,
    'Aloe vera': Toxicity.toxic,
    'Ocimum basilicum': Toxicity.safe,
    'Solanum lycopersicum': Toxicity.mild,
    'Citrus × limon': Toxicity.toxic,
    'Olea europaea': Toxicity.safe,
    'Lavandula angustifolia': Toxicity.safe,
  };

  /// Toxicité par genre. C'est ici qu'on écrit enfin les genres dangereux que
  /// le catalogue ne pouvait pas nommer, faute de leur inventer un entretien.
  static const byGenus = <String, Toxicity>{
    // Aracées et compagnie du feuillage d'intérieur.
    'Philodendron': Toxicity.toxic,
    'Epipremnum': Toxicity.toxic,
    'Scindapsus': Toxicity.toxic,
    'Monstera': Toxicity.toxic,
    'Alocasia': Toxicity.toxic,
    'Anthurium': Toxicity.toxic,
    'Aglaonema': Toxicity.toxic,
    'Dieffenbachia': Toxicity.toxic,
    'Syngonium': Toxicity.toxic,
    'Zamioculcas': Toxicity.toxic,
    'Spathiphyllum': Toxicity.toxic,
    'Calathea': Toxicity.safe,
    'Goeppertia': Toxicity.safe,
    'Maranta': Toxicity.safe,
    // Ficus et feuillages d'intérieur.
    'Ficus': Toxicity.mild,
    'Dracaena': Toxicity.mild,
    'Sansevieria': Toxicity.mild,
    'Yucca': Toxicity.mild,
    'Beaucarnea': Toxicity.safe,
    'Aspidistra': Toxicity.safe,
    'Chlorophytum': Toxicity.safe,
    // Palmiers et fougères.
    'Chamaedorea': Toxicity.safe,
    'Dypsis': Toxicity.safe,
    'Howea': Toxicity.safe,
    'Trachycarpus': Toxicity.safe,
    'Nephrolepis': Toxicity.safe,
    'Asplenium': Toxicity.safe,
    'Adiantum': Toxicity.safe,
    'Platycerium': Toxicity.safe,
    // Succulentes.
    'Echeveria': Toxicity.safe,
    'Crassula': Toxicity.mild,
    'Sedum': Toxicity.safe,
    'Haworthiopsis': Toxicity.safe,
    'Kalanchoe': Toxicity.toxic,
    'Sempervivum': Toxicity.safe,
    'Curio': Toxicity.mild,
    'Gasteria': Toxicity.safe,
    'Agave': Toxicity.mild,
    'Aeonium': Toxicity.safe,
    'Lithops': Toxicity.safe,
    'Schlumbergera': Toxicity.safe,
    'Rhipsalis': Toxicity.safe,
    // Aromatiques et potager.
    'Mentha': Toxicity.safe,
    'Thymus': Toxicity.safe,
    'Salvia': Toxicity.safe,
    'Petroselinum': Toxicity.safe,
    'Ocimum': Toxicity.safe,
    'Solanum': Toxicity.mild,
    'Capsicum': Toxicity.safe,
    'Cucurbita': Toxicity.safe,
    'Cucumis': Toxicity.safe,
    'Fragaria': Toxicity.safe,
    'Lactuca': Toxicity.safe,
    // Fruitiers : le feuillage et les pépins, surtout.
    'Citrus': Toxicity.toxic,
    'Prunus': Toxicity.mild,
    'Malus': Toxicity.toxic,
    'Vitis': Toxicity.toxic,
    'Rubus': Toxicity.safe,
    'Vaccinium': Toxicity.safe,
    // Floraison et jardin.
    'Rosa': Toxicity.safe,
    'Hydrangea': Toxicity.mild,
    'Pelargonium': Toxicity.mild,
    'Hosta': Toxicity.mild,
    'Acer': Toxicity.safe,
    'Buxus': Toxicity.toxic,
    'Hedera': Toxicity.toxic,
    'Hoya': Toxicity.safe,
    'Peperomia': Toxicity.safe,
    'Begonia': Toxicity.mild,
    'Tradescantia': Toxicity.mild,
    'Fittonia': Toxicity.safe,
    'Saintpaulia': Toxicity.safe,
    'Dahlia': Toxicity.mild,
    'Canna': Toxicity.safe,
    'Tillandsia': Toxicity.safe,
    'Strelitzia': Toxicity.mild,
    'Musa': Toxicity.safe,
    'Coffea': Toxicity.toxic,
    'Nerium': Toxicity.toxic,
    'Camellia': Toxicity.safe,
    'Rhododendron': Toxicity.toxic,
    'Gardenia': Toxicity.mild,
    'Bougainvillea': Toxicity.mild,
    'Phyllostachys': Toxicity.safe,
    'Fargesia': Toxicity.safe,
    // Plantes à réserves.
    'Cyclamen': Toxicity.toxic,
    'Crocus': Toxicity.mild,
    'Tulipa': Toxicity.mild,
    'Narcissus': Toxicity.toxic,
    'Hyacinthus': Toxicity.mild,
    'Hippeastrum': Toxicity.toxic,
    'Caladium': Toxicity.toxic,
    'Colocasia': Toxicity.toxic,
    'Zantedeschia': Toxicity.toxic,
    // Genres dangereux que les fiches d'entretien ne couvraient pas.
    'Abrus': Toxicity.toxic,
    'Aconitum': Toxicity.toxic,
    'Aloe': Toxicity.toxic,
    'Atropa': Toxicity.toxic,
    'Colchicum': Toxicity.toxic,
    'Conium': Toxicity.toxic,
    'Datura': Toxicity.toxic,
    'Digitalis': Toxicity.toxic,
    'Heracleum': Toxicity.toxic,
    'Hyoscyamus': Toxicity.toxic,
    'Jacobaea': Toxicity.toxic,
    'Laburnum': Toxicity.toxic,
    'Ligustrum': Toxicity.toxic,
    'Lobelia': Toxicity.toxic,
    'Oenanthe': Toxicity.toxic,
    'Ricinus': Toxicity.toxic,
    'Robinia': Toxicity.toxic,
    'Senecio': Toxicity.toxic,
    'Spartium': Toxicity.toxic,
    'Cytisus': Toxicity.toxic,
    'Lupinus': Toxicity.toxic,
    'Taxus': Toxicity.toxic,
    'Wisteria': Toxicity.toxic,
  };

  /// Toxicité par famille, quand ni l'espèce ni le genre ne disent rien.
  ///
  /// Aucune entrée `safe` : la famille donne un repère de prudence, jamais une
  /// promesse.
  static const byFamily = <String, Toxicity>{
    'Ranunculaceae': Toxicity.toxic,
    'Primulaceae': Toxicity.mild,
    'Boraginaceae': Toxicity.mild,
    'Plantaginaceae': Toxicity.toxic,
    'Papaveraceae': Toxicity.toxic,
    'Iridaceae': Toxicity.mild,
    'Liliaceae': Toxicity.toxic,
    'Fagaceae': Toxicity.mild,
    'Sapindaceae': Toxicity.mild,
    'Caprifoliaceae': Toxicity.mild,
    'Adoxaceae': Toxicity.mild,
    'Hydrangeaceae': Toxicity.mild,
    'Polygonaceae': Toxicity.mild,
    'Convolvulaceae': Toxicity.toxic,
    'Hypericaceae': Toxicity.mild,
    'Berberidaceae': Toxicity.mild,
    'Aquifoliaceae': Toxicity.toxic,
    'Buxaceae': Toxicity.toxic,
    'Araceae': Toxicity.toxic,
    'Crassulaceae': Toxicity.mild,
    'Asphodelaceae': Toxicity.mild,
    'Asparagaceae': Toxicity.mild,
    'Moraceae': Toxicity.mild,
    'Solanaceae': Toxicity.mild,
    'Ericaceae': Toxicity.mild,
    'Amaryllidaceae': Toxicity.mild,
    'Cupressaceae': Toxicity.mild,
    'Apocynaceae': Toxicity.toxic,
    'Euphorbiaceae': Toxicity.toxic,
    'Geraniaceae': Toxicity.mild,
  };

  /// Références des faits vérifiés, quand elles ont un nom.
  static const _sources = <String, String>{
    'Aloe': 'ASPCA',
    'Aloe vera': 'ASPCA',
    'Citrus': 'ASPCA',
    'Citrus × limon': 'ASPCA',
    'Malus': 'ASPCA',
    'Vitis': 'ASPCA',
    'Dahlia': 'ASPCA',
  };

  /// Le fait de toxicité d'une plante : espèce, puis genre, puis famille.
  ///
  /// [family] affine la recherche quand le genre est inconnu du catalogue, ou
  /// la précise quand il est connu.
  static ToxicityFact resolve(String? scientificName, {String? family}) {
    final name = scientificName == null ? '' : normalizeScientificName(scientificName);
    if (name.isNotEmpty) {
      final species = bySpecies[name];
      if (species != null) return _fact(species, ToxicitySource.species, name);

      final genus = genusOf(name);
      if (genus.isNotEmpty) {
        final byGenusValue = byGenus[genus];
        if (byGenusValue != null) return _fact(byGenusValue, ToxicitySource.genus, genus);
      }
    }

    final fam = _capitalize(family);
    if (fam != null) {
      final byFamilyValue = byFamily[fam];
      // Une famille ne peut pas affirmer l'innocuité : `safe` y serait une
      // promesse qu'aucune espèce dangereuse ne rattrape.
      if (byFamilyValue != null && byFamilyValue != Toxicity.safe) {
        return _fact(byFamilyValue, ToxicitySource.family, fam);
      }
    }

    return const ToxicityFact.unknown();
  }

  static ToxicityFact _fact(Toxicity status, ToxicitySource level, String matchedOn) =>
      ToxicityFact(status: status, level: level, matchedOn: matchedOn, source: _sources[matchedOn]);

  static String? _capitalize(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }
}
