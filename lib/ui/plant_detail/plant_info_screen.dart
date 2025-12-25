import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../widgets/leaf_background.dart';

class PlantInfoScreen extends StatelessWidget {
  final Plant plant;
  const PlantInfoScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final info = plant.speciesInfo;
    final recommendation = plant.wateringRecommendation;

    return Scaffold(body: LeafBackground(leafCount: 4, child: SafeArea(child: Column(children: [
      _buildHeader(context),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeroCard(),
        const SizedBox(height: 20),
        _buildCareOverview(info, recommendation),
        const SizedBox(height: 20),
        _buildDetailedCare(info, recommendation),
        if (info?.tips != null && info!.tips!.isNotEmpty) ...[const SizedBox(height: 20), _buildTipsCard(info.tips!)],
        const SizedBox(height: 40),
      ]))),
    ]))));
  }

  Widget _buildHeader(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    IconButton(onPressed: () => Navigator.pop(context), icon: Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen))),
    const Spacer(),
    Text('Plant Info', style: GoogleFonts.comfortaa(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
    const Spacer(), const SizedBox(width: 48),
  ]));

  Widget _buildHeroCard() {
    String emoji = '🪴';
    switch (plant.species.toLowerCase()) {
      case 'vine': case 'pothos': emoji = '🌿'; break;
      case 'spiky': case 'cactus': emoji = '🌵'; break;
      case 'tropical': case 'monstera': emoji = '🌴'; break;
    }

    return Container(padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        Text(plant.speciesInfo?.commonName ?? plant.species, style: GoogleFonts.comfortaa(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        if (plant.speciesInfo?.scientificName != null) Text(plant.speciesInfo!.scientificName, style: GoogleFonts.quicksand(fontSize: 14, fontStyle: FontStyle.italic, color: AppTheme.soilBrown.withOpacity(0.6))),
        const SizedBox(height: 12),
        if (plant.speciesInfo?.careLevel != null) Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: _careLevelColor(plant.speciesInfo!.careLevel!).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('${plant.speciesInfo!.careLevel} Care', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: _careLevelColor(plant.speciesInfo!.careLevel!)))),
        if (plant.speciesInfo?.description != null) ...[const SizedBox(height: 16),
          Text(plant.speciesInfo!.description!, style: GoogleFonts.quicksand(fontSize: 14, color: AppTheme.soilBrown.withOpacity(0.8), height: 1.5), textAlign: TextAlign.center)],
      ]));
  }

  Color _careLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'easy': return AppTheme.leafGreen;
      case 'medium': return Colors.orange;
      case 'hard': return AppTheme.terracotta;
      default: return AppTheme.soilBrown;
    }
  }

  Widget _buildCareOverview(PlantSpeciesInfo? info, WateringRecommendation rec) => Row(children: [
    Expanded(child: _CareStatCard(icon: Icons.water_drop, label: 'Water', value: 'Every ${rec.frequencyDays}d', color: AppTheme.waterBlue)),
    const SizedBox(width: 12),
    Expanded(child: _CareStatCard(icon: Icons.local_drink, label: 'Amount', value: '${rec.amountML}mL', color: AppTheme.leafGreen)),
    const SizedBox(width: 12),
    Expanded(child: _CareStatCard(icon: Icons.wb_sunny, label: 'Light', value: info?.lightRequirement?.split(' ').first ?? 'Medium', color: AppTheme.sunYellow)),
  ]);

  Widget _buildDetailedCare(PlantSpeciesInfo? info, WateringRecommendation rec) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Care Requirements', style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
      const SizedBox(height: 16),
      _CareDetailRow(icon: Icons.water_drop, title: 'Watering', value: 'Every ${rec.frequencyDays} days, ${rec.amountML}mL', color: AppTheme.waterBlue),
      _CareDetailRow(icon: Icons.wb_sunny, title: 'Light', value: info?.lightRequirement ?? 'Medium indirect light', color: AppTheme.sunYellow),
      _CareDetailRow(icon: Icons.thermostat, title: 'Temperature', value: info?.temperatureRange ?? '15-25°C', color: AppTheme.terracotta),
      _CareDetailRow(icon: Icons.water, title: 'Humidity', value: info?.humidityPreference ?? 'Medium', color: AppTheme.mintGreen),
    ]));

  Widget _buildTipsCard(List<String> tips) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppTheme.softSage.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.lightbulb_outline, color: AppTheme.sunYellow), const SizedBox(width: 8),
        Text('Care Tips', style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.soilBrown))]),
      const SizedBox(height: 12),
      ...tips.map((tip) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🌿 ', style: TextStyle(fontSize: 14)),
        Expanded(child: Text(tip, style: GoogleFonts.quicksand(fontSize: 14, color: AppTheme.soilBrown.withOpacity(0.8), height: 1.4)))]))),
    ]));
}

class _CareStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _CareStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, color: color, size: 28), const SizedBox(height: 8),
        Text(value, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        Text(label, style: GoogleFonts.quicksand(fontSize: 11, color: AppTheme.soilBrown.withOpacity(0.6))),
      ]));
  }
}

class _CareDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  const _CareDetailRow({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withOpacity(0.6))),
        Text(value, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
      ])),
    ]));
  }
}