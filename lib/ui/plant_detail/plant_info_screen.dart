import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/plant_profile.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../widgets/leaf_background.dart';
import '../../models/plant_measurements.dart' as pm;
import 'dart:convert';

class PlantInfoScreen extends StatefulWidget {
  final Plant plant;
  const PlantInfoScreen({super.key, required this.plant});

  @override
  State<PlantInfoScreen> createState() => _PlantInfoScreenState();
}

class _PlantInfoScreenState extends State<PlantInfoScreen> {
  PlantProfile? _profile;

  // ✅ NEW: store the full plant details (includes measurements)
  Plant? _plantDetails;

  bool _isLoading = true; // profile loading
  bool _isDetailsLoading = true; // ✅ NEW: details loading
  String? _error;
  String? _detailsError; // ✅ NEW

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPlantDetails(); // ✅ NEW
  }

  Future<void> _loadProfile() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final profile = await api.getPlantProfile(widget.plant.species);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load plant profile: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  String _jwtSub(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return '';

    String normalized = parts[1];
    normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }

    final payload = jsonDecode(utf8.decode(base64Decode(normalized))) as Map<String, dynamic>;
    return (payload['sub'] ?? '').toString();
  }

  // ✅ NEW: call getPlantDetails (your lambda) so measurements are present
  Future<void> _loadPlantDetails() async {
  try {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth.idToken!);

    final userId = _jwtSub(auth.idToken!); // ✅ no auth.user needed

    final json = await api.getPlantDetails(widget.plant.plantId, userId);
    final fullPlant = Plant.fromJson(json);

    if (mounted) {
      setState(() {
        _plantDetails = fullPlant;
        _isDetailsLoading = false;
      });
    }
  } catch (e) {
    debugPrint('Failed to load plant details: $e');
    if (mounted) {
      setState(() {
        _detailsError = e.toString();
        _isDetailsLoading = false;
      });
    }
  }
}

  // ✅ CHANGE: use details plant if loaded, otherwise fallback to widget.plant
  Plant get plant => _plantDetails ?? widget.plant;

  @override
  Widget build(BuildContext context) {
    // debugPrint('🧪 PlantInfo measurements = ${plant.measurements}');
    // debugPrint('🧪 PlantInfo hasMeasurements = ${plant.measurements?.hasMeasurements}');
    // debugPrint('🧪 PlantInfo detailsLoading = $_isDetailsLoading, detailsError = $_detailsError');

    return Scaffold(
      body: LeafBackground(
        leafCount: 4,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null && _profile == null
                        ? _buildFallbackContent()
                        : _buildProfileContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackContent() {
    // Fallback to embedded speciesInfo if API fails
    final info = plant.speciesInfo;
    final recommendation = plant.wateringRecommendation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            info?.commonName,
            info?.scientificName,
            info?.careLevel,
            info?.description,
          ),
          const SizedBox(height: 20),
          _buildCareOverviewFallback(info, recommendation),
          const SizedBox(height: 20),

          if (plant.measurements != null && plant.measurements!.hasMeasurements) ...[
            const SizedBox(height: 20),
            _MeasurementsInfoCard(measurements: plant.measurements!),
          ],

          _buildDetailedCareFallback(info, recommendation),

          if (info?.tips != null && info!.tips!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTipsCard(info.tips!),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final care = _profile?.careProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            _profile?.commonName,
            _profile?.species,
            null, // careLevel not in PlantProfile
            null, // description not in PlantProfile
          ),

          // ✅ Measurements will appear once getPlantDetails finishes
          if (plant.measurements != null && plant.measurements!.hasMeasurements) ...[
            const SizedBox(height: 20),
            _MeasurementsInfoCard(measurements: plant.measurements!),
          ],

          const SizedBox(height: 20),
          if (care != null) ...[
            _buildCareOverview(care),
            const SizedBox(height: 20),
            _buildDetailedCare(care),
            const SizedBox(height: 20),
            _buildSoilInfo(care),
            const SizedBox(height: 20),
            _buildGrowthInfo(care),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen),
              ),
            ),
            const Spacer(),
            Text(
              'Plant Info',
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.leafGreen,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      );

  Widget _buildHeroCard(
    String? commonName,
    String? scientificName,
    String? careLevel,
    String? description,
  ) {
    String emoji = '🪴';
    switch (plant.species.toLowerCase()) {
      case 'vine':
      case 'pothos':
      case 'epipremnum aureum':
        emoji = '🌿';
        break;
      case 'spiky':
      case 'cactus':
        emoji = '🌵';
        break;
      case 'tropical':
      case 'monstera':
        emoji = '🌴';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            commonName ?? plant.species,
            style: GoogleFonts.comfortaa(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
            textAlign: TextAlign.center,
          ),
          if (scientificName != null)
            Text(
              scientificName,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppTheme.soilBrown.withValues(alpha: 0.6),
              ),
            ),
          const SizedBox(height: 12),
          if (careLevel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _careLevelColor(careLevel).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$careLevel Care',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _careLevelColor(careLevel),
                ),
              ),
            ),
          if (description != null) ...[
            const SizedBox(height: 16),
            Text(
              description,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Color _careLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return AppTheme.leafGreen;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return AppTheme.terracotta;
      default:
        return AppTheme.soilBrown;
    }
  }

  Widget _buildCareOverview(CareProfile care) => Row(
        children: [
          Expanded(
              child: _CareStatCard(
                  icon: Icons.water_drop,
                  label: 'Water',
                  value: 'Every ${care.watering.frequencyDays}d',
                  color: AppTheme.waterBlue)),
          const SizedBox(width: 12),
          Expanded(
              child: _CareStatCard(
                  icon: Icons.local_drink,
                  label: 'Amount',
                  value: '${care.watering.amountML}mL',
                  color: AppTheme.leafGreen)),
          const SizedBox(width: 12),
          Expanded(
              child: _CareStatCard(
                  icon: Icons.wb_sunny,
                  label: 'Light',
                  value: _formatLightType(care.light.type),
                  color: AppTheme.sunYellow)),
        ],
      );

  Widget _buildCareOverviewFallback(PlantSpeciesInfo? info, WateringRecommendation rec) => Row(
        children: [
          Expanded(
              child: _CareStatCard(
                  icon: Icons.water_drop,
                  label: 'Water',
                  value: 'Every ${rec.frequencyDays}d',
                  color: AppTheme.waterBlue)),
          const SizedBox(width: 12),
          Expanded(
              child: _CareStatCard(
                  icon: Icons.local_drink,
                  label: 'Amount',
                  value: '${rec.amountML}mL',
                  color: AppTheme.leafGreen)),
          const SizedBox(width: 12),
          Expanded(
              child: _CareStatCard(
                  icon: Icons.wb_sunny,
                  label: 'Light',
                  value: info?.lightRequirement?.split(' ').first ?? 'Medium',
                  color: AppTheme.sunYellow)),
        ],
      );

  String _formatLightType(String type) {
    return type.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  Widget _buildDetailedCare(CareProfile care) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Care Requirements',
                style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
            const SizedBox(height: 16),
            _CareDetailRow(
              icon: Icons.water_drop,
              title: 'Watering',
              value: 'Every ${care.watering.frequencyDays} days, ${care.watering.amountML}mL',
              subtitle: 'Moisture: ${care.watering.moistureMin}% - ${care.watering.moistureMax}%',
              color: AppTheme.waterBlue,
            ),
            _CareDetailRow(
              icon: Icons.wb_sunny,
              title: 'Light',
              value: '${_formatLightType(care.light.type)} (${care.light.hoursDaily}h/day)',
              subtitle: 'Min ${care.light.minLux} lux',
              color: AppTheme.sunYellow,
            ),
            _CareDetailRow(
              icon: Icons.thermostat,
              title: 'Temperature',
              value: '${care.environment.tempMin}°C - ${care.environment.tempMax}°C',
              color: AppTheme.terracotta,
            ),
            _CareDetailRow(
              icon: Icons.water,
              title: 'Humidity',
              value: '${care.environment.humidityMin}% - ${care.environment.humidityMax}%',
              color: AppTheme.mintGreen,
            ),
          ],
        ),
      );

  Widget _buildDetailedCareFallback(PlantSpeciesInfo? info, WateringRecommendation rec) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Care Requirements',
                style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
            const SizedBox(height: 16),
            _CareDetailRow(
                icon: Icons.water_drop,
                title: 'Watering',
                value: 'Every ${rec.frequencyDays} days, ${rec.amountML}mL',
                color: AppTheme.waterBlue),
            _CareDetailRow(
                icon: Icons.wb_sunny,
                title: 'Light',
                value: info?.lightRequirement ?? 'Medium indirect light',
                color: AppTheme.sunYellow),
            _CareDetailRow(
                icon: Icons.thermostat,
                title: 'Temperature',
                value: info?.temperatureRange ?? '15-25°C',
                color: AppTheme.terracotta),
            _CareDetailRow(
                icon: Icons.water,
                title: 'Humidity',
                value: info?.humidityPreference ?? 'Medium',
                color: AppTheme.mintGreen),
          ],
        ),
      );

  Widget _buildSoilInfo(CareProfile care) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grass, color: AppTheme.soilBrown),
                const SizedBox(width: 8),
                Text('Soil Requirements',
                    style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.soilBrown.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science, size: 18, color: AppTheme.soilBrown),
                      const SizedBox(width: 8),
                      Text(
                        'pH Range: ${care.soil.phMin} - ${care.soil.phMax}',
                        style: GoogleFonts.quicksand(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    care.soil.type,
                    style: GoogleFonts.quicksand(
                        fontSize: 13, color: AppTheme.soilBrown.withValues(alpha: 0.8), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildGrowthInfo(CareProfile care) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppTheme.leafGreen),
                const SizedBox(width: 8),
                Text('Growth Info',
                    style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _GrowthStat(
                    icon: Icons.height,
                    label: 'Avg Height',
                    value: '${care.growth.avgHeightCm} cm',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _GrowthStat(
                    icon: Icons.calendar_today,
                    label: 'Maturity',
                    value: '${care.growth.maturityDays} days',
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildTipsCard(List<String> tips) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTheme.sunYellow),
                const SizedBox(width: 8),
                Text('Care Tips',
                    style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🌿 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          tip,
                          style: GoogleFonts.quicksand(
                              fontSize: 14, color: AppTheme.soilBrown.withValues(alpha: 0.8), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
}

class _CareStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _CareStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
          Text(label, style: GoogleFonts.quicksand(fontSize: 11, color: AppTheme.soilBrown.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _CareDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  const _CareDetailRow({required this.icon, required this.title, required this.value, this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha: 0.6))),
                Text(value,
                    style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: GoogleFonts.quicksand(fontSize: 11, color: AppTheme.soilBrown.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementsInfoCard extends StatelessWidget {
  final pm.PlantMeasurements measurements;
  const _MeasurementsInfoCard({required this.measurements});
  String _fmt3(num? v) => (v == null) ? '—' : v.toDouble().toStringAsFixed(2);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: AppTheme.leafGreen),
              const SizedBox(width: 8),
              Text(
                'Plant Measurements',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.leafGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('🌱 Plant Height', '${_fmt3(measurements.plantHeightInches)}"'),
          _row('🪴 Pot Width', '${_fmt3(measurements.potWidthInches)}"'),
          _row('📏 Pot Height', '${_fmt3(measurements.potHeightInches)}"'),
          _row('🧪 Pot Volume', '${_fmt3(measurements.potVolumeML)} mL'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.8),
              )),
          Text(value,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.soilBrown,
              )),
        ],
      ),
    );
  }
}

class _GrowthStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _GrowthStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.leafGreen, size: 24),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
          Text(label, style: GoogleFonts.quicksand(fontSize: 11, color: AppTheme.soilBrown.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
