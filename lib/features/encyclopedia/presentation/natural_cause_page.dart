import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/problems/natural_cause.dart';
import '../../onboarding/presentation/clay_illustration.dart';
import '../../problems/presentation/problem_kind_icon.dart';
import 'host_sections.dart';

/// La page d'un des phénomènes naturels de la base : ce que la plante fait
/// normalement et qu'on prend pour un problème.
///
/// Même retenue que la page d'un problème — un nom, une étendue, des hôtes,
/// et rien qu'un modèle inventerait par dessus. Une ligne de plus, parce que
/// c'est ce qui définit l'entrée et ce qu'on vient vérifier ici : il n'y a
/// rien à soigner.
class NaturalCausePage extends ConsumerWidget {
  const NaturalCausePage({super.key, required this.naturalId});

  final String naturalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(problemCatalogProvider);
    final cause = catalog.value?.natural(naturalId);

    if (cause == null) {
      return FloraPage(
        title: l10n.encyclopediaTitle,
        child: Padding(
          padding: const EdgeInsets.only(top: Space.huge),
          child: catalog.isLoading
              ? const Center(child: AdaptiveProgress())
              : EmptyState(emoji: '🔍', title: l10n.noResultsTitle, compact: true),
        ),
      );
    }

    return FloraPage(
      title: cause.nameIn(language),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(cause: cause),
          const SizedBox(height: Space.md),
          FloraGroup(
            footer: l10n.problemScopeNote(cause.scope),
            children: [_row(l10n.problemScope, l10n.problemScopeName(cause.scope))],
          ),
          HostsSection(hosts: cause.hosts),
          InGardenSection(scope: cause.scope, hosts: cause.hosts),
        ],
      ),
    );
  }

  static Widget _row(String title, String value) => Builder(
        builder: (context) => FloraListRow(
          title: title,
          chevron: false,
          dense: true,
          trailing: Text(
            value,
            style: context.text.callout.copyWith(color: context.colors.ink, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      );
}

/// Le dessin en grand, sur la sauge — la teinte de ce qui n'est pas un
/// problème, celle que sa tuile porte déjà dans un diagnostic —, le nom
/// entier, et la phrase qui fait l'entrée : rien à soigner.
class _Header extends StatelessWidget {
  const _Header({required this.cause});

  final NaturalCause cause;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const side = 112.0;
    return FloraCard(
      color: context.colors.sageSoft,
      padding: const EdgeInsets.symmetric(vertical: Space.lg, horizontal: Space.md),
      child: Column(
        children: [
          Breathing(
            animate: true,
            builder: (context, pose) => ClayFloat(
              side: side,
              pose: pose,
              child: NaturalCauseIcon(cause: cause, side: side),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            cause.nameIn(Localizations.localeOf(context).languageCode),
            style: context.text.title2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          // Le numéro est celui que le diagnostic échange avec le modèle : il
          // nomme la même chose d'une analyse à l'autre et d'une langue à
          // l'autre.
          Text(
            '${l10n.diagnosisNatural} · ${l10n.problemNumber(cause.id)}',
            style: context.text.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.sm),
          Text(
            l10n.naturalCauseNote,
            style: context.text.callout,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
