import 'dart:math';
import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';

class ParchmentBorderPainter extends CustomPainter {
  final Color color;

  ParchmentBorderPainter({this.color = MedievalColors.parchmentDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rng = Random(42);
    final path = Path();

    path.moveTo(_jitter(0, rng), _jitter(0, rng));
    path.lineTo(_jitter(size.width, rng), _jitter(0, rng));
    path.lineTo(_jitter(size.width, rng), _jitter(size.height, rng));
    path.lineTo(_jitter(0, rng), _jitter(size.height, rng));
    path.close();

    canvas.drawPath(path, paint);

    final innerPaint = Paint()
      ..color = MedievalColors.goldPale.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final innerPath = Path();
    innerPath.moveTo(_jitterInner(0, rng, 8), _jitterInner(0, rng, 8));
    innerPath.lineTo(_jitterInner(size.width, rng, 8), _jitterInner(0, rng, 8));
    innerPath.lineTo(_jitterInner(size.width, rng, 8), _jitterInner(size.height, rng, 8));
    innerPath.lineTo(_jitterInner(0, rng, 8), _jitterInner(size.height, rng, 8));
    innerPath.close();

    canvas.drawPath(innerPath, innerPaint);
  }

  double _jitter(double value, Random rng) {
    return value + (rng.nextDouble() - 0.5) * 4.0;
  }

  double _jitterInner(double value, Random rng, double inset) {
    final offset = value == 0 ? inset : -inset;
    return value + offset + (rng.nextDouble() - 0.5) * 4.0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}