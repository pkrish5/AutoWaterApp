import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidGaugePainter extends CustomPainter {
  final double value; // 0.0 to 1.0 (water level)
  final double animationValue; // Controls horizontal wave movement

  LiquidGaugePainter({required this.value, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.withOpacity(0.6);
    final path = Path();

    // Wave parameters
    double amplitude = 5.0; 
    double waveLength = size.width;
    // Calculate vertical fill level (0 at bottom, size.height at top)
    double fillLevel = size.height * (1 - value);

    path.moveTo(0, fillLevel);

    // Draw sine wave across the width
    for (double x = 0; x <= size.width; x++) {
      double y = fillLevel + amplitude * math.sin((x / waveLength * 2 * math.pi) + (animationValue * 2 * math.pi));
      path.lineTo(x, y);
    }

    // Close the path to fill the bottom area
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LiquidGaugePainter oldDelegate) => true; // Always repaint for animation
}