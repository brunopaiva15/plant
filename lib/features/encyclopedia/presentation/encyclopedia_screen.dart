import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../../domain/species/species_info.dart';
import 'glossary_section.dart';
import 'problems_section.dart';
import 'species_section.dart';

/// Les trois rayons de l'encyclopédie.
enum EncyclopediaSection { problems, species, glossary }

/// L'encyclopédie : ce que l'application sait, lisible sans avoir de plante
/// ni de problème.
///
/// Ces listes existaient déjà, mais chacune n'apparaissait qu'au moment où
/// elle servait — la base des deux cents problèmes derrière un diagnostic, le
/// catalogue d'espèces derrière la création d'une plante, le vocabulaire des
/// fiches nulle part. Elles se lisent ici à froid, d'un bout à l'autre.
///
/// Rien n'est ajouté au passage : l'écran ne fait que montrer les actifs
/// embarqués. Une entrée qui manque manque dans la base, pas ici.
class EncyclopediaScreen extends ConsumerStatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  ConsumerState<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends ConsumerState<EncyclopediaScreen> {
  final _search = TextEditingController();

  EncyclopediaSection _section = EncyclopediaSection.problems;
  String _query = '';

  /// Filtres propres à un rayon : la famille d'un problème, la catégorie
  /// d'une espèce. Gardés en changeant de rayon — on y revient comme on l'a
  /// laissé.
  ProblemKind? _kind;
  SpeciesCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Changer de rayon vide la recherche : « oïdium » tapé dans les problèmes
  /// ne trouve aucune espèce, et une liste vide au premier coup d'œil se lit
  /// comme un catalogue vide.
  void _go(EncyclopediaSection section) {
    if (section == _section) return;
    setState(() {
      _section = section;
      _query = '';
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final hint = switch (_section) {
      EncyclopediaSection.problems => l10n.encyclopediaSearchProblems,
      EncyclopediaSection.species => l10n.speciesSearchHint,
      EncyclopediaSection.glossary => l10n.encyclopediaSearchGlossary,
    };
    final searchField = isCupertino(context)
        ? CupertinoSearchTextField(
            controller: _search,
            placeholder: hint,
            backgroundColor: c.surfaceMuted,
            style: context.text.body,
            onChanged: (q) => setState(() => _query = q),
          )
        : FloraTextField(
            controller: _search,
            hint: hint,
            prefix: Icon(CupertinoIcons.search, size: 20, color: c.inkTertiary),
            textCapitalization: TextCapitalization.none,
            onChanged: (q) => setState(() => _query = q),
          );

    return LargeTitlePage(
      title: l10n.encyclopediaTitle,
      searchField: searchField,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.xs, Space.page, Space.md),
            child: AdaptiveSegmented<EncyclopediaSection>(
              segments: {
                EncyclopediaSection.problems: l10n.encyclopediaProblems,
                EncyclopediaSection.species: l10n.encyclopediaSpecies,
                EncyclopediaSection.glossary: l10n.encyclopediaGlossary,
              },
              value: _section,
              onChanged: _go,
            ),
          ),
        ),
        switch (_section) {
          EncyclopediaSection.problems => ProblemsSlivers(
              query: _query,
              kind: _kind,
              onKind: (k) => setState(() => _kind = k),
            ),
          EncyclopediaSection.species => SpeciesSlivers(
              query: _query,
              category: _category,
              onCategory: (cat) => setState(() => _category = cat),
            ),
          EncyclopediaSection.glossary => GlossarySlivers(query: _query),
        },
      ],
    );
  }
}

/// Le mobilier commun aux rayons : la bande de puces horizontale, pour les
/// familles de problèmes et les catégories d'espèces.
class EncyclopediaFilterRow<T> extends StatelessWidget {
  const EncyclopediaFilterRow({super.key, required this.options, required this.value, required this.onChanged});

  /// `null` en tête : « tout ».
  final List<(T?, String)> options;
  final T? value;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.page),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
        itemBuilder: (context, i) {
          final (option, label) = options[i];
          return FloraChip(
            label: label,
            selected: value == option,
            // Retoucher la puce allumée revient à « tout » ; celle de
            // « tout » ne se décoche pas, elle est déjà l'absence de filtre.
            onTap: () => onChanged(value == option && option != null ? null : option),
          );
        },
      ),
    );
  }
}

/// Le compte d'un rayon, sous les puces : « 200 problèmes ».
class EncyclopediaCount extends StatelessWidget {
  const EncyclopediaCount(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xs),
        child: Text(label, style: context.text.callout),
      );
}
