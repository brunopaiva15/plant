import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/l10n/likelihood_labels.dart';
import '../../../design_system/design_system.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../data/services/jev_identification_policy.dart';
import '../../../domain/identification/cascade_identifier.dart';
import '../../../domain/identification/comparison_model.dart';
import '../../../domain/identification/identification_context.dart';
import '../../../domain/identification/iris_feedback.dart';
import '../../../domain/identification/identification_confidence.dart';
import '../../../domain/identification/identification_policy.dart';
import '../../../domain/identification/plant_identifier.dart';
import '../../../domain/species/species_info.dart';
import '../../species/presentation/species_sheet.dart';
import 'identification_photos.dart';
import 'identification_source_note.dart';
import 'genus_row.dart';
import 'identification_uncertainty.dart';

/// Lance l'identification et laisse l'utilisateur choisir. Retourne le
/// candidat retenu, ou `null`.
///
/// [others] : des photos que l'appelant possède déjà et qui montrent la même
/// plante — la galerie d'une fiche, par exemple. Elles partent avec la
/// première, sans rien demander à personne : deux photos valent 13,7 points
/// de top-1 et trois en valent 22,4 (docs/09 § 6.7), et celles-là sont
/// gratuites, déjà prises, déjà sur l'appareil. La bande les montre, et une
/// croix retire celle qui n'aide pas.
Future<IdentificationCandidate?> showIdentificationSheet(
  BuildContext context, {
  required String absoluteImagePath,
  List<String> others = const [],
  IdentificationContext place = IdentificationContext.unknown,
}) =>
    showFloraSheet<IdentificationCandidate>(
      context,
      scrollable: true,
      builder: (_) => _IdentificationBody(path: absoluteImagePath, others: others, place: place),
    );

class _IdentificationBody extends ConsumerStatefulWidget {
  const _IdentificationBody(
      {required this.path, this.others = const [], this.place = IdentificationContext.unknown});

  final String path;
  final List<String> others;

  /// Le lieu de la plante, quand on le connaît. Il sert deux fois : le modèle
  /// renormalise ses sorties sur les classes du lieu quand il porte un masque
  /// (§ 14.2 de `docs/09`), et, tant qu'il n'en porte pas, il propose au lieu
  /// d'affirmer dehors (`FallbackPolicy.outdoors`).
  final IdentificationContext place;

  @override
  ConsumerState<_IdentificationBody> createState() => _IdentificationBodyState();
}

/// Une photo soumise au moteur, et à qui elle appartient.
///
/// La distinction n'est pas cosmétique : celles **prises dans la feuille** ne
/// sont la photo d'aucune plante et s'effacent en partant ; celles que
/// l'appelant a prêtées — sa photo principale, sa galerie — n'ont rien à se
/// faire effacer.
@immutable
class _Shot {
  const _Shot(this.path, {this.stored});

  /// Chemin absolu, le seul format que le moteur et la bande attendent.
  final String path;

  /// Présent si la feuille l'a prise, donc si elle doit l'effacer.
  final StoredPhoto? stored;
}

class _IdentificationBodyState extends ConsumerState<_IdentificationBody> {
  late Future<List<IdentificationCandidate>> _future;

  /// Ce que voit chaque modèle de comparaison allumé, sur les mêmes photos ;
  /// vide quand aucun ne l'est. Calculé **après** Iris et l'un après l'autre,
  /// jamais en même temps : deux inférences simultanées se partageraient le
  /// processeur et pousseraient Iris au-delà du délai de la cascade, qui
  /// partirait alors en ligne — la comparaison fausserait ce qu'elle mesure.
  Map<ComparisonModel, Future<List<IdentificationCandidate>>> _compare = const {};

  /// La photo d'origine, celles que l'appelant a prêtées, puis celles
  /// ajoutées ici pour lever un doute. Le moteur les fusionne par moyenne
  /// géométrique : l'espèce que toutes les photos voient remonte, celle qui
  /// ne tenait qu'à un cliché ambigu redescend — et une photo ratée pèse,
  /// d'où la croix de la bande.
  late final List<_Shot> _shots = [
    _Shot(widget.path),
    // Au-delà de trois, le gain n'est plus mesuré (§ 6.7) : on prend les
    // premières, c'est-à-dire les plus récentes.
    for (final p in widget.others.take(maxPhotos - 1)) _Shot(p),
  ];

  bool _picking = false;

  /// La dernière réponse complète.
  ///
  /// Une photo de plus relance l'identification, et le `FutureBuilder`
  /// repasserait par son attente : tout le corps de la feuille
  /// disparaîtrait une seconde à chaque fois. La liste précédente reste donc
  /// à l'écran pendant la relance ; seul le tout premier calcul, celui qui
  /// n'a rien à montrer, a droit au tourniquet.
  List<IdentificationCandidate>? _last;

  /// Au-delà, une photo de plus n'apporte plus grand-chose et la recherche
  /// en ligne est le meilleur recours.
  static const int maxPhotos = 2;

  /// Le nombre de candidates montrées sous la photo.
  static const int maxCandidates = 5;

  /// Le magasin de photos, gardé dès l'ouverture : `dispose` efface les
  /// photos prises ici, et `ref` n'est plus lisible à ce moment-là — le
  /// widget est déjà démonté, et Riverpod le refuse.
  late final PhotoStorageService _storage;

  @override
  void initState() {
    super.initState();
    _storage = ref.read(photoStorageProvider);
    _future = _identify();
  }

  @override
  void dispose() {
    // Les photos prises ici ne servaient qu'à identifier : elles ne sont la
    // photo d'aucune plante et n'ont rien à faire sur l'appareil après coup.
    // Celles que l'appelant a prêtées ne bougent pas.
    final storage = _storage;
    for (final shot in _shots) {
      final stored = shot.stored;
      if (stored != null) storage.deleteFiles(stored.filePath, stored.thumbPath);
    }
    super.dispose();
  }

  String get _language =>
      ref.read(preferencesProvider).locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;

  List<String> get _paths => [for (final s in _shots) s.path];

  List<File> get _files => [for (final s in _shots) File(s.path)];

  Future<List<IdentificationCandidate>> _identify() {
    final iris = _remember(
        ref.read(plantIdentifierProvider).identify(_files, language: _language, context: widget.place));
    _compare = _compareAfter(iris);
    return iris;
  }

  /// Les modèles de comparaison allumés, sur les photos du moment : chacun
  /// attend que le précédent — Iris d'abord — ait répondu ou échoué.
  Map<ComparisonModel, Future<List<IdentificationCandidate>>> _compareAfter(Future<Object?> iris) {
    final files = _files;
    final language = _language;
    final out = <ComparisonModel, Future<List<IdentificationCandidate>>>{};
    Future<Object?> previous = iris;
    for (final model in ComparisonModel.values) {
      final comparison = ref.read(comparisonIdentifierProvider(model));
      if (comparison == null) continue;
      final next = previous
          .then<void>((_) {}, onError: (Object _) {})
          .then((_) => comparison.identify(files, language: language, context: widget.place));
      out[model] = next;
      previous = next;
    }
    return out;
  }

  /// Retient la réponse pour que la relance suivante ait quelque chose à
  /// montrer pendant qu'elle calcule.
  Future<List<IdentificationCandidate>> _remember(Future<List<IdentificationCandidate>> pending) async {
    final results = await pending;
    if (mounted) _last = results;
    return results;
  }

  /// Relance la recherche, cette fois en ligne, parce qu'aucune proposition
  /// de l'appareil ne convenait. L'appel se fait sur ce geste et pas avant :
  /// c'est ce qui évite de payer un appel pour chaque photo. Toutes les
  /// photos partent, le quota se compte à l'appel et non à l'image.
  /// Retenir une candidate, c'est l'enregistrer : l'appelant écrit l'espèce
  /// dès le retour. Si la personne l'a permis, les photos partent entraîner
  /// Iris — à côté, sans retenir la feuille.
  void _use(IdentificationCandidate c, [JevProductAction? after]) {
    ref.read(jevIdentificationPolicyProvider).noteCandidateChosen(after);
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is CascadeIdentifier) {
      unawaited(ref.read(irisFeedbackRecorderProvider).record(IrisFeedback(
        photos: _files,
        local: identifier.lastLocal,
        chosenName: c.scientificName,
        chosenId: c.internalId,
        chosenSource: c.source == IdentificationSource.remote ? ChosenSource.remote : ChosenSource.local,
        remoteTop: c.source == IdentificationSource.remote ? c : null,
        modelVersion: identifier.local.version ?? '',
      )));
    }
    Navigator.of(context).pop(c);
  }

  Future<void> _searchOnline([JevProductAction? after]) async {
    ref.read(jevIdentificationPolicyProvider).noteOnlineSearch(after);
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier) return;
    setState(() => _future = _remember(identifier.identifyRemotely(_files, language: _language, context: widget.place)));
  }

  /// Décision produit complète autour d'un résultat Iris local ambigu.
  Future<JevPipelineEvaluation> _evaluation(
      List<IdentificationCandidate> results) {
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier) {
      return Future.value(const JevPipelineEvaluation(
        offer: SecondPhotoOffer.none,
        consultedJev: false,
        usedFallback: false,
      ));
    }
    return ref.read(jevIdentificationPolicyProvider).evaluate(
          policy: _policy,
          candidates: results,
          photos: _paths.length,
          maxPhotos: maxPhotos,
          online: ref.read(isOnlineProvider),
        );
  }

  /// Ce qu'Iris seule conclut, disponible sans attendre le réseau. C'est
  /// l'état affiché tant que Jev n'a pas répondu : l'arbitrage distant
  /// corrige une proposition déjà là plutôt que de retenir l'écran.
  JevPipelineEvaluation? _localEvaluation(
      List<IdentificationCandidate> results) {
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier) return null;
    return ref.read(jevIdentificationPolicyProvider).localEvaluation(
          policy: identifier.policy,
          candidates: results,
          photos: _paths.length,
          maxPhotos: maxPhotos,
        );
  }

  /// La politique de la cascade, tempérée par l'emplacement. Lue une fois et
  /// partagée : un seuil recopié dans une vue finit toujours par diverger.
  FallbackPolicy get _policy {
    final identifier = ref.read(plantIdentifierProvider);
    final base = identifier is CascadeIdentifier ? identifier.policy : const FallbackPolicy();
    if (widget.place != IdentificationContext.outdoor) return base;
    // La réserve du dehors ne vise pas l'extérieur en soi : elle vise un
    // modèle qui n'expose que de l'intérieur et nomme quand même une plante
    // de jardin (§ 12.7). Un modèle qui porte un masque extérieur n'est plus
    // dans ce cas — il a été mesuré sur ce terrain-là — et la réserve tombe
    // d'elle-même, sans qu'une constante soit à changer le jour de la
    // livraison.
    final covers = identifier is CascadeIdentifier &&
        identifier.local.contexts.contains(IdentificationContext.outdoor);
    return covers ? base : base.outdoors();
  }

  /// Les candidates à montrer, parmi tout ce que le moteur a rendu.
  ///
  /// Tronquer la liste brute suffisait tant qu'elle n'en portait qu'une.
  /// Masquée par le lieu, elle en porte deux — les classes du lieu, puis
  /// celles d'ailleurs — et prendre les cinq premières les prendrait toutes
  /// du lieu : le candidat d'ailleurs serait pris en compte par la politique,
  /// puis jamais montré. Il passe donc en dernier, après la réponse du lieu :
  /// c'est une alternative, pas une correction.
  List<IdentificationCandidate> _shown(List<IdentificationCandidate> all) {
    final inside = inContext(all);
    final other = _policy.challenger(all);
    if (other == null) return inside.take(maxCandidates).toList();
    return [...inside.take(maxCandidates - 1), other];
  }

  /// Le genre, quand aucune espèce ne passe le seuil. Même politique que le
  /// reste : c'est elle qui dit ce que « sûr » veut dire.
  GenusAnswer? _genus(List<IdentificationCandidate> results) {
    final identifier = ref.read(plantIdentifierProvider);
    return identifier is CascadeIdentifier ? genusAnswer(_policy, results) : null;
  }

  /// Une photo de plus, et on recommence. C'est gratuit, hors ligne et
  /// instantané, là où la recherche en ligne se prend sur un quota mensuel.
  Future<void> _addPhoto(PhotoSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final stored = await ref.read(photoStorageProvider).pick(source);
      if (stored == null) return;
      await _accept(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'identification.addPhoto');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Range une photo de plus dans la bande et relance l'identification.
  Future<void> _accept(StoredPhoto stored) async {
    final path = await ref.read(photoStorageProvider).absolutePath(stored.filePath);
    if (!mounted) return;
    setState(() {
      _shots.add(_Shot(path, stored: stored));
      _future = _identify();
    });
  }

  /// Retirer une photo ajoutée ici, et recommencer sans elle.
  ///
  /// La fusion par moyenne géométrique **exige que les photos soient
  /// d'accord** : un cliché raté — le pot, le mur, une feuille floue — tire
  /// le résultat vers le bas au lieu de l'affiner. Jusqu'ici le seul recours
  /// était de fermer la feuille et de tout reprendre.
  ///
  /// Le rang zéro n'est pas d'ici : c'est la photo qui a ouvert la feuille,
  /// et elle appartient à l'appelant. Une photo prêtée se retire de la bande
  /// mais ne s'efface pas de l'appareil ; une photo prise ici, si.
  Future<void> _removePhoto(int index) async {
    if (_picking || index <= 0 || index >= _shots.length) return;
    final storage = ref.read(photoStorageProvider);
    final stored = _shots[index].stored;
    setState(() {
      _shots.removeAt(index);
      _future = _identify();
    });
    if (stored != null) await storage.deleteFiles(stored.filePath, stored.thumbPath);
  }

  void _chooseSource() {
    final l10n = context.l10n;
    showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(label: l10n.camera, icon: CupertinoIcons.camera, onPressed: () => _addPhoto(PhotoSource.camera)),
        SheetAction(label: l10n.gallery, icon: CupertinoIcons.photo, onPressed: () => _addPhoto(PhotoSource.gallery)),
      ],
    );
  }

  /// D'où vient la réponse : sur l'appareil, ou par le service en ligne.
  /// L'utilisateur a le droit de savoir si sa photo est partie sur le réseau.
  String _sourceHint(AppLocalizations l10n, IdentificationSource source) => switch (source) {
        IdentificationSource.local => l10n.identifyOnDevice(AppConfig.modelName),
        IdentificationSource.remote => l10n.identifyViaPlantNet,
        IdentificationSource.unknown => l10n.identifyHint,
      };

  /// Le service distant est-il utilisable ? Sans clé, ou repli coupé, le
  /// bouton n'aurait rien à proposer.
  bool get _canSearchOnline {
    final identifier = ref.read(plantIdentifierProvider);
    return identifier is CascadeIdentifier && identifier.fallbackEnabled && identifier.fallback.isConfigured && identifier.remoteAllowedThisMonth;
  }

  Widget _normalIdentificationContent(
    BuildContext context,
    AppLocalizations l10n,
    List<IdentificationCandidate> results,
    GenusAnswer? genus,
    JevPipelineEvaluation? state,
  ) {
    final action = state?.decision?.action;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (genus != null) ...[
          GenusRow(
            answer: genus,
            onUse: () =>
                _use(genusCandidate(genus, l10n.localeName), action),
          ),
          const SizedBox(height: Space.xs),
        ],
        FloraGroup(
          children: [
            for (final c in results)
              CandidateRow(
                candidate: c,
                onUse: () => _use(c, action),
                policy: _policy,
                showScore: _compare.isNotEmpty,
              ),
          ],
        ),
        if (state?.offer == SecondPhotoOffer.prominent &&
            _paths.length < maxPhotos) ...[
          const SizedBox(height: Space.sm),
          Text(l10n.identifyAnotherPhotoHint, style: context.text.caption),
          const SizedBox(height: Space.xs),
          FloraButton(
            label: l10n.identifyAnotherPhoto,
            icon: CupertinoIcons.camera,
            style: FloraButtonStyle.secondary,
            onPressed: _chooseSource,
          ),
        ],
        _PhotoSourceNote(candidates: results),
        if (results.first.source == IdentificationSource.local &&
            _canSearchOnline) ...[
          const SizedBox(height: Space.sm),
          if (ref.watch(isOnlineProvider))
            FloraButton(
              label: l10n.searchOnline,
              expand: true,
              style: FloraButtonStyle.ghost,
              onPressed: () => _searchOnline(action),
            )
          else
            Text(
              l10n.offlineIdentification,
              style: context.text.caption,
              textAlign: TextAlign.center,
            ),
        ],
      ],
    );
  }

  Widget _uncertainIdentificationContent(
    BuildContext context,
    AppLocalizations l10n,
    List<IdentificationCandidate> results,
    GenusAnswer? genus,
  ) {
    final online = ref.watch(isOnlineProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const IdentificationUncertaintyNotice(),
        if (genus != null) ...[
          const SizedBox(height: Space.sm),
          GenusRow(
            answer: genus,
            onUse: () => _use(
                genusCandidate(genus, l10n.localeName),
                JevProductAction.keepUncertain),
          ),
        ],
        if (_canSearchOnline) ...[
          const SizedBox(height: Space.sm),
          if (online)
            FloraButton(
              label: l10n.searchOnline,
              expand: true,
              onPressed: () => _searchOnline(JevProductAction.keepUncertain),
            )
          else
            Text(
              l10n.offlineIdentification,
              style: context.text.caption,
              textAlign: TextAlign.center,
            ),
        ],
        const SizedBox(height: Space.md),
        Text(
          l10n.identificationSuggestionsToCheck,
          style: context.text.caption.copyWith(
            color: context.colors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Space.xs),
        FloraGroup(
          children: [
            for (final c in results)
              CandidateRow(
                candidate: c,
                onUse: () => _use(c, JevProductAction.keepUncertain),
                policy: _policy,
                showScore: _compare.isNotEmpty,
              ),
          ],
        ),
        _PhotoSourceNote(candidates: results),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.identifyTitle),
          FutureBuilder<List<IdentificationCandidate>>(
            future: _future,
            builder: (context, snap) {
              // Une relance — une photo de plus, une photo retirée — garde la
              // réponse précédente le temps de calculer la suivante. Seul le
              // premier calcul n'a rien à montrer et prend le tourniquet.
              final busy = snap.connectionState != ConnectionState.done;
              final data = snap.data ?? _last;
              if (busy && data == null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Space.xl),
                  child: Column(
                    children: [
                      ProcessingField(
                        height: 220,
                        child: Image.file(
                          File(widget.path),
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => ColoredBox(color: context.colors.surfaceMuted),
                        ),
                        foregroundAlignment: Alignment.topRight,
                        foreground: const Padding(
                          padding: EdgeInsets.only(top: Space.xs, right: Space.sm),
                          child: BreathingIrisMark(size: 48),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Text(l10n.identifying, style: context.text.callout),
                    ],
                  ),
                );
              }
              if (snap.hasError && data == null) return EmptyState(emoji: '📡', title: l10n.identifyError, compact: true);
              final results = _shown(data ?? const <IdentificationCandidate>[]);
              if (results.isEmpty) return EmptyState(emoji: '🤔', title: l10n.identifyNone, compact: true);
              final evaluationFuture =
                  !busy && results.first.source == IdentificationSource.local
                      ? _evaluation(data ?? const <IdentificationCandidate>[])
                      : null;
              // Le genre se somme sur toutes les candidates rendues, pas sur
              // les cinq affichées : c'est la masse qui décide, et elle se
              // perdrait à tronquer deux fois.
              final genus = _genus(data ?? const []);
              final hasSecondPhoto = _paths.length > 1;
              // Pendant une relance, la liste à l'écran est la précédente et
              // la provenance de la suivante n'est pas encore connue : le
              // signe attend plutôt que d'affirmer l'ancienne.
              final source = busy ? IdentificationSource.unknown : results.first.source;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IdentificationSourceNote(source: source, label: busy ? l10n.identifying : _sourceHint(l10n, source)),
                  if (hasSecondPhoto) ...[
                    const SizedBox(height: Space.xs),
                    IdentificationPhotoStrip(
                      paths: _paths,
                      maxPhotos: maxPhotos,
                      onRemove: _removePhoto,
                    ),
                  ],
                  const SizedBox(height: Space.sm),
                  if (evaluationFuture == null)
                    _normalIdentificationContent(
                      context,
                      l10n,
                      results,
                      genus,
                      null,
                    )
                  else
                    FutureBuilder<JevPipelineEvaluation>(
                      future: evaluationFuture,
                      initialData:
                          _localEvaluation(data ?? const <IdentificationCandidate>[]),
                      builder: (context, decisionSnap) {
                        final state = decisionSnap.data;
                        if (state?.keepsUncertain == true) {
                          return _uncertainIdentificationContent(
                            context,
                            l10n,
                            results,
                            genus,
                          );
                        }
                        return _normalIdentificationContent(
                          context,
                          l10n,
                          results,
                          genus,
                          state,
                        );
                      },
                    ),
                ],
              );
            },
          ),
          for (final entry in _compare.entries)
            _ComparisonSection(
              model: entry.key,
              future: entry.value,
              maxCandidates: maxCandidates,
              onUse: _use,
            ),
        ],
      ),
    );
  }
}

/// Les propositions d'un modèle de comparaison, sous celles d'Iris, pour les
/// comparer sur la même photo (§ 15 de docs/09). Elles se choisissent comme les
/// autres : une comparaison qui obligerait à recopier le bon nom à la main ne
/// servirait pas longtemps.
class _ComparisonSection extends ConsumerWidget {
  const _ComparisonSection(
      {required this.model, required this.future, required this.maxCandidates, required this.onUse});

  final ComparisonModel model;
  final Future<List<IdentificationCandidate>> future;
  final int maxCandidates;
  final void Function(IdentificationCandidate candidate) onUse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = model.displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.modelComparisonSuggestions(name),
          padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
        ),
        FutureBuilder<List<IdentificationCandidate>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Text(l10n.identifying, style: context.text.caption);
            }
            final results = (snap.data ?? const <IdentificationCandidate>[]).take(maxCandidates).toList();
            // Un modèle qui ne s'est pas chargé ne « reconnaît aucune
            // plante » : il n'a rien regardé. Le dire comme les réglages le
            // disent pour Iris, erreur native comprise — c'est elle qui
            // distingue un asset absent d'un runtime trop ancien.
            final error = ref.read(comparisonPlantModelProvider(model)).loadError;
            if (results.isEmpty && error != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.modelMissing(name), style: context.text.caption),
                  SelectableText(error, style: context.text.caption),
                ],
              );
            }
            if (results.isEmpty) return Text(l10n.modelComparisonNone(name), style: context.text.caption);
            return FloraGroup(
              children: [
                for (final c in results) CandidateRow(candidate: c, onUse: () => onUse(c), showScore: true),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// D'où viennent les vignettes, dit une fois sous la liste et seulement
/// quand il y en a. Une photo affichée sans qu'on sache à qui elle est n'a
/// pas sa place ici ; le crédit de celle qu'on touche est sur la fiche
/// espèce, où la place ne manque pas.
class _PhotoSourceNote extends ConsumerWidget {
  const _PhotoSourceNote({required this.candidates});

  final List<IdentificationCandidate> candidates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final illustrated = candidates
        .any((c) => c.image != null || ref.watch(speciesThumbnailProvider(c.scientificName)).asData?.value != null);
    if (!illustrated) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Text(context.l10n.identifyPhotoSource, style: context.text.caption),
    );
  }
}

class CandidateRow extends ConsumerWidget {
  const CandidateRow({
    super.key,
    required this.candidate,
    required this.onUse,
    this.selected = false,
    this.policy = const FallbackPolicy(),
    this.showScore = false,
  });

  final IdentificationCandidate candidate;
  final VoidCallback onUse;
  final bool selected;

  /// Celle de la cascade, tempérée par l'emplacement s'il est extérieur : le
  /// mot affiché doit dire la même chose que la décision prise.
  final FallbackPolicy policy;

  /// Le score brut du modèle en plus du cran. Réservé à la comparaison
  /// d'Iris avec d'autres modèles : ailleurs, un pourcentage se lit comme une
  /// certitude qu'il n'est pas, et le cran suffit.
  final bool showScore;

  /// Le côté de la vignette. Assez grand pour qu'une feuille se distingue
  /// d'une fleur, assez petit pour que la ligne reste une ligne de liste.
  static const double thumbnailSize = 44;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final confidence = IdentificationConfidence.of(candidate, policy: policy);
    final cran = l10n.confidenceLabel(confidence);
    final mot = showScore
        ? '$cran · ${NumberFormat.percentPattern(Localizations.localeOf(context).languageCode).format(candidate.score)}'
        : cran;
    final commun = candidate.commonName ?? '';
    // Pl@ntNet livre sa photo de référence avec le résultat ; le modèle
    // embarqué ne connaît que des noms, et c'est GBIF qui illustre alors.
    final image = candidate.image ?? ref.watch(speciesThumbnailProvider(candidate.scientificName)).asData?.value;
    return FloraListRow(
      // Le nom courant en titre : « Pied d'éléphant » se reconnaît d'un coup
      // d'œil, « Beaucarnea recurvata » demande de lire. Le nom scientifique
      // reste dessous, c'est lui qui identifie l'espèce.
      title: commun.isEmpty ? candidate.scientificName : commun,
      // Sans nom courant, le nom scientifique monte en titre et le
      // sous-titre ne garde que le cran, plutôt que de le répéter.
      subtitle: commun.isEmpty ? mot : '${candidate.scientificName} · $mot',
      // La place de la vignette est tenue dès le premier rendu, même vide :
      // la photo arrive une seconde après les noms, et une liste qui se
      // décale sous le doigt au moment où l'on vise est une liste qui trompe.
      leadingWidth: thumbnailSize,
      leading: image == null ? _ConfidenceMark(confidence: confidence) : _CandidateThumbnail(image: image, scientificName: candidate.scientificName),
      trailing: selected
          ? Semantics(
              selected: true,
              label: l10n.done,
              child: Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                color: context.colors.sage,
                size: 28,
              ),
            )
          : FloraButton(
              label: l10n.useThis,
              size: FloraButtonSize.small,
              style: FloraButtonStyle.tonal,
              onPressed: () {
                Haptics.success();
                onUse();
              },
            ),
      chevron: false,
    );
  }
}

/// Le cran de confiance, quand aucune photo ne vient le remplacer : trois
/// losanges, du plein au vide. Le mot reste dans le sous-titre, la forme
/// donne le classement d'un coup d'œil.
class _ConfidenceMark extends StatelessWidget {
  const _ConfidenceMark({required this.confidence});

  final IdentificationConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      switch (confidence) {
        IdentificationConfidence.likely => '◆',
        IdentificationConfidence.possible => '◈',
        IdentificationConfidence.unlikely => '◇',
      },
      style: TextStyle(
        fontSize: 15,
        color: switch (confidence) {
          IdentificationConfidence.likely => c.sage,
          IdentificationConfidence.possible => c.inkSecondary,
          IdentificationConfidence.unlikely => c.inkTertiary,
        },
      ),
    );
  }
}

/// À quoi ressemble l'espèce proposée. Une photo d'illustration, pas la
/// plante de l'utilisateur — d'où l'ouverture de la fiche espèce au doigt :
/// on y voit d'autres clichés, et le crédit de celui-ci.
class _CandidateThumbnail extends StatelessWidget {
  const _CandidateThumbnail({required this.image, required this.scientificName});

  final SpeciesImage image;
  final String scientificName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final credit = image.rightsHolder == null
        ? image.licenseLabel
        : (image.licenseLabel == null ? image.rightsHolder : l10n.speciesPhotoCredit(image.rightsHolder!, image.licenseLabel!));
    return Pressable(
      // Quarante-quatre points de photo ne portent pas leur crédit à
      // l'écran ; la synthèse vocale, elle, peut le dire, et la fiche
      // espèce l'écrit en toutes lettres.
      semanticLabel: credit == null ? scientificName : '$scientificName · $credit',
      semanticHint: l10n.speciesInfo,
      onTap: () => showSpeciesSheet(context, scientificName: scientificName),
      child: ClipRRect(
        borderRadius: Radii.smallAll,
        child: SizedBox.square(
          dimension: CandidateRow.thumbnailSize,
          child: PlantImage(remoteUrl: image.url, cacheWidth: 132),
        ),
      ),
    );
  }
}
