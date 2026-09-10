import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/identification/cascade_identifier.dart';

/// Réglages de l'identification. Rien à configurer : le modèle est embarqué
/// et le service en ligne est fourni avec l'application. L'utilisateur décide
/// seulement si ses photos ont le droit de sortir de l'appareil.
class IdentificationSettingsScreen extends ConsumerWidget {
  const IdentificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identifier = ref.watch(plantIdentifierProvider);
    final l10n = context.l10n;
    final configured = ref.watch(plantIdentifierProvider).isConfigured;
    final metrics = ref.watch(identificationMetricsStoreProvider).read();
    final model = ref.watch(localModelStatusProvider);
    final status = model.asData?.value;
    return FloraPage(
      title: l10n.identificationSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FloraCard(
            child: Row(
              children: [
                EmojiTile(emoji: configured ? '🔬' : '🔒', background: configured ? context.colors.sageSoft : null),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(configured ? l10n.identificationEnabled : l10n.identificationDisabled, style: context.text.title3)),
              ],
            ),
          ),
          // Chargé, le modèle se présente lui-même et cela vaut diagnostic.
          // Sinon il faut encore distinguer « le modèle a hésité » de « le
          // modèle ne s'est jamais chargé » : les deux donnent zéro
          // identification locale.
          if (status != null && status.ready)
            _IrisSection(status: status)
          else ...[
            const SizedBox(height: Space.sm),
            FloraCard(
              child: Row(
                children: [
                  EmojiTile(emoji: model.isLoading ? '⏳' : '⚠️'),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      model.isLoading ? l10n.modelLoading : l10n.modelMissing(AppConfig.modelName),
                      style: context.text.callout,
                    ),
                  ),
                ],
              ),
            ),
            if (status?.error != null) ...[
              const SizedBox(height: Space.xs),
              // Le message natif, brut : c'est lui qui distingue un asset
              // absent d'une bibliothèque non liée, et il est copiable.
              SelectableText(status!.error!, style: context.text.caption),
            ],
          ],
          const SizedBox(height: Space.md),
          Text(l10n.identificationHint(AppConfig.modelName), style: context.text.callout),
          const SizedBox(height: Space.lg),
          FloraGroup(
            children: [
              FloraListRow(
                title: l10n.identificationFallback,
                trailing: AdaptiveSwitch(
                  value: ref.watch(preferencesProvider.select((p) => p.identificationFallbackEnabled)),
                  onChanged: (v) => ref.read(preferencesProvider.notifier).setIdentificationFallbackEnabled(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(l10n.identificationFallbackHint(AppConfig.modelName), style: context.text.caption),
          const SizedBox(height: Space.sm),
          Text(l10n.identificationStats(metrics.local, metrics.localAccepted, metrics.remote), style: context.text.caption),
          if (identifier is CascadeIdentifier) ...[
            const SizedBox(height: Space.xxs),
            Text(l10n.onlineSearchesMonth(identifier.remoteUsedThisMonth, identifier.monthlyRemoteLimit), style: context.text.caption),
          ],
        ],
      ),
    );
  }
}

/// La section du modèle embarqué : sa marque, son nom, ce qu'il sait, et le
/// geste qui le rend meilleur.
///
/// Le nom et le compte d'espèces viennent du `model.json` livré avec les poids
/// (§ 0 de docs/09-plant-recognition.md), pas d'ici : livrer une v8 change la
/// section sans qu'on touche à cet écran.
class _IrisSection extends StatelessWidget {
  const _IrisSection({required this.status});

  final LocalModelStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    // Le code langue plutôt que l'étiquette complète : intl connaît « fr »
    // à coup sûr, « fr-CH » demanderait un repli.
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.irisSection, padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm)),
        FloraCard(
          color: c.sageSoft,
          depth: ClayDepth.deep,
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Décorative : le nom est écrit juste à côté.
                  const IrisMark(size: 64),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppConfig.modelDisplayName(status.version), style: context.text.title1),
                        const SizedBox(height: Space.xxs),
                        // Pleine encre : sur un fond de couleur, c'est la
                        // seule qui tienne AAA en contraste élevé. La
                        // hiérarchie se fait par la taille.
                        Text(l10n.irisTagline, style: context.text.callout.copyWith(color: c.ink)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.lg),
              // Ils plient plutôt que de se serrer : à 350 % de
              // grossissement, deux colonnes n'existent plus.
              Wrap(
                spacing: Space.xl,
                runSpacing: Space.md,
                children: [
                  _IrisFact(value: NumberFormat.decimalPattern(locale).format(status.speciesCount), label: l10n.irisSpeciesLabel),
                  _IrisFact(value: l10n.irisOfflineValue, label: l10n.irisOfflineLabel),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        // Quatorze points de top-1 pour zéro milliseconde de calcul
        // (§ 6.7 de docs/09-plant-recognition.md).
        FloraCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EmojiTile(emoji: '📷', variant: 2),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.irisTwoPhotosTitle, style: context.text.title3),
                    const SizedBox(height: Space.xxs),
                    Text(l10n.irisTwoPhotosBody(AppConfig.modelName), style: context.text.callout),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Un chiffre et ce qu'il compte, empilés.
class _IrisFact extends StatelessWidget {
  const _IrisFact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Fusionné : sans cela la synthèse vocale lit « 1 457 », puis
    // « espèces », comme deux éléments sans rapport.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: context.text.title2),
          // Vert plutôt que gris : sur le pastel, c'est l'accent que le
          // contrat de contraste tient déjà.
          Text(label, style: context.text.caption.copyWith(color: context.colors.sage)),
        ],
      ),
    );
  }
}
