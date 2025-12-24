import 'package:flutter/material.dart';
import 'liquid_gauge_painter.dart';

class LiquidGauge extends StatefulWidget {
  final double level; // 0.0 to 1.0
  final double size;
  final Color? waterColor;
  final Color? waterColorLight;

  const LiquidGauge({
    super.key,
    required this.level,
    this.size = 100,
    this.waterColor,
    this.waterColorLight,
  });

  @override
  State<LiquidGauge> createState() => _LiquidGaugeState();
}

class _LiquidGaugeState extends State<LiquidGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _levelAnimation;
  double _currentLevel = 0;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.level;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _levelAnimation = Tween<double>(begin: 0, end: widget.level).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(LiquidGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _currentLevel = widget.level;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: LiquidGaugePainter(
            value: _currentLevel,
            animationValue: _controller.value,
            waterColor: widget.waterColor ?? const Color(0xFF5B9BD5),
            waterColorLight: widget.waterColorLight ?? const Color(0xFF8BC4EA),
          ),
        );
      },
    );
  }
}
