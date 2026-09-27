import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../application/whats_new.dart';

/// Ouvre les nouveautés une fois, à l'arrivée sur la coquille.
///
/// Après l'animation d'ouverture, pas pendant : une feuille qui monte sous le
/// pot qui cligne ne se lit pas. Et seulement si rien d'autre n'est ouvert —
/// un lien, un raccourci de l'icône, une notification ont posé leur page ;
/// les nouveautés attendent alors la prochaine ouverture plutôt que de
/// s'empiler dessus.
class WhatsNewHost extends ConsumerStatefulWidget {
  const WhatsNewHost({super.key, required this.child});

  final Widget child;

  /// Le temps de l'animation d'ouverture (1,64 s), et un peu de marge.
  static const delay = Duration(milliseconds: 2200);

  @override
  ConsumerState<WhatsNewHost> createState() => _WhatsNewHostState();
}

class _WhatsNewHostState extends ConsumerState<WhatsNewHost> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesServiceProvider);
    if (!WhatsNew.shouldShow(seen: prefs.whatsNewSeen, onboardingDone: prefs.onboardingDone)) return;
    _timer = Timer(WhatsNewHost.delay, _open);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _open() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    showWhatsNew(context, ref);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Les nouveautés de l'édition en cours, en feuille.
Future<void> showWhatsNew(BuildContext context, WidgetRef ref) async {
  // Marquée avant d'ouvrir : fermée d'un geste ou d'un bouton, elle a été vue.
  await ref.read(preferencesServiceProvider).setWhatsNewSeen(WhatsNew.edition);
  if (!context.mounted) return;
  await showFloraSheet<void>(context, scrollable: true, builder: (_) => const WhatsNewView());
}

class WhatsNewView extends ConsumerWidget {
  const WhatsNewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final side = Space.page + readableInset(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(side, Space.lg, side, Space.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.whatsNewTitle, style: context.text.title2),
          const SizedBox(height: 2),
          Text(l10n.version(ref.watch(appVersionProvider).name), style: context.text.caption),
          const SizedBox(height: Space.lg),
          for (final item in WhatsNew.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmojiTile(emoji: item.emoji),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.whatsNewItemTitle(item), style: context.text.title3),
                      const SizedBox(height: 2),
                      Text(l10n.whatsNewItemBody(item), style: context.text.callout.copyWith(color: c.inkSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
          ],
          const SizedBox(height: Space.sm),
          FloraButton(label: l10n.continueLabel, expand: true, onPressed: () => Navigator.of(context, rootNavigator: true).pop()),
        ],
      ),
    );
  }
}

extension on AppLocalizations {
  String whatsNewItemTitle(WhatsNewItem item) => switch (item) {
        WhatsNewItem.pot => whatsNewPotTitle,
        WhatsNewItem.camera => whatsNewCameraTitle,
        WhatsNewItem.species => whatsNewSpeciesTitle,
        WhatsNewItem.diagnosis => whatsNewDiagnosisTitle,
      };

  String whatsNewItemBody(WhatsNewItem item) => switch (item) {
        WhatsNewItem.pot => whatsNewPotBody,
        WhatsNewItem.camera => whatsNewCameraBody,
        WhatsNewItem.species => whatsNewSpeciesBody,
        WhatsNewItem.diagnosis => whatsNewDiagnosisBody,
      };
}
