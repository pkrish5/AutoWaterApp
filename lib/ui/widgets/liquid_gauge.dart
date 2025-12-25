import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidGauge extends StatefulWidget {
  final double level;
  final double size;
  final Color? waterColor;
  final Color? waterColorLight;

  const LiquidGauge({super.key, required this.level, this.size = 100, this.waterColor, this.waterColorLight});

  @override
  State<LiquidGauge> createState() => _LiquidGaugeState();
}

class _LiquidGaugeState extends State<LiquidGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) {
      return CustomPaint(size: Size(widget.size, widget.size),
        painter: _LiquidGaugePainter(value: widget.level, animationValue: _controller.value,
          waterColor: widget.waterColor ?? const Color(0xFF5B9BD5),
          waterColorLight: widget.waterColorLight ?? const Color(0xFF8BC4EA)));
    });
  }
}

class _LiquidGaugePainter extends CustomPainter {
  final double value;
  final double animationValue;
  final Color waterColor;
  final Color waterColorLight;

  _LiquidGaugePainter({required this.value, required this.animationValue, required this.waterColor, required this.waterColorLight});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    final bgPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Colors.white.withOpacity(0.3), Colors.blue.withOpacity(0.05)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final waterPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [waterColorLight, waterColor]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    double fillLevel = size.height * (1 - value);
    final wavePath = Path()..moveTo(0, fillLevel);
    for (double x = 0; x <= size.width; x++) {
      double y = fillLevel + 4 * math.sin((x / (size.width * 0.8) * 2 * math.pi) + (animationValue * 2 * math.pi));
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, waterPaint);

    canvas.restore();
    final borderPaint = Paint()..color = waterColor.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawCircle(center, radius - 1.5, borderPaint);
  }

  @override
  bool shouldRepaint(_LiquidGaugePainter oldDelegate) => oldDelegate.value != value || oldDelegate.animationValue != animationValue;
}