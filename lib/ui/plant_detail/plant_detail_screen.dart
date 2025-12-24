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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      // Only load water level and schedule if device is linked
      if (widget.plant.hasDevice) {
        final waterLevel = await api.getWaterLevel(widget.plant.plantId);
        final schedule = await api.getWateringSchedule(widget.plant.plantId);

        if (mounted) {
          setState(() {
            _waterLevel = waterLevel;
            _schedule = schedule;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _triggerWatering() async {
    if (!widget.plant.hasDevice) {
      _showSnackBar('Please link a device first', isError: true);
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

      _showSnackBar('Watering started! ${result['amountML']}mL');
      _loadData(); // Refresh water level
    } catch (e) {
      _showSnackBar('$e', isError: true);
    } finally {
      if (mounted) setState(() => _isWatering = false);
    }
  }

  Future<void> _refillWater() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      await api.refillWater(widget.plant.plantId);
      _showSnackBar('Water tank refilled!');
      _loadData();
    } catch (e) {
      _showSnackBar('Failed to mark as refilled', isError: true);
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
      // Refresh the plant data from parent
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              if (!widget.plant.hasDevice) _buildLinkDeviceCard(),
                              if (widget.plant.hasDevice) ...[
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
    );
  }

  Widget _buildHeader() {
    return Padding(
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              const Icon(Icons.water_drop, color: AppTheme.waterBlue),
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
              if (_waterLevel!.needsRefill)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.terracotta.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Needs Refill!',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.terracotta,
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
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.waterBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (_waterLevel!.waterPercentage / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.waterBlue, AppTheme.waterBlueDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${_waterLevel!.waterPercentage.toInt()}%',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _waterLevel!.waterPercentage > 50 
                          ? Colors.white 
                          : AppTheme.soilBrown,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_waterLevel!.currentWaterLevel}mL / ${_waterLevel!.containerSize}mL',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: AppTheme.soilBrown.withOpacity(0.7),
                ),
              ),
              TextButton.icon(
                onPressed: _refillWater,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Mark Refilled'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.waterBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.water_drop,
            label: 'Water Now',
            color: AppTheme.waterBlue,
            isLoading: _isWatering,
            onTap: _triggerWatering,
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
              Switch(
                value: _schedule!.enabled,
                onChanged: (value) => _navigateToSchedule(),
                activeColor: AppTheme.leafGreen,
              ),
            ],
          ),
          if (_schedule!.enabled && _schedule!.recurringSchedule != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.repeat, size: 16, color: AppTheme.soilBrown.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  _schedule!.recurringSchedule!.formattedDays,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: AppTheme.soilBrown.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.soilBrown.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  _schedule!.recurringSchedule!.timeOfDay,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: AppTheme.soilBrown.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.water_drop, size: 16, color: AppTheme.soilBrown.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  '${_schedule!.amountML}mL',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: AppTheme.soilBrown.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
          if (!_schedule!.enabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Automatic watering is disabled',
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
