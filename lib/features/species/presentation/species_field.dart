import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/species/species_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/species/species_info.dart';

/// Champ « espèce » avec suggestions GBIF (noms scientifiques acceptés,
/// règne Plantae) : un tap remplit le champ.
class SpeciesField extends ConsumerStatefulWidget {
  const SpeciesField({super.key, required this.controller, this.hint, this.onPicked});

  final TextEditingController controller;
  final String? hint;
  final ValueChanged<SpeciesSuggestion>? onPicked;

  @override
  ConsumerState<SpeciesField> createState() => _SpeciesFieldState();
}

class _SpeciesFieldState extends ConsumerState<SpeciesField> {
  Timer? _debounce;
  List<SpeciesSuggestion> _suggestions = const [];
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    _lastQuery = query;
    final lang = Localizations.localeOf(context).languageCode;

    // Le catalogue Auxine répond tout de suite ; GBIF vient en complément.
    final local = await _localSuggestions(query, lang);
    if (!mounted || _lastQuery != query) return;
    setState(() => _suggestions = _merge(local, const [], query));

    List<SpeciesSuggestion> remote = const [];
    try {
      remote = await ref.read(speciesServiceProvider).suggest(query, languageCode: lang);
    } catch (_) {}
    if (!mounted || _lastQuery != query) return;
    setState(() => _suggestions = _merge(local, remote, query));
  }

  /// Le catalogue intégré d'abord — trié à la main, puis étendu — classé par
  /// pertinence (nom courant de la langue, puis nom scientifique, famille).
  Future<List<SpeciesSuggestion>> _localSuggestions(String query, String lang) async {
    final seen = <String>{};
    final ranked = <({int rank, int source, String label, SpeciesSuggestion suggestion})>[];
    for (final e in SpeciesCatalog.search(query, languageCode: lang)) {
      if (seen.add(e.scientificName.toLowerCase())) {
        ranked.add((rank: e.relevance(query, lang), source: 0, label: e.commonName(lang).toLowerCase(), suggestion: e.toSuggestion(lang)));
      }
    }
    final index = await ref.read(speciesIndexProvider.future);
    for (final r in index.search(query, limit: 60, exclude: seen)) {
      if (seen.add(r.scientificName.toLowerCase())) {
        ranked.add((rank: r.relevance(query, lang), source: 1, label: r.commonName(lang).toLowerCase(), suggestion: r.toSuggestion(lang)));
      }
    }
    ranked.sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      if (byRank != 0) return byRank;
      final bySource = a.source.compareTo(b.source);
      if (bySource != 0) return bySource;
      return a.label.compareTo(b.label);
    });
    return [for (final r in ranked) r.suggestion];
  }

  /// Le catalogue d'abord, GBIF ensuite, sans doublon, et sans proposer le
  /// nom déjà tapé en entier.
  List<SpeciesSuggestion> _merge(List<SpeciesSuggestion> local, List<SpeciesSuggestion> remote, String query) {
    final typed = query.trim().toLowerCase();
    final seen = <String>{};
    final out = <SpeciesSuggestion>[];
    for (final s in [...local, ...remote]) {
      final key = s.scientificName.toLowerCase();
      if (key == typed) continue;
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  void _pick(SpeciesSuggestion s) {
    widget.controller.text = s.scientificName;
    setState(() => _suggestions = const []);
    widget.onPicked?.call(s);
  }

  Future<void> _browse() async {
    final q = widget.controller.text.trim();
    final picked = await context.push<SpeciesSuggestion>(Uri(path: Routes.speciesPicker, queryParameters: q.isEmpty ? null : {'q': q}).toString());
    if (picked != null && mounted) _pick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: FloraTextField(controller: widget.controller, hint: widget.hint ?? l10n.speciesHint, onChanged: _onChanged, textInputAction: TextInputAction.done)),
            const SizedBox(width: Space.xs),
            FloraIconButton(icon: CupertinoIcons.list_bullet, semanticLabel: l10n.speciesBrowse, onPressed: _browse, size: 48),
          ],
        ),
        AnimatedSize(
          duration: Motion.of(context, Motion.standard),
          curve: Motion.easeOut,
          alignment: Alignment.topLeft,
          child: _suggestions.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      for (final s in _suggestions.take(5))
                        FloraChip(label: s.commonName == null ? s.scientificName : '${s.scientificName} · ${s.commonName}', onTap: () => _pick(s)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
