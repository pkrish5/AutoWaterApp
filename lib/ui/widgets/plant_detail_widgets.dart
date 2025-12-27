import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/water_level.dart';
import '../../models/watering_schedule.dart';
import '../../models/sensor_data.dart';

class PlantDetailHeader extends StatelessWidget {
  final Plant plant;
  final VoidCallback onBack;
  final VoidCallback onInfo;
  final VoidCallback onGallery;
  final VoidCallback? onUnlink;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlantDetailHeader({super.key, required this.plant, required this.onBack, 
    required this.onInfo, required this.onGallery, this.onUnlink, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      IconButton(onPressed: onBack, icon: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen))),
      const Spacer(),
      Text(plant.nickname, style: GoogleFonts.comfortaa(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
      const Spacer(),
      PopupMenuButton<String>(
        icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.more_vert, color: AppTheme.soilBrown)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (_) => [
          if (onEdit != null) PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, color: AppTheme.leafGreen), const SizedBox(width: 12), Text('Edit Plant', style: GoogleFonts.quicksand())])),
          PopupMenuItem(value: 'info', child: Row(children: [const Icon(Icons.info_outline, color: AppTheme.leafGreen), const SizedBox(width: 12), Text('Plant Info', style: GoogleFonts.quicksand())])),
          PopupMenuItem(value: 'gallery', child: Row(children: [const Icon(Icons.photo_library, color: AppTheme.waterBlue), const SizedBox(width: 12), Text('Photo Gallery', style: GoogleFonts.quicksand())])),
          if (onUnlink != null) PopupMenuItem(value: 'unlink', child: Row(children: [const Icon(Icons.link_off, color: AppTheme.terracotta), const SizedBox(width: 12), Text('Unlink Device', style: GoogleFonts.quicksand())])),
          if (onDelete != null) PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_forever, color: AppTheme.terracotta), const SizedBox(width: 12), Text('Delete Plant', style: GoogleFonts.quicksand(color: AppTheme.terracotta))])),
        ],
        onSelected: (v) { 
          if (v == 'edit') onEdit?.call(); 
          else if (v == 'info') onInfo(); 
          else if (v == 'gallery') onGallery(); 
          else if (v == 'unlink') onUnlink?.call(); 
          else if (v == 'delete') onDelete?.call();
        },
      ),
    ]));
  }
}

class PlantInfoCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback? onEdit; 
  const PlantInfoCard({super.key, required this.plant, this.onEdit}); 

  String get _emoji {
    switch (plant.species.toLowerCase()) {
      case 'vine': case 'pothos': return '🌿';
      case 'spiky': case 'cactus': return '🌵';
      case 'tropical': case 'monstera': return '🌴';
      default: return '🪴';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppTheme.leafGreen.withValues(alpha:0.1), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(children: [
          Text(_emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(plant.species, style: GoogleFonts.quicksand(fontSize: 16, color: AppTheme.soilBrown.withValues(alpha:0.7))),
            if (onEdit != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.edit, size: 14, color: AppTheme.soilBrown.withValues(alpha:0.4)),
            ],
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(plant.hasDevice ? Icons.bluetooth_connected : Icons.bluetooth_disabled, size: 16, color: plant.hasDevice ? AppTheme.leafGreen : AppTheme.terracotta),
            const SizedBox(width: 6),
            Text(plant.hasDevice ? 'Device: ${plant.esp32DeviceId}' : 'No device linked',
              style: GoogleFonts.quicksand(fontSize: 12, color: plant.hasDevice ? AppTheme.leafGreen : AppTheme.terracotta)),
          ]),
        ]),
      ),
    );
  }
}

class QuickActionsRow extends StatelessWidget {
  final Plant plant;
  final bool isWatering;
  final VoidCallback onWater;
  final VoidCallback onGallery;
  final VoidCallback onInfo;

  const QuickActionsRow({super.key, required this.plant, required this.isWatering, 
    required this.onWater, required this.onGallery, required this.onInfo});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _QuickActionCard(icon: Icons.photo_camera, label: 'Photo', color: AppTheme.terracotta, onTap: onGallery)),
      const SizedBox(width: 12),
      Expanded(child: _QuickActionCard(icon: Icons.info_outline, label: 'Info', color: AppTheme.leafGreen, onTap: onInfo)),
      if (plant.hasDevice) ...[const SizedBox(width: 12),
        Expanded(child: _QuickActionCard(icon: Icons.water_drop, label: 'Water', color: AppTheme.waterBlue, isLoading: isWatering, onTap: onWater))],
    ]);
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: isLoading ? null : onTap,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha:0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
          else Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    );
  }
}

class SensorDataCard extends StatelessWidget {
  final SensorData? sensorData;
  const SensorDataCard({super.key, this.sensorData});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.sensors, color: AppTheme.leafGreen), const SizedBox(width: 8),
          Text('Latest Sensor Data', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
          const Spacer(),
          if (sensorData != null) Text(sensorData!.lastUpdateFormatted, style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.5))),
        ]),
        const SizedBox(height: 16),
        if (sensorData != null) ...[
          _MoistureIndicator(moisture: sensorData!.moisture ?? 0, status: sensorData!.moistureStatus),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _SensorTile(icon: Icons.wb_sunny, label: 'Light', value: sensorData!.light != null ? '${sensorData!.light!.toInt()} lux' : '--', color: AppTheme.sunYellow)),
            const SizedBox(width: 12),
            Expanded(child: _SensorTile(icon: Icons.thermostat, label: 'Temp', value: sensorData!.temperature != null ? '${sensorData!.temperature!.toStringAsFixed(1)}°C' : '--', color: AppTheme.terracotta)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SensorTile(icon: Icons.water, label: 'Humidity', value: sensorData!.humidity != null ? '${sensorData!.humidity!.toInt()}%' : '--', color: AppTheme.mintGreen)),
            const SizedBox(width: 12),
            Expanded(child: _SensorTile(icon: Icons.science, label: 'pH', value: sensorData!.ph != null ? sensorData!.ph!.toStringAsFixed(1) : '--', color: Colors.purple)),
          ]),
        ] else Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No sensor data yet', style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha:0.5))))),
      ]),
    );
  }
}

class _MoistureIndicator extends StatelessWidget {
  final double moisture;
  final MoistureStatus status;
  const _MoistureIndicator({required this.moisture, required this.status});

  Color get _color {
    switch (status) {
      case MoistureStatus.optimal: return AppTheme.leafGreen;
      case MoistureStatus.good: return AppTheme.waterBlue;
      case MoistureStatus.low: return Colors.orange;
      case MoistureStatus.critical: return AppTheme.terracotta;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(16),
        border: status == MoistureStatus.critical ? Border.all(color: _color, width: 2) : null),
      child: Row(children: [
        Icon(Icons.water_drop, color: _color, size: 32), const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Soil Moisture', style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.6))),
          Row(children: [
            Text('${moisture.toInt()}%', style: GoogleFonts.comfortaa(fontSize: 24, fontWeight: FontWeight.bold, color: _color)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(8)),
              child: Text(status.label, style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
          ]),
        ])),
      ]),
    );
  }
}

class _SensorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SensorTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: color, size: 24), const SizedBox(height: 4),
        Text(value, style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        Text(label, style: GoogleFonts.quicksand(fontSize: 11, color: AppTheme.soilBrown.withValues(alpha:0.6))),
      ]),
    );
  }
}

class WaterLevelCard extends StatelessWidget {
  final WaterLevel? waterLevel;
  final bool isRefilling;
  final VoidCallback onRefill;
  const WaterLevelCard({super.key, this.waterLevel, required this.isRefilling, required this.onRefill});

  @override
  Widget build(BuildContext context) {
    if (waterLevel == null) return const SizedBox.shrink();
    final pct = waterLevel!.waterPercentage;
    final critical = waterLevel!.needsRefill;
    return Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: critical ? Border.all(color: AppTheme.terracotta, width: 2) : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.water_drop, color: critical ? AppTheme.terracotta : AppTheme.waterBlue), const SizedBox(width: 8),
          Text('Water Tank', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
          const Spacer(),
          if (critical) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppTheme.terracotta, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.warning, color: Colors.white, size: 14), const SizedBox(width: 4), Text('Refill!', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))])),
        ]),
        const SizedBox(height: 16),
        Stack(children: [
          Container(height: 32, decoration: BoxDecoration(color: AppTheme.waterBlue.withValues(alpha:0.15), borderRadius: BorderRadius.circular(16))),
          FractionallySizedBox(widthFactor: (pct / 100).clamp(0.0, 1.0),
            child: Container(height: 32, decoration: BoxDecoration(gradient: LinearGradient(colors: critical ? [AppTheme.terracotta.withValues(alpha:0.8), AppTheme.terracotta] : [AppTheme.waterBlue, AppTheme.waterBlueDark]), borderRadius: BorderRadius.circular(16)))),
          Positioned.fill(child: Center(child: Text('${pct.toInt()}%', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.bold, color: pct > 40 ? Colors.white : AppTheme.soilBrown)))),
        ]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${waterLevel!.currentWaterLevel}mL / ${waterLevel!.containerSize}mL', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
          Text('Last refilled: ${waterLevel!.lastRefilledFormatted}', style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.6)))])),
          ElevatedButton.icon(onPressed: isRefilling ? null : onRefill,
            icon: isRefilling ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Icon(Icons.local_drink, size: 18),
            label: Text('Refill', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.waterBlue)),
        ]),
      ]),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  final WateringSchedule? schedule;
  final VoidCallback onTap;
  const ScheduleCard({super.key, this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.leafGreen.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.schedule, color: AppTheme.leafGreen)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Watering Schedule', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
          Text(schedule?.enabled == true ? 'Active - ${schedule?.recurringSchedule?.formattedDays ?? 'Custom'}' : 'Tap to configure', style: GoogleFonts.quicksand(fontSize: 13, color: AppTheme.soilBrown.withValues(alpha:0.6)))])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: schedule?.enabled == true ? AppTheme.leafGreen.withValues(alpha:0.1) : AppTheme.soilBrown.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(schedule?.enabled == true ? 'On' : 'Off', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: schedule?.enabled == true ? AppTheme.leafGreen : AppTheme.soilBrown))),
        const SizedBox(width: 8), const Icon(Icons.chevron_right, color: AppTheme.soilBrown),
      ])));
  }
}

class LinkDeviceCard extends StatelessWidget {
  final VoidCallback onLink;
  const LinkDeviceCard({super.key, required this.onLink});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.terracotta.withValues(alpha:0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.terracotta.withValues(alpha:0.3))),
      child: Column(children: [
        const Icon(Icons.sensors_off, size: 48, color: AppTheme.terracotta), const SizedBox(height: 12),
        Text('No Device Connected', style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.terracotta)),
        const SizedBox(height: 8),
        Text('Link an ESP32 sensor to enable auto watering.', style: GoogleFonts.quicksand(fontSize: 14, color: AppTheme.soilBrown.withValues(alpha:0.7)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: onLink, icon: const Icon(Icons.add_link), label: const Text('Link Device'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.terracotta)),
      ]));
  }
}

class ManualCareCard extends StatelessWidget {
  final Plant plant;
  const ManualCareCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final rec = plant.wateringRecommendation;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.eco, color: AppTheme.leafGreen), const SizedBox(width: 8),
          Text('Manual Care Guide', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown))]),
        const SizedBox(height: 16),
        _CareRow(icon: Icons.water_drop, text: 'Water every ${rec.frequencyDays} days', color: AppTheme.waterBlue),
        _CareRow(icon: Icons.local_drink, text: '${rec.amountML}mL per watering', color: AppTheme.leafGreen),
        const SizedBox(height: 8),
        Text(rec.description, style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.6), fontStyle: FontStyle.italic)),
      ]));
  }
}

class _CareRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _CareRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Icon(icon, size: 18, color: color), const SizedBox(width: 10),
      Text(text, style: GoogleFonts.quicksand(fontSize: 14, color: AppTheme.soilBrown)),
    ]));
  }
}