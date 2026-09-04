import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/species/species_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/species/species_info.dart';
import '../../plants/application/plant_providers.dart';

/// Sélecteur d'espèce : espèces déjà dans le jardin, catalogue intégré par
/// catégorie (hors ligne), puis la base GBIF complète en défilement infini.
/// Retourne la [SpeciesSuggestion] choisie, ou `null`.
class SpeciesPickerScreen extends ConsumerStatefulWidget {
  const SpeciesPickerScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SpeciesPickerScreen> createState() => _SpeciesPickerScreenState();
}

class _SpeciesPickerScreenState extends ConsumerState<SpeciesPickerScreen> {
  late final TextEditingController _search = TextEditingController(text: widget.initialQuery);
  final _scroll = ScrollController();
  Timer? _debounce;
  SpeciesCategory? _category;

  // Résultats GBIF pour la requête courante.
  String _query = '';
  List<SpeciesSuggestion> _remote = const [];
  bool _loading = false;
  bool _error = false;
  bool _end = true;
  int? _total;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    if (widget.initialQuery.trim().length >= 2) _onChanged(widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_end || _loading || _query.isEmpty) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _query = '';
        _remote = const [];
        _end = true;
        _total = null;
        _error = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _startSearch(q));
  }

  Future<void> _startSearch(String q) async {
    setState(() {
      _query = q;
      _remote = const [];
      _loading = true;
      _error = false;
      _end = false;
      _total = null;
    });
    await _fetch(q, 0);
  }

  Future<void> _loadMore() => _fetch(_query, _remote.length);

  Future<void> _fetch(String q, int offset) async {
    setState(() => _loading = true);
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final page = await ref.read(speciesServiceProvider).search(q, offset: offset, limit: 30, languageCode: lang);
      if (!mounted || _query != q) return;
      final seen = _remote.map((s) => s.scientificName.toLowerCase()).toSet();
      setState(() {
        _remote = [..._remote, ...page.results.where((s) => seen.add(s.scientificName.toLowerCase()))];
        _end = page.endOfRecords;
        _total = page.total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || _query != q) return;
      setState(() {
        _loading = false;
        _error = true;
        _end = true;
      });
    }
  }

  void _pick(SpeciesSuggestion s) {
    Haptics.selection();
    context.pop(s);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final raw = _search.text.trim();
    final searching = raw.length >= 2;

    // Espèces déjà utilisées dans le jardin.
    final plants = ref.watch(plantSummariesProvider(const PlantFilter())).value ?? const [];
    final inGarden = <String>{};
    for (final p in plants) {
      final s = p.plant.speciesName?.trim();
      if (s != null && s.isNotEmpty) inGarden.add(s);
    }
    final gardenList = inGarden.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final gardenFiltered = searching ? gardenList.where((s) => s.toLowerCase().contains(raw.toLowerCase())).toList() : gardenList;

    final catalog = (searching ? SpeciesCatalog.search(raw) : SpeciesCatalog.byCategory(_category)).toList()
      ..sort((a, b) => a.commonName(lang).toLowerCase().compareTo(b.commonName(lang).toLowerCase()));
    final catalogNames = catalog.map((e) => e.scientificName.toLowerCase()).toSet();
    final remote = _remote.where((s) => !catalogNames.contains(s.scientificName.toLowerCase())).toList();

    final searchField = isCupertino(context)
        ? CupertinoSearchTextField(controller: _search, placeholder: l10n.speciesSearchHint, onChanged: _onChanged, autofocus: widget.initialQuery.isEmpty)
        : FloraTextField(controller: _search, hint: l10n.speciesSearchHint, onChanged: _onChanged, prefix: Icon(CupertinoIcons.search, size: 20, color: c.inkTertiary), autofocus: widget.initialQuery.isEmpty);

    final categories = <(SpeciesCategory?, String)>[
      (null, l10n.speciesCatAll),
      (SpeciesCategory.indoor, l10n.speciesCatIndoor),
      (SpeciesCategory.succulent, l10n.speciesCatSucculent),
      (SpeciesCategory.herb, l10n.speciesCatHerb),
      (SpeciesCategory.vegetable, l10n.speciesCatVegetable),
      (SpeciesCategory.fruit, l10n.speciesCatFruit),
      (SpeciesCategory.flower, l10n.speciesCatFlower),
      (SpeciesCategory.tree, l10n.speciesCatTree),
    ];

    final children = <Widget>[
      Padding(padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.sm), child: searchField),
      if (!searching)
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
            itemBuilder: (context, i) {
              final (cat, label) = categories[i];
              return FloraChip(label: label, selected: _category == cat, onTap: () => setState(() => _category = cat));
            },
          ),
        ),
      if (gardenFiltered.isNotEmpty) ...[
        SectionHeader(title: l10n.speciesInGarden, padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.sm)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          child: FloraGroup(
            children: [
              for (final name in gardenFiltered)
                FloraListRow(
                  leading: const Text('🪴', style: TextStyle(fontSize: 18)),
                  title: SpeciesCatalog.find(name)?.commonName(lang) ?? name,
                  subtitle: name,
                  dense: true,
                  chevron: false,
                  onTap: () => _pick(SpeciesCatalog.find(name)?.toSuggestion(lang) ?? SpeciesSuggestion(key: 0, scientificName: name)),
                ),
            ],
          ),
        ),
      ],
      if (catalog.isNotEmpty) ...[
        SectionHeader(title: l10n.speciesCommonList, padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.sm)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          child: FloraGroup(
            children: [
              for (final e in catalog)
                FloraListRow(
                  leading: Text(_emojiFor(e.category), style: const TextStyle(fontSize: 18)),
                  title: e.commonName(lang),
                  subtitle: '${e.scientificName} · ${e.family}',
                  dense: true,
                  chevron: false,
                  onTap: () => _pick(e.toSuggestion(lang)),
                ),
            ],
          ),
        ),
      ],
      if (searching) ...[
        SectionHeader(
          title: l10n.speciesGbifResults,
          padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.sm),
          trailing: _total == null ? null : Text(l10n.speciesGbifCount(_total!), style: context.text.caption),
        ),
        if (_error)
          Padding(padding: const EdgeInsets.symmetric(horizontal: Space.page), child: EmptyState(emoji: '📡', title: l10n.speciesOffline, compact: true))
        else if (remote.isEmpty && !_loading && _query.isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: Space.page), child: EmptyState(emoji: '🌱', title: l10n.speciesNoResults, compact: true))
        else if (remote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: FloraGroup(
              children: [
                for (final s in remote)
                  FloraListRow(
                    leading: const Text('🌿', style: TextStyle(fontSize: 18)),
                    title: s.commonName ?? s.scientificName,
                    subtitle: s.commonName == null ? (s.family ?? '') : '${s.scientificName}${s.family == null ? '' : ' · ${s.family}'}',
                    dense: true,
                    chevron: false,
                    onTap: () => _pick(s),
                  ),
              ],
            ),
          ),
        if (_loading) const Padding(padding: EdgeInsets.all(Space.lg), child: Center(child: AdaptiveProgress())),
        const SizedBox(height: Space.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          child: FloraButton(
            label: l10n.speciesUseText(raw),
            style: FloraButtonStyle.secondary,
            expand: true,
            onPressed: () => _pick(SpeciesSuggestion(key: 0, scientificName: raw)),
          ),
        ),
      ],
      const SizedBox(height: Space.huge),
    ];

    return FloraPage(
      title: l10n.speciesPickerTitle,
      scrollable: false,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(top: Space.sm),
        children: children,
      ),
    );
  }

  static String _emojiFor(SpeciesCategory c) => switch (c) {
        SpeciesCategory.indoor => '🪴',
        SpeciesCategory.succulent => '🌵',
        SpeciesCategory.herb => '🌿',
        SpeciesCategory.vegetable => '🥕',
        SpeciesCategory.fruit => '🍋',
        SpeciesCategory.flower => '🌸',
        SpeciesCategory.tree => '🌳',
      };
}
