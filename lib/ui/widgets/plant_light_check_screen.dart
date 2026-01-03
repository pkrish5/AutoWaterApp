import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:ambient_light/ambient_light.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';

class PlantLightCheckScreen extends StatefulWidget {
  final Plant plant;
  
  const PlantLightCheckScreen({
    super.key,
    required this.plant,
  });

  @override
  State<PlantLightCheckScreen> createState() => _PlantLightCheckScreenState();
}

class _PlantLightCheckScreenState extends State<PlantLightCheckScreen> {
  CameraController? _cameraController;
  bool _isInitializing = true;
  double _currentLux = 0.0;
  double _averageLux = 0.0;
  final List<double> _luxReadings = [];
  Timer? _readingTimer;
  bool _isCalibrating = false;
  int _calibrationCountdown = 0;
  bool _showInstructions = true;
  AmbientLight? _ambientLight;

  // Helper to get display lux (floor at 0)
  double get _displayLux => _currentLux < 0 ? 0 : _currentLux;

  @override
  void initState() {
    super.initState();
    _initializeLightSensor();
    _initializeCamera();
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showInstructions = false);
      }
    });
  }

  Future<void> _initializeLightSensor() async {
    try {
      _ambientLight = AmbientLight();
      
      final testReading = await _ambientLight!.currentAmbientLight();
      debugPrint('📊 Initial ambient light reading: $testReading lux');
      
      _readingTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
        try {
          final rawLux = await _ambientLight!.currentAmbientLight();
          
          if (rawLux != null && mounted) {
            final double calibratedLux = rawLux * 2000.0;
            
            final smoothedLux = _currentLux == 0 
                ? calibratedLux 
                : (_currentLux * 0.7) + (calibratedLux * 0.3);
            
            final absoluteDifference = (smoothedLux - _currentLux).abs();
            
            if (absoluteDifference > 200 || _currentLux == 0) {
              debugPrint('💡 Raw: $rawLux lux → Smoothed: ${smoothedLux.toInt()} lux');
              
              setState(() {
                _currentLux = smoothedLux;
                // Update average immediately to stay in sync
                _addReading(smoothedLux);
              });
            }
          }
        } catch (e) {
          debugPrint('Error reading ambient light: $e');
        }
      });
      
      debugPrint('✅ Ambient light sensor initialized');
    } catch (e) {
      debugPrint('❌ Ambient light sensor not available: $e');
      if (mounted) {
        setState(() => _currentLux = 0.0);
      }
    }
  }

  Future<void> _initializeCamera() async {
    setState(() => _isInitializing = true);
    
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _isInitializing = false);
          _showError('No camera available on this device');
        }
        return;
      }

      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      if (mounted) {
        setState(() => _isInitializing = false);
        
        if (e.toString().contains('permission') || e.toString().contains('Permission')) {
          _showError('Camera permission denied. Please enable camera access in Settings.');
        } else {
          _showError('Failed to initialize camera: ${e.toString()}');
        }
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  void _addReading(double lux) {
    _luxReadings.add(lux);
    if (_luxReadings.length > 10) {
      _luxReadings.removeAt(0);
    }
    
    if (_luxReadings.isNotEmpty) {
      _averageLux = _luxReadings.reduce((a, b) => a + b) / _luxReadings.length;
    }
  }

  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _calibrationCountdown = 5;
      _luxReadings.clear();
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isCalibrating) {
        timer.cancel();
        return;
      }

      setState(() => _calibrationCountdown--);

      if (_calibrationCountdown <= 0) {
        timer.cancel();
        setState(() => _isCalibrating = false);
      }
    });
  }

  ({double minLux, String category}) _getPlantRequirement() {
    if (widget.plant.speciesInfo?.careProfile != null) {
      final careProfile = widget.plant.speciesInfo!.careProfile!;
      final minLux = careProfile.light.minLux.toDouble();
      final category = careProfile.light.type;
      return (minLux: minLux, category: category);
    }
    
    if (widget.plant.speciesInfo?.lightRequirement != null) {
      final req = widget.plant.speciesInfo!.lightRequirement!.toLowerCase();
      if (req.contains('full sun') || req.contains('direct')) {
        return (minLux: 25000, category: 'full-sun');
      } else if (req.contains('partial')) {
        return (minLux: 10000, category: 'partial-sun');
      } else if (req.contains('bright') || req.contains('indirect')) {
        return (minLux: 5000, category: 'bright-indirect');
      } else if (req.contains('low')) {
        return (minLux: 500, category: 'low-light');
      }
    }
    
    final species = widget.plant.species.toLowerCase();
    if (species.contains('cactus') || species.contains('succulent') || 
        species.contains('strawberry')) {
      return (minLux: 20000, category: 'full-sun');
    } else if (species.contains('snake') || species.contains('pothos') || 
               species.contains('zz')) {
      return (minLux: 500, category: 'low-light');
    } else if (species.contains('fern') || species.contains('calathea')) {
      return (minLux: 5000, category: 'bright-indirect');
    }
    
    return (minLux: 5000, category: 'bright-indirect');
  }

  LightCheckResult _checkLightSuitability() {
    final requirement = _getPlantRequirement();
    final minLux = requirement.minLux;
    final currentLux = _displayLux;
    
    final minAcceptable = minLux * 0.8;
    final maxAcceptable = minLux * 1.5;
    final tooMuchThreshold = minLux * 2.5;
    
    if (currentLux >= minLux && currentLux <= maxAcceptable) {
      return LightCheckResult.perfect;
    } else if (currentLux >= minAcceptable && currentLux < minLux) {
      return LightCheckResult.acceptable;
    } else if (currentLux > maxAcceptable && currentLux < tooMuchThreshold) {
      return LightCheckResult.acceptable;
    } else if (currentLux < minAcceptable) {
      return LightCheckResult.tooLow;
    } else {
      return LightCheckResult.tooHigh;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.terracotta,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _readingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitializing
            ? _buildLoadingState()
            : Stack(
                children: [
                  // Camera preview
                  if (_cameraController != null && _cameraController!.value.isInitialized)
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize!.height,
                          height: _cameraController!.value.previewSize!.width,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  
                  // Center circle indicator
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha:0.6), width: 3),
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.sunYellow,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.sunYellow.withValues(alpha:0.6),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Overlays
                  if (_isCalibrating)
                    _buildCalibrationOverlay()
                  else ...[
                    _buildHeader(),
                    if (_showInstructions)
                      Center(child: _buildInstructions()),
                    if (!_showInstructions)
                      _buildCenterLuxDisplay(),
                    _buildMeasurementPanel(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.leafGreen),
          const SizedBox(height: 24),
          Text('Initializing camera...', style: GoogleFonts.quicksand(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCalibrationOverlay() {
    return Container(
      color: Colors.black.withValues(alpha:0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.sunYellow, width: 4),
              ),
              child: Center(
                child: Text(
                  '$_calibrationCountdown',
                  style: GoogleFonts.comfortaa(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.sunYellow),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Calibrating...', style: GoogleFonts.quicksand(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Hold your phone steady', style: GoogleFonts.quicksand(color: Colors.white.withValues(alpha:0.7), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final requirement = _getPlantRequirement();
    final result = _checkLightSuitability();
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_sunny, color: AppTheme.sunYellow, size: 18),
                      const SizedBox(width: 8),
                      Text('Light Check', style: GoogleFonts.comfortaa(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showInstructions = !_showInstructions),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.help_outline, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
          
          // Optimal vs Current - compact row at top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_florist, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text('${requirement.minLux.toInt()}+', style: GoogleFonts.comfortaa(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 4),
                        Text('optimal', style: GoogleFonts.quicksand(fontSize: 11, color: Colors.white60)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: result.color.withValues(alpha:0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wb_sunny, color: result.color, size: 16),
                        const SizedBox(width: 6),
                        Text('${_displayLux.toInt()}', style: GoogleFonts.comfortaa(fontSize: 14, fontWeight: FontWeight.bold, color: result.color)),
                        const SizedBox(width: 4),
                        Text('current', style: GoogleFonts.quicksand(fontSize: 11, color: Colors.white60)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterLuxDisplay() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.sunYellow, width: 3),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha:0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_displayLux.toInt()} lux',
              style: GoogleFonts.comfortaa(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.sunYellow),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return AnimatedOpacity(
      opacity: _showInstructions ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha:0.3), width: 2),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wb_sunny, color: AppTheme.sunYellow, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Point your camera at the light source',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.comfortaa(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aim at the window, lamp, or skylight from where your plant will be placed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(color: Colors.white.withValues(alpha:0.8), fontSize: 14),
                ),
              ],
            ),
            Positioned(
              top: -8,
              right: -8,
              child: IconButton(
                onPressed: () => setState(() => _showInstructions = false),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementPanel() {
    final result = _checkLightSuitability();
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: result.color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: result.color.withValues(alpha:0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(result.icon, color: result.color, size: 18),
                  const SizedBox(width: 8),
                  Text(result.title, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: result.color)),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(fontSize: 13, color: AppTheme.soilBrown.withValues(alpha:0.7)),
            ),
            
            const SizedBox(height: 16),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _startCalibration,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppTheme.soilBrown.withValues(alpha:0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Recalibrate', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.leafGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Done', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum LightCheckResult {
  perfect,
  acceptable,
  tooLow,
  tooHigh;

  Color get color {
    switch (this) {
      case perfect: return AppTheme.leafGreen;
      case acceptable: return AppTheme.sunYellow;
      case tooLow: return AppTheme.terracotta;
      case tooHigh: return AppTheme.terracotta;
    }
  }

  IconData get icon {
    switch (this) {
      case perfect: return Icons.check_circle;
      case acceptable: return Icons.info;
      case tooLow: return Icons.cancel;
      case tooHigh: return Icons.cancel;
    }
  }

  String get title {
    switch (this) {
      case perfect: return 'Perfect Light!';
      case acceptable: return 'Acceptable Light';
      case tooLow: return 'Not Enough Light';
      case tooHigh: return 'Too Much Light';
    }
  }

  String get message {
    switch (this) {
      case perfect: return 'This spot has ideal lighting for this plant.';
      case acceptable: return 'This spot will work, but not optimal.';
      case tooLow: return 'This spot does not have enough light for this plant.';
      case tooHigh: return 'This spot has too much direct light for this plant.';
    }
  }
}