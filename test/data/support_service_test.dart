import 'dart:async';

import 'package:flora/data/services/store_support_service.dart';
import 'package:flora/domain/support/support_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const _id = 'ch.vergasta.plant.support';

/// Un magasin de comédie : il répond ce qu'on lui dit de répondre, et note ce
/// qu'on lui a demandé.
class FakeStore implements PurchaseStore {
  FakeStore({this.available = true, this.sells = true, this.buyAnswer = true, this.buyThrows = false});

  bool available;
  bool sells;
  bool buyAnswer;
  bool buyThrows;

  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];
  var buys = 0;
  var restores = 0;

  @override
  Stream<List<PurchaseDetails>> get purchases => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> query(Set<String> ids) async => ProductDetailsResponse(
    productDetails: sells
        ? [
            ProductDetails(id: _id, title: 'Soutien', description: 'Merci', price: 'CHF 5.00', rawPrice: 5, currencyCode: 'CHF'),
          ]
        : const [],
    notFoundIDs: sells ? const [] : [_id],
  );

  @override
  Future<bool> buy(PurchaseParam param) async {
    buys++;
    if (buyThrows) throw StateError('magasin fermé');
    return buyAnswer;
  }

  @override
  Future<void> restore() async => restores++;

  @override
  Future<void> complete(PurchaseDetails purchase) async => completed.add(purchase.productID);

  /// Fait parler le magasin, comme il le ferait de lui-même.
  void emit(PurchaseStatus status, {String id = _id, bool pendingComplete = true}) {
    _controller.add([
      PurchaseDetails(
        productID: id,
        verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: 'test'),
        transactionDate: null,
        status: status,
      )..pendingCompletePurchase = pendingComplete,
    ]);
  }

  void close() => _controller.close();
}

void main() {
  late FakeStore store;
  late StoreSupportService service;

  setUp(() {
    store = FakeStore();
    service = StoreSupportService(store, restoreTimeout: const Duration(milliseconds: 60));
  });

  tearDown(() {
    service.dispose();
    store.close();
  });

  group("l'offre", () {
    test('porte le prix du magasin, déjà mis en forme', () async {
      final offer = await service.offer();
      expect(offer?.id, _id);
      expect(offer?.price, 'CHF 5.00');
    });

    test("est absente quand le magasin n'est pas joignable", () async {
      store.available = false;
      expect(await service.offer(), isNull);
    });

    test("est absente quand le produit n'existe pas encore", () async {
      store.sells = false;
      expect(await service.offer(), isNull);
    });
  });

  group("l'achat", () {
    test('remercie quand le magasin confirme', () async {
      final result = service.give();
      await Future<void>.delayed(Duration.zero);
      store.emit(PurchaseStatus.purchased);
      expect(await result, SupportResult.thanks);
    });

    test('reconnaît un soutien déjà versé', () async {
      final result = service.give();
      await Future<void>.delayed(Duration.zero);
      store.emit(PurchaseStatus.restored);
      expect(await result, SupportResult.alreadyGiven);
    });

    test('accepte sans bruit que l on renonce', () async {
      final result = service.give();
      await Future<void>.delayed(Duration.zero);
      store.emit(PurchaseStatus.canceled);
      expect(await result, SupportResult.cancelled);
    });

    test('signale un refus du magasin', () async {
      final result = service.give();
      await Future<void>.delayed(Duration.zero);
      store.emit(PurchaseStatus.error);
      expect(await result, SupportResult.failed);
    });

    test("échoue tout de suite si la demande n'est pas partie", () async {
      store.buyAnswer = false;
      expect(await service.give(), SupportResult.failed);
    });

    test('échoue proprement si le magasin lève', () async {
      store.buyThrows = true;
      expect(await service.give(), SupportResult.failed);
    });

    test("ne propose rien là où le magasin n'existe pas", () async {
      store.available = false;
      expect(await service.give(), SupportResult.unavailable);
      expect(store.buys, 0);
    });

    test("l'attente en cours n'est pas doublée", () async {
      final first = service.give();
      await Future<void>.delayed(Duration.zero);
      final second = service.give();
      await Future<void>.delayed(Duration.zero);
      store.emit(PurchaseStatus.purchased);
      expect(await first, SupportResult.thanks);
      expect(await second, SupportResult.thanks);
      expect(store.buys, 1);
    });

    test("l'achat livré est clos, sinon le magasin le reproposerait", () async {
      final result = service.give();
      await Future<void>.delayed(Duration.zero);
      store.emit(PurchaseStatus.purchased);
      await result;
      await Future<void>.delayed(Duration.zero);
      expect(store.completed, [_id]);
    });

    test("un achat qui n'est pas le nôtre est ignoré", () async {
      final result = service.give();
      await Future<void>.delayed(Duration.zero);
      store.emit(PurchaseStatus.purchased, id: 'autre.chose');
      store.emit(PurchaseStatus.canceled);
      expect(await result, SupportResult.cancelled);
      expect(store.completed, isNot(contains('autre.chose')));
    });
  });

  group('la restauration', () {
    test('retrouve un soutien que le magasin rend', () async {
      final found = service.restore();
      await Future<void>.delayed(Duration.zero);
      store.emit(PurchaseStatus.restored);
      expect(await found, isTrue);
      expect(store.restores, 1);
    });

    test("conclut à rien quand le magasin ne rend rien", () async {
      expect(await service.restore(), isFalse);
    });

    test("ne demande rien là où il n'y a pas de magasin", () async {
      store.available = false;
      expect(await service.restore(), isFalse);
      expect(store.restores, 0);
    });
  });

  test("sans magasin, le service muet ne promet rien", () async {
    const none = NoStoreSupport();
    expect(await none.offer(), isNull);
    expect(await none.give(), SupportResult.unavailable);
    expect(await none.restore(), isFalse);
  });
}
