import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/plant_onboarding.dart';
import '../../models/plant_profile.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/care_reminder_service.dart';
import '../widgets/leaf_background.dart';
import '../widgets/room_selector.dart';
import '../widgets/searchable_species_selector.dart';
import '../widgets/lux_meter_screen.dart';
import '../widgets/onboarding_pot_meter_screen.dart';
import '../widgets/onboarding_lux_meter_screen.dart';

class PlantOnboardingWizard extends StatefulWidget {
  const PlantOnboardingWizard({super.key});

  @override
  State<PlantOnboardingWizard> createState() => _PlantOnboardingWizardState();
}

class _PlantOnboardingWizardState extends State<PlantOnboardingWizard> {
  final PageController _pageController = PageController();
  final PlantOnboardingData _data = PlantOnboardingData();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _errorMessage;
  
  // Plant profiles for species selection
  List<PlantProfile> _profiles = [];
  bool _isLoadingProfiles = true;
  
  // Controllers
  final _nicknameController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _potHeightController = TextEditingController();
  final _potWidthController = TextEditingController();
  final _plantHeightController = TextEditingController();
  
  // Location state
  RoomLocation? _selectedLocation;
  bool _showDeviceField = false;

  static const List<String> _stepTitles = [
    'Take a Photo',
    'Plant Details', 
    'Pot Size',
    'Light Level',
    'Location',
  ];

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
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _deviceIdController.dispose();
    _potHeightController.dispose();
    _potWidthController.dispose();
    _plantHeightController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _stepTitles.length) return;
    
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  bool _canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0: // Photo - always can proceed (photo is optional)
        return true;
      case 1: // Details - need nickname and species
        return _nicknameController.text.trim().isNotEmpty &&
               (_data.species != null || _data.selectedProfile != null);
      case 2: // Pot size - optional
        return true;
      case 3: // Light - optional
        return true;
      case 4: // Location - optional
        return true;
      default:
        return true;
    }
  }

  Future<void> _capturePhoto() async {
    final status = await Permission.camera.request();
    
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog('Camera');
      return;
    }
    
    if (!status.isGranted) {
      _showSnackBar('Camera permission required', isError: true);
      return;
    }

    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _data.capturedImage = File(image.path);
        _isAnalyzing = true;
        _errorMessage = null;
      });

      await _analyzeImage(File(image.path));
    } catch (e) {
      _showSnackBar('Could not access camera: $e', isError: true);
    }
  }

  Future<void> _pickFromGallery() async {
    // On iOS, ImagePicker handles its own permissions
    // On Android, we need storage permission for older versions
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog('Photo Library');
        return;
      }
    }

    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _data.capturedImage = File(image.path);
        _isAnalyzing = true;
        _errorMessage = null;
      });

      await _analyzeImage(File(image.path));
    } catch (e) {
      _showSnackBar('Could not access photos: $e', isError: true);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      _data.imageBase64 = base64Image;

      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final response = await api.analyzeOnboardingImage(
        userId: auth.userId!,
        imageData: base64Image,
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          
          // Update data from analysis
          _data.plantId = response['plantId'];
          _data.capturedAt = response['capturedAt'];
          _data.imageUrl = response['imageUrl'];
          _data.needsSpeciesSelection = response['needsSpeciesSelection'] ?? true;
          
          if (response['suggestions'] != null) {
            _data.suggestions = OnboardingSuggestions.fromJson(response['suggestions']);
            _data.species = _data.suggestions!.species;
            _data.commonName = _data.suggestions!.commonName;
            _data.emoji = _data.suggestions!.emoji ?? '🪴';
            _data.environment = _data.suggestions!.environment ?? 'indoor';
            
            // Pre-fill nickname
            final suggestedNickname = _data.suggestions!.nickname ?? 
                                      _data.commonName ?? 
                                      'My Plant';
            _nicknameController.text = suggestedNickname;
            _data.nickname = suggestedNickname;
          }
          
          if (response['healthAssessment'] != null) {
            _data.healthAssessment = HealthAssessment.fromJson(response['healthAssessment']);
            
            if (_data.healthAssessment!.estimatedHeightCm != null) {
              _data.plantHeightInches = _data.healthAssessment!.estimatedHeightCm! / 2.54;
              _plantHeightController.text = _data.plantHeightInches!.toStringAsFixed(1);
            }
          }
        });

        // Show success and auto-advance
        _showSnackBar(
          _data.needsSpeciesSelection 
              ? 'Photo analyzed! Please confirm the species.'
              : 'Found: ${_data.commonName ?? _data.species}',
        );
        
        // Auto-advance to details step
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _nextStep();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Failed to analyze image: $e';
        });
        _showSnackBar('Analysis failed. You can still add plant manually.', isError: true);
      }
    }
  }

  Future<void> _measureLux() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showSnackBar('Camera permission required', isError: true);
      return;
    }

    final result = await Navigator.push<double>(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingLuxMeterScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _data.measuredLux = result;
        _data.lightCategory = _getLightCategory(result);
      });
      _showSnackBar('Light: ${result.toInt()} lux (${_data.lightCategory})');
    }
  }

  String _getLightCategory(double lux) {
    if (lux < 1000) return 'Low light';
    if (lux < 10000) return 'Bright indirect';
    if (lux < 25000) return 'Partial sun';
    return 'Full sun';
  }

  Future<void> _savePlant() async {
    // Validate
    if (_nicknameController.text.trim().isEmpty) {
      _showSnackBar('Please give your plant a name', isError: true);
      return;
    }

    final species = _data.isCustomSpecies 
        ? _data.species
        : (_data.selectedProfile?.species ?? _data.species);

    if (species == null || species.isEmpty) {
      _showSnackBar('Please select a species', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      // Update data from controllers
      _data.nickname = _nicknameController.text.trim();
      _data.species = species;
      
      if (_selectedLocation != null && _selectedLocation!.isSet) {
        _data.room = _selectedLocation!.room;
        // windowProximity is part of the location JSON, not a direct property
      }
      
      if (_showDeviceField && _deviceIdController.text.isNotEmpty) {
        _data.esp32DeviceId = _deviceIdController.text.trim();
      }

      // Parse measurements
      if (_potHeightController.text.isNotEmpty) {
        _data.potHeightInches = double.tryParse(_potHeightController.text);
      }
      if (_potWidthController.text.isNotEmpty) {
        _data.potWidthInches = double.tryParse(_potWidthController.text);
      }
      if (_plantHeightController.text.isNotEmpty) {
        _data.plantHeightInches = double.tryParse(_plantHeightController.text);
      }
      
      // Calculate pot volume if we have dimensions
      if (_data.potHeightInches != null && _data.potWidthInches != null) {
        // Approximate cylinder volume: π * r² * h, convert cubic inches to mL
        final radius = _data.potWidthInches! / 2;
        final volumeCubicInches = 3.14159 * radius * radius * _data.potHeightInches!;
        _data.potVolumeML = volumeCubicInches * 16.387; // cubic inch to mL
      }

      // Build environment
      Map<String, dynamic>? environment;
      
      if (_selectedLocation != null && _selectedLocation!.isSet) {
        final locationJson = _selectedLocation!.toJson();
        
        // Add lux level if measured
        if (_data.measuredLux != null) {
          locationJson['luxLevel'] = _data.measuredLux;
        }
        
        environment = {
          'type': _data.environment,
          'location': locationJson,
        };
      } else if (_data.measuredLux != null) {
        // Just lux, no room selected
        environment = {
          'type': _data.environment,
          'location': {'luxLevel': _data.measuredLux},
        };
      } else if (_data.environment == 'outdoor') {
        environment = {'type': 'outdoor'};
      }

      // Build speciesInfo
      Map<String, dynamic>? speciesInfo = _data.buildSpeciesInfo();
      if (speciesInfo == null && _data.selectedProfile != null) {
        speciesInfo = {
          'commonName': _data.selectedProfile!.commonName,
          'scientificName': _data.selectedProfile!.species,
          'emoji': _data.selectedProfile!.emoji,
        };
      }

      // Call API
      final result = await api.addPlant(
        userId: auth.userId!,
        nickname: _data.nickname,
        species: species,
        esp32DeviceId: _data.esp32DeviceId,
        environment: environment,
        speciesInfo: speciesInfo,
        // Pass plantId if we have one from image analysis
        // This links the already-uploaded image to this plant
      );

      // Create care reminders
      if (result != null) {
        await _createReminders(result);
      }

      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar(
          _data.esp32DeviceId != null
              ? '${_data.nickname} added with device!'
              : '${_data.nickname} added successfully!',
        );
      }
    } catch (e) {
      _showSnackBar('Failed to add plant: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createReminders(Plant plant) async {
    try {
      final reminderService = CareReminderService();
      await reminderService.initialize();
      await reminderService.addDefaultRemindersForPlant(plant);
    } catch (e) {
      debugPrint('Failed to create reminders: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.quicksand()),
        backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.no_photography, color: AppTheme.terracotta),
            const SizedBox(width: 12),
            Text(
              '$permissionName Access',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '$permissionName access was denied. Please enable it in Settings to take photos of your plants.',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.quicksand(color: AppTheme.soilBrown),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.leafGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.quicksand(color: Colors.white),
            ),
          ),
        ],
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
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentStep = index),
                  children: [
                    _buildPhotoStep(),
                    _buildDetailsStep(),
                    _buildPotSizeStep(),
                    _buildLightStep(),
                    _buildLocationStep(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
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
            onPressed: () {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                Navigator.pop(context);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                _currentStep > 0 ? Icons.arrow_back : Icons.close,
                color: AppTheme.leafGreen,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _stepTitles[_currentStep],
              textAlign: TextAlign.center,
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.leafGreen,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.leafGreen : AppTheme.softSage,
                borderRadius: BorderRadius.circular(2),
              ),
              child: isCurrent
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.leafGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _stepTitles.length - 1;
    final canProceed = _canProceedFromCurrentStep();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.leafGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.leafGreen,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading || !canProceed
                  ? null
                  : (isLastStep ? _savePlant : _nextStep),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.leafGreen,
                disabledBackgroundColor: AppTheme.softSage,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Add Plant' : 'Continue',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (!isLastStep) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STEP 1: Photo Capture
  // ============================================
  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Photo preview or placeholder
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.leafGreen.withValues(alpha:0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _isAnalyzing
                ? _buildAnalyzingState()
                : _data.capturedImage != null
                    ? _buildPhotoPreview()
                    : _buildPhotoPlaceholder(),
          ),
          
          const SizedBox(height: 24),
          
          // Camera buttons
          if (!_isAnalyzing) ...[
            Row(
              children: [
                Expanded(
                  child: _buildPhotoButton(
                    icon: Icons.camera_alt,
                    label: 'Take Photo',
                    onTap: _capturePhoto,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPhotoButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: _pickFromGallery,
                    isPrimary: false,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Skip option
            TextButton(
              onPressed: _nextStep,
              child: Text(
                'Skip - Add details manually',
                style: GoogleFonts.quicksand(
                  color: AppTheme.soilBrown.withValues(alpha:0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          
          // Show health assessment if available
          if (_data.healthAssessment != null && !_isAnalyzing) ...[
            const SizedBox(height: 24),
            _buildHealthCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.softSage.withValues(alpha:0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_florist,
            size: 64,
            color: AppTheme.leafGreen.withValues(alpha:0.5),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Take a photo of your plant',
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.soilBrown,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI will identify the species and\nassess its health',
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            fontSize: 14,
            color: AppTheme.soilBrown.withValues(alpha:0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(
            _data.capturedImage!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        
        // Retake button
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            onPressed: () {
              setState(() {
                _data.capturedImage = null;
                _data.imageBase64 = null;
                _data.suggestions = null;
                _data.healthAssessment = null;
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
        
        // Species badge if identified
        if (_data.suggestions != null && _data.suggestions!.isIdentified)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(_data.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _data.commonName ?? 'Unknown',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.soilBrown,
                          ),
                        ),
                        Text(
                          '${(_data.suggestions!.confidence * 100).toInt()}% confident',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            color: AppTheme.leafGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppTheme.leafGreen),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppTheme.leafGreen),
              ),
            ),
            const Text('🌱', style: TextStyle(fontSize: 36)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Analyzing your plant...',
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.soilBrown,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Identifying species and checking health',
          style: GoogleFonts.quicksand(
            fontSize: 14,
            color: AppTheme.soilBrown.withValues(alpha:0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? AppTheme.leafGreen : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isPrimary ? null : Border.all(color: AppTheme.softSage),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isPrimary ? Colors.white : AppTheme.leafGreen,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : AppTheme.soilBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    final health = _data.healthAssessment!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softSage),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(health.healthEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                'Health: ${health.healthLabel}',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.soilBrown,
                ),
              ),
              const Spacer(),
              if (health.healthScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.leafGreen.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(health.healthScore! * 100).toInt()}%',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.leafGreen,
                    ),
                  ),
                ),
            ],
          ),
          if (health.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...health.issues.take(2).map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: AppTheme.terracotta),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        color: AppTheme.soilBrown.withValues(alpha:0.8),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  // ============================================
  // STEP 2: Plant Details
  // ============================================
  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show photo thumbnail if available
          if (_data.capturedImage != null) ...[
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.leafGreen.withValues(alpha:0.2),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(_data.capturedImage!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // Show emoji selector if no photo
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.leafGreen.withValues(alpha:0.15),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Text(
                  _data.selectedProfile?.emoji ?? _data.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
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
              prefixIcon: Icon(Icons.eco, color: AppTheme.leafGreen.withValues(alpha:0.7)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.softSage),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.softSage),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.leafGreen, width: 2),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => _data.nickname = value,
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
          
          // If AI identified, show that first
          if (_data.suggestions != null && _data.suggestions!.isIdentified) ...[
            _buildAIIdentifiedCard(),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _data.needsSpeciesSelection = true;
                });
              },
              child: Text(
                'Choose different species',
                style: GoogleFonts.quicksand(
                  color: AppTheme.soilBrown.withValues(alpha:0.6),
                ),
              ),
            ),
          ],
          
          if (_data.needsSpeciesSelection || _data.suggestions == null) ...[
            SearchableSpeciesSelector(
              profiles: _profiles,
              selectedProfile: _data.selectedProfile,
              isCustomSpecies: _data.isCustomSpecies,
              customSpeciesText: _data.isCustomSpecies ? (_data.species ?? '') : '',
              isLoading: _isLoadingProfiles,
              onProfileSelected: (profile) {
                if (profile != null) {
                  setState(() {
                    _data.selectedProfile = profile;
                    _data.isCustomSpecies = false;
                    _data.species = profile.species;
                    _data.commonName = profile.commonName;
                    _data.emoji = profile.emoji;
                  });
                }
              },
              onCustomSpeciesChanged: (text) {
                setState(() {
                  _data.species = text;
                });
              },
              onCustomSelected: () {
                setState(() {
                  _data.isCustomSpecies = true;
                  _data.selectedProfile = null;
                });
              },
            ),
          ],
          
          // Care info preview
          if (_data.selectedProfile?.careProfile != null) ...[
            const SizedBox(height: 24),
            _buildCareInfoCard(_data.selectedProfile!),
          ],
        ],
      ),
    );
  }

  Widget _buildAIIdentifiedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.leafGreen.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.leafGreen.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Text(_data.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _data.commonName ?? 'Unknown',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.soilBrown,
                  ),
                ),
                Text(
                  _data.species ?? '',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.soilBrown.withValues(alpha:0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppTheme.leafGreen),
                    const SizedBox(width: 4),
                    Text(
                      'AI Identified',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.leafGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: AppTheme.leafGreen, size: 28),
        ],
      ),
    );
  }

  Widget _buildCareInfoCard(PlantProfile profile) {
    final care = profile.careProfile;
    if (care == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withValues(alpha:0.2),
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
          _buildCareRow(Icons.wb_sunny, care.light.type.replaceAll('-', ' ')),
          _buildCareRow(Icons.thermostat, '${care.environment.tempMin}-${care.environment.tempMax}°C'),
        ],
      ),
    );
  }

  Widget _buildCareRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.soilBrown.withValues(alpha:0.6)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: AppTheme.soilBrown.withValues(alpha:0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STEP 3: Pot Size - Navigate to full pot meter screen
  // ============================================
  
  OnboardingPotResult? _potResult;
  
  Future<void> _openPotMeter() async {
    final result = await Navigator.push<OnboardingPotResult>(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingPotMeterScreen(
          initialPlantHeight: _data.plantHeightInches,
        ),
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _potResult = result;
        _data.potHeightInches = result.potHeightInches;
        _data.potWidthInches = result.potWidthInches;
        _data.potVolumeML = result.potVolumeML;
        _data.plantHeightInches = result.plantHeightInches;
        _data.measurementMethod = result.measurementMethod;
        
        // Update controllers for display
        _potHeightController.text = result.potHeightInches.toString();
        _potWidthController.text = result.potWidthInches.toString();
        if (result.plantHeightInches != null) {
          _plantHeightController.text = result.plantHeightInches!.toStringAsFixed(1);
        }
      });
      _showSnackBar('Pot size: ${result.potWidthInches.toInt()}" × ${result.potHeightInches.toInt()}"');
    }
  }
  
  Widget _buildPotSizeStep() {
    final hasMeasurements = _potResult != null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Pot icon
          Container(
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.terracotta.withValues(alpha:0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: hasMeasurements
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🪴', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(
                          '${_potResult!.potWidthInches.toInt()}" × ${_potResult!.potHeightInches.toInt()}"',
                          style: GoogleFonts.comfortaa(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.terracotta,
                          ),
                        ),
                        if (_potResult!.sizePreset != null)
                          Text(
                            _potResult!.sizePreset!,
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              color: AppTheme.soilBrown.withValues(alpha:0.6),
                            ),
                          ),
                      ],
                    )
                  : Icon(
                      Icons.straighten,
                      size: 64,
                      color: AppTheme.terracotta.withValues(alpha:0.4),
                    ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            hasMeasurements
                ? 'Pot measurements saved!'
                : 'Measure your pot for accurate watering',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasMeasurements
                ? 'Estimated volume: ${_getVolumeFormatted(_potResult!.potVolumeML)}'
                : 'Choose from preset sizes or enter custom dimensions',
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown.withValues(alpha:0.6),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Measure button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openPotMeter,
              icon: Icon(hasMeasurements ? Icons.edit : Icons.straighten),
              label: Text(
                hasMeasurements ? 'Change Measurements' : 'Measure Pot',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skip option
          TextButton(
            onPressed: _nextStep,
            child: Text(
              'Skip for now',
              style: GoogleFonts.quicksand(
                color: AppTheme.soilBrown.withValues(alpha:0.6),
              ),
            ),
          ),
          
          // Show measurements summary if available
          if (hasMeasurements) ...[
            const SizedBox(height: 24),
            _buildMeasurementsSummary(),
          ],
        ],
      ),
    );
  }
  
  String _getVolumeFormatted(double volumeML) {
    if (volumeML >= 1000) {
      return '${(volumeML / 1000).toStringAsFixed(1)}L';
    }
    return '${volumeML.round()}mL';
  }
  
  Widget _buildMeasurementsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMeasurementRow(Icons.straighten, 'Width', '${_potResult!.potWidthInches}"'),
          _buildMeasurementRow(Icons.height, 'Height', '${_potResult!.potHeightInches}"'),
          _buildMeasurementRow(Icons.water_drop, 'Volume', _getVolumeFormatted(_potResult!.potVolumeML)),
          if (_potResult!.plantHeightInches != null)
            _buildMeasurementRow(Icons.eco, 'Plant Height', '${_potResult!.plantHeightInches!.toStringAsFixed(1)}"'),
        ],
      ),
    );
  }
  
  Widget _buildMeasurementRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.leafGreen),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown.withValues(alpha:0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STEP 4: Light Level - Navigate to LuxMeterScreen
  // ============================================
  Widget _buildLightStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Light meter visual
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.sunYellow.withValues(alpha:0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: _data.measuredLux != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_data.measuredLux!.toInt()}',
                          style: GoogleFonts.comfortaa(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sunYellow,
                          ),
                        ),
                        Text(
                          'lux',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            color: AppTheme.soilBrown.withValues(alpha:0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.sunYellow.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _data.lightCategory ?? '',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.sunYellow,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.light_mode,
                      size: 80,
                      color: AppTheme.sunYellow.withValues(alpha:0.5),
                    ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            _data.measuredLux != null
                ? 'Light level recorded!'
                : 'Measure the light where your plant will live',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _data.measuredLux != null
                ? 'This helps us give better care advice'
                : 'Point your phone camera at the plant\'s spot',
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown.withValues(alpha:0.6),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Measure button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _measureLux,
              icon: Icon(
                _data.measuredLux != null ? Icons.refresh : Icons.light_mode,
              ),
              label: Text(
                _data.measuredLux != null ? 'Measure Again' : 'Measure Light',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.sunYellow,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skip option
          TextButton(
            onPressed: _nextStep,
            child: Text(
              'Skip for now',
              style: GoogleFonts.quicksand(
                color: AppTheme.soilBrown.withValues(alpha:0.6),
              ),
            ),
          ),
          
          // Light guide
          const SizedBox(height: 32),
          _buildLightGuide(),
        ],
      ),
    );
  }

  Widget _buildLightGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softSage),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Light Level Guide',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 12),
          _buildLightGuideRow('🌑', 'Low light', '< 1,000 lux'),
          _buildLightGuideRow('☁️', 'Bright indirect', '1,000 - 10,000 lux'),
          _buildLightGuideRow('⛅', 'Partial sun', '10,000 - 25,000 lux'),
          _buildLightGuideRow('☀️', 'Full sun', '> 25,000 lux'),
        ],
      ),
    );
  }

  Widget _buildLightGuideRow(String emoji, String label, String range) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
          const Spacer(),
          Text(
            range,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              color: AppTheme.soilBrown.withValues(alpha:0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STEP 5: Location & Device
  // ============================================
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Environment toggle
          Text(
            'Environment',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEnvironmentOption(
                  icon: Icons.home,
                  label: 'Indoor',
                  isSelected: _data.environment == 'indoor',
                  onTap: () => setState(() => _data.environment = 'indoor'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnvironmentOption(
                  icon: Icons.park,
                  label: 'Outdoor',
                  isSelected: _data.environment == 'outdoor',
                  onTap: () => setState(() => _data.environment = 'outdoor'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Room selector
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
          
          const SizedBox(height: 24),
          
          // Device linking
          Container(
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
                      color: _showDeviceField 
                          ? AppTheme.leafGreen 
                          : AppTheme.soilBrown.withValues(alpha:0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Link IoT Device',
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
                              color: AppTheme.soilBrown.withValues(alpha:0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _showDeviceField,
                      onChanged: (value) => setState(() => _showDeviceField = value),
                      activeTrackColor: AppTheme.leafGreen.withValues(alpha:0.5),
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
                      prefixIcon: Icon(Icons.qr_code, color: AppTheme.leafGreen.withValues(alpha:0.7)),
                      filled: true,
                      fillColor: AppTheme.softSage.withValues(alpha:0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Summary card
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildEnvironmentOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.leafGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : AppTheme.soilBrown,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.soilBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _data.selectedProfile?.emoji ?? _data.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nicknameController.text.isEmpty 
                          ? 'Your Plant' 
                          : _nicknameController.text,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    Text(
                      _data.selectedProfile?.commonName ?? 
                      _data.commonName ?? 
                      _data.species ?? 
                      'No species selected',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        color: AppTheme.soilBrown.withValues(alpha:0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (_potWidthController.text.isNotEmpty || _potHeightController.text.isNotEmpty)
            _buildSummaryRow(Icons.straighten,   'Pot: ${_fmt3(_potWidthController.text)}" × ${_fmt3(_potHeightController.text)}"',),
          if (_data.measuredLux != null)
            _buildSummaryRow(Icons.light_mode, 'Light: ${_data.measuredLux!.toInt()} lux'),
          if (_selectedLocation?.room != null)
            _buildSummaryRow(Icons.room, 'Location: ${_selectedLocation!.room}'),
          if (_showDeviceField && _deviceIdController.text.isNotEmpty)
            _buildSummaryRow(Icons.sensors, 'Device: ${_deviceIdController.text}'),
        ],
      ),
    );
  }
  String _fmt3(String s) {
    final v = double.tryParse(s.trim());
    return v == null ? s : v.toStringAsFixed(3);
  }
  Widget _buildSummaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.leafGreen),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown,
            ),
          ),
        ],
      ),
    );
  }
}