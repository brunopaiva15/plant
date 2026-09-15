import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/connectivity.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/support/support_service.dart';
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
/// **Une seule pièce d'argile**, et rien d'empilé autour. Deux versions ont
/// échoué avant celle-ci, et pour la même raison : une illustration, un titre,
/// une phrase, un bouton — le squelette de tous les écrans du monde, qu'on
/// l'habille de tuiles à icônes ou qu'on le dégraisse jusqu'à l'os. Ce n'est
/// pas la densité qui clochait, c'est la structure.
///
/// Ici la page n'est pas une page : c'est un objet qu'on tend. Une pièce
/// modelée porte tout — le titre, ce qui est ouvert, le montant, le bouton —
/// et la plante n'y est pas rangée : elle est **posée dessus**, débordant du
/// coin, comme on laisse une plante sur un coin de table. C'est ce
/// débordement qui fait la différence entre un objet et une carte à image.
/// Ne reste sur le papier, sous la pièce, que ce qui ne lui appartient pas :
/// retrouver un soutien déjà versé.
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

  /// Le bas de la pièce : la proposition, ou ce qui l'empêche — et si la
  /// restauration a lieu d'être en dessous.
  ///
  /// Une fois le soutien versé il n'y a plus rien à demander, et c'est la
  /// phrase du haut qui revient là en plus petit : la pièce se ferme sur ce
  /// qu'elle est venue dire plutôt que sur un blanc.
  (Widget, bool) _below(bool supported) {
    final l10n = context.l10n;
    final c = context.colors;
    final quiet = context.text.callout.copyWith(color: c.inkSecondary);
    if (supported) return (Text(l10n.supportBody, style: quiet), false);
    // L'achat passe par le magasin, et le magasin par le réseau : hors ligne
    // le bouton échouerait au moment de payer.
    if (!ref.watch(isOnlineProvider)) return (Text(l10n.offlineSupport, style: quiet), false);
    return ref.watch(supportOfferProvider).when(
      loading: () => (const Center(child: AdaptiveProgress()), false),
      error: (_, _) => (Text(l10n.supportUnavailable, style: quiet), false),
      data: (offer) => offer == null
          ? (Text(l10n.supportUnavailable, style: quiet), false)
          : (_Offer(price: offer.price, busy: _busy, onGive: _give), true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final supported = ref.watch(preferencesProvider.select((p) => p.hasSupported));
    final compact = widget.compact;
    final (below, restorable) = _below(supported);
    // La plante déborde du haut de la pièce : ce qui en dépasse pousse la
    // pièce vers le bas, ce qui y entre creuse sa marge haute.
    final plant = compact ? 104.0 : 124.0;
    final over = plant * 0.56;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: compact ? Space.xs : Space.md),
        Appear(
          key: const ValueKey('piece'),
          child: Stack(
            // La plante sort du cadre par le haut et par la droite : sans
            // cela le Stack la rognerait au ras de la pièce.
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(top: over),
                child: _Piece(supported: supported, topRoom: plant - over, below: below),
              ),
              Positioned(
                top: 0,
                right: Space.xxs,
                child: ExcludeSemantics(child: _Plant(supported: supported, side: plant)),
              ),
            ],
          ),
        ),
        // Sur le papier, sous la pièce : ce qui n'appartient pas à la
        // proposition. Retrouver un soutien déjà versé n'est pas l'accepter.
        if (restorable) ...[
          const SizedBox(height: Space.xs),
          Appear(
            key: const ValueKey('restore'),
            rank: 1,
            child: FloraButton(
              label: l10n.supportRestore,
              style: FloraButtonStyle.ghost,
              size: FloraButtonSize.small,
              expand: true,
              onPressed: _busy ? null : _restore,
            ),
          ),
        ],
      ],
    );
  }
}

/// La pièce : tout ce que la page a à dire, dans une seule forme modelée.
///
/// De l'argile crue — `surfaceMuted`, un cran sous le papier — et un relief
/// franc. Elle a été en terre cuite pâle, et c'était une erreur de sens
/// autant que de goût : dans cette application la terre cuite est la couleur
/// du retard et de l'urgence, et un grand aplat rouge derrière une demande
/// se lit comme un avertissement. `surfaceMuted` ne dit rien d'autre que la
/// matière, laisse le vert du bouton et la terre cuite du montant ressortir,
/// et rentre dans le contrat de contraste — les trois encres y tiennent
/// 4,5:1, ce que le pastel de terre cuite ne faisait pas.
class _Piece extends StatelessWidget {
  const _Piece({required this.supported, required this.topRoom, required this.below});

  final bool supported;

  /// Ce que la plante occupe à l'intérieur, en haut : la marge haute la
  /// dégage, sans quoi le titre lui passerait dessous.
  final double topRoom;

  final Widget below;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return ClayBox(
      color: c.surfaceMuted,
      shape: const ClayShape.rounded(Radii.xl),
      depth: ClayDepth.deep,
      padding: EdgeInsets.fromLTRB(Space.xl, topRoom + Space.md, Space.xl, Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(supported ? l10n.supportThanksTitle : l10n.supportTitle, style: context.text.display),
          const SizedBox(height: Space.sm),
          Text(
            supported ? l10n.supportThanksBody : l10n.supportBody,
            style: context.text.body.copyWith(color: c.inkSecondary),
          ),
          // Pourquoi donner. La page disait ce qui est gratuit sans jamais
          // dire ce que cela coûte à quelqu'un : les trois « aucun » du
          // paragraphe au-dessus sont exactement ce qui prive l'application
          // de revenu, et c'est là tout l'argument. En pleine encre, parce
          // que c'est la phrase qui compte.
          if (!supported) ...[
            const SizedBox(height: Space.md),
            Text(l10n.supportWhy, style: context.text.body),
          ],
          const SizedBox(height: Space.xxxl),
          below,
        ],
      ),
    );
  }
}

/// La plante posée sur le coin de la pièce, et le sceau de qui a soutenu.
class _Plant extends StatelessWidget {
  const _Plant({required this.supported, required this.side});

  final bool supported;
  final double side;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // La plante de l'icône : celle qui a poussé sur le premier écran de
          // l'onboarding, et qui est déjà debout quand on arrive ici. Depuis
          // les réglages, sur un lancement neuf, elle pousse une fois.
          GrowingPlant(side: side),
          if (supported) Positioned(right: 0, bottom: side * 0.06, child: const _Seal()),
        ],
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

/// La proposition, au bas de la pièce : combien, et le bouton.
///
/// Le montant est tracé à la main, à la taille du titre, et sa précision se
/// pose à côté sur la même ligne de base — un prix écrit sur une étiquette de
/// pot, pas un tarif au bas d'un bouton.
class _Offer extends StatelessWidget {
  const _Offer({required this.price, required this.busy, required this.onGive});

  final String price;
  final bool busy;
  final VoidCallback onGive;

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
            Text(
              price,
              style: context.text.display.copyWith(
                color: c.terracotta,
                // Une lueur d'un point sous les chiffres : le montant paraît
                // pressé dans la pâte plutôt que posé dessus. L'ombre est
                // derrière la glyphe, le contraste du chiffre ne bouge pas.
                shadows: [Shadow(color: Colors.white.withValues(alpha: c.isDark ? 0.07 : 0.5), offset: const Offset(0, 1))],
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(l10n.supportOnce, style: context.text.callout.copyWith(color: c.inkSecondary))),
          ],
        ),
        const SizedBox(height: Space.lg),
        // Le bouton ferme la pièce. Une mention en dessous — « le soutien ne
        // déverrouille rien » — était la dernière chose lue avant le geste, et
        // c'est un avertissement : la phrase du haut dit déjà que tout est
        // ouvert, il n'y a rien à déverrouiller et rien à rappeler.
        FloraButton(label: l10n.supportGive, expand: true, loading: busy, onPressed: onGive),
      ],
    );
  }
}
