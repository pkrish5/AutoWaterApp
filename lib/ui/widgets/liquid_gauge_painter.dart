import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidGaugePainter extends CustomPainter {
  final double value;
  final double animationValue;
  final Color waterColor;
  final Color waterColorLight;

  LiquidGaugePainter({
    required this.value,
    required this.animationValue,
    this.waterColor = const Color(0xFF5B9BD5),
    this.waterColorLight = const Color(0xFF8BC4EA),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha:0.3),
          Colors.blue.withValues(alpha:0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [waterColorLight, waterColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    double amplitude = 4.0;
    double waveLength = size.width * 0.8;
    double fillLevel = size.height * (1 - value);

    final backWavePath = Path();
    backWavePath.moveTo(0, fillLevel);
    for (double x = 0; x <= size.width; x++) {
      double y = fillLevel + amplitude * math.sin(
        (x / waveLength * 2 * math.pi) + (animationValue * 2 * math.pi) + math.pi
      );
      backWavePath.lineTo(x, y);
    }
    backWavePath.lineTo(size.width, size.height);
    backWavePath.lineTo(0, size.height);
    backWavePath.close();

    final backWavePaint = Paint()..color = waterColorLight.withValues(alpha:0.5);
    canvas.drawPath(backWavePath, backWavePaint);

    final wavePath = Path();
    wavePath.moveTo(0, fillLevel);
    for (double x = 0; x <= size.width; x++) {
      double y = fillLevel + amplitude * math.sin(
        (x / waveLength * 2 * math.pi) + (animationValue * 2 * math.pi)
      );
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, waterPaint);

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha:0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      -math.pi * 0.7,
      math.pi * 0.4,
      false,
      shinePaint,
    );

    canvas.restore();

    final borderPaint = Paint()
      ..color = waterColor.withValues(alpha:0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 1.5, borderPaint);
  }

  @override
  bool shouldRepaint(LiquidGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.animationValue != animationValue;
  }
}
