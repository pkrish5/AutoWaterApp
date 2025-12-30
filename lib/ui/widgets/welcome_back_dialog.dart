import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';

class WelcomeBackDialog extends StatelessWidget {
  final int streak;
  final bool streakIncreased;
  final List<Plant>? plants;
  final VoidCallback onDismiss;

  const WelcomeBackDialog({
    super.key,
    required this.streak,
    required this.streakIncreased,
    this.plants,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.leafGreen.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildStreakSection(),
              if (plants != null && plants!.isNotEmpty) _buildGardenSummary(),
              _buildDismissButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.leafGreen.withValues(alpha: 0.1),
            AppTheme.softSage.withValues(alpha: 0.2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            'Welcome Back!',
            style: GoogleFonts.comfortaa(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.leafGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your plants missed you!',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streak > 0
                ? [AppTheme.streakOrange, AppTheme.streakYellow]
                : [Colors.grey.shade300, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: streak > 0
              ? [
                  BoxShadow(
                    color: AppTheme.streakOrange.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 32,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$streak',
                      style: GoogleFonts.comfortaa(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' day${streak == 1 ? '' : 's'}',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                if (streakIncreased)
                  Text(
                    '🎉 Streak increased!',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  )
                else
                  Text(
                    'Keep it going!',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGardenSummary() {
    final plantsNeedingWater = plants!.where((p) => 
      p.hasDevice && p.waterPercentage < 30
    ).toList();
    
    final plantsWithDevices = plants!.where((p) => p.hasDevice).length;
    final totalPlants = plants!.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.softSage.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.yard, size: 16, color: AppTheme.leafGreen),
                const SizedBox(width: 6),
                Text(
                  'Garden Update',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.leafGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              '🪴',
              '$totalPlants plant${totalPlants == 1 ? '' : 's'} in your garden',
            ),
            if (plantsWithDevices > 0)
              _buildSummaryRow(
                '📡',
                '$plantsWithDevices connected to sensors',
              ),
            if (plantsNeedingWater.isNotEmpty)
              _buildSummaryRow(
                '💧',
                '${plantsNeedingWater.length} need${plantsNeedingWater.length == 1 ? 's' : ''} water soon',
                highlight: true,
              ),
            if (plantsNeedingWater.isEmpty && plantsWithDevices > 0)
              _buildSummaryRow(
                '✅',
                'All plants are well hydrated!',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String emoji, String text, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.quicksand(
                fontSize: 12,
                color: highlight 
                    ? AppTheme.terracotta 
                    : AppTheme.soilBrown.withValues(alpha: 0.8),
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.leafGreen,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Let\'s Grow! 🌿',
            style: GoogleFonts.quicksand(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}