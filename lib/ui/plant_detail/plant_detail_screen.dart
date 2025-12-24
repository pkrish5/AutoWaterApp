import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/water_level.dart';
import '../../models/watering_schedule.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../widgets/leaf_background.dart';
import 'schedule_screen.dart';
import 'link_device_screen.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  WaterLevel? _waterLevel;
  WateringSchedule? _schedule;
  bool _isLoading = true;
  bool _isWatering = false;
  bool _isRefilling = false;
  bool _needsDashboardRefresh = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _triggerWatering() async {
    if (!widget.plant.hasDevice) {
      _showSnackBar('Please link a device first', isError: true);
      return;
    }

    if (_waterLevel != null && _waterLevel!.needsRefill) {
      _showSnackBar('Please refill the water tank first', isError: true);
      return;
    }

    setState(() => _isWatering = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final result = await api.triggerWatering(
        widget.plant.plantId,
        amountML: _schedule?.amountML ?? 100,
      );
      _needsDashboardRefresh = true;

      _showSnackBar('Watering started! ${result['amountML']}mL');
      _loadData(); // Refresh water level
    } catch (e) {
      _showSnackBar('$e', isError: true);
    } finally {
      if (mounted) setState(() => _isWatering = false);
    }
  }

  Future<void> _refillWater() async {
    setState(() => _isRefilling = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      await api.refillWater(widget.plant.plantId, markFull: true);
      _needsDashboardRefresh = true;
      _showSnackBar('Water tank marked as full!');
      _loadData();
    } catch (e) {
      _showSnackBar('Failed to mark as refilled: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isRefilling = false);
    }
  }

  void _showRefillDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.water_drop, color: AppTheme.waterBlue),
            const SizedBox(width: 12),
            Text(
              'Refill Water Tank',
              style: GoogleFonts.comfortaa(
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have you refilled the water container?',
              style: GoogleFonts.quicksand(color: AppTheme.soilBrown),
            ),
            const SizedBox(height: 12),
            if (_waterLevel != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.softSage.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: AppTheme.leafGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current: ${_waterLevel!.currentWaterLevel}mL / ${_waterLevel!.containerSize}mL',
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          color: AppTheme.soilBrown.withOpacity(0.8),
                        ),
                      ),
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
              'Cancel',
              style: GoogleFonts.quicksand(
                color: AppTheme.soilBrown.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _refillWater();
            },
            icon: const Icon(Icons.check, size: 18),
            label: Text(
              'Mark as Full',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.waterBlue,
            ),
          ),
        ],
      ),
    );
  }
 

 Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  final auth = Provider.of<AuthService>(context, listen: false);
  final api = ApiService(auth.idToken!);

  try {
    final waterLevel = await api.getWaterLevel(widget.plant.plantId);
    if (mounted) setState(() => _waterLevel = waterLevel);
  } catch (e) {
    debugPrint('WaterLevel failed: $e');
  }

  try {
    final schedule = await api.getWateringSchedule(widget.plant.plantId);
    if (mounted) setState(() => _schedule = schedule);
  } catch (e) {
    debugPrint('Schedule failed: $e');
  }

  if (mounted) {
    setState(() => _isLoading = false);
  }
}

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToSchedule() async {
    if (!widget.plant.hasDevice) {
      _showSnackBar('Please link a device first', isError: true);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleScreen(
          plant: widget.plant,
          schedule: _schedule,
        ),
      ),
    );

    if (result == true) _loadData();
  }

  void _navigateToLinkDevice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LinkDeviceScreen(plant: widget.plant),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // we handle popping manually
    onPopInvoked: (didPop) {
      if (didPop) return;

      Navigator.pop(context, _needsDashboardRefresh);
    },
    child: Scaffold(
      body: LeafBackground(
        leafCount: 4,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildPlantInfo(),
                              const SizedBox(height: 20),
                              if (!widget.plant.hasDevice) ...[
                                _buildLinkDeviceCard(),
                              ] else if (_waterLevel != null) ...[
                                _buildWaterLevelCard(),
                                const SizedBox(height: 16),
                                _buildQuickActions(),
                                const SizedBox(height: 16),
                                _buildScheduleCard(),
                                const SizedBox(height: 16),
                                if (widget.plant.currentHealth != null)
                                  _buildSensorCard(),
                              ],
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, _needsDashboardRefresh);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen),
            ),
          ),
          const Spacer(),
          Text(
            widget.plant.nickname,
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
  }

  Widget _buildPlantInfo() {
    String emoji = '🪴';
    switch (widget.plant.species.toLowerCase()) {
      case 'vine':
        emoji = '🌿';
        break;
      case 'spiky':
        emoji = '🌵';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.leafGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            widget.plant.species,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              color: AppTheme.soilBrown.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.plant.hasDevice ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                size: 16,
                color: widget.plant.hasDevice ? AppTheme.leafGreen : AppTheme.terracotta,
              ),
              const SizedBox(width: 6),
              Text(
                widget.plant.hasDevice 
                    ? 'Device: ${widget.plant.esp32DeviceId}'
                    : 'No device linked',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: widget.plant.hasDevice 
                      ? AppTheme.leafGreen 
                      : AppTheme.terracotta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.terracotta.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.terracotta.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.sensors_off, size: 48, color: AppTheme.terracotta),
          const SizedBox(height: 12),
          Text(
            'No Device Connected',
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.terracotta,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Link an ESP32 sensor to track water levels and enable automatic watering.',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToLinkDevice,
            icon: const Icon(Icons.add_link),
            label: const Text('Link Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterLevelCard() {
    if (_waterLevel == null) return const SizedBox.shrink();

    final percentage = _waterLevel!.waterPercentage;
    final isLow = percentage < 20;
    final isCritical = _waterLevel!.needsRefill;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCritical ? Border.all(color: AppTheme.terracotta, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.waterBlue.withOpacity(0.1),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop,
                color: isCritical ? AppTheme.terracotta : AppTheme.waterBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Water Tank',
                style: GoogleFonts.comfortaa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.soilBrown,
                ),
              ),
              const Spacer(),
              if (isCritical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.terracotta,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Needs Refill!',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isLow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Low',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Water level bar
          Stack(
            children: [
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.waterBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCritical
                          ? [AppTheme.terracotta.withOpacity(0.8), AppTheme.terracotta]
                          : isLow
                              ? [Colors.orange.withOpacity(0.8), Colors.orange]
                              : [AppTheme.waterBlue, AppTheme.waterBlueDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${percentage.toInt()}%',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: percentage > 40 ? Colors.white : AppTheme.soilBrown,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_waterLevel!.currentWaterLevel}mL / ${_waterLevel!.containerSize}mL',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last refilled: ${_waterLevel!.lastRefilledFormatted}',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.soilBrown.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Refill Button
              ElevatedButton.icon(
                onPressed: _isRefilling ? null : _showRefillDialog,
                icon: _isRefilling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.local_drink, size: 18),
                label: Text(
                  'Refill',
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.waterBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final canWater = _waterLevel != null && !_waterLevel!.needsRefill;
    
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.water_drop,
            label: 'Water Now',
            color: canWater ? AppTheme.waterBlue : Colors.grey,
            isLoading: _isWatering,
            onTap: canWater ? _triggerWatering : () {
              _showSnackBar('Please refill the water tank first', isError: true);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.schedule,
            label: 'Schedule',
            color: AppTheme.leafGreen,
            onTap: _navigateToSchedule,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard() {
    if (_schedule == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.leafGreen),
              const SizedBox(width: 8),
              Text(
                'Watering Schedule',
                style: GoogleFonts.comfortaa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.soilBrown,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _schedule!.enabled 
                      ? AppTheme.leafGreen.withOpacity(0.1)
                      : AppTheme.soilBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _schedule!.enabled ? 'Active' : 'Off',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _schedule!.enabled ? AppTheme.leafGreen : AppTheme.soilBrown,
                  ),
                ),
              ),
            ],
          ),
          if (_schedule!.enabled && _schedule!.recurringSchedule != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _ScheduleInfoChip(
                  icon: Icons.repeat,
                  text: _schedule!.recurringSchedule!.formattedDays,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ScheduleInfoChip(
                  icon: Icons.access_time,
                  text: _schedule!.recurringSchedule!.timeOfDay,
                ),
                const SizedBox(width: 12),
                _ScheduleInfoChip(
                  icon: Icons.water_drop,
                  text: '${_schedule!.amountML}mL',
                ),
                const SizedBox(width: 12),
                _ScheduleInfoChip(
                  icon: Icons.speed,
                  text: '>${_schedule!.moistureThreshold}%',
                ),
              ],
            ),
          ],
          if (!_schedule!.enabled)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Tap Schedule to set up automatic watering',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: AppTheme.soilBrown.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorCard() {
    final health = widget.plant.currentHealth!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors, color: AppTheme.leafGreen),
              const SizedBox(width: 8),
              Text(
                'Sensor Readings',
                style: GoogleFonts.comfortaa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.soilBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SensorTile(
                icon: Icons.water_drop,
                label: 'Moisture',
                value: health.moisture != null ? '${health.moisture!.toInt()}%' : '--',
                color: AppTheme.waterBlue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _SensorTile(
                icon: Icons.wb_sunny,
                label: 'Light',
                value: health.light != null ? '${health.light!.toInt()} lux' : '--',
                color: AppTheme.sunYellow,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SensorTile(
                icon: Icons.thermostat,
                label: 'Temp',
                value: health.temperature != null ? '${health.temperature!.toStringAsFixed(1)}°C' : '--',
                color: AppTheme.terracotta,
              )),
              const SizedBox(width: 12),
              Expanded(child: _SensorTile(
                icon: Icons.water,
                label: 'Humidity',
                value: health.humidity != null ? '${health.humidity!.toInt()}%' : '--',
                color: AppTheme.mintGreen,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ScheduleInfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.soilBrown.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: AppTheme.soilBrown.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SensorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 11,
              color: AppTheme.soilBrown.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
