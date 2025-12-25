import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class StreakWidget extends StatelessWidget {
  final int streak;
  final bool showLabel;
  final double size;

  const StreakWidget({
    super.key,
    required this.streak,
    this.showLabel = true,
    this.size = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showStreakDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * size,
          vertical: 6 * size,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streak > 0
                ? [AppTheme.streakOrange, AppTheme.streakYellow]
                : [Colors.grey.shade300, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20 * size),
          boxShadow: streak > 0
              ? [
                  BoxShadow(
                    color: AppTheme.streakOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFireIcon(size),
            SizedBox(width: 4 * size),
            Text(
              '$streak',
              style: GoogleFonts.quicksand(
                fontSize: 16 * size,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (showLabel) ...[
              SizedBox(width: 2 * size),
              Text(
                'day${streak == 1 ? '' : 's'}',
                style: GoogleFonts.quicksand(
                  fontSize: 12 * size,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFireIcon(double scale) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        if (streak > 0)
          Icon(
            Icons.local_fire_department,
            size: 24 * scale,
            color: Colors.white.withOpacity(0.5),
          ),
        // Main icon
        Icon(
          Icons.local_fire_department,
          size: 20 * scale,
          color: Colors.white,
        ),
      ],
    );
  }

  void _showStreakDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.streakOrange, AppTheme.streakYellow],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Your Streak',
              style: GoogleFonts.comfortaa(
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$streak',
              style: GoogleFonts.comfortaa(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.streakOrange,
              ),
            ),
            Text(
              'day streak! 🔥',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                color: AppTheme.soilBrown,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.softSage.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _getStreakMessage(streak),
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      color: AppTheme.soilBrown.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStreakTip(),
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppTheme.soilBrown.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Growing!',
              style: GoogleFonts.quicksand(
                color: AppTheme.leafGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStreakMessage(int streak) {
    if (streak == 0) return "Start caring for your plants today!";
    if (streak < 3) return "Great start! Keep checking on your plants daily.";
    if (streak < 7) return "You're building a habit! Your plants appreciate it.";
    if (streak < 14) return "Amazing dedication! You're becoming a plant parent pro.";
    if (streak < 30) return "Incredible commitment! Your garden is thriving because of you.";
    if (streak < 100) return "Legendary status! You're a true plant whisperer.";
    return "🏆 MASTER GARDENER 🏆 Your dedication is unmatched!";
  }

  String _getStreakTip() {
    const tips = [
      "Check your plants at the same time each day for best results",
      "Upload a photo to track your plants' growth over time",
      "Water consistently based on your plants' needs",
      "Your streak resets if you miss a day - stay consistent!",
    ];
    return tips[DateTime.now().day % tips.length];
  }
}

class AnimatedStreakWidget extends StatefulWidget {
  final int streak;
  final bool showLabel;

  const AnimatedStreakWidget({
    super.key,
    required this.streak,
    this.showLabel = true,
  });

  @override
  State<AnimatedStreakWidget> createState() => _AnimatedStreakWidgetState();
}

class _AnimatedStreakWidgetState extends State<AnimatedStreakWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.streak > 0) {
      _controller.repeat(reverse: true);
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.streak > 0
                    ? [AppTheme.streakOrange, AppTheme.streakYellow]
                    : [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: widget.streak > 0
                  ? [
                      BoxShadow(
                        color: AppTheme.streakOrange.withOpacity(_glowAnimation.value),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.streak}',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}