import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/connectivity.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/support/support_service.dart';
import '../../network/presentation/offline_notice.dart';
import '../../onboarding/presentation/growing_plant.dart';

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
///
/// Cinq pièces, pas une de plus : la plante sur sa lueur, une phrase à la
/// main, ce qui est ouvert, un trait, le montant et son bouton. Une version
/// intermédiaire alignait une pastille en capitales, une grille de quatre
/// tuiles à icônes et une carte de prix — la page d'accueil de n'importe quel
/// service, et le contraire de cette application, qui est du papier et de
/// l'argile. Le relief se garde pour ce qu'on touche ; le reste est écrit.
class SupportPitch extends ConsumerStatefulWidget {
  const SupportPitch({super.key, this.onDone, this.compact = false});

  /// Appelé une fois le soutien versé ou retrouvé. L'onboarding s'en sert
  /// pour passer à la suite ; l'écran des réglages n'en a pas besoin.
  ///
  /// Le geste qui passe outre, lui, n'est pas ici : « Continuer sans » est de
  /// la navigation de l'onboarding, et c'est l'onboarding qui le dessine,
  /// dans son propre style. Deux boutons fantômes verts empilés — celui-là et
  /// « Restaurer mon soutien » — ne disaient plus lequel était la sortie.
  final VoidCallback? onDone;

  /// La version de l'onboarding : la scène rapetisse, la page y partageant sa
  /// hauteur avec les points de progression et le bouton du pied.
  final bool compact;

  @override
  ConsumerState<SupportPitch> createState() => _SupportPitchState();
}

class _SupportPitchState extends ConsumerState<SupportPitch> {
  var _busy = false;

  Future<void> _give() async {
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

  /// Ce qui vient sous le trait : la proposition, ou ce qui l'empêche. Une
  /// fois le soutien versé il n'y a plus rien à demander, et c'est la phrase
  /// du haut qui descend là, en plus petit — la page se ferme sur ce qu'elle
  /// est venue dire.
  Widget _below(bool supported) {
    final l10n = context.l10n;
    final c = context.colors;
    if (supported) return Text(l10n.supportBody, style: context.text.callout.copyWith(color: c.inkSecondary));
    // L'achat passe par le magasin, et le magasin par le réseau : hors ligne
    // le bouton échouerait au moment de payer.
    if (!ref.watch(isOnlineProvider)) return OfflineBanner(message: l10n.offlineSupport, padding: EdgeInsets.zero);
    return ref.watch(supportOfferProvider).when(
      loading: () => const Center(child: AdaptiveProgress()),
      error: (_, _) => _Unavailable(message: l10n.supportUnavailable),
      data: (offer) => offer == null
          ? _Unavailable(message: l10n.supportUnavailable)
          : _Offer(price: offer.price, busy: _busy, onGive: _give, onRestore: _restore),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final supported = ref.watch(preferencesProvider.select((p) => p.hasSupported));
    final compact = widget.compact;

    return Column(
      // Le texte est rangé à gauche, sous la scène, comme sur les écrans de
      // l'onboarding : un titre d'affiche, pas une légende. Tout centrer
      // donnait une affiche symétrique que rien ne tenait.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: compact ? Space.xs : Space.md),
        Appear(
          key: const ValueKey('hero'),
          child: _SupportHero(supported: supported, side: compact ? 108.0 : 140.0),
        ),
        const SizedBox(height: Space.xxl),
        Appear(
          key: const ValueKey('title'),
          rank: 1,
          child: Text(supported ? l10n.supportThanksTitle : l10n.supportTitle, style: context.text.display),
        ),
        const SizedBox(height: Space.sm),
        Appear(
          key: const ValueKey('body'),
          rank: 2,
          child: Text(
            supported ? l10n.supportThanksBody : l10n.supportBody,
            style: context.text.body.copyWith(color: c.inkSecondary),
          ),
        ),
        const SizedBox(height: Space.xxl),
        // Le seul trait de toute la page, là où elle change de sujet : ce qui
        // est donné au-dessus, ce qu'on peut donner en dessous.
        Appear(key: const ValueKey('rule'), rank: 3, child: Divider(height: 1, thickness: 1, color: c.line)),
        const SizedBox(height: Space.xl),
        Appear(key: const ValueKey('below'), rank: 4, child: _below(supported)),
      ],
    );
  }
}

/// La scène du haut : la plante de l'icône, posée sur une lueur.
///
/// C'était un disque plein de `sageSoft`, et le disque coupait net l'ombre au
/// sol de la plante : un bord franc, le seul de l'application. Une lueur qui
/// s'éteint dans le papier laisse l'objet flotter, comme sur la scène de
/// l'onboarding. Elle vire au rose une fois le soutien versé, et la plante
/// reçoit son sceau — le seul endroit où la page récompense quelque chose,
/// puisqu'aucune fonction ne le fait.
class _SupportHero extends StatelessWidget {
  const _SupportHero({required this.supported, required this.side});

  final bool supported;

  /// Côté de la plante, en points. La lueur s'en déduit.
  final double side;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = supported ? c.rose : c.sage;
    final glow = c.isDark ? 0.30 : 0.22;
    final halo = side * 1.5;
    return ExcludeSemantics(
      child: SizedBox(
        height: halo,
        child: Center(
          child: SizedBox(
            width: halo,
            height: halo,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.emphasis),
                    curve: Motion.easeOut,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Trois arrêts plutôt que deux : une lueur qui décroît
                      // linéairement se voit comme un cône.
                      gradient: RadialGradient(
                        colors: [tint.withValues(alpha: glow), tint.withValues(alpha: glow * 0.42), tint.withValues(alpha: 0)],
                        stops: const [0.0, 0.56, 1.0],
                      ),
                    ),
                  ),
                ),
                // La plante de l'icône : celle qui a poussé sur le premier
                // écran de l'onboarding, et qui est déjà debout quand on
                // arrive ici. Depuis les réglages, sur un lancement neuf, elle
                // pousse une fois.
                GrowingPlant(side: side),
                if (supported) Positioned(right: halo * 0.08, bottom: halo * 0.12, child: const _Seal()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le sceau de qui a soutenu : un galet de terre rose, posé au pied de la
/// plante. Il se pose au ressort — c'est le seul instant de la page qui
/// célèbre quelque chose, il a le droit de rebondir.
class _Seal extends StatelessWidget {
  const _Seal();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Motion.of(context, Motion.emphasis),
      curve: Motion.spring,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: ClayBox(
        color: c.roseSoft,
        shape: const ClayShape.blob(2),
        depth: ClayDepth.deep,
        width: 46,
        height: 46,
        alignment: Alignment.center,
        child: Icon(CupertinoIcons.heart_fill, size: 20, color: c.rose),
      ),
    );
  }
}

/// La proposition : combien, et le bouton.
///
/// Le montant est tracé à la main, à la taille du titre, et sa précision se
/// pose à côté sur la même ligne de base — un prix écrit sur une étiquette de
/// pot, pas un tarif au bas d'un bouton. Il n'y a pas de carte autour : rien
/// à encadrer, la page entière est déjà la proposition.
class _Offer extends StatelessWidget {
  const _Offer({required this.price, required this.busy, required this.onGive, required this.onRestore});

  final String price;
  final bool busy;
  final VoidCallback onGive;

  /// Retrouver un soutien déjà versé : nouvel appareil, réinstallation.
  ///
  /// Proposé partout où l'achat l'est, y compris à l'onboarding : l'achat est
  /// un non consommable, donc restaurable, et la règle 3.1.1 de l'App Store
  /// demande un mécanisme de restauration. C'est aussi là qu'il sert le plus
  /// — quelqu'un qui change de téléphone repasse par l'onboarding avant de
  /// voir les réglages.
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(price, style: context.text.display.copyWith(color: c.terracotta)),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(l10n.supportOnce, style: context.text.callout.copyWith(color: c.inkSecondary))),
          ],
        ),
        const SizedBox(height: Space.lg),
        FloraButton(label: l10n.supportGive, expand: true, loading: busy, onPressed: onGive),
        const SizedBox(height: Space.xs),
        Text(l10n.supportNothingLocked, style: context.text.caption.copyWith(color: c.inkTertiary)),
        const SizedBox(height: Space.xs),
        FloraButton(
          label: l10n.supportRestore,
          style: FloraButtonStyle.ghost,
          size: FloraButtonSize.small,
          expand: true,
          onPressed: busy ? null : onRestore,
        ),
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
    return Text(message, style: context.text.callout.copyWith(color: c.inkSecondary));
  }
}
