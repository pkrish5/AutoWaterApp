import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

/// Manual input screen for devices without AR support
class PotMeterManualScreen extends StatefulWidget {
  final Plant plant;
  final String? arUnavailableReason;

  const PotMeterManualScreen({
    super.key,
    required this.plant,
    this.arUnavailableReason,
  });

  @override
  State<PotMeterManualScreen> createState() => _PotMeterManualScreenState();
}

class _PotMeterManualScreenState extends State<PotMeterManualScreen> {
  // Selected preset or custom
  _PotSize? _selectedSize;
  bool _isCustom = false;
  
  // Custom input controllers
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  final _plantHeightController = TextEditingController();
  bool _isSaving = false;

  // Common pot sizes with familiar comparisons
  static const List<_PotSize> _presetSizes = [
    _PotSize(
      name: 'Extra Small',
      description: 'Like a coffee mug',
      icon: '☕',
      heightInches: 3,
      widthInches: 3,
      examples: ['Succulents', 'Small cacti', 'Propagations'],
    ),
    _PotSize(
      name: 'Small',
      description: 'Like a soup bowl',
      icon: '🥣',
      heightInches: 4,
      widthInches: 4,
      examples: ['Small herbs', 'Air plants', '4" nursery pots'],
    ),
    _PotSize(
      name: 'Medium',
      description: 'Like a cereal bowl',
      icon: '🥗',
      heightInches: 6,
      widthInches: 6,
      examples: ['Most houseplants', 'Pothos', 'Spider plants'],
    ),
    _PotSize(
      name: 'Large',
      description: 'Like a dinner plate depth',
      icon: '🍽️',
      heightInches: 8,
      widthInches: 8,
      examples: ['Snake plants', 'Peace lilies', 'Ferns'],
    ),
    _PotSize(
      name: 'Extra Large',
      description: 'Like a basketball',
      icon: '🏀',
      heightInches: 10,
      widthInches: 10,
      examples: ['Fiddle leaf figs', 'Monsteras', 'Floor plants'],
    ),
    _PotSize(
      name: 'XXL / Floor Planter',
      description: 'Like a small trash bin',
      icon: '🪴',
      heightInches: 14,
      widthInches: 12,
      examples: ['Large trees', 'Bird of paradise', 'Outdoor planters'],
    ),
  ];

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
    return volumeCubicInches * 16.387; // Convert to mL
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

  Future<void> _save() async {
    if (!_canSave) return;
    
    setState(() => _isSaving = true);
    
    try {
      double heightInches;
      double widthInches;
      
      if (_isCustom) {
        heightInches = double.parse(_heightController.text);
        widthInches = double.parse(_widthController.text);
      } else {
        heightInches = _selectedSize!.heightInches;
        widthInches = _selectedSize!.widthInches;
      }
      
      final volumeML = _calculateVolume(heightInches, widthInches);
      final plantHeightInches = double.parse(_plantHeightController.text);

      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      
      final measurements = {
        'potHeightInches': heightInches,
        'potWidthInches': widthInches,
        'potVolumeML': volumeML.round(),        'plantHeightInches': plantHeightInches,
        'measurementMethod': 'manual',
        if (!_isCustom) 'sizePreset': _selectedSize!.name,
        'measuredAt': DateTime.now().toIso8601String(),
      };
      
      await api.updatePlant(
        plantId: widget.plant.plantId,
        measurements: measurements,
      );
      
      if (mounted) {
        Navigator.pop(context, true);

        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Measurements saved for ${widget.plant.nickname}!'),
            backgroundColor: AppTheme.leafGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.terracotta,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close, color: AppTheme.soilBrown),
        ),
        title: Text(
          'Pot Size',
          style: GoogleFonts.comfortaa(
            fontWeight: FontWeight.bold,
            color: AppTheme.leafGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // AR unavailable notice
          if (widget.arUnavailableReason != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sunYellow.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.sunYellow, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AR measurement not available. Select a size below or enter custom dimensions.',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.soilBrown.withValues(alpha:0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Size selection tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    label: 'Preset Sizes',
                    icon: Icons.grid_view,
                    isSelected: !_isCustom,
                    onTap: () => setState(() => _isCustom = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    label: 'Custom',
                    icon: Icons.edit,
                    isSelected: _isCustom,
                    onTap: () => setState(() => _isCustom = true),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isCustom ? _buildCustomInput() : _buildPresetGrid(),
          ),
// Plant height (required)
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: TextField(
    controller: _plantHeightController,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: 'Plant height (inches) *',
      hintText: 'e.g., 12',
      prefixIcon: const Icon(Icons.eco, color: AppTheme.leafGreen),
      helperText: 'Required for better care recommendations',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

// Save button

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Volume preview
                  if (_canSave)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.waterBlue.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.water_drop, color: AppTheme.waterBlue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Estimated volume: ${_getVolumePreview()}',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.waterBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canSave && !_isSaving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.leafGreen,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Save Measurements',
                              style: GoogleFonts.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
    if (volumeML >= 1000) {
      return '${(volumeML / 1000).toStringAsFixed(1)}L';
    }
    return '${volumeML.round()}mL';
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.leafGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.soilBrown,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.soilBrown,
              ),
            ),
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
              border: Border.all(
                color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon/emoji
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.leafGreen.withValues(alpha:0.2)
                        : AppTheme.softSage.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      size.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            size.name,
                            style: GoogleFonts.comfortaa(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.leafGreen : AppTheme.soilBrown,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.soilBrown.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${size.heightInches}" × ${size.widthInches}"',
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.soilBrown.withValues(alpha:0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        size.description,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          color: AppTheme.soilBrown.withValues(alpha:0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: size.examples.map((example) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.softSage.withValues(alpha:0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              example,
                              style: GoogleFonts.quicksand(
                                fontSize: 10,
                                color: AppTheme.soilBrown.withValues(alpha:0.7),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.leafGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
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
            decoration: BoxDecoration(
              color: AppTheme.softSage.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.straighten, color: AppTheme.mossGreen),
                    const SizedBox(width: 8),
                    Text(
                      'How to Measure',
                      style: GoogleFonts.comfortaa(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Pot diagram
                SizedBox(
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pot shape
                      Container(
                        width: 100,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.terracotta.withValues(alpha:0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          border: Border.all(
                            color: AppTheme.terracotta,
                            width: 2,
                          ),
                        ),
                      ),
                      
                      // Height arrow
                      Positioned(
                        left: 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_upward, size: 16, color: AppTheme.waterBlue),
                            Container(
                              width: 2,
                              height: 50,
                              color: AppTheme.waterBlue,
                            ),
                            const Icon(Icons.arrow_downward, size: 16, color: AppTheme.waterBlue),
                            const SizedBox(height: 4),
                            Text(
                              'Height',
                              style: GoogleFonts.quicksand(
                                fontSize: 10,
                                color: AppTheme.waterBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Width arrow
                      Positioned(
                        bottom: 5,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, size: 16, color: AppTheme.leafGreen),
                            Container(
                              width: 60,
                              height: 2,
                              color: AppTheme.leafGreen,
                            ),
                            const Icon(Icons.arrow_forward, size: 16, color: AppTheme.leafGreen),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: -10,
                        child: Text(
                          'Width (diameter)',
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            color: AppTheme.leafGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Height input
          Text(
            'Pot Height',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g., 6',
              suffixText: 'inches',
              prefixIcon: const Icon(Icons.height, color: AppTheme.waterBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Width input
          Text(
            'Pot Width (Diameter)',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _widthController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g., 6',
              suffixText: 'inches',
              prefixIcon: const Icon(Icons.width_normal, color: AppTheme.leafGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick reference
          Text(
            'Quick Reference',
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown.withValues(alpha:0.6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickRef('Credit card', '3.4" × 2.1"'),
              _buildQuickRef('iPhone', '~6" tall'),
              _buildQuickRef('Hand span', '~8"'),
              _buildQuickRef('Ruler/foot', '12"'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRef(String item, String size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item,
            style: GoogleFonts.quicksand(
              fontSize: 11,
              color: AppTheme.soilBrown.withValues(alpha:0.7),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            size,
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
        ],
      ),
    );
  }
}

/// Preset pot size data
class _PotSize {
  final String name;
  final String description;
  final String icon;
  final double heightInches;
  final double widthInches;
  final List<String> examples;

  const _PotSize({
    required this.name,
    required this.description,
    required this.icon,
    required this.heightInches,
    required this.widthInches,
    required this.examples,
  });
}