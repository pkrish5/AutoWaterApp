import 'dart:math' as math;
import 'package:flutter/material.dart';

class LeafBackground extends StatelessWidget {
  final Widget child;
  final int leafCount;

  const LeafBackground({super.key, required this.child, this.leafCount = 8});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [const Color(0xFFFAF8F5), const Color(0xFFE8F5E9).withOpacity(0.5), const Color(0xFFFAF8F5)]))),
      ...List.generate(leafCount, (index) {
        final random = math.Random(index);
        return Positioned(
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          top: random.nextDouble() * MediaQuery.of(context).size.height,
          child: Transform.rotate(angle: random.nextDouble() * math.pi * 2,
            child: Opacity(opacity: 0.08 + random.nextDouble() * 0.07,
              child: Icon(Icons.eco, size: 40 + random.nextDouble() * 60, color: const Color(0xFF2D5A27)))));
      }),
      child,
    ]);
  }
}