import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../application/release_notes.dart';
import 'whats_new_sheet.dart';

/// Ouvre la fenêtre des nouveautés au lancement, une fois, après une
/// installation ou une mise à jour.
///
/// Posée autour de la coquille à onglets plutôt que dans un écran : c'est là
/// que l'application atterrit une fois l'onboarding passé, et la fenêtre
/// n'appartient à aucun des quatre onglets.
///
/// Le contrôle ne rend rien : il laisse passer son enfant tel quel, et ne
/// coûte qu'un appel au premier rendu. [WhatsNew.take] fait le reste — c'est
/// lui qui décide, et lui qui s'en souvient.
class WhatsNewGate extends ConsumerStatefulWidget {
  const WhatsNewGate({super.key, required this.child});

  final Widget child;

  /// Le temps de l'animation d'ouverture (1,64 s), et un peu de marge.
  static const delay = Duration(milliseconds: 2200);

  @override
  ConsumerState<WhatsNewGate> createState() => _WhatsNewGateState();
}

class _WhatsNewGateState extends ConsumerState<WhatsNewGate> {
  bool _asked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Après l'animation d'ouverture, et non à la première image : la fenêtre
    // montait sous le pot qui cligne, et on ne la voyait qu'arrivée.
    _timer = Timer(WhatsNewGate.delay, _open);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    if (_asked || !mounted) return;
    // Un lien profond — un QR scanné depuis l'appareil photo du système —
    // ouvre une fiche par-dessus la coquille avant même la première image.
    // Il a été demandé, pas nous : on lui laisse l'écran. Et on ne consomme
    // rien au passage, sans quoi la nouveauté serait perdue pour de bon : elle
    // attendra simplement le lancement suivant.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _asked = true;
    final note = await ref.read(whatsNewProvider).take(releaseNotes(context.l10n));
    if (note == null || !mounted) return;
    await showWhatsNew(context, note);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
