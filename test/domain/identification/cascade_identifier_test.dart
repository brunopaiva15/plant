import 'dart:io';

import 'package:flora/domain/identification/cascade_identifier.dart';
import 'package:flora/domain/identification/identification_metrics.dart';
import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/local_plant_model.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate c(String name, double score) => IdentificationCandidate(scientificName: name, score: score);

class FakeLocal implements LocalPlantModel {
  FakeLocal(this.result, {this.available = true, this.error, this.delay = Duration.zero});

  List<IdentificationCandidate> result;
  bool available;
  Object? error;
  Duration delay;
  int calls = 0;

  @override
  bool get isAvailable => available;
  @override
  String? get version => available ? 'test-1' : null;

  @override
  int get speciesCount => available ? 3 : 0;

  @override
  String? get loadError => null;

  @override
  void dispose() {}

  int warmUps = 0;
  bool loadFails = false;

  @override
  Future<bool> warmUp() async {
    warmUps++;
    return available && !loadFails;
  }

  @override
  Future<List<IdentificationCandidate>> classify(File image) async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return result;
  }
}

class FakeRemote implements PlantIdentifier {
  FakeRemote(this.result, {this.configured = true, this.error});

  List<IdentificationCandidate> result;
  bool configured;
  Object? error;
  int calls = 0;
  String? lastLanguage;

  @override
  bool get isConfigured => configured;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images, {String? language}) async {
    calls++;
    lastLanguage = language;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  late Directory dir;
  late File photo;
  late File other;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('flora-cascade');
    photo = File('${dir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
    other = File('${dir.path}/b.jpg')..writeAsBytesSync([4, 5, 6, 7]);
  });

  tearDown(() => dir.delete(recursive: true));

  final sure = [c('Monstera deliciosa Liebm.', 0.96), c('Monstera adansonii', 0.02)];
  final plausible = [c('Monstera deliciosa', 0.40), c('Monstera adansonii', 0.30)];
  final hesitant = [c('Monstera deliciosa', 0.15), c('Monstera adansonii', 0.12)];
  final remoteAnswer = [c('Monstera adansonii', 0.88), c('Monstera deliciosa', 0.10)];

  CascadeIdentifier build(FakeLocal local, FakeRemote remote, {InMemoryMetricsStore? store, bool fallbackEnabled = true, int limit = 200, DateTime Function()? now, CatalogLookup? lookup}) =>
      CascadeIdentifier(
        local: local,
        fallback: remote,
        metrics: store ?? InMemoryMetricsStore(),
        fallbackEnabled: fallbackEnabled,
        monthlyRemoteLimit: limit,
        now: now,
        lookup: lookup ??
            (name, language) => name.startsWith('Monstera deliciosa')
                ? CatalogMatch(internalId: 'monstera-deliciosa', commonName: language == 'fr' ? 'Monstera' : 'Swiss cheese plant')
                : null,
        localTimeout: const Duration(milliseconds: 200),
      );

  test('confident local answer never calls the remote service', () async {
    final local = FakeLocal(sure);
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(local, remote);
    final result = await cascade.identify([photo], language: 'fr');
    expect(remote.calls, 0);
    expect(result.first.scientificName, 'Monstera deliciosa'); // auteur retiré
    expect(result.first.source, IdentificationSource.local);
    expect(result.first.internalId, 'monstera-deliciosa');
    expect(result[1].internalId, isNull);
    final m = cascade.metrics;
    expect(m.total, 1);
    expect(m.local, 1);
    expect(m.localAccepted, 1);
    expect(m.remote, 0);
    expect(m.remoteCallsSaved, 1);
    expect(m.averageConfidence, closeTo(0.96, 1e-9));
  });

  test('a plausible local list is shown without paying for a remote call', () async {
    // C'est tout l'objet du changement : le modèle n'est pas sûr, mais sa
    // liste vaut d'être montrée, et l'appel distant attend qu'on le demande.
    final local = FakeLocal(plausible);
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(local, remote);
    final result = await cascade.identify([photo]);
    expect(remote.calls, 0, reason: 'aucun appel distant sur une liste plausible');
    expect(result.first.scientificName, 'Monstera deliciosa');
    expect(result.first.source, IdentificationSource.local);
    expect(cascade.metrics.localAccepted, 1);
  });

  test('the online search asked for explicitly does call the service', () async {
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(FakeLocal(plausible), remote);
    await cascade.identify([photo]);
    expect(remote.calls, 0);
    final online = await cascade.identifyRemotely([photo], language: 'fr');
    expect(remote.calls, 1);
    expect(remote.lastLanguage, 'fr');
    expect(online.first.source, IdentificationSource.remote);
    expect(cascade.metrics.remote, 1);
  });

  test('the explicit online search respects the daily quota', () async {
    var day = DateTime(2026, 9, 5, 10);
    final remote = FakeRemote(remoteAnswer);
    final store = InMemoryMetricsStore();
    final cascade = build(FakeLocal(plausible), remote, store: store, limit: 1, now: () => day);
    expect((await cascade.identifyRemotely([photo])).length, 2);
    expect((await cascade.identifyRemotely([other])), isEmpty, reason: 'quota atteint');
    expect(remote.calls, 1);
    expect(store.read().quotaRefusals, 1);
  });

  test('the explicit online search does nothing when the fallback is off', () async {
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(FakeLocal(plausible), remote, fallbackEnabled: false);
    expect(await cascade.identifyRemotely([photo]), isEmpty);
    expect(remote.calls, 0);
  });

  test('a local candidate gets its common name from the catalogue, in the user\'s language', () async {
    // Le modèle ne connaît que les noms scientifiques ; « Monstera
    // deliciosa » ne parle pas à tout le monde, « Monstera » si.
    final cascade = build(FakeLocal(sure), FakeRemote(remoteAnswer));
    final fr = await cascade.identify([photo], language: 'fr');
    expect(fr.first.commonName, 'Monstera');
    final en = await cascade.identify([other], language: 'en');
    expect(en.first.commonName, 'Swiss cheese plant');
    expect(fr[1].commonName, isNull, reason: 'hors catalogue : pas de nom inventé');
  });

  test('a remote candidate keeps the common name the service gave', () async {
    final remote = FakeRemote([IdentificationCandidate(scientificName: 'Monstera deliciosa', score: 0.9, commonName: 'Faux philodendron')]);
    final cascade = build(FakeLocal(const [], available: false), remote);
    final result = await cascade.identify([photo], language: 'fr');
    expect(result.first.commonName, 'Faux philodendron');
  });

  test('the local model is loaded by the cascade itself before deciding', () async {
    // Le bug d'origine : le modèle n'était consulté que si autre chose
    // l'avait chargé avant — ouvrir les réglages, par exemple. Sinon la
    // photo partait en ligne sans qu'il l'ait vue.
    final local = FakeLocal(sure);
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(local, remote);
    await cascade.identify([photo]);
    expect(local.warmUps, 1, reason: 'chargé par la cascade');
    expect(local.calls, 1, reason: 'puis consulté');
    expect(remote.calls, 0);
    expect(cascade.metrics.local, 1);
  });

  test('a model whose loading fails is skipped, not counted as run', () async {
    final local = FakeLocal(sure, )..loadFails = true;
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(local, remote);
    final result = await cascade.identify([photo]);
    expect(local.calls, 0);
    expect(remote.calls, 1);
    expect(result.first.source, IdentificationSource.remote);
    expect(cascade.metrics.local, 0);
    expect(cascade.metrics.fallbacks, 0, reason: 'un appel direct n\'est pas un repli');
  });

  test('hesitant local answer falls back to the remote service', () async {
    final local = FakeLocal(hesitant);
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(local, remote);
    final result = await cascade.identify([photo], language: 'de');
    expect(remote.calls, 1);
    expect(remote.lastLanguage, 'de');
    expect(result.first.scientificName, 'Monstera adansonii');
    expect(result.first.source, IdentificationSource.remote);
    final m = cascade.metrics;
    expect(m.fallbacks, 1);
    expect(m.remote, 1);
    expect(m.localAccepted, 0);
    expect(m.fallbackRate, 1.0);
  });

  test('without a local model the remote service is used directly', () async {
    final local = FakeLocal(const [], available: false);
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(local, remote);
    expect(cascade.isConfigured, isTrue);
    await cascade.identify([photo]);
    expect(local.calls, 0);
    expect(remote.calls, 1);
    expect(cascade.metrics.fallbacks, 0, reason: 'un appel direct n\'est pas un repli');
    expect(cascade.metrics.remote, 1);
  });

  test('nothing configured means nothing to do', () {
    final cascade = build(FakeLocal(const [], available: false), FakeRemote(const [], configured: false));
    expect(cascade.isConfigured, isFalse);
  });

  test('fallback disabled: the hesitant local answer is returned as is', () async {
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(FakeLocal(hesitant), remote, fallbackEnabled: false);
    final result = await cascade.identify([photo]);
    expect(remote.calls, 0);
    expect(result.map((r) => r.scientificName), ['Monstera deliciosa', 'Monstera adansonii']);
    expect(result.first.source, IdentificationSource.local);
  });

  test('fallback disabled and no local model: not configured', () {
    expect(build(FakeLocal(const [], available: false), FakeRemote(remoteAnswer), fallbackEnabled: false).isConfigured, isFalse);
  });

  test('local failure or timeout is absorbed and the remote service answers', () async {
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(FakeLocal(sure, error: StateError('boom')), remote);
    expect((await cascade.identify([photo])).first.scientificName, 'Monstera adansonii');
    expect(cascade.metrics.errors, 1);

    final slow = build(FakeLocal(sure, delay: const Duration(seconds: 1)), FakeRemote(remoteAnswer));
    expect((await slow.identify([photo])).first.source, IdentificationSource.remote);
    expect(slow.metrics.errors, 1);
  });

  test('remote failure after a hesitant local answer returns the local list', () async {
    final cascade = build(FakeLocal(hesitant), FakeRemote(remoteAnswer, error: const IdentificationException('http 500')));
    final result = await cascade.identify([photo]);
    expect(result.first.scientificName, 'Monstera deliciosa');
    expect(cascade.metrics.errors, 1);
  });

  test('remote failure without any local answer is rethrown', () async {
    final cascade = build(FakeLocal(const [], available: false), FakeRemote(remoteAnswer, error: const IdentificationException('http 500')));
    await expectLater(cascade.identify([photo]), throwsA(isA<IdentificationException>()));
    expect(cascade.metrics.errors, 1);
  });

  test('same photo is answered from the cache', () async {
    final remote = FakeRemote(remoteAnswer);
    final cascade = build(FakeLocal(const [], available: false), remote);
    await cascade.identify([photo]);
    await cascade.identify([photo]);
    await cascade.identify([other]);
    expect(remote.calls, 2);
    expect(cascade.metrics.cacheHits, 1);
    expect(cascade.metrics.total, 2);
  });

  test('monthly remote quota is enforced and resets the next month', () async {
    var day = DateTime(2026, 9, 5, 10);
    final remote = FakeRemote(remoteAnswer);
    final store = InMemoryMetricsStore();
    final cascade = build(FakeLocal(hesitant), remote, store: store, limit: 2, now: () => day);
    await cascade.identify([photo]);
    await cascade.identify([other]);
    expect(remote.calls, 2);
    expect(cascade.remoteUsedThisMonth, 2);
    expect(cascade.remoteAllowedThisMonth, isFalse);
    final third = File('${dir.path}/c.jpg')..writeAsBytesSync([9]);
    final result = await cascade.identify([third]);
    expect(remote.calls, 2, reason: 'quota atteint : pas d\'appel');
    expect(result.first.source, IdentificationSource.local, reason: 'la réponse locale, même incertaine, est rendue');
    expect(store.read().quotaRefusals, 1);

    // Le lendemain, toujours le même mois : rien ne se rouvre.
    day = DateTime(2026, 9, 6, 8);
    expect(cascade.remoteAllowedThisMonth, isFalse);

    day = DateTime(2026, 10, 1, 8);
    expect(cascade.remoteAllowedThisMonth, isTrue);
    final fourth = File('${dir.path}/d.jpg')..writeAsBytesSync([10]);
    await cascade.identify([fourth]);
    expect(remote.calls, 3);
    expect(store.read().remotePeriod, '2026-10');
    expect(store.read().remoteInPeriod, 1);
  });

  test('several photos are merged by species before the verdict', () async {
    final local = FakeLocal(sure);
    final cascade = build(local, FakeRemote(remoteAnswer));
    final result = await cascade.identify([photo, other]);
    expect(local.calls, 2);
    expect(result.first.score, closeTo(0.96, 1e-9));
    expect(result.length, 2);
  });

  test('metrics survive a JSON round trip', () {
    const m = IdentificationMetrics(total: 5, local: 4, localAccepted: 3, remote: 2, fallbacks: 1, cacheHits: 7, errors: 1, quotaRefusals: 0, confidenceSum: 4.2, remotePeriod: '2026-09-05', remoteInPeriod: 2);
    final back = IdentificationMetrics.decode(m.encode());
    expect(back.toJson(), m.toJson());
    expect(IdentificationMetrics.decode(null).total, 0);
    expect(IdentificationMetrics.decode('{not json').total, 0);
    expect(m.localSuccessRate, 0.75);
    expect(m.averageConfidence, closeTo(0.84, 1e-9));
  });

  test('policy is consulted with the merged list', () {
    const policy = FallbackPolicy();
    expect(policy.decide(sure), IdentificationVerdict.accepted);
    expect(policy.decide(hesitant), IdentificationVerdict.uncertain);
  });
}
