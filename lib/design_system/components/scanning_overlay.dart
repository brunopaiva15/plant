import 'package:flutter/material.dart';

/// Surimpression de cadrage pour les prises destinées à Iris.
///
/// Elle reprend l'idée d'un balayage de scanner sans basculer dans une DA
/// technique : une grille presque invisible, quatre repères doux et une
/// bande sauge/crème qui traverse lentement l'image. Rien n'intercepte les
/// gestes du viseur.
///
/// Avec « Réduire les animations », les repères restent en place mais le
/// balayage disparaît complètement.
class ScanningOverlay extends StatefulWidget {
  const ScanningOverlay({
    super.key,
    this.color = const Color(0xFFE8F2E8),
    this.duration = const Duration(milliseconds: 3600),
  });

  /// Teinte posée sur la photo. Fixe plutôt que liée au thème : ce qui se
  /// trouve dessous est une image réelle, pas une surface claire ou sombre.
  final Color color;

  /// Un passage complet, du dessus du cadre au-dessous.
  final Duration duration;

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion && (_reduceMotion || _controller.isAnimating)) return;
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ScanningOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (!_reduceMotion) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _ScanningPainter(
              color: widget.color,
              progress: _reduceMotion ? null : Curves.easeInOut.transform(_controller.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanningPainter extends CustomPainter {
  const _ScanningPainter({required this.color, required this.progress});

  final Color color;

  /// `null` signifie que l'animation est désactivée : seuls les repères fixes
  /// sont peints.
  final double? progress;

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

    final p = progress;
    if (p == null) return;

    // La bande naît et disparaît hors cadre ; le retour à zéro n'est donc
    // jamais visible. Son centre est plus lumineux que ses bords.
    final bandHeight = (size.height * 0.15).clamp(48.0, 82.0);
    final y = -bandHeight + (size.height + bandHeight * 2) * p;
    final bandRect = Rect.fromLTWH(0, y - bandHeight / 2, size.width, bandHeight);
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.035),
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.035),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.25, 0.5, 0.75, 1],
      ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.62)
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
    canvas.drawLine(Offset(_inset, y), Offset(size.width - _inset, y), linePaint);
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
  bool shouldRepaint(_ScanningPainter oldDelegate) => oldDelegate.color != color || oldDelegate.progress != progress;
}
