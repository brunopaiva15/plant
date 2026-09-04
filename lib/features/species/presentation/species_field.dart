import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
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
    List<SpeciesSuggestion> results = const [];
    try {
      results = await ref.read(speciesServiceProvider).suggest(query, languageCode: lang);
    } catch (_) {}
    if (!mounted || _lastQuery != query) return;
    // Pas de suggestion si l'utilisateur a déjà tapé exactement ce nom.
    setState(() => _suggestions = results.where((s) => s.scientificName.toLowerCase() != query.trim().toLowerCase()).toList());
  }

  void _pick(SpeciesSuggestion s) {
    widget.controller.text = s.scientificName;
    setState(() => _suggestions = const []);
    widget.onPicked?.call(s);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloraTextField(controller: widget.controller, hint: widget.hint ?? l10n.speciesHint, onChanged: _onChanged, textInputAction: TextInputAction.done),
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
