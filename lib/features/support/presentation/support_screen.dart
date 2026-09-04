import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/support/support_service.dart';

/// Le soutien facultatif au développeur.
///
/// L'écran ne vend rien : l'application est entière et gratuite, et il le dit
/// avant de proposer quoi que ce soit. Sans magasin — le web, un appareil où
/// l'achat n'est pas proposé — le bouton n'apparaît pas du tout : mieux vaut
/// une phrase honnête qu'un bouton mort.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloraPage(
      title: context.l10n.supportSettings,
      child: const SupportPitch(),
    );
  }
}

/// Le corps de la proposition, réutilisé par l'écran et par l'onboarding.
class SupportPitch extends ConsumerStatefulWidget {
  const SupportPitch({super.key, this.onDone});

  /// Appelé une fois l'affaire réglée — soutien versé ou non. L'onboarding s'en
  /// sert pour passer à la suite ; l'écran des réglages n'en a pas besoin.
  final VoidCallback? onDone;

  @override
  ConsumerState<SupportPitch> createState() => _SupportPitchState();
}

class _SupportPitchState extends ConsumerState<SupportPitch> {
  var _busy = false;

  Future<void> _give(SupportOffer offer) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final result = await ref.read(supportServiceProvider).give();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case SupportResult.thanks:
      case SupportResult.alreadyGiven:
        await ref.read(preferencesProvider.notifier).setSupported(true);
        Haptics.success();
        if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.supportThanksTitle, emoji: '💚'));
        widget.onDone?.call();
      case SupportResult.cancelled:
        break;
      case SupportResult.unavailable:
        ref.read(toastProvider.notifier).show(ToastData(message: l10n.supportUnavailable, emoji: '🛒'));
      case SupportResult.failed:
        ref.read(toastProvider.notifier).show(ToastData(message: l10n.supportFailed, emoji: '⚠️'));
    }
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final found = await ref.read(supportServiceProvider).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (found) await ref.read(preferencesProvider.notifier).setSupported(true);
    if (!mounted) return;
    ref.read(toastProvider.notifier).show(
      ToastData(message: found ? l10n.supportThanksTitle : l10n.supportNothingToRestore, emoji: found ? '💚' : '🔎'),
    );
    if (found) widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final supported = ref.watch(preferencesProvider.select((p) => p.hasSupported));
    final offer = ref.watch(supportOfferProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        Center(
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(color: c.sageSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Image.asset('assets/onboarding/onboarding_1.png', width: 84, height: 84, excludeFromSemantics: true),
          ),
        ),
        const SizedBox(height: Space.lg),
        Text(
          supported ? l10n.supportThanksTitle : l10n.supportTitle,
          style: context.text.title1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.sm),
        Text(
          supported ? l10n.supportThanksBody : l10n.supportBody,
          style: context.text.body.copyWith(color: c.inkSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.xl),
        if (!supported)
          offer.when(
            loading: () => const Center(child: AdaptiveProgress()),
            error: (_, _) => _Unavailable(message: l10n.supportUnavailable),
            data: (offer) => offer == null
                ? _Unavailable(message: l10n.supportUnavailable)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FloraButton(
                        label: l10n.supportGive(offer.price),
                        expand: true,
                        loading: _busy,
                        onPressed: () => _give(offer),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        l10n.supportNothingLocked,
                        style: context.text.caption.copyWith(color: c.inkTertiary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Space.xs),
                      FloraButton(
                        label: l10n.supportRestore,
                        style: FloraButtonStyle.ghost,
                        expand: true,
                        onPressed: _busy ? null : _restore,
                      ),
                    ],
                  ),
          ),
        if (supported)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.heart_fill, size: 16, color: c.rose),
              const SizedBox(width: 6),
              Text(l10n.supportAlready, style: context.text.callout.copyWith(color: c.sage)),
            ],
          ),
        if (widget.onDone != null) ...[
          const SizedBox(height: Space.sm),
          FloraButton(
            label: supported ? l10n.continueLabel : l10n.supportNoThanks,
            style: FloraButtonStyle.ghost,
            expand: true,
            onPressed: widget.onDone,
          ),
        ],
      ],
    );
  }
}

/// Pas de magasin ici : on le dit, plutôt que d'afficher un bouton inerte.
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      message,
      style: context.text.caption.copyWith(color: c.inkTertiary),
      textAlign: TextAlign.center,
    );
  }
}
