import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/plant_profile.dart';
import '../widgets/leaf_background.dart';
import '../widgets/room_selector.dart';
import '../widgets/searchable_species_selector.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nameController = TextEditingController();
  final _deviceIdController = TextEditingController();
  
  List<PlantProfile> _profiles = [];
  PlantProfile? _selectedProfile;
  bool _isCustomSpecies = false;
  String _customSpeciesText = '';
  bool _isLoading = false;
  bool _isLoadingProfiles = true;
  bool _showDeviceField = false;
  
  // Room/Location
  RoomLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
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
        });
      }
    } catch (e) {
      debugPrint('Failed to load profiles: $e');
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
        _showSnackBar('Failed to load plant types', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  void _savePlant() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please give your plant a name', isError: true);
      return;
    }

    final species = _isCustomSpecies 
        ? _customSpeciesText
        : _selectedProfile?.commonName ?? _selectedProfile?.species;

    if (species == null || species.isEmpty) {
      _showSnackBar('Please select or enter a plant species', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final deviceId = _deviceIdController.text.trim();

      // Build speciesInfo from profile if available
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

      // Build environment with location
      Map<String, dynamic>? environment;
      if (_selectedLocation != null && _selectedLocation!.isSet) {
        environment = {
          'type': 'indoor',
          'location': _selectedLocation!.toJson(),
        };
      }

      await api.addPlant(
        userId: auth.userId!,
        nickname: _nameController.text.trim(),
        species: species,
        esp32DeviceId: deviceId.isNotEmpty ? deviceId : null,
        environment: environment,
        speciesInfo: speciesInfo,
      );

      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar(
          deviceId.isNotEmpty 
              ? '${_nameController.text} added with device!'
              : '${_nameController.text} added! Link a device later to enable watering.',
        );
      }
    } catch (e) {
      _showSnackBar('Failed to add plant: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.quicksand()),
        backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        leafCount: 6,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      _buildPlantIcon(),
                      const SizedBox(height: 36),
                      _buildNameField(),
                      const SizedBox(height: 24),
                      _buildSpeciesSelector(),
                      if (_selectedProfile != null && !_isCustomSpecies) ...[
                        const SizedBox(height: 16),
                        _buildCareInfoCard(),
                      ],
                      const SizedBox(height: 24),
                      _buildLocationSelector(),
                      const SizedBox(height: 24),
                      _buildDeviceLinkingToggle(),
                      const SizedBox(height: 36),
                      _buildAddButton(),
                      const SizedBox(height: 40),
                    ],
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
      padding: const EdgeInsets.all(20),
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen),
            ),
          ),
          const Spacer(),
          Text(
            'New Plant',
            style: GoogleFonts.comfortaa(
              fontSize: 22,
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

  Widget _buildPlantIcon() {
    // Use selected profile emoji or default
    final emoji = _isCustomSpecies 
        ? '🪴' 
        : (_selectedProfile?.emoji ?? '🪴');
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.leafGreen.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 64)),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g., Fernie Sanders',
            prefixIcon: Icon(Icons.eco, color: AppTheme.leafGreen.withValues(alpha: 0.7)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildSpeciesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildCareInfoCard() {
    final care = _selectedProfile!.careProfile;
    if (care == null) return const SizedBox.shrink();
    
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

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location in Home',
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.soilBrown,
          ),
        ),
        const SizedBox(height: 8),
        RoomSelector(
          selectedLocation: _selectedLocation,
          onLocationChanged: (location) {
            setState(() => _selectedLocation = location);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceLinkingToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softSage),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.sensors,
                color: _showDeviceField ? AppTheme.leafGreen : AppTheme.soilBrown.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link Device Now',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    Text(
                      'Optional - can be done later',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.soilBrown.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _showDeviceField,
                onChanged: (value) => setState(() => _showDeviceField = value),
                activeTrackColor: AppTheme.leafGreen.withValues(alpha: 0.5),
                activeThumbColor: AppTheme.leafGreen,
              ),
            ],
          ),
          if (_showDeviceField) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _deviceIdController,
              decoration: InputDecoration(
                hintText: 'Device ID (e.g., plant-001)',
                prefixIcon: Icon(Icons.qr_code, color: AppTheme.leafGreen.withValues(alpha: 0.7)),
                filled: true,
                fillColor: AppTheme.softSage.withValues(alpha: 0.2),
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePlant,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Add to Garden',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}