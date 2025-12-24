import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../widgets/liquid_gauge.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback? onTap;

  const PlantCard({super.key, required this.plant, this.onTap});

  Color get _statusColor {
    if (plant.waterPercentage >= 70) return AppTheme.leafGreen;
    if (plant.waterPercentage >= 40) return AppTheme.waterBlue;
    if (plant.waterPercentage >= 20) return Colors.orange;
    return AppTheme.terracotta;
  }

  String get _plantEmoji {
    switch (plant.archetype.toLowerCase()) {
      case 'vine':
        return '🌿';
      case 'spiky':
        return '🌵';
      case 'bushy':
      default:
        return '🪴';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.leafGreen.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header row with archetype and streak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.softSage.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plant.archetype,
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.leafGreen,
                      ),
                    ),
                  ),
                  if (plant.streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.sunYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${plant.streak}',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Plant name
              Text(
                plant.nickname,
                style: GoogleFonts.comfortaa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.soilBrown,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Liquid gauge with plant emoji overlay
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    LiquidGauge(
                      level: plant.waterLevel,
                      size: 90,
                      waterColor: _statusColor,
                      waterColorLight: _statusColor.withOpacity(0.5),
                    ),
                    Text(_plantEmoji, style: const TextStyle(fontSize: 36)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 14,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${plant.waterPercentage.toInt()}%',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      plant.waterStatus,
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        color: _statusColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
