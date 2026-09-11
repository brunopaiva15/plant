import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/likelihood_labels.dart';
import '../../../design_system/design_system.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../domain/identification/cascade_identifier.dart';
import '../../../domain/identification/identification_confidence.dart';
import '../../../domain/identification/identification_policy.dart';
import '../../../domain/identification/plant_identifier.dart';
import '../../../domain/species/species_info.dart';
import '../../species/presentation/species_sheet.dart';
import 'identification_photos.dart';

/// La photo d'illustration d'un candidat, cherchée chez GBIF après coup.
/// Séparée de l'identification elle-même : la liste s'affiche dès que les
/// noms sont là, les vignettes arrivent quand elles arrivent, et l'absence
/// de réseau ne coûte qu'une vignette. Seul le nom de l'espèce sort de
/// l'appareil — la photo de l'utilisateur, jamais.
final candidateThumbnailProvider = FutureProvider.autoDispose.family<SpeciesImage?, String>(
    (ref, scientificName) => ref.watch(speciesServiceProvider).thumbnail(scientificName));

/// Lance l'identification sur une photo et laisse l'utilisateur choisir.
/// Retourne le candidat retenu, ou `null`.
Future<IdentificationCandidate?> showIdentificationSheet(BuildContext context, {required String absoluteImagePath}) =>
    showFloraSheet<IdentificationCandidate>(context, scrollable: true, builder: (_) => _IdentificationBody(path: absoluteImagePath));

class _IdentificationBody extends ConsumerStatefulWidget {
  const _IdentificationBody({required this.path});

  final String path;

  @override
  ConsumerState<_IdentificationBody> createState() => _IdentificationBodyState();
}

class _IdentificationBodyState extends ConsumerState<_IdentificationBody> {
  late Future<List<IdentificationCandidate>> _future;

  /// La photo d'origine, puis celles ajoutées ici pour lever un doute. Le
  /// moteur les fusionne par moyenne géométrique : l'espèce que toutes les
  /// photos voient remonte, celle qui ne tenait qu'à un cliché ambigu
  /// redescend — et une photo ratée pèse, d'où la croix de la bande.
  late final List<String> _paths = [widget.path];

  /// Celles prises ici, et elles seules. La première appartient à l'appelant.
  final _extra = <StoredPhoto>[];
  bool _picking = false;

  /// Au-delà, une photo de plus n'apporte plus grand-chose et la recherche
  /// en ligne est le meilleur recours.
  static const int maxPhotos = 3;

  @override
  void initState() {
    super.initState();
    _future = _identify();
  }

  @override
  void dispose() {
    // Ces photos ne servaient qu'à identifier : elles ne sont la photo
    // d'aucune plante et n'ont rien à faire sur l'appareil après coup.
    final storage = ref.read(photoStorageProvider);
    for (final p in _extra) {
      storage.deleteFiles(p.filePath, p.thumbPath);
    }
    super.dispose();
  }

  String get _language =>
      ref.read(preferencesProvider).locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;

  List<File> get _files => [for (final p in _paths) File(p)];

  Future<List<IdentificationCandidate>> _identify() =>
      ref.read(plantIdentifierProvider).identify(_files, language: _language);

  /// Relance la recherche, cette fois en ligne, parce qu'aucune proposition
  /// de l'appareil ne convenait. L'appel se fait sur ce geste et pas avant :
  /// c'est ce qui évite de payer un appel pour chaque photo. Toutes les
  /// photos partent, le quota se compte à l'appel et non à l'image.
  Future<void> _searchOnline() async {
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier) return;
    setState(() => _future = identifier.identifyRemotely(_files, language: _language));
  }

  /// Faut-il proposer une photo de plus, et sur quel ton ? C'est la
  /// politique de la cascade qui le dit, celle-là même qui décide d'appeler
  /// ou non le service distant, plutôt qu'un seuil recopié ici qui finirait
  /// par diverger.
  SecondPhotoOffer _offer(List<IdentificationCandidate> results) {
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier) return SecondPhotoOffer.none;
    return secondPhotoOffer(identifier.policy, results, photos: _paths.length, maxPhotos: maxPhotos);
  }

  /// Une photo de plus, et on recommence. C'est gratuit, hors ligne et
  /// instantané, là où la recherche en ligne se prend sur un quota mensuel.
  Future<void> _addPhoto(PhotoSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final stored = await ref.read(photoStorageProvider).pick(source);
      if (stored == null) return;
      final path = await ref.read(photoStorageProvider).absolutePath(stored.filePath);
      if (!mounted) return;
      setState(() {
        _extra.add(stored);
        _paths.add(path);
        _future = _identify();
      });
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'identification.addPhoto');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Retirer une photo ajoutée ici, et recommencer sans elle.
  ///
  /// La fusion par moyenne géométrique **exige que les photos soient
  /// d'accord** : un cliché raté — le pot, le mur, une feuille floue — tire
  /// le résultat vers le bas au lieu de l'affiner. Jusqu'ici le seul recours
  /// était de fermer la feuille et de tout reprendre.
  ///
  /// Le rang zéro n'est pas d'ici : c'est la photo qui a ouvert la feuille,
  /// et elle appartient à l'appelant.
  Future<void> _removePhoto(int index) async {
    if (_picking || index <= 0 || index >= _paths.length) return;
    final stored = _extra.removeAt(index - 1);
    final storage = ref.read(photoStorageProvider);
    setState(() {
      _paths.removeAt(index);
      _future = _identify();
    });
    await storage.deleteFiles(stored.filePath, stored.thumbPath);
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
              if (snap.connectionState != ConnectionState.done) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.xxl),
                  child: Column(children: [const AdaptiveProgress(), const SizedBox(height: Space.sm), Text(l10n.identifying, style: context.text.callout)]),
                );
              }
              if (snap.hasError) return EmptyState(emoji: '📡', title: l10n.identifyError, compact: true);
              final results = (snap.data ?? const <IdentificationCandidate>[]).take(5).toList();
              if (results.isEmpty) return EmptyState(emoji: '🤔', title: l10n.identifyNone, compact: true);
              final offer = _offer(results);
              // La bande montre ce qui est parti dès qu'il y a plusieurs
              // photos, et la place libre seulement si la cascade en veut
              // une de plus. Le compte n'est plus écrit — « · 2 photos »
              // disait l'état sans jamais dire le geste ; deux vignettes et
              // une case vide disent les deux.
              final showStrip = _paths.length > 1 || offer != SecondPhotoOffer.none;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_sourceHint(l10n, results.first.source), style: context.text.caption),
                  if (showStrip) ...[
                    const SizedBox(height: Space.xs),
                    IdentificationPhotoStrip(
                      paths: _paths,
                      maxPhotos: maxPhotos,
                      // Rien n'est retiré de la bande pendant qu'on prend
                      // une photo : les cases libres disparaîtraient puis
                      // reviendraient. Les deux gestes se gardent eux-mêmes.
                      onAdd: offer == SecondPhotoOffer.none ? null : _chooseSource,
                      onRemove: _removePhoto,
                    ),
                    // Le modèle hésite : la photo est le geste qui tranche,
                    // et il vaut la phrase qui dit quoi photographier.
                    if (offer == SecondPhotoOffer.prominent) ...[
                      const SizedBox(height: Space.xs),
                      Text(l10n.identifyAnotherPhotoHint, style: context.text.caption),
                    ],
                  ],
                  const SizedBox(height: Space.sm),
                  FloraGroup(children: [for (final c in results) CandidateRow(candidate: c, onUse: () => Navigator.of(context).pop(c))]),
                  _PhotoSourceNote(candidates: results),
                  // La photo d'abord, l'appel réseau ensuite : l'une est
                  // gratuite et immédiate, l'autre se prend sur un quota. Le
                  // geste gratuit est donc au-dessus de la liste, dans la
                  // bande, et celui qui se paie reste ici-bas.
                  if (results.first.source == IdentificationSource.local && _canSearchOnline) ...[
                    const SizedBox(height: Space.sm),
                    FloraButton(label: l10n.searchOnline, expand: true, style: FloraButtonStyle.ghost, onPressed: _searchOnline),
                  ],
                ],
              );
            },
          ),
        ],
      ),
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
        .any((c) => c.image != null || ref.watch(candidateThumbnailProvider(c.scientificName)).asData?.value != null);
    if (!illustrated) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Text(context.l10n.identifyPhotoSource, style: context.text.caption),
    );
  }
}

class CandidateRow extends ConsumerWidget {
  const CandidateRow({super.key, required this.candidate, required this.onUse});

  final IdentificationCandidate candidate;
  final VoidCallback onUse;

  /// Le côté de la vignette. Assez grand pour qu'une feuille se distingue
  /// d'une fleur, assez petit pour que la ligne reste une ligne de liste.
  static const double thumbnailSize = 44;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final confidence = IdentificationConfidence.of(candidate);
    final mot = l10n.confidenceLabel(confidence);
    final commun = candidate.commonName ?? '';
    // Pl@ntNet livre sa photo de référence avec le résultat ; le modèle
    // embarqué ne connaît que des noms, et c'est GBIF qui illustre alors.
    final image = candidate.image ?? ref.watch(candidateThumbnailProvider(candidate.scientificName)).asData?.value;
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
      trailing: FloraButton(
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
