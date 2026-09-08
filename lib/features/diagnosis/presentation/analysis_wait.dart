import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../problems/presentation/problem_kind_icon.dart';

/// L'attente de l'analyse : la photo au centre dans son propre halo, et les
/// quatre familles de problèmes qui gravitent autour.
///
/// C'est la photo de l'utilisateur qu'on regarde, pas une illustration :
/// l'attente porte sur cette plante-là, et le halo est son propre flou, ce
/// qui donne à l'écran la couleur de la photo sans rien y ajouter.
///
/// Les quatre symboles disent aussi ce que la machine cherche — un trouble,
/// un ravageur, une maladie, un dépôt — plutôt que de faire tourner une roue
/// qui ne dit rien. Avec « réduire les animations », tout se pose.
class AnalysisWait extends StatefulWidget {
  const AnalysisWait({super.key, required this.photo, this.side = 260});

  /// La photo analysée. Posée deux fois : nette au centre, floue derrière.
  /// Le même fournisseur d'image, donc un seul décodage.
  final Widget photo;

  /// Côté de la scène, en points.
  final double side;

  /// Durée d'un tour complet. Lente : on attend, on ne s'agite pas.
  static const Duration period = Duration(seconds: 14);

  @override
  State<AnalysisWait> createState() => _AnalysisWaitState();
}

class _AnalysisWaitState extends State<AnalysisWait> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  /// Avancement de la ronde, en tours.
  double _turns = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (!MediaQuery.disableAnimationsOf(context)) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
      setState(() => _turns = 0);
    }
  }

  void _tick(Duration elapsed) {
    setState(() => _turns = elapsed.inMicroseconds / AnalysisWait.period.inMicroseconds);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final side = widget.side;
    final photo = side * 0.49;
    // L'orbite est une ellipse écrasée : vue de face ce serait un cercle, et
    // les symboles passeraient au-dessus et au-dessous de la photo plutôt
    // qu'autour d'elle.
    final rx = side * 0.40;
    final ry = side * 0.165;

    final derriere = <Widget>[];
    final devant = <Widget>[];
    for (final (i, kind) in ProblemKind.values.indexed) {
      final angle = (_turns + i / ProblemKind.values.length) * 2 * math.pi;
      // En coordonnées d'écran, y descend : un sinus positif place le symbole
      // sous le centre, donc devant.
      final avant = math.sin(angle) > 0;
      final profondeur = (math.sin(angle) + 1) / 2;
      (avant ? devant : derriere).add(Transform.translate(
        offset: Offset(math.cos(angle) * rx, math.sin(angle) * ry),
        // L'échelle est appliquée ici et jamais au `side` du symbole : ce
        // dernier sert de clé au cache d'images, et le faire varier à chaque
        // image redécoderait le WebP soixante fois par seconde.
        child: Transform.scale(
          scale: 0.72 + 0.28 * profondeur,
          child: Opacity(opacity: 0.5 + 0.5 * profondeur, child: ProblemKindIcon(kind: kind, side: side * 0.15)),
        ),
      ));
    }

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: side,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Le halo : la photo elle-même, plus grande et floue. Sa propre
            // couche, sans quoi le flou serait recalculé à chaque image de la
            // ronde alors qu'il ne bouge pas.
            RepaintBoundary(
              child: Opacity(
                opacity: 0.45,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: SizedBox.square(dimension: side * 0.68, child: ClipRRect(borderRadius: Radii.xlAll, child: widget.photo)),
                ),
              ),
            ),
            ...derriere,
            // La photo non plus ne bouge pas, et son argile porte des ombres :
            // même raison, même couche.
            RepaintBoundary(
              child: SizedBox.square(
                dimension: photo,
                child: ClayBox(
                  color: context.colors.surface,
                  shape: const ClayShape.rounded(Radii.large),
                  clip: true,
                  child: widget.photo,
                ),
              ),
            ),
            ...devant,
          ],
        ),
      ),
    );
  }
}
