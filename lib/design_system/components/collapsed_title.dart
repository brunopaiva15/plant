import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Dit à la barre quand le titre de la page est passé dessous.
///
/// Le guetteur ne dessine rien : il pose [title] dans [notifier] au
/// franchissement de [threshold], et le retire au retour en haut. C'est la
/// barre qui l'affiche — celle d'UIKit par `NativeActions.titleListenable`,
/// celle de Flutter en écoutant le même porteur.
///
/// « Passé dessous », et non « sorti de l'écran » : iOS bascule dès que le
/// titre glisse *sous* la barre, pas une fois qu'il a disparu. Une première
/// version guettait la sortie d'un sliver posé après le titre ; elle basculait
/// une hauteur de barre trop tard — un sliver ne sait pas qu'il *approche* du
/// bord, seulement qu'il l'a franchi. D'où la mesure sur la position de
/// défilement, où le seuil se dit d'avance.
///
/// À poser dans la liste qu'on défile — un `SliverToBoxAdapter` suffit : c'est
/// là que le guetteur trouve la position à lire.
class CollapsedTitleWatcher extends StatefulWidget {
  const CollapsedTitleWatcher({
    super.key,
    required this.notifier,
    required this.title,
    required this.threshold,
  });

  /// Ce que la barre montre : [title] une fois le seuil franchi, rien avant.
  final ValueNotifier<String> notifier;

  final String title;

  /// Le point de défilement où le titre de la page passe sous la barre.
  ///
  /// Une page à grand titre a le sien tout en haut, à hauteur fixe
  /// ([largeTitleCollapse]). Une fiche à photo le pose sous l'en-tête : son
  /// seuil se compte depuis la hauteur de l'image.
  final double threshold;

  /// Le repli du grand titre d'une page d'onglet, en points de défilement.
  static const double largeTitleCollapse = 52;

  @override
  State<CollapsedTitleWatcher> createState() => _CollapsedTitleWatcherState();
}

class _CollapsedTitleWatcherState extends State<CollapsedTitleWatcher> {
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _position)) return;
    _position?.removeListener(_relire);
    _position = position;
    _position?.addListener(_relire);
    _relire();
  }

  @override
  void didUpdateWidget(CollapsedTitleWatcher old) {
    super.didUpdateWidget(old);
    // Le nom d'une plante se corrige, une photo arrive et grandit l'en-tête :
    // ce que la barre montre est relu, jamais figé à la première image.
    if (old.title != widget.title || old.threshold != widget.threshold || old.notifier != widget.notifier) {
      _relire();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_relire);
    super.dispose();
  }

  void _relire() {
    final position = _position;
    final passe = position != null && position.hasPixels && position.pixels >= widget.threshold;
    final titre = passe ? widget.title : '';
    if (widget.notifier.value == titre) return;
    // Le guetteur est aussi relu depuis une construction — la sienne, quand la
    // page se redessine. Poser le titre là demanderait à la barre de se
    // reconstruire au milieu d'une construction, ce que Flutter refuse : on
    // attend alors la fin de l'image. Le défilement, lui, arrive entre deux
    // images et passe tout droit.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.notifier.value = titre;
      });
      return;
    }
    widget.notifier.value = titre;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
