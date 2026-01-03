import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/plant_measurements.dart' as plant_measurements;
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
import '../widgets/room_selector.dart';
import '../widgets/searchable_species_selector.dart';
import '../../models/plant_profile.dart';
import '../community/subforum_screen.dart';
import '../../models/forum.dart';
import '../../services/care_reminder_service.dart';
import '../widgets/plant_care_card.dart';
import '../reminders/plant_care_schedule_screen.dart';
//import 'package:permission_handler/permission_handler.dart';
import '../widgets/plant_light_check_screen.dart';
import 'pot_meter_screen.dart';

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
  bool _isEditDialogOpen = false;
  bool _isLocationSheetOpen = false;
  bool _childJustClosed = false;

  int? _updatedStreak;
  
  late Plant _plant;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _loadData();
    
  }
  void _navigateToCareSchedule() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlantCareScheduleScreen(plant: _plant),
    ),
  );
}

void _navigateToPotMeter() async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PotMeterScreen(plant: _plant)),
  );

  // after coming back, reload from backend
  _needsDashboardRefresh = true;
}
void _checkLight() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlantLightCheckScreen(plant: _plant),
    ),
  );
}
void _navigateToLightMeter() {
  // Navigate to your existing light meter screen
  // Or implement light sensing here
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PlantLightCheckScreen(plant: _plant)),
  );
}
ApiService? _apiOrNull() {
  final auth = Provider.of<AuthService>(context, listen: false);

  if (auth.idToken == null || auth.idToken!.isEmpty) {
    _showSnackBar('Session expired. Please log in again.', isError: true);
    return null;
  }
  return ApiService(auth.idToken!);
}


void _navigateToCommunity() {
  // Use scientific name as subforumId (matches your DynamoDB structure)
  final scientificName = _plant.speciesInfo?.scientificName ?? _plant.species;
  final commonName = _plant.speciesInfo?.commonName ?? _plant.species;
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SubforumScreen(
        subforum: Subforum(
          subforumId: scientificName,
          speciesId: scientificName,
          name: commonName,
          emoji: _plant.emoji,
          memberCount: 0,
          postCount: 0,
          createdAt: DateTime.now(),
        ),
      ),
    ),
  );
}
  Future<void> _deletePlant() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppTheme.terracotta),
            const SizedBox(width: 12),
            Text(
              'Delete Plant?',
              style: GoogleFonts.comfortaa(
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${_plant.nickname}?',
              style: GoogleFonts.quicksand(color: AppTheme.soilBrown),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.terracotta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppTheme.terracotta, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: GoogleFonts.quicksand(
                        color: AppTheme.terracotta,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.quicksand(
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.terracotta),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final success = await api.deletePlant(_plant.plantId, auth.userId!);

      if (success && mounted) {
        Navigator.pop(
          context,
          PlantDetailResult(
            needsRefresh: true,
            updatedStreak: _updatedStreak,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_plant.nickname} has been deleted'),
            backgroundColor: AppTheme.leafGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Failed to delete: $e', isError: true);
    }
  }

  Future<void> _refreshPlant() async {
  final api = _apiOrNull();
  if (api == null) return;

  final updatedPlant = await api.getPlant(_plant.plantId);
  if (!mounted) return;

  debugPrint('🌱 Refreshed plant location: ${updatedPlant.environment?.location?.room} - ${updatedPlant.environment?.location?.windowProximity}');
  setState(() => _plant = updatedPlant);
}

  Future<void> _loadData() async {
  setState(() => _isLoading = true);

  final auth = Provider.of<AuthService>(context, listen: false);
  final api = _apiOrNull();
  if (api == null) {
    if (mounted) setState(() => _isLoading = false);
    return;
  }

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
      // auth.userId can also be null depending on your AuthService lifecycle
      if (auth.userId != null) {
        final sensorData = await api.getLatestSensorData(_plant.plantId, auth.userId!);
        if (mounted) setState(() => _latestSensor = sensorData);
      }
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha: 0.7)))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.terracotta), child: const Text('Unlink')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      await api.unlinkDevice(plantId: _plant.plantId, userId: auth.userId!);
      _needsDashboardRefresh = true;
      _showSnackBar('Device unlinked successfully');
      await _refreshPlant();
      await _loadData();
      final reminderService = CareReminderService();
      await reminderService.initialize();
      await reminderService.updateRemindersForSensorChange(_plant);
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
    final linked = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => LinkDeviceScreen(plant: _plant)));
    if (linked == true) {
      _needsDashboardRefresh = true;
      await _refreshPlant();
      await _loadData();
    }
  }

  void _navigateToGallery() async {
    final newStreak = await Navigator.push<int?>(context, MaterialPageRoute(builder: (_) => PlantGalleryScreen(plant: _plant)));
    if (newStreak != null) {
      _updatedStreak = newStreak;
    }
  }
  
  void _navigateToPlantInfo() => Navigator.push(context, MaterialPageRoute(builder: (_) => PlantInfoScreen(plant: _plant)));

  void _showEditLocationDialog() async {
    if (_isLocationSheetOpen) return;
    _isLocationSheetOpen = true;

    try {
      RoomLocation? currentLocation;
      if (_plant.environment?.location != null) {
        final loc = _plant.environment!.location!;
        currentLocation = RoomLocation(
          room: loc.room ?? 'Not set',
          spot: loc.windowProximity,
          sunExposure: loc.sunExposure,
        );
      }

      final selectedLocation = await showModalBottomSheet<RoomLocation>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _LocationPickerSheet(initialLocation: currentLocation),
      );

      if (selectedLocation != null && mounted) {
        await _updatePlantLocation(selectedLocation);
      }
    } finally {
      _isLocationSheetOpen = false;
    }
  }

  Future<void> _updatePlantLocation(RoomLocation location) async {
  try {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth.idToken!);
    
    // Infer indoor/outdoor from room
    const outdoorRooms = ['Balcony', 'Patio', 'Back Garden', 'Front Yard', 'Greenhouse'];
    final isOutdoor = outdoorRooms.contains(location.room);
    
    final locationData = {
      'room': location.room,
      if (location.spot != null && location.spot!.isNotEmpty) 'windowProximity': location.spot,
      if (location.sunExposure != null) 'sunExposure': location.sunExposure,
    };
    
    await api.updatePlant(
      plantId: _plant.plantId,
      location: locationData,
      environment: {'type': isOutdoor ? 'outdoor' : 'indoor'},
    );
      
      setState(() {
        _plant = Plant(
          plantId: _plant.plantId,
          userId: _plant.userId,
          nickname: _plant.nickname,
          species: _plant.species,
          esp32DeviceId: _plant.esp32DeviceId,
          waterPercentage: _plant.waterPercentage,
          streak: _plant.streak,
          currentHealth: _plant.currentHealth,
          environment: PlantEnvironment(
            type: isOutdoor ? 'outdoor' : 'indoor',
            location: PlantLocation(
              room: location.room,
              windowProximity: location.spot,
              sunExposure: location.sunExposure,
            ),
          ),
          addedAt: _plant.addedAt,
          speciesInfo: _plant.speciesInfo,
          measurements: _plant.measurements,
        );
      });
      
      _needsDashboardRefresh = true;
      _showSnackBar('Location updated to ${location.displayName}');
    } catch (e) {
      _showSnackBar('Failed to update location: $e', isError: true);
    }
  }

  // NEW: Uses bottom sheet with searchable species selector
  Future<void> _showEditPlantDialog() async {
    if (_isEditDialogOpen) return;
    _isEditDialogOpen = true;

    try {
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _EditPlantSheet(plant: _plant),
      );

      if (result != null && mounted) {
        await _updatePlant(
          result['nickname'] as String,
          result['species'] as String,
          result['speciesInfo'] as Map<String, dynamic>?,
        );
      }
    } finally {
      _isEditDialogOpen = false;
    }
  }

  Future<void> _updatePlant(String nickname, String species, Map<String, dynamic>? speciesInfo) async {
    if (nickname == _plant.nickname && species == _plant.species) return;
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      await api.updatePlant(
        plantId: _plant.plantId,
        nickname: nickname != _plant.nickname ? nickname : null,
        species: species != _plant.species ? species : null,
        speciesInfo: speciesInfo,
      );
      
      // Update local state directly
      setState(() {
        _plant = Plant(
          plantId: _plant.plantId,
          userId: _plant.userId,
          nickname: nickname,
          species: species,
          esp32DeviceId: _plant.esp32DeviceId,
          waterPercentage: _plant.waterPercentage,
          streak: _plant.streak,
          currentHealth: _plant.currentHealth,
          environment: _plant.environment,
          addedAt: _plant.addedAt,
          speciesInfo: speciesInfo != null 
              ? PlantSpeciesInfo.fromJson(speciesInfo)
              : _plant.speciesInfo,
          measurements: _plant.measurements,
        );
      });
      
      _needsDashboardRefresh = true;
      _showSnackBar('Plant updated successfully!');
    } catch (e) { _showSnackBar('Failed to update: $e', isError: true); }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      
      child: Scaffold(
        body: LeafBackground(
          leafCount: 4,
          child: SafeArea(
            child: Column(
              children: [
                PlantDetailHeader(
                  plant: _plant,
                  onBack: () => Navigator.pop(context, PlantDetailResult(needsRefresh: _needsDashboardRefresh, updatedStreak: _updatedStreak)),
                  onInfo: _navigateToPlantInfo,
                  onGallery: _navigateToGallery,
                  onUnlink: _plant.hasDevice ? _unlinkDevice : null,
                  onEdit: _showEditPlantDialog,
                  onEditLocation: _showEditLocationDialog,
                  onDelete: _deletePlant,
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
                              PlantInfoCard(plant: _plant, onEdit: _showEditPlantDialog, onEditLocation: _showEditLocationDialog),
                              const SizedBox(height: 20),
                              
                              // Main 4-button row (Photo, Info, Forum, Water/Care)
                              QuickActionsRow(
                                plant: _plant, 
                                isWatering: _isWatering, 
                                onWater: _triggerWatering, 
                                onGallery: _navigateToGallery, 
                                onInfo: _navigateToPlantInfo, 
                                onCommunity: _navigateToCommunity,
                                onCare: _navigateToCareSchedule,
                              ),
                              const SizedBox(height: 16),
                              
                              // Tools row (Light Meter, Pot Meter) - SEPARATE from main actions
                              PlantToolsRow(
                                plant: _plant,
                                onLightMeter: _navigateToLightMeter,
                                onPotMeter: _navigateToPotMeter,
                              ),
                              const SizedBox(height: 20),
                              
                              // Show measurements card if measurements exist
                              if (_plant.measurements?.hasMeasurements == true) ...[
                                MeasurementsCard(
                                  measurements: _plant.measurements! as plant_measurements.PlantMeasurements,
                                  onTap: _navigateToPotMeter,
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                              // Rest of your existing cards...
                              if (_plant.hasDevice) ...[
                                ScheduleCard(schedule: _schedule, onTap: _navigateToSchedule),
                                const SizedBox(height: 16),
                                WaterLevelCard(waterLevel: _waterLevel, isRefilling: _isRefilling, onRefill: _refillWater),
                                const SizedBox(height: 16),
                                LatestHealthCheckCard(plantId: _plant.plantId, onTapGallery: _navigateToGallery),
                                const SizedBox(height: 16),
                                SensorDataCard(sensorData: _latestSensor),
                              ] else ...[
                                PlantCareCard(plant: _plant),
                                const SizedBox(height: 16),
                                LinkDeviceCard(onLink: _navigateToLinkDevice),
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

// NEW: Edit Plant Sheet with searchable species selector
class _EditPlantSheet extends StatefulWidget {
  final Plant plant;
  const _EditPlantSheet({required this.plant});

  @override
  State<_EditPlantSheet> createState() => _EditPlantSheetState();
}

class _EditPlantSheetState extends State<_EditPlantSheet> {
  late TextEditingController _nicknameController;
  List<PlantProfile> _profiles = [];
  PlantProfile? _selectedProfile;
  bool _isCustomSpecies = false;
  String _customSpeciesText = '';
  bool _isLoadingProfiles = true;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.plant.nickname);
    _loadProfiles();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      final profiles = await api.getPlantProfiles();
      
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _isLoadingProfiles = false;
          
          // Find current species in profiles
          final currentSpecies = widget.plant.species;
          final matchingProfile = profiles.where(
            (p) => p.species == currentSpecies || p.commonName == currentSpecies
          ).firstOrNull;
          
          if (matchingProfile != null) {
            _selectedProfile = matchingProfile;
            _isCustomSpecies = false;
          } else {
            _isCustomSpecies = true;
            _customSpeciesText = currentSpecies;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load profiles: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfiles = false;
          _isCustomSpecies = true;
          _customSpeciesText = widget.plant.species;
        });
      }
    }
  }

  void _save() {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    final species = _isCustomSpecies 
      ? _customSpeciesText
      : _selectedProfile?.species ?? widget.plant.species; 


    if (species.isEmpty) return;

    // Build speciesInfo if profile selected
    Map<String, dynamic>? speciesInfo;
    if (_selectedProfile != null && !_isCustomSpecies) {
      speciesInfo = {
        'commonName': _selectedProfile!.commonName,
        'scientificName': _selectedProfile!.species,
        'emoji': _selectedProfile!.emoji,
        if (_selectedProfile!.careProfile != null) ...{
          'waterFrequencyDays': _selectedProfile!.careProfile!.watering.frequencyDays,
          'waterAmountML': _selectedProfile!.careProfile!.watering.amountML,
          'lightRequirement': _selectedProfile!.careProfile!.light.type,
          'temperatureRange': '${_selectedProfile!.careProfile!.environment.tempMin}-${_selectedProfile!.careProfile!.environment.tempMax}°C',
          'humidityPreference': '${_selectedProfile!.careProfile!.environment.humidityMin}-${_selectedProfile!.careProfile!.environment.humidityMax}%',
        },
      };
    }

    Navigator.pop(context, {
      'nickname': nickname,
      'species': species,
      'speciesInfo': speciesInfo,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.edit, color: AppTheme.leafGreen),
                const SizedBox(width: 12),
                Text(
                  'Edit Plant',
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.quicksand(
                      color: AppTheme.soilBrown.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant icon preview
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.softSage.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _isCustomSpecies 
                            ? '🪴' 
                            : (_selectedProfile?.emoji ?? widget.plant.emoji),
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nickname field
                  Text(
                    'Plant Name',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Fernie Sanders',
                      prefixIcon: Icon(
                        Icons.local_florist,
                        color: AppTheme.leafGreen.withValues(alpha: 0.7),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),

                  // Species selector
                  Text(
                    'Plant Species',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SearchableSpeciesSelector(
                    profiles: _profiles,
                    selectedProfile: _selectedProfile,
                    isCustomSpecies: _isCustomSpecies,
                    customSpeciesText: _customSpeciesText,
                    isLoading: _isLoadingProfiles,
                    onProfileSelected: (profile) {
                      setState(() {
                        _selectedProfile = profile;
                        _isCustomSpecies = false;
                        _customSpeciesText = '';
                      });
                    },
                    onCustomSpeciesChanged: (text) {
                      setState(() {
                        _customSpeciesText = text;
                      });
                    },
                    onCustomSelected: () {
                      setState(() {
                        _isCustomSpecies = true;
                        _selectedProfile = null;
                      });
                    },
                  ),

                  // Care info preview
                  if (_selectedProfile != null && !_isCustomSpecies && _selectedProfile!.careProfile != null) ...[
                    const SizedBox(height: 16),
                    _buildCareInfoCard(),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _nicknameController.text.trim().isNotEmpty ? _save : null,
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareInfoCard() {
    final care = _selectedProfile!.careProfile!;
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
              Icon(Icons.info_outline, color: AppTheme.leafGreen, size: 18),
              const SizedBox(width: 6),
              Text(
                'Care Requirements',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.leafGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCareRow(Icons.water_drop, 'Water every ${care.watering.frequencyDays} days'),
          _buildCareRow(Icons.wb_sunny, care.light.type.replaceAll('-', ' ').toUpperCase()),
          _buildCareRow(Icons.thermostat, '${care.environment.tempMin}-${care.environment.tempMax}°C'),
          _buildCareRow(Icons.water, '${care.environment.humidityMin}-${care.environment.humidityMax}% humidity'),
        ],
      ),
    );
  }

  Widget _buildCareRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.soilBrown.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: AppTheme.soilBrown.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Location Picker Sheet
class _LocationPickerSheet extends StatefulWidget {
  final RoomLocation? initialLocation;
  const _LocationPickerSheet({this.initialLocation});
  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  String? _selectedRoom;
  String? _selectedSpot;
  String? _selectedSunExposure;
  final _customRoomController = TextEditingController();
  final _customSpotController = TextEditingController();
  bool _isCustomRoom = false;

  static const List<_RoomOption> rooms = [
    _RoomOption(name: 'Living Room', emoji: '🛋️', spots: ['By window', 'Corner', 'Shelf', 'Coffee table']),
    _RoomOption(name: 'Kitchen', emoji: '🍳', spots: ['Windowsill', 'Counter', 'Above cabinets', 'Herb shelf']),
    _RoomOption(name: 'Bedroom', emoji: '🛏️', spots: ['Nightstand', 'Windowsill', 'Dresser', 'Hanging']),
    _RoomOption(name: 'Bathroom', emoji: '🚿', spots: ['Windowsill', 'Shelf', 'Counter']),
    _RoomOption(name: 'Office', emoji: '💻', spots: ['Desk', 'Windowsill', 'Bookshelf', 'Corner']),
    _RoomOption(name: 'Balcony', emoji: '🌅', spots: ['Railing', 'Floor', 'Hanging', 'Table']),
    _RoomOption(name: 'Patio', emoji: '☀️', spots: ['Sunny spot', 'Shaded area', 'Table', 'Planter box']),
    _RoomOption(name: 'Back Garden', emoji: '🌳', spots: ['Flower bed', 'Vegetable patch', 'Along fence', 'Under tree']),
    _RoomOption(name: 'Front Yard', emoji: '🏡', spots: ['Porch', 'Garden bed', 'Pathway', 'Planter']),
    _RoomOption(name: 'Greenhouse', emoji: '🌱', spots: ['Bench', 'Hanging', 'Floor', 'Shelf']),
  ];

  static const List<String> sunOptions = ['Full sun', 'Partial sun', 'Bright indirect', 'Low light', 'Shade'];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null && widget.initialLocation!.isSet) {
      final match = rooms.where((r) => r.name == widget.initialLocation!.room).firstOrNull;
      if (match != null) { _selectedRoom = match.name; _selectedSpot = widget.initialLocation!.spot; }
      else { _isCustomRoom = true; _customRoomController.text = widget.initialLocation!.room; _customSpotController.text = widget.initialLocation!.spot ?? ''; }
      _selectedSunExposure = widget.initialLocation!.sunExposure;
    }
  }

  @override
  void dispose() { _customRoomController.dispose(); _customSpotController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          Text('Set Plant Location', style: GoogleFonts.comfortaa(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context, RoomLocation(room: 'Not set')), child: Text('Clear', style: GoogleFonts.quicksand(color: AppTheme.terracotta))),
        ])),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Room', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ...rooms.map((r) => _buildRoomChip(r)),
            _buildCustomChip(),
          ]),
          if (_isCustomRoom) ...[const SizedBox(height: 16), TextField(controller: _customRoomController, decoration: InputDecoration(labelText: 'Custom Room', hintText: 'e.g., Sunroom')), const SizedBox(height: 12), TextField(controller: _customSpotController, decoration: InputDecoration(labelText: 'Spot (optional)', hintText: 'e.g., Near window'))],
          if (_selectedRoom != null && !_isCustomRoom) ...[const SizedBox(height: 24), Text('Spot in $_selectedRoom', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)), const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: rooms.firstWhere((r) => r.name == _selectedRoom).spots.map((s) => _buildSpotChip(s)).toList())],
          const SizedBox(height: 24),
          Text('Sun Exposure', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: sunOptions.map((s) => _buildSunChip(s)).toList()),
          const SizedBox(height: 32),
        ]))),
        Padding(padding: const EdgeInsets.all(20), child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _canSave() ? _save : null, child: Text('Save Location', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w600))))),
      ]),
    );
  }

  Widget _buildRoomChip(_RoomOption r) {
    final sel = _selectedRoom == r.name && !_isCustomRoom;
    return GestureDetector(onTap: () => setState(() { _selectedRoom = r.name; _selectedSpot = null; _isCustomRoom = false; }),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: sel ? AppTheme.leafGreen : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? AppTheme.leafGreen : AppTheme.softSage)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(r.emoji, style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(r.name, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.soilBrown))])));
  }

  Widget _buildCustomChip() {
    return GestureDetector(onTap: () => setState(() { _isCustomRoom = true; _selectedRoom = null; _selectedSpot = null; }),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: _isCustomRoom ? AppTheme.mossGreen : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _isCustomRoom ? AppTheme.mossGreen : AppTheme.softSage)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_circle_outline, size: 16, color: _isCustomRoom ? Colors.white : AppTheme.mossGreen), const SizedBox(width: 6), Text('Other', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: _isCustomRoom ? Colors.white : AppTheme.mossGreen))])));
  }

  Widget _buildSpotChip(String s) {
    final sel = _selectedSpot == s;
    return GestureDetector(onTap: () => setState(() => _selectedSpot = s),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: sel ? AppTheme.waterBlue : AppTheme.waterBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Text(s, style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.waterBlue))));
  }

  Widget _buildSunChip(String s) {
    final sel = _selectedSunExposure == s;
    return GestureDetector(onTap: () => setState(() => _selectedSunExposure = s),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: sel ? AppTheme.sunYellow : AppTheme.sunYellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Text(s, style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.soilBrown.withValues(alpha: 0.8)))));
  }

  bool _canSave() => _isCustomRoom ? _customRoomController.text.trim().isNotEmpty : _selectedRoom != null;

  void _save() {
    Navigator.pop(context, RoomLocation(
      room: _isCustomRoom ? _customRoomController.text.trim() : _selectedRoom!,
      spot: _isCustomRoom ? _customSpotController.text.trim() : _selectedSpot,
      sunExposure: _selectedSunExposure,
    ));
  }
}

class _RoomOption { final String name; final String emoji; final List<String> spots; const _RoomOption({required this.name, required this.emoji, required this.spots}); }