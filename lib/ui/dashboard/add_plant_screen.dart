import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/plant_species.dart';
import '../widgets/leaf_background.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nameController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _searchController = TextEditingController();
  PlantSpecies? _selectedSpecies;
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _showDeviceField = false;
  bool _showSpeciesSelector = false;

  List<PlantSpecies> get _filteredSpecies {
    final species = PlantSpecies.commonSpecies;
    if (_selectedCategory == 'All') return species;
    return species.where((s) => s.category == _selectedCategory).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deviceIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _savePlant() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please give your plant a name', isError: true);
      return;
    }

    if (_selectedSpecies == null) {
      _showSnackBar('Please select a plant species', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final deviceId = _deviceIdController.text.trim();

      await api.addPlant(
        userId: auth.userId!,
        nickname: _nameController.text.trim(),
        species: _selectedSpecies!.commonName,
        speciesId: _selectedSpecies!.id,
        esp32DeviceId: deviceId.isNotEmpty ? deviceId : null,
        speciesInfo: {
          'commonName': _selectedSpecies!.commonName,
          'scientificName': _selectedSpecies!.scientificName,
          'careLevel': _selectedSpecies!.careLevel,
          'waterFrequencyDays': _selectedSpecies!.careInfo.waterFrequencyDays,
          'waterAmountML': _selectedSpecies!.careInfo.waterAmountML,
          'lightRequirement': _selectedSpecies!.careInfo.lightRequirement,
          'temperatureRange': _selectedSpecies!.careInfo.temperatureRange,
          'humidityPreference': _selectedSpecies!.careInfo.humidityPreference,
          'description': _selectedSpecies!.careInfo.description,
          'tips': _selectedSpecies!.careInfo.tips,
        },
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
                      if (_selectedSpecies != null) ...[
                        const SizedBox(height: 16),
                        _buildCareInfoCard(),
                      ],
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.leafGreen.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          _selectedSpecies?.emoji ?? '🪴',
          style: const TextStyle(fontSize: 64),
        ),
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
            prefixIcon: Icon(Icons.eco, color: AppTheme.leafGreen.withOpacity(0.7)),
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
        GestureDetector(
          onTap: () => _showSpeciesPicker(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.softSage, width: 2),
            ),
            child: Row(
              children: [
                Text(
                  _selectedSpecies?.emoji ?? '🌱',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSpecies?.commonName ?? 'Select a species',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedSpecies != null 
                              ? AppTheme.soilBrown 
                              : AppTheme.soilBrown.withOpacity(0.5),
                        ),
                      ),
                      if (_selectedSpecies != null)
                        Text(
                          _selectedSpecies!.scientificName,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.soilBrown.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.soilBrown.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSpeciesPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Select Plant Species',
                        style: GoogleFonts.comfortaa(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.leafGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Category filter
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: PlantSpecies.categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() => _selectedCategory = category);
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? AppTheme.leafGreen 
                                        : AppTheme.softSage.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: Text(
                                      category,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : AppTheme.soilBrown,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredSpecies.length,
                    itemBuilder: (context, index) {
                      final species = _filteredSpecies[index];
                      final isSelected = _selectedSpecies?.id == species.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedSpecies = species);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.leafGreen.withOpacity(0.1) 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? AppTheme.leafGreen 
                                  : AppTheme.softSage,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(species.emoji, style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      species.commonName,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.soilBrown,
                                      ),
                                    ),
                                    Text(
                                      species.scientificName,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.soilBrown.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildTag(species.category, AppTheme.leafGreen),
                                        const SizedBox(width: 6),
                                        _buildTag(species.careLevel, _careLevelColor(species.careLevel)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: AppTheme.leafGreen),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.quicksand(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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

  Widget _buildCareInfoCard() {
    final care = _selectedSpecies!.careInfo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withOpacity(0.2),
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
          _buildCareRow(Icons.water_drop, 'Water every ${care.waterFrequencyDays} days'),
          _buildCareRow(Icons.wb_sunny, care.lightRequirement),
          _buildCareRow(Icons.thermostat, care.temperatureRange),
          if (care.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                care.description!,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: AppTheme.soilBrown.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCareRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.soilBrown.withOpacity(0.6)),
          const SizedBox(width: 8),
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
                color: _showDeviceField ? AppTheme.leafGreen : AppTheme.soilBrown.withOpacity(0.5),
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
                        color: AppTheme.soilBrown.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _showDeviceField,
                onChanged: (value) => setState(() => _showDeviceField = value),
                activeColor: AppTheme.leafGreen,
              ),
            ],
          ),
          if (_showDeviceField) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _deviceIdController,
              decoration: InputDecoration(
                hintText: 'Device ID (e.g., plant-001)',
                prefixIcon: Icon(Icons.qr_code, color: AppTheme.leafGreen.withOpacity(0.7)),
                filled: true,
                fillColor: AppTheme.softSage.withOpacity(0.2),
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