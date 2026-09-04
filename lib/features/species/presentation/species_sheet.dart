import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/species/species_info.dart';

/// Fiche espèce GBIF pour un nom scientifique (taxonomie, noms communs,
/// observations photographiées avec attribution).
final speciesInfoProvider = FutureProvider.family<SpeciesInfo?, String>((ref, name) => ref.watch(speciesServiceProvider).lookup(name));

Future<void> showSpeciesSheet(BuildContext context, {required String scientificName}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => SpeciesSheetBody(scientificName: scientificName));

class SpeciesSheetBody extends ConsumerWidget {
  const SpeciesSheetBody({super.key, required this.scientificName});

  final String scientificName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final info = ref.watch(speciesInfoProvider(scientificName));
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.speciesInfo),
          info.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xxl),
              child: Column(children: [const AdaptiveProgress(), const SizedBox(height: Space.sm), Text(l10n.speciesLoading, style: context.text.caption)]),
            ),
            error: (_, _) => EmptyState(emoji: '📡', title: l10n.genericError, compact: true),
            data: (s) {
              if (s == null) return EmptyState(emoji: '🌱', title: l10n.speciesNotFound, subtitle: scientificName, compact: true);
              final common = s.commonNamesFor(lang);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (s.images.isNotEmpty) ...[
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: s.images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
                        itemBuilder: (context, i) => _ObservationImage(image: s.images[i]),
                      ),
                    ),
                    const SizedBox(height: Space.md),
                  ],
                  Text(s.canonicalName, style: context.text.title2.copyWith(fontStyle: FontStyle.italic)),
                  if (s.authorship != null && s.authorship!.isNotEmpty) Text(s.authorship!, style: context.text.caption),
                  if (common.isNotEmpty) ...[
                    const SizedBox(height: Space.xs),
                    Text(common.take(3).join(' · '), style: context.text.callout.copyWith(color: c.ink)),
                  ],
                  const SizedBox(height: Space.md),
                  FloraGroup(
                    children: [
                      if (s.family != null) FloraListRow(title: l10n.speciesFamily, trailing: Text(s.family!, style: context.text.callout), dense: true),
                      if (s.order != null) FloraListRow(title: l10n.speciesOrder, trailing: Text(s.order!, style: context.text.callout), dense: true),
                      if (s.genus != null) FloraListRow(title: l10n.speciesGenus, trailing: Text(s.genus!, style: context.text.callout), dense: true),
                      if (s.status != null)
                        FloraListRow(title: l10n.speciesStatus, trailing: Text(s.status == 'ACCEPTED' ? l10n.speciesStatusAccepted : (s.status == 'SYNONYM' ? l10n.speciesStatusSynonym : s.status!), style: context.text.callout), dense: true),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                  FloraButton(
                    label: l10n.speciesOpenGbif,
                    icon: CupertinoIcons.arrow_up_right_square,
                    style: FloraButtonStyle.tonal,
                    expand: true,
                    onPressed: () => launchUrl(Uri.parse(s.gbifUrl), mode: LaunchMode.externalApplication),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(l10n.speciesSource, style: context.text.caption, textAlign: TextAlign.center),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ObservationImage extends StatelessWidget {
  const _ObservationImage({required this.image});

  final SpeciesImage image;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final credit = image.rightsHolder == null ? image.licenseLabel : (image.licenseLabel == null ? image.rightsHolder : l10n.speciesPhotoCredit(image.rightsHolder!, image.licenseLabel!));
    return ClipRRect(
      borderRadius: Radii.mediumAll,
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(image.url, fit: BoxFit.cover, errorBuilder: (_, _, _) => ColoredBox(color: context.colors.surfaceMuted)),
            if (credit != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  color: Colors.black45,
                  child: Text(credit, style: context.text.caption.copyWith(color: Colors.white, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
