/// Le soutien facultatif au développeur.
///
/// L'application est entière et gratuite : cet achat ne déverrouille rien,
/// n'ouvre aucune fonction et ne retire aucune limite — il n'y en a pas. Il
/// n'existe que pour qui souhaite remercier.
library;

/// Ce que le magasin propose : un identifiant et un prix déjà mis en forme
/// dans la monnaie de l'utilisateur (« CHF 5.00 »).
class SupportOffer {
  const SupportOffer({required this.id, required this.price});

  final String id;
  final String price;
}

/// Issue d'un achat, du point de vue de l'écran qui l'a lancé.
enum SupportResult {
  /// Le soutien vient d'être versé.
  thanks,

  /// Il l'avait déjà été : le magasin ne facture pas deux fois.
  alreadyGiven,

  /// L'utilisateur a renoncé.
  cancelled,

  /// Le magasin ne propose pas cet achat ici.
  unavailable,

  /// Le magasin a refusé ou a échoué.
  failed,
}

abstract class SupportService {
  /// L'offre, ou `null` si l'achat n'est pas proposé sur cet appareil.
  Future<SupportOffer?> offer();

  /// Lance l'achat et attend son issue.
  Future<SupportResult> give();

  /// Retrouve un soutien déjà versé : nouvel appareil, réinstallation.
  Future<bool> restore();

  /// Libère l'écoute du magasin.
  void dispose();
}

/// Là où il n'y a pas de magasin — le web, le bureau, les tests — on n'affiche
/// pas de bouton mort : l'offre est absente, et l'écran le dit.
class NoStoreSupport implements SupportService {
  const NoStoreSupport();

  @override
  Future<SupportOffer?> offer() async => null;

  @override
  Future<SupportResult> give() async => SupportResult.unavailable;

  @override
  Future<bool> restore() async => false;

  @override
  void dispose() {}
}
