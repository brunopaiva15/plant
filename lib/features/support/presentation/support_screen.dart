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
/// Il se lit de haut en bas comme une démonstration en quatre temps : la
/// plante sur sa lueur, l'étiquette qui dit d'emblée que rien n'est exigé, le
/// relevé de ce qui est gratuit — quatre faits, pas une phrase de plus —, et
/// seulement ensuite le montant. Demander avant d'avoir montré ce qui est
/// donné, c'est ce que faisait la version précédente : un titre, deux lignes,
/// un bouton.
class SupportPitch extends ConsumerStatefulWidget {
  const SupportPitch({super.key, this.onDone, this.compact = false});

  /// Appelé une fois l'affaire réglée — soutien versé ou non. L'onboarding s'en
  /// sert pour passer à la suite ; l'écran des réglages n'en a pas besoin.
  final VoidCallback? onDone;

  /// La version courte, celle de l'onboarding : la scène rapetisse et le
  /// relevé s'efface.
  ///
  /// La page y partage la hauteur avec les points de progression, et le geste
  /// qui passe outre doit rester sous les yeux : quelqu'un qui vient
  /// d'installer l'application ne doit pas avoir à faire défiler pour trouver
  /// « Continuer sans ». Aux réglages, la page est venue pour elle-même et
  /// peut tout montrer.
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

  /// Ce qu'on propose, ou ce qui l'empêche : c'est le seul bloc de la page qui
  /// change d'un appareil à l'autre.
  Widget _ask(bool supported) {
    final l10n = context.l10n;
    if (supported) return const _Thanks();
    // L'achat passe par le magasin, et le magasin par le réseau : hors ligne
    // le bouton échouerait au moment de payer.
    if (!ref.watch(isOnlineProvider)) return OfflineBanner(message: l10n.offlineSupport, padding: EdgeInsets.zero);
    return ref.watch(supportOfferProvider).when(
      loading: () => const Center(child: AdaptiveProgress()),
      error: (_, _) => _Unavailable(message: l10n.supportUnavailable),
      data: (offer) => offer == null
          ? _Unavailable(message: l10n.supportUnavailable)
          : _GiveCard(price: offer.price, busy: _busy, onGive: _give, onRestore: _busy ? null : _restore),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final supported = ref.watch(preferencesProvider.select((p) => p.hasSupported));
    final compact = widget.compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: compact ? Space.xxs : Space.sm),
        Appear(
          key: const ValueKey('hero'),
          child: _SupportHero(supported: supported, side: compact ? 104.0 : 128.0),
        ),
        SizedBox(height: compact ? Space.xs : Space.md),
        // L'étiquette dit l'essentiel avant le titre : rien n'est exigé. Une
        // fois le soutien versé, elle n'a plus de raison d'être — c'est le
        // sceau posé sur la scène qui prend sa place.
        if (!supported) ...[
          Appear(key: const ValueKey('badge'), rank: 1, child: _OptionalBadge(label: l10n.supportOptional)),
          const SizedBox(height: Space.sm),
        ],
        Appear(
          key: const ValueKey('title'),
          rank: 2,
          child: Text(
            supported ? l10n.supportThanksTitle : l10n.supportTitle,
            style: context.text.display,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: Space.xs),
        Appear(
          key: const ValueKey('body'),
          rank: 3,
          child: Text(
            supported ? l10n.supportThanksBody : l10n.supportBody,
            style: context.text.body.copyWith(color: c.inkSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: Space.xl),
          const Appear(key: ValueKey('ledger'), rank: 4, child: _FreeLedger()),
        ],
        const SizedBox(height: Space.xl),
        Appear(key: const ValueKey('ask'), rank: 5, child: _ask(supported)),
        if (widget.onDone != null) ...[
          const SizedBox(height: Space.xs),
          Appear(
            key: const ValueKey('done'),
            rank: 6,
            child: FloraButton(
              label: supported ? l10n.continueLabel : l10n.supportNoThanks,
              style: FloraButtonStyle.ghost,
              expand: true,
              onPressed: widget.onDone,
            ),
          ),
        ],
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
                if (supported) Positioned(right: 0, bottom: halo * 0.14, child: const _Seal()),
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

/// L'étiquette au-dessus du titre : une pilule d'argile, le mot en petites
/// capitales. Elle dit ce qu'on attend de la page avant que la page ne le
/// demande.
class _OptionalBadge extends StatelessWidget {
  const _OptionalBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ClayBox(
        color: c.sageSoft,
        shape: const ClayShape.pill(),
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 6),
        child: Text(
          label.toUpperCase(),
          style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
      ),
    );
  }
}

/// Le relevé de ce qui est gratuit : quatre faits, quatre pièces.
///
/// « Toutes les fonctions sont gratuites » est une phrase, et une phrase se
/// survole. Quatre pièces qu'on lit d'un regard disent ce que l'application
/// ne fait pas payer, et c'est cela — pas le bouton — qui donne son sens au
/// geste d'après.
class _FreeLedger extends StatelessWidget {
  const _FreeLedger();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final perks = <Widget>[
      _Perk(icon: CupertinoIcons.square_grid_2x2_fill, tint: c.sage, soft: c.sageSoft, label: l10n.supportPerkFeatures, variant: 0),
      _Perk(icon: CupertinoIcons.eye_slash, tint: c.terracotta, soft: c.terracottaSoft, label: l10n.supportPerkNoAds, variant: 1),
      _Perk(icon: CupertinoIcons.repeat, tint: c.water, soft: c.waterSoft, label: l10n.supportPerkNoSubscription, variant: 2),
      _Perk(icon: CupertinoIcons.person, tint: c.sun, soft: c.sunSoft, label: l10n.supportPerkNoAccount, variant: 3),
    ];
    // À gros caractères, deux colonnes ne laissent plus de quoi écrire « Sans
    // abonnement » : les pièces se remettent en file.
    if (MediaQuery.textScalerOf(context).scale(13) > 19) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, perk) in perks.indexed) ...[
            if (i > 0) const SizedBox(height: Space.xs),
            perk,
          ],
        ],
      );
    }
    // Deux pièces d'une même rangée font la même hauteur, quelle que soit la
    // longueur de leur libellé : une carte plus courte que sa voisine se
    // verrait comme une erreur.
    Widget row(Widget left, Widget right) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: left), const SizedBox(width: Space.xs), Expanded(child: right)],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(perks[0], perks[1]),
        const SizedBox(height: Space.xs),
        row(perks[2], perks[3]),
      ],
    );
  }
}

/// Une pièce du relevé : le galet de couleur, et ce qui est gratuit.
class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.tint, required this.soft, required this.label, required this.variant});

  final IconData icon;
  final Color tint;
  final Color soft;
  final String label;

  /// Le gabarit du galet. Quatre formes, une par pièce : deux voisines ne
  /// sont jamais la même pâte.
  final int variant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Le galet suit le texte : à 300 %, un rond de 34 points à côté d'un
    // libellé de 40 aurait l'air d'une miette.
    final pebble = MediaQuery.textScalerOf(context).scale(34).clamp(34.0, 48.0);
    return MergeSemantics(
      child: FloraCard(
        padding: const EdgeInsets.all(Space.sm),
        child: Row(
          children: [
            ClayBox(
              color: soft,
              shape: ClayShape.blob(variant),
              width: pebble,
              height: pebble,
              alignment: Alignment.center,
              child: Icon(icon, size: pebble * 0.46, color: tint),
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(label, style: context.text.caption.copyWith(color: c.ink, fontWeight: FontWeight.w600), maxLines: 2),
            ),
          ],
        ),
      ),
    );
  }
}

/// La proposition : combien, une fois, et le bouton.
///
/// Le montant est écrit en grand et à la main, comme sur l'étiquette d'un
/// pot : un prix qu'on lit d'un coup d'œil, pas un tarif au bas d'un bouton.
/// La carte est en terre cuite, la couleur de ce qui compte dans
/// l'application, et le bouton reste vert, celui de l'action.
class _GiveCard extends StatelessWidget {
  const _GiveCard({required this.price, required this.busy, required this.onGive, required this.onRestore});

  final String price;
  final bool busy;
  final VoidCallback onGive;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FloraCard(
          color: c.terracottaSoft,
          depth: ClayDepth.deep,
          radius: Radii.xl,
          padding: const EdgeInsets.fromLTRB(Space.md, Space.lg, Space.md, Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.supportSettings, style: context.text.title3, textAlign: TextAlign.center),
              const SizedBox(height: Space.xs),
              Text(price, style: context.text.display.copyWith(color: c.terracotta), textAlign: TextAlign.center),
              Text(
                l10n.supportOnce,
                style: context.text.caption.copyWith(color: c.inkSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.md),
              FloraButton(label: l10n.supportGive, expand: true, loading: busy, onPressed: onGive),
              const SizedBox(height: Space.sm),
              // Sur une carte teintée, l'encre tertiaire tombe sous 4,5:1 :
              // c'est la secondaire qui porte la phrase.
              Text(
                l10n.supportNothingLocked,
                style: context.text.caption.copyWith(color: c.inkSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xxs),
        FloraButton(
          label: l10n.supportRestore,
          style: FloraButtonStyle.ghost,
          size: FloraButtonSize.small,
          expand: true,
          onPressed: onRestore,
        ),
      ],
    );
  }
}

/// Une fois le soutien versé, la carte du montant n'a plus lieu d'être : il
/// reste un mot, et le cœur qui le porte.
class _Thanks extends StatelessWidget {
  const _Thanks();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloraCard(
      color: c.roseSoft,
      radius: Radii.xl,
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.heart_fill, size: 16, color: c.rose),
          const SizedBox(width: Space.xs),
          Flexible(
            child: Text(
              context.l10n.supportAlready,
              style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Text(
        message,
        style: context.text.callout.copyWith(color: c.inkSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
