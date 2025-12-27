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

  /// Get emoji from speciesInfo if available, otherwise fall back to species-based lookup
  String get _plantEmoji {
    // First check if emoji is stored in speciesInfo (from DB)
    if (plant.speciesInfo != null) {
      // Check if there's an emoji field in the raw data
      // This would be added to PlantSpeciesInfo model
      final emoji = _getEmojiFromSpeciesInfo();
      if (emoji != null) return emoji;
    }
    
    // Fall back to species name matching
    return _getEmojiFromSpeciesName(plant.species);
  }

  String? _getEmojiFromSpeciesInfo() {
    // The emoji should come from the speciesInfo stored when the plant was created
    // This relies on the backend storing and returning the emoji
    // For now, we'll use the species name from speciesInfo for better matching
    if (plant.speciesInfo?.commonName != null) {
      return _getEmojiFromSpeciesName(plant.speciesInfo!.commonName);
    }
    return null;
  }

  static String _getEmojiFromSpeciesName(String species) {
    final s = species.toLowerCase();
    
    // Vines and trailing plants
    if (s.contains('pothos') || s.contains('epipremnum')) return '🌿';
    if (s.contains('philodendron')) return '🌿';
    if (s.contains('ivy') || s.contains('hedera')) return '🌿';
    
    // Succulents and cacti
    if (s.contains('snake') || s.contains('sansevieria')) return '🌵';
    if (s.contains('aloe')) return '🌵';
    if (s.contains('cactus') || s.contains('cacti')) return '🌵';
    if (s.contains('succulent')) return '🌵';
    if (s.contains('jade') || s.contains('crassula')) return '🌵';
    if (s.contains('echeveria')) return '🌵';
    if (s.contains('haworthia')) return '🌵';
    if (s.contains('sedum')) return '🌵';
    
    // Tropical plants
    if (s.contains('monstera')) return '🌴';
    if (s.contains('calathea') || s.contains('prayer')) return '🌴';
    if (s.contains('palm')) return '🌴';
    if (s.contains('dracaena') || s.contains('dragon')) return '🌴';
    if (s.contains('bird of paradise') || s.contains('strelitzia')) return '🌴';
    if (s.contains('banana')) return '🌴';
    
    // Trees and large plants
    if (s.contains('fiddle') || s.contains('ficus lyrata')) return '🌳';
    if (s.contains('rubber') || s.contains('ficus elastica')) return '🌳';
    if (s.contains('ficus')) return '🌳';
    if (s.contains('tree')) return '🌳';
    
    // Flowering plants
    if (s.contains('peace lily') || s.contains('spathiphyllum')) return '🌸';
    if (s.contains('orchid')) return '🌸';
    if (s.contains('anthurium')) return '🌸';
    if (s.contains('rose')) return '🌹';
    if (s.contains('lily')) return '🌸';
    if (s.contains('hibiscus')) return '🌺';
    if (s.contains('flower')) return '🌸';
    
    // Ferns
    if (s.contains('fern') || s.contains('nephrolepis')) return '🌿';
    if (s.contains('maidenhair') || s.contains('adiantum')) return '🌿';
    
    // Herbs and edibles
    if (s.contains('basil')) return '🌱';
    if (s.contains('mint')) return '🌱';
    if (s.contains('rosemary')) return '🌱';
    if (s.contains('thyme')) return '🌱';
    if (s.contains('herb')) return '🌱';
    if (s.contains('tomato')) return '🍅';
    if (s.contains('pepper')) return '🌶️';
    if (s.contains('lettuce') || s.contains('salad')) return '🥬';
    if (s.contains('strawberry')) return '🍓';
    
    // Other common houseplants
    if (s.contains('spider') || s.contains('chlorophytum')) return '🌿';
    if (s.contains('zz') || s.contains('zamioculcas')) return '🌿';
    if (s.contains('peperomia')) return '🌿';
    if (s.contains('pilea') || s.contains('money')) return '🌿';
    if (s.contains('begonia')) return '🌸';
    if (s.contains('croton')) return '🌴';
    if (s.contains('dieffenbachia')) return '🌿';
    if (s.contains('aglaonema') || s.contains('chinese evergreen')) return '🌿';
    if (s.contains('schefflera') || s.contains('umbrella')) return '🌳';
    if (s.contains('yucca')) return '🌵';
    
    // Generic categories from archetypes
    if (s.contains('vine')) return '🌿';
    if (s.contains('spiky')) return '🌵';
    if (s.contains('tropical')) return '🌴';
    if (s.contains('bushy')) return '🌿';
    if (s.contains('hanging')) return '🌿';
    
    // Default
    return '🪴';
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
              color: AppTheme.leafGreen.withValues(alpha: 0.08),
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.softSage.withValues(alpha: 0.5),
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
        ),
        if (plant.hasDevice && plant.streak > 0) ...[
          const SizedBox(width: 6),
          _buildStreakTag(),
        ],
      ],
    );
  }

  Widget _buildStreakTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.sunYellow.withValues(alpha: 0.2),
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
            waterColorLight: _statusColor.withValues(alpha: 0.5),
          ),
          Text(_plantEmoji, style: const TextStyle(fontSize: 36)),
        ],
      );
    } else {
      // Show plant emoji only for plants without devices
      return Center(
        child: Text(_plantEmoji, style: const TextStyle(fontSize: 48)),
      );
    }
  }

  Widget _buildBottomStatus() {
    if (plant.hasDevice) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColor.withValues(alpha: 0.1),
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
                color: _statusColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    } else {
      // Show watering frequency and manual tag inline
      final recommendation = plant.wateringRecommendation;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.waterBlue.withValues(alpha: 0.15),
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
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.terracotta.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, size: 10, color: AppTheme.terracotta),
                const SizedBox(width: 2),
                Text(
                  'Manual',
                  style: GoogleFonts.quicksand(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.terracotta,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}