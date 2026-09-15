import 'package:flutter/material.dart';

/// Surimpression de cadrage pour les prises destinées à Iris.
///
/// Le layout « scan » reste volontairement statique : une grille presque
/// invisible et quatre repères doux cadrent la plante sans ajouter de
/// balayage animé. Rien n'intercepte les gestes du viseur.
class ScanningOverlay extends StatelessWidget {
  const ScanningOverlay({
    super.key,
    this.color = const Color(0xFFE8F2E8),
  });

  /// Teinte posée sur la photo. Fixe plutôt que liée au thème : ce qui se
  /// trouve dessous est une image réelle, pas une surface claire ou sombre.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ScanningPainter(color: color),
        ),
      ),
    );
  }
}

class _ScanningPainter extends CustomPainter {
  const _ScanningPainter({required this.color});

  final Color color;

  static const double _grid = 44;
  static const double _inset = 18;
  static const double _corner = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // La grille sert uniquement de matière au viseur. Elle doit se deviner,
    // jamais concurrencer la plante ni donner un rendu « scanner médical ».
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.075)
      ..strokeWidth = 0.7;
    for (double x = _grid; x < size.width; x += _grid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = _grid; y < size.height; y += _grid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Quatre coins arrondis : ils cadrent la plante sans enfermer l'image
    // dans un rectangle complet.
    final cornerPaint = Paint()
      ..color = color.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _cornerPath(canvas, cornerPaint, size);
  }

  void _cornerPath(Canvas canvas, Paint paint, Size size) {
    final left = _inset;
    final top = _inset;
    final right = size.width - _inset;
    final bottom = size.height - _inset;

    final path = Path()
      ..moveTo(left, top + _corner)
      ..lineTo(left, top + 8)
      ..quadraticBezierTo(left, top, left + 8, top)
      ..lineTo(left + _corner, top)
      ..moveTo(right - _corner, top)
      ..lineTo(right - 8, top)
      ..quadraticBezierTo(right, top, right, top + 8)
      ..lineTo(right, top + _corner)
      ..moveTo(right, bottom - _corner)
      ..lineTo(right, bottom - 8)
      ..quadraticBezierTo(right, bottom, right - 8, bottom)
      ..lineTo(right - _corner, bottom)
      ..moveTo(left + _corner, bottom)
      ..lineTo(left + 8, bottom)
      ..quadraticBezierTo(left, bottom, left, bottom - 8)
      ..lineTo(left, bottom - _corner);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanningPainter oldDelegate) => oldDelegate.color != color;
}
