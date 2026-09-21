import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/flora_theme.dart';

/// Efface le bas d'une zone défilante tant qu'il reste du contenu dessous.
///
/// Une page que la barre du bas referme s'arrête net sur elle : le dernier
/// élément visible touche le bord, aligné au pixel près, et rien ne distingue
/// une page qui se termine là d'une page qui continue. C'est ce qui arrivait
/// au diagnostic, où les observations — ce qui affine le plus l'analyse —
/// vivaient sous un champ de symptômes qui avait tout l'air d'être le dernier.
///
/// Le fondu répond à cela sans rien ajouter à la page : le contenu se dissout
/// dans le fond au lieu d'être coupé, et il disparaît une fois le bas atteint.
/// Il se règle sur ce qui reste à défiler, si bien que les derniers points du
/// geste l'effacent au lieu de l'éteindre d'un coup.
///
/// C'est une couche teintée du fond, non un masque d'opacité (`HeaderFade`) :
/// la page porte la même couleur de part et d'autre de la barre, le voile n'a
/// donc rien à trahir, et il évite un `saveLayer` par-dessus le viseur et sa
/// texture de caméra.
class ScrollFade extends StatefulWidget {
  const ScrollFade({super.key, required this.child, this.height = 36});

  /// Hauteur du fondu, en points.
  final double height;

  final Widget child;

  @override
  State<ScrollFade> createState() => _ScrollFadeState();
}

class _ScrollFadeState extends State<ScrollFade> {
  /// Force du fondu : 0 quand le bas est atteint, 1 tant qu'il reste au moins
  /// une hauteur de fondu à défiler.
  double _fade = 0;

  void _read(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical || !metrics.hasContentDimensions) return;
    final fade = (metrics.extentAfter / widget.height).clamp(0.0, 1.0);
    // Au centième près : le voile ne se redessine que sur les derniers points
    // du défilement, pas à chaque pixel de la page.
    if ((fade - _fade).abs() < 0.02 && fade != 0 && fade != 1) return;
    if (fade == _fade || !mounted) return;
    // Une mesure qui arriverait pendant la mise en page ne peut pas rebâtir
    // sur-le-champ : le voile suit d'une image, ce qui ne se voit pas.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && fade != _fade) setState(() => _fade = fade);
      });
      return;
    }
    setState(() => _fade = fade);
  }

  /// Les défilements des listes imbriquées — les rangées de choix d'une carte
  /// — ne parlent pas du bas de la page : seul le niveau zéro compte.
  bool _onScroll(Notification notification) {
    if (notification is ScrollNotification && notification.depth == 0) {
      _read(notification.metrics);
    } else if (notification is ScrollMetricsNotification && notification.depth == 0) {
      _read(notification.metrics);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onScroll,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        // Le contenu garde les contraintes de la page : la zone défilante
        // occupe exactement la place qu'elle avait sans le fondu.
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            if (_fade > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: widget.height,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        // Une montée adoucie, comme au fondu d'en-tête : l'œil
                        // ne voit pas où le voile commence.
                        colors: [
                          c.canvas.withValues(alpha: 0),
                          c.canvas.withValues(alpha: 0.22 * _fade),
                          c.canvas.withValues(alpha: 0.68 * _fade),
                          c.canvas.withValues(alpha: _fade),
                        ],
                        stops: const [0, 0.35, 0.7, 1],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
