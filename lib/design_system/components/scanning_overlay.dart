import 'package:flutter/material.dart';

/// Surimpression de cadrage pour les prises destinées à Iris.
///
/// Le layout « scan » reste volontairement statique : quatre repères doux
/// cadrent la plante sans quadrillage ni balayage animé. La photo reste ainsi
/// le seul sujet du viseur. Rien n'intercepte ses gestes.
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

  static const double _inset = 18;
  static const double _corner = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

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
