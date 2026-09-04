import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/config/app_config.dart';
import '../../domain/support/support_service.dart';

/// Le magasin, réduit à ce dont le soutien a besoin.
///
/// Cette couche mince sépare la logique du plugin : le service se teste sans
/// magasin, et le jour où l'on change de plugin, seul l'adaptateur bouge.
abstract class PurchaseStore {
  Stream<List<PurchaseDetails>> get purchases;

  Future<bool> isAvailable();
  Future<ProductDetailsResponse> query(Set<String> ids);
  Future<bool> buy(PurchaseParam param);
  Future<void> restore();

  /// À appeler pour chaque achat livré, sinon le magasin le repropose au
  /// prochain lancement.
  Future<void> complete(PurchaseDetails purchase);
}

/// Le magasin de la plateforme : App Store sur iOS, Play sur Android.
class PluginPurchaseStore implements PurchaseStore {
  PluginPurchaseStore([InAppPurchase? store]) : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;

  @override
  Stream<List<PurchaseDetails>> get purchases => _store.purchaseStream;

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<ProductDetailsResponse> query(Set<String> ids) => _store.queryProductDetails(ids);

  @override
  Future<bool> buy(PurchaseParam param) => _store.buyNonConsumable(purchaseParam: param);

  @override
  Future<void> restore() => _store.restorePurchases();

  @override
  Future<void> complete(PurchaseDetails purchase) => _store.completePurchase(purchase);
}

/// Soutien facultatif adossé au magasin de la plateforme.
///
/// L'achat est un produit non consommable : le magasin ne le facture qu'une
/// fois et sait le rendre sur un nouvel appareil. Il ne déverrouille rien —
/// l'application est complète pour tout le monde.
class StoreSupportService implements SupportService {
  StoreSupportService(this._store, {this.productId = AppConfig.supportProductId, this.restoreTimeout = const Duration(seconds: 8)}) {
    // L'écoute commence tout de suite : un achat interrompu au lancement
    // précédent est resservi dès l'abonnement au flux.
    _subscription = _store.purchases.listen(_onPurchases, onError: (_) => _settle(SupportResult.failed));
  }

  final PurchaseStore _store;
  final String productId;

  /// Le magasin répond à une restauration par le flux, ou ne répond pas. Passé
  /// ce délai, on conclut qu'il n'y avait rien à rendre.
  final Duration restoreTimeout;

  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  /// L'achat en cours, s'il y en a un.
  Completer<SupportResult>? _pending;

  /// Un soutien retrouvé, hors de tout achat en cours : c'est la réponse de
  /// [restore], et la trace d'un achat abouti pendant que l'app était fermée.
  final _restored = StreamController<bool>.broadcast();

  SupportOffer? _offer;

  @override
  Future<SupportOffer?> offer() async {
    if (_offer != null) return _offer;
    if (!await _store.isAvailable()) return null;
    final response = await _store.query({productId});
    final product = response.productDetails.where((p) => p.id == productId).firstOrNull;
    if (product == null) return null;
    return _offer = SupportOffer(id: product.id, price: product.price);
  }

  @override
  Future<SupportResult> give() async {
    final product = await _productDetails();
    if (product == null) return SupportResult.unavailable;
    // Un seul achat à la fois : le second attend l'issue du premier.
    final pending = _pending;
    if (pending != null) return pending.future;
    final completer = _pending = Completer<SupportResult>();
    try {
      final sent = await _store.buy(PurchaseParam(productDetails: product));
      if (!sent) _settle(SupportResult.failed);
    } catch (_) {
      _settle(SupportResult.failed);
    }
    return completer.future;
  }

  @override
  Future<bool> restore() async {
    if (!await _store.isAvailable()) return false;
    // Le magasin répond par le flux : on attend un instant sa réponse, et
    // l'absence de réponse vaut « rien à restaurer ».
    final found = _restored.stream.first.timeout(restoreTimeout, onTimeout: () => false);
    try {
      await _store.restore();
    } catch (_) {
      return false;
    }
    return found;
  }

  Future<ProductDetails?> _productDetails() async {
    if (!await _store.isAvailable()) return null;
    final response = await _store.query({productId});
    return response.productDetails.where((p) => p.id == productId).firstOrNull;
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          continue;
        case PurchaseStatus.purchased:
          _settle(SupportResult.thanks);
          _announce(true);
        case PurchaseStatus.restored:
          _settle(SupportResult.alreadyGiven);
          _announce(true);
        case PurchaseStatus.canceled:
          _settle(SupportResult.cancelled);
        case PurchaseStatus.error:
          _settle(SupportResult.failed);
      }
      if (purchase.pendingCompletePurchase) _store.complete(purchase);
    }
  }

  void _settle(SupportResult result) {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  void _announce(bool found) {
    if (!_restored.isClosed) _restored.add(found);
  }

  @override
  void dispose() {
    _subscription.cancel();
    _restored.close();
  }
}
