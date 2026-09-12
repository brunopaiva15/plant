import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/finder_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/species/plant_advisor.dart';
import '../../../domain/species/plant_finder.dart';
import '../../../domain/species/species_info.dart';

/// La photo d'une espèce proposée, cherchée chez GBIF après coup.
///
/// Les propositions viennent du catalogue et s'affichent sans réseau ; la
/// photo arrive quand elle arrive, et son absence ne coûte qu'une tuile
/// d'emoji à la place. Seul le nom de l'espèce sort de l'appareil.
final finderThumbnailProvider = FutureProvider.autoDispose.family<SpeciesImage?, String>(
    (ref, scientificName) => ref.watch(speciesServiceProvider).thumbnail(scientificName));

/// La tuile d'une espèce : sa photo d'observation quand GBIF en a une libre
/// de droits, sinon l'emoji de sa catégorie sur une pâte d'argile. Même
/// forme dans les deux cas, pour que la liste ne saute pas quand la photo
/// arrive.
class SpeciesTile extends ConsumerWidget {
  const SpeciesTile({super.key, required this.scientificName, required this.emoji, this.size = 56, this.variant = 0, this.background});

  final String scientificName;
  final String emoji;
  final double size;
  final int variant;
  final Color? background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final image = ref.watch(finderThumbnailProvider(scientificName)).asData?.value;
    if (image == null) return EmojiTile(emoji: emoji, size: size, variant: variant, background: background);
    return ClayBox(
      width: size,
      height: size,
      color: c.surfaceMuted,
      shape: ClayShape.blob(variant),
      clip: true,
      child: PlantImage(remoteUrl: image.url, cacheWidth: (size * 3).round(), placeholderEmoji: emoji),
    );
  }
}

/// Ce que dit la photo d'une espèce, pour VoiceOver et pour la fiche : son
/// auteur et sa licence, ou rien si elle n'est pas là.
String? speciesPhotoCredit(BuildContext context, SpeciesImage? image) {
  if (image == null) return null;
  final l10n = context.l10n;
  final author = image.rightsHolder;
  final license = image.licenseLabel;
  if (author == null) return license;
  if (license == null) return author;
  return l10n.speciesPhotoCredit(author, license);
}

/// La ligne qui signe les photos, une fois qu'au moins une est arrivée. Tant
/// qu'aucune n'est là, il n'y a rien à signer.
class FinderPhotoSource extends ConsumerWidget {
  const FinderPhotoSource({super.key, required this.scientificNames});

  final List<String> scientificNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final any = scientificNames.any((n) => ref.watch(finderThumbnailProvider(n)).asData?.value != null);
    if (!any) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Space.md),
      child: Text(context.l10n.finderPhotoSource, style: context.text.caption),
    );
  }
}

/// Une raison d'être proposée, en pastille : une coche et trois mots.
///
/// Sur la crème d'une carte, la pastille est en pastel ; sur le pastel de la
/// carte du premier choix, elle repasse en crème pour rester lisible.
class FinderReasonPill extends StatelessWidget {
  const FinderReasonPill({super.key, required this.label, this.onSoft = false});

  final String label;
  final bool onSoft;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.xs, Space.xxs, Space.sm, Space.xxs),
      decoration: BoxDecoration(color: onSoft ? c.surface : c.sageSoft, borderRadius: Radii.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.checkmark_alt, size: 13, color: c.sage),
          const SizedBox(width: Space.xxs),
          Flexible(child: Text(label, style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// Les raisons d'une proposition, en pastilles qui plient à la ligne.
class FinderReasons extends StatelessWidget {
  const FinderReasons({super.key, required this.reasons, this.onSoft = false});

  final List<FinderReason> reasons;
  final bool onSoft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final r in reasons) FinderReasonPill(label: l10n.finderReasonName(r), onSoft: onSoft)],
    );
  }
}

/// La première proposition, en carte de couleur et en relief franc : c'est
/// elle que l'on regarde d'abord, et elle dit tout de suite ce qu'elle
/// demande — l'eau, la lumière, l'effort.
class FinderTopPickCard extends StatelessWidget {
  const FinderTopPickCard({super.key, required this.match, required this.onTap});

  final FinderMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final p = match.care.profile;
    final facts = <(String, String)>[
      ('💧', l10n.finderFactWater(p.wateringSummerDays)),
      ('☀️', l10n.lightName(p.light)),
      ('📈', l10n.difficultyName(p.difficulty)),
    ];
    return MergeSemantics(
      child: FloraCard(
        onTap: onTap,
        color: c.sageSoft,
        depth: ClayDepth.deep,
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.finderTopPick, style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                SpeciesTile(scientificName: match.entry.scientificName, emoji: match.entry.category.emoji, size: 72, variant: 0, background: c.surface),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.entry.commonName(lang), style: context.text.title2, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(match.entry.scientificName, style: context.text.caption.copyWith(fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: Space.xs),
                Icon(CupertinoIcons.chevron_right, size: 16, color: c.inkTertiary),
              ],
            ),
            if (match.reasons.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              FinderReasons(reasons: match.reasons, onSoft: true),
            ],
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.md,
              runSpacing: Space.xs,
              children: [for (final (emoji, label) in facts) _Fact(emoji: emoji, label: label)],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14, height: 1)),
        const SizedBox(width: Space.xxs),
        Text(label, style: context.text.caption.copyWith(color: context.colors.ink)),
      ],
    );
  }
}

/// Une autre proposition du catalogue : la tuile, les deux noms, et ce qui
/// la fait correspondre.
class FinderMatchCard extends StatelessWidget {
  const FinderMatchCard({super.key, required this.match, required this.index, required this.onTap});

  final FinderMatch match;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return _ProposalCard(
      onTap: onTap,
      tile: SpeciesTile(scientificName: match.entry.scientificName, emoji: match.entry.category.emoji, variant: index),
      title: match.entry.commonName(lang),
      scientificName: match.entry.scientificName,
      detail: match.reasons.isEmpty ? null : FinderReasons(reasons: match.reasons),
    );
  }
}

/// Une proposition de l'IA, hors catalogue : la raison qu'elle donne tient
/// lieu de pastilles.
class FinderAdvisorCard extends StatelessWidget {
  const FinderAdvisorCard({super.key, required this.suggestion, required this.index, required this.onTap});

  final AdvisorSuggestion suggestion;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ProposalCard(
      onTap: onTap,
      tile: SpeciesTile(scientificName: suggestion.scientificName, emoji: '✨', variant: index + 1),
      title: suggestion.commonName ?? suggestion.scientificName,
      scientificName: suggestion.commonName == null ? null : suggestion.scientificName,
      detail: suggestion.reason.isEmpty ? null : Text(suggestion.reason, style: context.text.callout.copyWith(color: c.ink)),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.onTap, required this.tile, required this.title, required this.scientificName, required this.detail});

  final VoidCallback onTap;
  final Widget tile;
  final String title;
  final String? scientificName;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: FloraCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            tile,
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.body.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (scientificName != null) ...[
                    const SizedBox(height: 2),
                    Text(scientificName!, style: context.text.caption.copyWith(fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (detail != null) ...[const SizedBox(height: Space.xs), detail!],
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            Icon(CupertinoIcons.chevron_right, size: 16, color: c.inkTertiary),
          ],
        ),
      ),
    );
  }
}
