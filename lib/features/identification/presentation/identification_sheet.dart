import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/likelihood_labels.dart';
import '../../../design_system/design_system.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../domain/identification/cascade_identifier.dart';
import '../../../domain/identification/identification_confidence.dart';
import '../../../domain/identification/identification_policy.dart';
import '../../../domain/identification/plant_identifier.dart';

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
  /// moteur additionne les scores par espèce : celle qu'on retrouve sur
  /// toutes les photos remonte, celle qui ne tenait qu'à un cliché ambigu
  /// redescend.
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

  /// Le modèle hésite-t-il ? C'est la politique de la cascade qui le dit,
  /// celle-là même qui décide d'appeler ou non le service distant, plutôt
  /// qu'un seuil recopié ici qui finirait par diverger.
  bool _ambiguous(List<IdentificationCandidate> results) {
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier || results.isEmpty) return false;
    if (results.first.source != IdentificationSource.local) return false;
    return identifier.policy.decide(results) != IdentificationVerdict.accepted;
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
        IdentificationSource.local => l10n.identifyOnDevice,
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    // Le nombre de photos n'apparaît qu'une fois qu'il y en a
                    // plusieurs : « 1 photo » n'apprendrait rien.
                    _paths.length > 1
                        ? '${_sourceHint(l10n, results.first.source)} · ${l10n.photosCount(_paths.length)}'
                        : _sourceHint(l10n, results.first.source),
                    style: context.text.caption,
                  ),
                  const SizedBox(height: Space.sm),
                  FloraGroup(children: [for (final c in results) CandidateRow(candidate: c, onUse: () => Navigator.of(context).pop(c))]),
                  // La photo d'abord, l'appel réseau ensuite : l'une est
                  // gratuite et immédiate, l'autre se prend sur un quota.
                  if (_paths.length < maxPhotos && _ambiguous(results)) ...[
                    const SizedBox(height: Space.md),
                    Text(l10n.identifyAnotherPhotoHint, style: context.text.caption),
                    const SizedBox(height: Space.xs),
                    FloraButton(
                      label: l10n.identifyAnotherPhoto,
                      icon: CupertinoIcons.camera,
                      expand: true,
                      style: FloraButtonStyle.secondary,
                      onPressed: _picking ? null : _chooseSource,
                    ),
                  ],
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

class CandidateRow extends StatelessWidget {
  const CandidateRow({super.key, required this.candidate, required this.onUse});

  final IdentificationCandidate candidate;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final confidence = IdentificationConfidence.of(candidate);
    final mot = l10n.confidenceLabel(confidence);
    final commun = candidate.commonName ?? '';
    return FloraListRow(
      // Le nom courant en titre : « Pied d'éléphant » se reconnaît d'un coup
      // d'œil, « Beaucarnea recurvata » demande de lire. Le nom scientifique
      // reste dessous, c'est lui qui identifie l'espèce.
      title: commun.isEmpty ? candidate.scientificName : commun,
      // Sans nom courant, le nom scientifique monte en titre et le
      // sous-titre ne garde que le cran, plutôt que de le répéter.
      subtitle: commun.isEmpty ? mot : '${candidate.scientificName} · $mot',
      leading: Text(
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
      ),
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
