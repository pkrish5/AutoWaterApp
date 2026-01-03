import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/theme.dart';
import 'onboarding_pot_meter_ar_screens.dart';

/// Result from pot measurement during onboarding
class OnboardingPotResult {
  final double potHeightInches;
  final double potWidthInches;
  final double potVolumeML;
  final double? plantHeightInches;
  final String measurementMethod;
  final String? sizePreset;

  OnboardingPotResult({
    required this.potHeightInches,
    required this.potWidthInches,
    required this.potVolumeML,
    this.plantHeightInches,
    required this.measurementMethod,
    this.sizePreset,
  });

  Map<String, dynamic> toJson() => {
    'potHeightInches': potHeightInches,
    'potWidthInches': potWidthInches,
    'potVolumeML': potVolumeML,
    if (plantHeightInches != null) 'plantHeightInches': plantHeightInches,
    'measurementMethod': measurementMethod,
    if (sizePreset != null) 'sizePreset': sizePreset,
    'measuredAt': DateTime.now().toIso8601String(),
  };
}

/// Entry point for pot measurement during onboarding
/// Shows choice between AR and manual, returns results instead of saving
class OnboardingPotMeterScreen extends StatefulWidget {
  final double? initialPlantHeight; // From AI estimation (in inches)

  const OnboardingPotMeterScreen({
    super.key,
    this.initialPlantHeight,
  });

  @override
  State<OnboardingPotMeterScreen> createState() => _OnboardingPotMeterScreenState();
}

class _OnboardingPotMeterScreenState extends State<OnboardingPotMeterScreen> {
  bool _isChecking = true;
  bool _arAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkARAvailability();
  }

  Future<void> _checkARAvailability() async {
    // AR is available on iOS and Android if camera permission can be granted
    final canUseAR = Platform.isIOS || Platform.isAndroid;
    
    if (mounted) {
      setState(() {
        _isChecking = false;
        _arAvailable = canUseAR;
      });
    }
  }

  Future<void> _requestCameraAndOpenAR() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _openARMeasurement();
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera permission required for AR measurement'),
          backgroundColor: AppTheme.terracotta,
        ),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.camera_alt, color: AppTheme.terracotta),
            const SizedBox(width: 12),
            Text('Camera Access', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Camera access was denied. Please enable it in Settings to use AR measurement.',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.quicksand(color: AppTheme.soilBrown)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.leafGreen),
            child: Text('Open Settings', style: GoogleFonts.quicksand(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openARMeasurement() {
    // Navigate to platform-specific AR screen
    if (Platform.isIOS) {
      Navigator.push<OnboardingPotResult>(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingPotMeterARiOS(
            initialPlantHeight: widget.initialPlantHeight,
            onSwitchToManual: () {
              Navigator.pop(context); // Pop AR screen
              _openManualMeasurement(); // Open manual
            },
          ),
        ),
      ).then((result) {
        if (result != null && mounted) {
          Navigator.pop(context, result);
        }
      });
    } else if (Platform.isAndroid) {
      Navigator.push<OnboardingPotResult>(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingPotMeterARAndroid(
            initialPlantHeight: widget.initialPlantHeight,
            onSwitchToManual: () {
              Navigator.pop(context);
              _openManualMeasurement();
            },
          ),
        ),
      ).then((result) {
        if (result != null && mounted) {
          Navigator.pop(context, result);
        }
      });
    }
  }

  void _openManualMeasurement() {
    Navigator.push<OnboardingPotResult>(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingPotMeterManual(
          initialPlantHeight: widget.initialPlantHeight,
        ),
      ),
    ).then((result) {
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.leafGreen),
              const SizedBox(height: 16),
              Text('Loading...', style: GoogleFonts.quicksand()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppTheme.soilBrown),
        ),
        title: Text(
          'Measure Pot',
          style: GoogleFonts.comfortaa(
            fontWeight: FontWeight.bold,
            color: AppTheme.leafGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            
            // AR option (if available)
            if (_arAvailable)
              _buildMethodCard(
                icon: Icons.view_in_ar,
                title: 'AR Measure',
                description: 'Use your camera to measure',
                badge: 'Most Accurate',
                badgeColor: AppTheme.leafGreen,
                onTap: _requestCameraAndOpenAR,
              ),
            
            if (_arAvailable) const SizedBox(height: 16),
            
            // Manual option
            _buildMethodCard(
              icon: Icons.edit,
              title: 'Manual Entry',
              description: 'Select from preset sizes or enter custom dimensions',
              badge: 'Quickest',
              badgeColor: AppTheme.waterBlue,
              onTap: _openManualMeasurement,
            ),
            
            const Spacer(),
            
            // Skip option
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Skip for now',
                style: GoogleFonts.quicksand(
                  color: AppTheme.soilBrown.withValues(alpha:0.6),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.softSage),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: badgeColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.comfortaa(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: AppTheme.soilBrown.withValues(alpha:0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.soilBrown.withValues(alpha:0.3),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================
// Manual Entry Screen
// ============================================

class OnboardingPotMeterManual extends StatefulWidget {
  final double? initialPlantHeight;

  const OnboardingPotMeterManual({
    super.key,
    this.initialPlantHeight,
  });

  @override
  State<OnboardingPotMeterManual> createState() => _OnboardingPotMeterManualState();
}

class _OnboardingPotMeterManualState extends State<OnboardingPotMeterManual> {
  _PotSize? _selectedSize;
  bool _isCustom = false;
  
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  final _plantHeightController = TextEditingController();
  
  final bool _measurePlantHeight = true;

  static const List<_PotSize> _presetSizes = [
    _PotSize(name: 'Extra Small', description: 'Like a coffee mug', icon: '☕', heightInches: 3, widthInches: 3, examples: ['Succulents', 'Small cacti', 'Propagations']),
    _PotSize(name: 'Small', description: 'Like a soup bowl', icon: '🥣', heightInches: 4, widthInches: 4, examples: ['Small herbs', 'Air plants', '4" nursery pots']),
    _PotSize(name: 'Medium', description: 'Like a cereal bowl', icon: '🥗', heightInches: 6, widthInches: 6, examples: ['Most houseplants', 'Pothos', 'Spider plants']),
    _PotSize(name: 'Large', description: 'Like a dinner plate depth', icon: '🍽️', heightInches: 8, widthInches: 8, examples: ['Snake plants', 'Peace lilies', 'Ferns']),
    _PotSize(name: 'Extra Large', description: 'Like a basketball', icon: '🏀', heightInches: 10, widthInches: 10, examples: ['Fiddle leaf figs', 'Monsteras', 'Floor plants']),
    _PotSize(name: 'XXL / Floor Planter', description: 'Like a small trash bin', icon: '🪴', heightInches: 14, widthInches: 12, examples: ['Large trees', 'Bird of paradise', 'Outdoor planters']),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPlantHeight != null) {
      _plantHeightController.text = widget.initialPlantHeight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _widthController.dispose();
    _plantHeightController.dispose();
    super.dispose();
  }

  double _calculateVolume(double heightInches, double widthInches) {
    final radiusInches = widthInches / 2;
    final volumeCubicInches = math.pi * radiusInches * radiusInches * heightInches;
    return volumeCubicInches * 16.387;
  }

  bool get _canSave {
  // Plant height is REQUIRED
  final plantHeight = double.tryParse(_plantHeightController.text);
  if (plantHeight == null || plantHeight <= 0) return false;

  if (_isCustom) {
    final height = double.tryParse(_heightController.text);
    final width = double.tryParse(_widthController.text);
    return height != null && height > 0 && width != null && width > 0;
  }
  return _selectedSize != null;
}

void _saveAndReturn() {
    if (!_canSave) return;
    
    double heightInches;
    double widthInches;
    String? sizePreset;
    
    if (_isCustom) {
      heightInches = double.parse(_heightController.text);
      widthInches = double.parse(_widthController.text);
    } else {
      heightInches = _selectedSize!.heightInches;
      widthInches = _selectedSize!.widthInches;
      sizePreset = _selectedSize!.name;
    }
    
    final volumeML = _calculateVolume(heightInches, widthInches);
    final plantHeightInches = double.parse(_plantHeightController.text);

    final result = OnboardingPotResult(
      potHeightInches: heightInches,
      potWidthInches: widthInches,
      potVolumeML: volumeML,
      plantHeightInches: plantHeightInches,
      measurementMethod: 'manual',
      sizePreset: sizePreset,
    );
    
    Navigator.pop(context, result);
  }

  String _getVolumePreview() {
    double height, width;
    
    if (_isCustom) {
      height = double.tryParse(_heightController.text) ?? 0;
      width = double.tryParse(_widthController.text) ?? 0;
    } else if (_selectedSize != null) {
      height = _selectedSize!.heightInches;
      width = _selectedSize!.widthInches;
    } else {
      return '--';
    }
    
    if (height <= 0 || width <= 0) return '--';
    
    final volumeML = _calculateVolume(height, width);
    if (volumeML >= 1000) return '${(volumeML / 1000).toStringAsFixed(1)}L';
    return '${volumeML.round()}mL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppTheme.soilBrown),
        ),
        title: Text('Pot Size', style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildTabButton(label: 'Preset Sizes', icon: Icons.grid_view, isSelected: !_isCustom, onTap: () => setState(() => _isCustom = false))),
                const SizedBox(width: 12),
                Expanded(child: _buildTabButton(label: 'Custom', icon: Icons.edit, isSelected: _isCustom, onTap: () => setState(() => _isCustom = true))),
              ],
            ),
          ),
          
          Expanded(child: _isCustom ? _buildCustomInput() : _buildPresetGrid()),
// Plant height (required)
Padding(
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.initialPlantHeight != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'AI estimated: ${widget.initialPlantHeight!.toStringAsFixed(1)}" (edit if needed)',
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.leafGreen,
            ),
          ),
        ),
      TextField(
        controller: _plantHeightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Plant height (inches) *',
          hintText: 'e.g., 12',
          prefixIcon: const Icon(Icons.eco, color: AppTheme.leafGreen),
          helperText: 'Required for better care recommendations',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  ),
),

// Save button

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_canSave)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: AppTheme.waterBlue.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.water_drop, color: AppTheme.waterBlue, size: 18),
                          const SizedBox(width: 8),
                          Text('Estimated volume: ${_getVolumePreview()}', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: AppTheme.waterBlue)),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canSave ? _saveAndReturn : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.leafGreen, disabledBackgroundColor: Colors.grey.shade300, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: Text('Use These Measurements', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.leafGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.leafGreen : AppTheme.softSage),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.soilBrown),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.soilBrown)),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetGrid() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _presetSizes.length,
      itemBuilder: (context, index) {
        final size = _presetSizes[index];
        final isSelected = _selectedSize == size;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedSize = size),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.leafGreen.withValues(alpha:0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppTheme.leafGreen : AppTheme.softSage, width: isSelected ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: isSelected ? AppTheme.leafGreen.withValues(alpha:0.2) : AppTheme.softSage.withValues(alpha:0.3), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(size.icon, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(size.name, style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.leafGreen : AppTheme.soilBrown)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.soilBrown.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('${size.heightInches.toInt()}" × ${size.widthInches.toInt()}"', style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.soilBrown.withValues(alpha:0.7))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(size.description, style: GoogleFonts.quicksand(fontSize: 13, color: AppTheme.soilBrown.withValues(alpha:0.6))),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: size.examples.map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.3), borderRadius: BorderRadius.circular(6)),
                          child: Text(e, style: GoogleFonts.quicksand(fontSize: 10, color: AppTheme.soilBrown.withValues(alpha:0.7))),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                if (isSelected) Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppTheme.leafGreen, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual guide
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.15), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.straighten, color: AppTheme.mossGreen),
                    const SizedBox(width: 8),
                    Text('How to Measure', style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 100, height: 80, decoration: BoxDecoration(color: AppTheme.terracotta.withValues(alpha:0.3), borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)), border: Border.all(color: AppTheme.terracotta, width: 2))),
                      Positioned(left: 20, child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.arrow_upward, size: 16, color: AppTheme.waterBlue), Container(width: 2, height: 50, color: AppTheme.waterBlue), const Icon(Icons.arrow_downward, size: 16, color: AppTheme.waterBlue), const SizedBox(height: 4), Text('Height', style: GoogleFonts.quicksand(fontSize: 10, color: AppTheme.waterBlue, fontWeight: FontWeight.w600))])),
                      Positioned(bottom: 5, child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.arrow_back, size: 16, color: AppTheme.leafGreen), Container(width: 60, height: 2, color: AppTheme.leafGreen), const Icon(Icons.arrow_forward, size: 16, color: AppTheme.leafGreen)])),
                      Positioned(bottom: -10, child: Text('Width (diameter)', style: GoogleFonts.quicksand(fontSize: 10, color: AppTheme.leafGreen, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Pot Height', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
          const SizedBox(height: 8),
          TextField(controller: _heightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'e.g., 6', suffixText: 'inches', prefixIcon: const Icon(Icons.height, color: AppTheme.waterBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 20),
          Text('Pot Width (Diameter)', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
          const SizedBox(height: 8),
          TextField(controller: _widthController, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'e.g., 6', suffixText: 'inches', prefixIcon: const Icon(Icons.straighten, color: AppTheme.leafGreen), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          Text('Quick Reference', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.soilBrown.withValues(alpha:0.6))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [_buildQuickRef('Credit card', '3.4" × 2.1"'), _buildQuickRef('iPhone', '~6" tall'), _buildQuickRef('Hand span', '~8"'), _buildQuickRef('Ruler/foot', '12"')]),
        ],
      ),
    );
  }

  Widget _buildQuickRef(String item, String size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(item, style: GoogleFonts.quicksand(fontSize: 11, color: AppTheme.soilBrown.withValues(alpha:0.7))), const SizedBox(width: 4), Text(size, style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.soilBrown))]),
    );
  }
}

class _PotSize {
  final String name;
  final String description;
  final String icon;
  final double heightInches;
  final double widthInches;
  final List<String> examples;

  const _PotSize({required this.name, required this.description, required this.icon, required this.heightInches, required this.widthInches, required this.examples});
}