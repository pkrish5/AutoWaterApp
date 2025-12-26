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
    // Try to match from speciesInfo first
    switch (plant.species.toLowerCase()) {
      case 'pothos':
      case 'vine':
      case 'philodendron':
        return '🌿';
      case 'snake plant':
      case 'aloe vera':
      case 'jade plant':
      case 'zz plant':
      case 'succulent':
      case 'spiky':
      case 'cactus':
        return '🌵';
      case 'monstera':
      case 'calathea':
      case 'tropical':
      case 'dracaena':
        return '🌴';
      case 'peace lily':
      case 'flowering':
        return '🌸';
      case 'fiddle leaf fig':
      case 'rubber plant':
      case 'tree':
        return '🌳';
      case 'boston fern':
      case 'fern':
        return '🌿';
      case 'spider plant':
      case 'hanging':
        return '🌿';
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
              color: AppTheme.leafGreen.withValues(alpha:0.08),
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
              _buildTopRow(),
              const SizedBox(height: 12),
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
              Expanded(
                child: _buildCenterContent(),
              ),
              const SizedBox(height: 8),
              _buildBottomStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.softSage.withValues(alpha:0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            plant.species,
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.leafGreen,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!plant.hasDevice)
          _buildNoDeviceTag()
        else if (plant.streak > 0)
          _buildStreakTag(),
      ],
    );
  }

  Widget _buildNoDeviceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.terracotta.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off, size: 12, color: AppTheme.terracotta),
          const SizedBox(width: 2),
          Text(
            'Manual',
            style: GoogleFonts.quicksand(
              fontSize: 9,
              color: AppTheme.terracotta,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.sunYellow.withValues(alpha:0.2),
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
    );
  }

  Widget _buildCenterContent() {
    if (plant.hasDevice) {
      // Show water gauge for plants with devices
      return Stack(
        alignment: Alignment.center,
        children: [
          LiquidGauge(
            level: plant.waterLevel,
            size: 90,
            waterColor: _statusColor,
            waterColorLight: _statusColor.withValues(alpha:0.5),
          ),
          Text(_plantEmoji, style: const TextStyle(fontSize: 36)),
        ],
      );
    } else {
      // Show watering recommendation for plants without devices
      return _buildManualWateringIndicator();
    }
  }

  Widget _buildManualWateringIndicator() {
    final recommendation = plant.wateringRecommendation;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(_plantEmoji, style: const TextStyle(fontSize: 48)),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.waterBlue.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop, size: 12, color: AppTheme.waterBlue),
                const SizedBox(width: 3),
                Text(
                  '${recommendation.frequencyDays}d',
                  style: GoogleFonts.quicksand(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.waterBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStatus() {
    if (plant.hasDevice) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColor.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop, size: 14, color: _statusColor),
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
                color: _statusColor.withValues(alpha:0.8),
              ),
            ),
          ],
        ),
      );
    } else {
      // Show approximate moisture status for manual plants
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.softSage.withValues(alpha:0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Tap for care info',
          style: GoogleFonts.quicksand(
            fontSize: 11,
            color: AppTheme.soilBrown.withValues(alpha:0.7),
          ),
        ),
      );
    }
  }
}