import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/water_level.dart';
import '../../models/watering_schedule.dart';
import '../../models/sensor_data.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../widgets/leaf_background.dart';
import '../gallery/plant_gallery_screen.dart';
import 'schedule_screen.dart';
import 'link_device_screen.dart';
import 'plant_info_screen.dart';
import '../widgets/plant_detail_widgets.dart';

// Result class to pass back both refresh flag and streak
class PlantDetailResult {
  final bool needsRefresh;
  final int? updatedStreak;
  
  PlantDetailResult({this.needsRefresh = false, this.updatedStreak});
}

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  WaterLevel? _waterLevel;
  WateringSchedule? _schedule;
  SensorData? _latestSensor;
  bool _isLoading = true;
  bool _isWatering = false;
  bool _isRefilling = false;
  bool _needsDashboardRefresh = false;
  int? _updatedStreak;
  late Plant _plant;

  Future<void> _refreshPlant() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth.idToken!);

    final updatedPlant = await api.getPlant(_plant.plantId);

    setState(() {
      _plant = updatedPlant;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth.idToken!);

    if (_plant.hasDevice) {
      try {
        final waterLevel = await api.getWaterLevel(_plant.plantId);
        if (mounted) setState(() => _waterLevel = waterLevel);
      } catch (e) { debugPrint('WaterLevel failed: $e'); }

      try {
        final schedule = await api.getWateringSchedule(_plant.plantId);
        if (mounted) setState(() => _schedule = schedule);
      } catch (e) { debugPrint('Schedule failed: $e'); }

      try {
        final sensorData = await api.getLatestSensorData(_plant.plantId, auth.userId!);
        if (mounted) setState(() => _latestSensor = sensorData);
      } catch (e) { debugPrint('Sensor data failed: $e'); }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _triggerWatering() async {
    if (!_plant.hasDevice) { _showSnackBar('Please link a device first', isError: true); return; }
    if (_waterLevel != null && _waterLevel!.needsRefill) {
      _showSnackBar('Please refill the water tank first', isError: true); return;
    }
    setState(() => _isWatering = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      final result = await api.triggerWatering(_plant.plantId, amountML: _schedule?.amountML ?? 100);
      _needsDashboardRefresh = true;
      _showSnackBar('Watering started! ${result['amountML']}mL');
      _loadData();
    } catch (e) { _showSnackBar('$e', isError: true); } 
    finally { if (mounted) setState(() => _isWatering = false); }
  }

  Future<void> _refillWater() async {
    setState(() => _isRefilling = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      await api.refillWater(_plant.plantId, markFull: true);
      _needsDashboardRefresh = true;
      _showSnackBar('Water tank marked as full!');
      _loadData();
    } catch (e) { _showSnackBar('Failed: $e', isError: true); } 
    finally { if (mounted) setState(() => _isRefilling = false); }
  }

  Future<void> _unlinkDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.link_off, color: AppTheme.terracotta),
          const SizedBox(width: 12),
          Text('Unlink Device?', style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        ]),
        content: Text('This will disconnect the sensor from ${_plant.nickname}.', style: GoogleFonts.quicksand(color: AppTheme.soilBrown)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withOpacity(0.7)))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.terracotta), child: const Text('Unlink')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      await api.unlinkDevice(
        plantId: _plant.plantId,
        userId: auth.userId!,
      );

      _needsDashboardRefresh = true;
      _showSnackBar('Device unlinked successfully');

      await _refreshPlant();
      await _loadData();
    } catch (e) {
      _showSnackBar('Failed: $e', isError: true);
    }
  }
  
  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _navigateToSchedule() async {
    if (!_plant.hasDevice) { _showSnackBar('Please link a device first', isError: true); return; }
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleScreen(plant: _plant, schedule: _schedule)));
    if (result == true) _loadData();
  }

  void _navigateToLinkDevice() async {
    final linked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LinkDeviceScreen(plant: _plant),
      ),
    );

    if (linked == true) {
      setState(() {
        _plant = Plant(
          plantId: _plant.plantId,
          userId: _plant.userId,
          nickname: _plant.nickname,
          species: _plant.species,
          esp32DeviceId: 'linked',
          waterPercentage: _plant.waterPercentage,
          streak: _plant.streak,
          currentHealth: _plant.currentHealth,
          environment: _plant.environment,
          addedAt: _plant.addedAt,
          speciesInfo: _plant.speciesInfo,
        );
      });
      _needsDashboardRefresh = true;
      await _loadData();
    }
  }

  void _navigateToGallery() async {
    final newStreak = await Navigator.push<int?>(
      context, 
      MaterialPageRoute(builder: (_) => PlantGalleryScreen(plant: _plant)),
    );
    
    // If streak was updated in gallery, store it to pass back to dashboard
    if (newStreak != null) {
      _updatedStreak = newStreak;
    }
  }
  
  void _navigateToPlantInfo() => Navigator.push(context, MaterialPageRoute(builder: (_) => PlantInfoScreen(plant: _plant)));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Return both refresh flag and streak
          Navigator.pop(context, PlantDetailResult(
            needsRefresh: _needsDashboardRefresh,
            updatedStreak: _updatedStreak,
          ));
        }
      },
      child: Scaffold(
        body: LeafBackground(
          leafCount: 4,
          child: SafeArea(
            child: Column(
              children: [
                PlantDetailHeader(
                  plant: _plant,
                  onBack: () => Navigator.pop(context, PlantDetailResult(
                    needsRefresh: _needsDashboardRefresh,
                    updatedStreak: _updatedStreak,
                  )),
                  onInfo: _navigateToPlantInfo,
                  onGallery: _navigateToGallery,
                  onUnlink: _plant.hasDevice ? _unlinkDevice : null,
                ),
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
                                PlantInfoCard(plant: _plant),
                                const SizedBox(height: 20),
                                QuickActionsRow(
                                  plant: _plant,
                                  isWatering: _isWatering,
                                  onWater: _triggerWatering,
                                  onGallery: _navigateToGallery,
                                  onInfo: _navigateToPlantInfo,
                                ),
                                const SizedBox(height: 20),
                                if (_plant.hasDevice) ...[
                                  SensorDataCard(sensorData: _latestSensor),
                                  const SizedBox(height: 16),
                                  WaterLevelCard(
                                    waterLevel: _waterLevel,
                                    isRefilling: _isRefilling,
                                    onRefill: _refillWater,
                                  ),
                                  const SizedBox(height: 16),
                                  ScheduleCard(
                                    schedule: _schedule,
                                    onTap: _navigateToSchedule,
                                  ),
                                ] else ...[
                                  LinkDeviceCard(onLink: _navigateToLinkDevice),
                                  const SizedBox(height: 16),
                                  ManualCareCard(plant: _plant),
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
}