import 'package:flutter/material.dart';
import 'liquid_gauge_painter.dart';

class LiquidGauge extends StatefulWidget {
  final double level; // 0.0 to 1.0

  const LiquidGauge({super.key, required this.level});

  @override
  State<LiquidGauge> createState() => _LiquidGaugeState();
}

class _LiquidGaugeState extends State<LiquidGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Infinite loop for horizontal wave motion
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose(); // Prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(100, 100),
          painter: LiquidGaugePainter(
            value: widget.level,
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}