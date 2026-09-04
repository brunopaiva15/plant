import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Saisit ou modifie le titre d'une photo. Retourne le texte, ou `null` si
/// l'utilisateur annule. Une chaîne vide efface le titre.
Future<String?> showPhotoLabelSheet(BuildContext context, {String? initial}) =>
    showFloraSheet<String>(context, builder: (_) => _PhotoLabelBody(initial: initial));

class _PhotoLabelBody extends StatefulWidget {
  const _PhotoLabelBody({this.initial});

  final String? initial;

  @override
  State<_PhotoLabelBody> createState() => _PhotoLabelBodyState();
}

class _PhotoLabelBodyState extends State<_PhotoLabelBody> {
  late final _controller = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.photoLabel),
          FloraTextField(
            controller: _controller,
            hint: l10n.photoLabelHint,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
          ),
          const SizedBox(height: Space.xl),
          FloraButton(label: l10n.save, expand: true, onPressed: () => Navigator.of(context).pop(_controller.text.trim())),
        ],
      ),
    );
  }
}

/// Ajoute une photo hébergée ailleurs, par son adresse web.
Future<void> showPhotoUrlSheet(BuildContext context, {required String plantId}) =>
    showFloraSheet<void>(context, builder: (_) => _PhotoUrlBody(plantId: plantId));

class _PhotoUrlBody extends ConsumerStatefulWidget {
  const _PhotoUrlBody({required this.plantId});

  final String plantId;

  @override
  ConsumerState<_PhotoUrlBody> createState() => _PhotoUrlBodyState();
}

class _PhotoUrlBodyState extends ConsumerState<_PhotoUrlBody> {
  final _url = TextEditingController();
  final _label = TextEditingController();
  bool _saving = false;
  bool _invalid = false;

  @override
  void dispose() {
    _url.dispose();
    _label.dispose();
    super.dispose();
  }

  /// Seules les adresses https sont acceptées : une image en http serait
  /// bloquée sur iOS et Android récents, autant le dire tout de suite.
  bool get _valid {
    final uri = Uri.tryParse(_url.text.trim());
    return uri != null && uri.isScheme('https') && uri.host.isNotEmpty;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_valid) {
      setState(() => _invalid = true);
      Haptics.warning();
      return;
    }
    setState(() => _saving = true);
    await ref.read(photoRepositoryProvider).addFromUrl(plantId: widget.plantId, url: _url.text.trim(), label: _label.text.trim());
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.addPhotoByUrl),
          FloraTextField(
            controller: _url,
            hint: l10n.photoUrlHint,
            autofocus: true,
            keyboardType: TextInputType.url,
            textCapitalization: TextCapitalization.none,
            onChanged: (_) => setState(() => _invalid = false),
          ),
          if (_invalid) ...[
            const SizedBox(height: Space.xs),
            Text(l10n.photoUrlInvalid, style: context.text.caption.copyWith(color: context.colors.danger)),
          ],
          const SizedBox(height: Space.sm),
          FloraTextField(controller: _label, hint: l10n.photoLabelHint),
          const SizedBox(height: Space.xl),
          FloraButton(label: l10n.add, expand: true, loading: _saving, onPressed: _url.text.trim().isEmpty ? null : _save),
        ],
      ),
    );
  }
}
