import 'package:flutter/widgets.dart';

import '../../../domain/models/inventory_item.dart';

/// Les six formes d'engrais dans l'argile d'Auxine. Sans forme renseignée,
/// la boîte générique sert de repère sans attribuer une forme à l'article.
/// Le libellé est porté par la puce ou la ligne, pas répété par l'image.
class FertilizerFormIcon extends StatelessWidget {
  const FertilizerFormIcon({super.key, this.form, this.size = 40});

  final FertilizerForm? form;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/inventory/fertilizer_forms/${(form ?? FertilizerForm.other).name}.webp',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      );
}
