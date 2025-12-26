import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PlantLoadingIndicator extends StatefulWidget {
  final String? message;
  const PlantLoadingIndicator({super.key, this.message});

  @override
  State<PlantLoadingIndicator> createState() => _PlantLoadingIndicatorState();
}

class _PlantLoadingIndicatorState extends State<PlantLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(animation: _bounceAnimation, builder: (context, child) {
        return Transform.translate(offset: Offset(0, _bounceAnimation.value), child: const Text('🌱', style: TextStyle(fontSize: 48)));
      }),
      const SizedBox(height: 16),
      if (widget.message != null) Text(widget.message!, style: TextStyle(color: AppTheme.soilBrown.withValues(alpha:0.7), fontSize: 16)),
    ]);
  }
}