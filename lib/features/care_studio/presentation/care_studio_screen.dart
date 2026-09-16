import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/species/care_override_store.dart';
import '../../../data/species/catalog_care_guide.dart';
import '../../../data/species/species_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_override.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/species/species_info.dart';

/// Care Studio : corriger une fiche d'entretien sans toucher au code.
///
/// L'écran n'existe que pour les modérateurs. On cherche une espèce, on voit
/// la fiche que le catalogue résout, et on retouche un noyau de champs. La
/// retouche s'applique à cette fiche, sur cet appareil, et la provenance passe
/// à [CareMatch.edited] pour que la fiche ne fasse pas passer une correction
/// pour un fait d'espèce.
class CareStudioScreen extends ConsumerStatefulWidget {
  const CareStudioScreen({super.key});

  @override
  ConsumerState<CareStudioScreen> createState() => _CareStudioScreenState();
}

class _CareStudioScreenState extends ConsumerState<CareStudioScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _species;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FloraPage(
      title: l10n.careStudio,
      child: _species == null
          ? _searchView(context)
          : _Editor(
              key: ValueKey(_species),
              species: _species!,
              onBack: () => setState(() => _species = null),
            ),
    );
  }

  Widget _searchView(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final results = _query.trim().isEmpty ? const <SpeciesCatalogEntry>[] : SpeciesCatalog.search(_query).take(20).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.careStudioHint, style: context.text.callout),
        const SizedBox(height: Space.md),
        CupertinoTextField(
          controller: _search,
          placeholder: l10n.careStudioSearch,
          padding: const EdgeInsets.all(Space.md),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: Space.md),
        if (_query.trim().isEmpty)
          Text(l10n.careStudioPrompt, style: context.text.caption)
        else if (results.isEmpty)
          Text(l10n.careStudioEmpty, style: context.text.caption)
        else
          FloraGroup(
            children: [
              for (final entry in results)
                FloraListRow(
                  title: entry.commonName(lang),
                  subtitle: '${entry.scientificName} · ${entry.family}',
                  onTap: () => setState(() => _species = entry.scientificName),
                ),
            ],
          ),
      ],
    );
  }
}

/// Le noyau éditable d'une fiche : le catalogue d'un côté, la retouche de
/// l'autre, et l'écart entre les deux qui devient la retouche enregistrée.
class _Editor extends ConsumerStatefulWidget {
  const _Editor({super.key, required this.species, required this.onBack});

  final String species;
  final VoidCallback onBack;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  static const _summerDayValues = [1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 18, 21, 30];
  static const _temperatureValues = [-15, -10, -5, -2, 0, 2, 5, 8, 10, 12, 15];

  late final ResolvedCare _base;
  late LightNeed _light;
  late HumidityNeed _humidity;
  late CareDifficulty _difficulty;
  late int _summer;
  late int _winter;
  late int? _damage;

  @override
  void initState() {
    super.initState();
    // La fiche du catalogue, sans les retouches : c'est elle qui sert de
    // repère, pour montrer la valeur d'origine et calculer l'écart à garder.
    _base = const CatalogCareGuide().resolve(widget.species);
    final override = ref.read(careOverridesProvider)[CareOverrideStore.keyOf(widget.species)];
    _light = override?.light ?? _base.profile.light;
    _humidity = override?.humidity ?? _base.profile.humidity;
    _difficulty = override?.difficulty ?? _base.profile.difficulty;
    _summer = override?.wateringSummerDays ?? _base.profile.wateringSummerDays;
    _winter = override?.wateringWinterDays ?? _base.profile.wateringWinterDays;
    _damage = override?.damageBelowC ?? _base.profile.damageBelowC;
  }

  /// La retouche à garder : seuls les champs qui s'écartent du catalogue.
  CareOverride _diff() {
    final base = _base.profile;
    return CareOverride(
      light: _light == base.light ? null : _light,
      humidity: _humidity == base.humidity ? null : _humidity,
      difficulty: _difficulty == base.difficulty ? null : _difficulty,
      wateringSummerDays: _summer == base.wateringSummerDays ? null : _summer,
      wateringWinterDays: _winter == base.wateringWinterDays ? null : _winter,
      damageBelowC: _damage == base.damageBelowC ? null : _damage,
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    await ref.read(careOverridesProvider.notifier).save(widget.species, _diff());
    if (!mounted) return;
    ref.read(toastProvider.notifier).show(ToastData(message: l10n.careStudioSaved, emoji: '🌿'));
  }

  Future<void> _reset() async {
    final l10n = context.l10n;
    await ref.read(careOverridesProvider.notifier).save(widget.species, const CareOverride());
    if (!mounted) return;
    setState(() {
      _light = _base.profile.light;
      _humidity = _base.profile.humidity;
      _difficulty = _base.profile.difficulty;
      _summer = _base.profile.wateringSummerDays;
      _winter = _base.profile.wateringWinterDays;
      _damage = _base.profile.damageBelowC;
    });
    ref.read(toastProvider.notifier).show(ToastData(message: l10n.careStudioReset, emoji: '↩️'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final base = _base.profile;
    final days = {..._summerDayValues, _summer, _winter}.toList()..sort();
    final temperatures = {..._temperatureValues, ?_damage}.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.species, style: context.text.title3.copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(height: 2),
        Text(l10n.careMatchLabel(_base), style: context.text.caption),
        const SizedBox(height: Space.md),

        FloraGroup(
          children: [
            _Field(
              child: FloraChoice<LightNeed>(
                label: l10n.careLight,
                values: LightNeed.values,
                selected: _light,
                labelOf: l10n.lightName,
                onChanged: (v) => v == null ? null : setState(() => _light = v),
              ),
            ),
            _Field(
              child: FloraChoice<HumidityNeed>(
                label: l10n.careHumidity,
                values: HumidityNeed.values,
                selected: _humidity,
                labelOf: l10n.humidityName,
                onChanged: (v) => v == null ? null : setState(() => _humidity = v),
              ),
            ),
            _Field(
              child: FloraChoice<CareDifficulty>(
                label: l10n.careDifficulty,
                values: CareDifficulty.values,
                selected: _difficulty,
                labelOf: l10n.difficultyName,
                onChanged: (v) => v == null ? null : setState(() => _difficulty = v),
              ),
            ),
            _Field(
              child: FloraChoice<int>(
                label: l10n.careStudioWateringSummer,
                values: days,
                selected: _summer,
                labelOf: (n) => l10n.careEveryDays(n),
                onChanged: (v) => v == null ? null : setState(() => _summer = v),
              ),
            ),
            _Field(
              child: FloraChoice<int>(
                label: l10n.careStudioWateringWinter,
                values: days,
                selected: _winter,
                labelOf: (n) => l10n.careEveryDays(n),
                onChanged: (v) => v == null ? null : setState(() => _winter = v),
              ),
            ),
            _Field(
              child: FloraChoice<int>(
                label: l10n.careStudioDamageBelow,
                values: temperatures,
                selected: _damage,
                labelOf: (n) => '$n °C',
                onChanged: (v) => setState(() => _damage = v),
              ),
            ),
          ],
        ),

        const SizedBox(height: Space.md),
        Text(l10n.careEditedNote, style: context.text.caption.copyWith(color: c.inkSecondary)),
        const SizedBox(height: Space.lg),

        Row(
          children: [
            Expanded(
              child: FloraButton(
                label: l10n.careStudioSave,
                expand: true,
                onPressed: _save,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: FloraButton(
                label: l10n.careStudioReset,
                style: FloraButtonStyle.ghost,
                expand: true,
                onPressed: _reset,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        FloraButton(
          label: l10n.careStudioSearch,
          style: FloraButtonStyle.ghost,
          size: FloraButtonSize.small,
          onPressed: widget.onBack,
        ),
      ],
    );
  }
}

/// Le même gabarit d'encadrement que les champs de la fiche d'une plante.
class _Field extends StatelessWidget {
  const _Field({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
        child: child,
      );
}
