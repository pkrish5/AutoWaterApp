import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/theme.dart';

class LuxMeterScreen extends StatefulWidget {
  const LuxMeterScreen({super.key});

  @override
  State<LuxMeterScreen> createState() => _LuxMeterScreenState();
}

class _LuxMeterScreenState extends State<LuxMeterScreen> {
  CameraController? _cameraController;
  bool _isInitializing = true;
  double _currentLux = 0.0;
  double _averageLux = 0.0;
  final List<double> _luxReadings = [];
  StreamSubscription? _lightSensorSubscription;
  Timer? _readingTimer;
  bool _useCamera = true;
  bool _isCalibrating = false;
  int _calibrationCountdown = 0;

  // Light level categories with ranges
  static const List<LightCategory> _lightCategories = [
    LightCategory(
      name: 'Low Light',
      emoji: '🌑',
      minLux: 0,
      maxLux: 1000,
      color: Color(0xFF4A5568),
      plants: ['Snake Plant', 'ZZ Plant', 'Pothos', 'Peace Lily'],
    ),
    LightCategory(
      name: 'Bright Indirect',
      emoji: '☁️',
      minLux: 1000,
      maxLux: 10000,
      color: Color(0xFF7FB069),
      plants: ['Monstera', 'Philodendron', 'Ferns', 'Spider Plant'],
    ),
    LightCategory(
      name: 'Partial Sun',
      emoji: '⛅',
      minLux: 10000,
      maxLux: 25000,
      color: Color(0xFFF4A261),
      plants: ['Succulents', 'Jade Plant', 'Rubber Plant', 'Fiddle Leaf Fig'],
    ),
    LightCategory(
      name: 'Full Sun',
      emoji: '☀️',
      minLux: 25000,
      maxLux: 100000,
      color: Color(0xFFE76F51),
      plants: ['Cacti', 'Aloe', 'Herbs', 'Vegetables'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSensor();
  }

  Future<void> _initializeSensor() async {
    setState(() => _isInitializing = true);

    // Most mobile devices don't have a dedicated light sensor API
    // We'll primarily use camera for accurate measurements
    // If you have a device with light sensor, you can enable this:
    
    /*
    // Try to use light sensor first (if available on device)
    try {
      bool gotReading = false;
      _lightSensorSubscription = lightSensorEvents.listen((event) {
        if (mounted && event != null) {
          setState(() {
            _currentLux = event;
            _useCamera = false;
          });
          _addReading(event);
          gotReading = true;
        }
      });

      // Wait a bit to see if we get readings
      await Future.delayed(const Duration(milliseconds: 500));

      if (!gotReading) {
        await _initializeCamera();
      }
    } catch (e) {
      debugPrint('Light sensor not available, using camera: $e');
      await _initializeCamera();
    }
    */
    
    // For now, just use camera which works on all devices
    await _initializeCamera();

    setState(() => _isInitializing = false);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
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
        setState(() => _useCamera = true);
        _startCameraLuxReading();
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      if (mounted) {
        // Check if it's a permission error
        if (e.toString().contains('permission') || e.toString().contains('Permission')) {
          _showError('Camera permission denied. Please enable camera access in Settings.');
        } else {
          _showError('Failed to initialize camera: ${e.toString()}');
        }
        
        // Navigate back after showing error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  void _startCameraLuxReading() {
    // Sample camera exposure settings every 500ms to estimate lux
    _readingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          // Get exposure settings
          final exposureOffset = await _cameraController!.getExposureOffsetStepSize();
          
          // Estimate lux from camera exposure (simplified algorithm)
          // This is an approximation - actual lux calculation would need calibration
          final estimatedLux = _estimateLuxFromCamera(exposureOffset);
          
          if (mounted) {
            setState(() => _currentLux = estimatedLux);
            _addReading(estimatedLux);
          }
        } catch (e) {
          debugPrint('Error reading camera exposure: $e');
        }
      }
    });
  }

  double _estimateLuxFromCamera(double exposureOffset) {
    // Simplified lux estimation based on camera exposure
    // In a production app, this would need device-specific calibration
    // This gives a rough approximation for demonstration
    
    // Typical range: exposure offset is usually between -2.0 and 2.0
    // Higher exposure offset = darker scene = lower lux
    // Lower exposure offset = brighter scene = higher lux
    
    // Map exposure offset to lux (very rough approximation)
    if (exposureOffset > 1.5) return 500; // Very dark (low light)
    if (exposureOffset > 0.5) return 2000; // Dark (bright indirect)
    if (exposureOffset > -0.5) return 8000; // Normal (bright indirect)
    if (exposureOffset > -1.5) return 15000; // Bright (partial sun)
    return 30000; // Very bright (full sun)
  }

  void _addReading(double lux) {
    _luxReadings.add(lux);
    if (_luxReadings.length > 20) {
      _luxReadings.removeAt(0);
    }
    
    // Calculate rolling average
    if (_luxReadings.isNotEmpty) {
      setState(() {
        _averageLux = _luxReadings.reduce((a, b) => a + b) / _luxReadings.length;
      });
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

  LightCategory _getCurrentCategory() {
    return _lightCategories.firstWhere(
      (cat) => _averageLux >= cat.minLux && _averageLux < cat.maxLux,
      orElse: () => _lightCategories.last,
    );
  }

  void _saveReading() {
    Navigator.pop(context, _averageLux);
  }

  void _showError(String message) {
    if (!mounted) return;
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
    _lightSensorSubscription?.cancel();
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
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildCameraView()),
                  _buildInfoPanel(),
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
          Text(
            'Initializing light sensor...',
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Light Meter',
                style: GoogleFonts.comfortaa(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _useCamera ? 'Using camera' : 'Using light sensor',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _startCalibration,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.leafGreen.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isCalibrating) {
      return _buildCalibrationOverlay();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_useCamera && _cameraController != null && _cameraController!.value.isInitialized)
          CameraPreview(_cameraController!)
        else
          Container(
            color: Colors.black,
            child: Center(
              child: Icon(
                Icons.wb_sunny,
                size: 120,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        
        // Crosshair overlay
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _getCurrentCategory().color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getCurrentCategory().color.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Instructions
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: _getCurrentCategory().color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Point camera at the light source',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aim at window, lamp, or skylight where your plant will get light',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalibrationOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.leafGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _calibrationCountdown.toString(),
                  style: GoogleFonts.comfortaa(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Calibrating...',
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hold steady',
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    final category = _getCurrentCategory();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Current reading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Reading',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: AppTheme.soilBrown.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _averageLux.toInt().toString(),
                          style: GoogleFonts.comfortaa(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: category.color,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            'lux',
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              color: AppTheme.soilBrown.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Light category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: category.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, color: category.color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        category.name,
                        style: GoogleFonts.comfortaa(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: category.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.minLux.toInt()} - ${category.maxLux.toInt()} lux',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: AppTheme.soilBrown.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Best for:',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.soilBrown.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: category.plants.map((plant) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: category.color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        plant,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: AppTheme.soilBrown.withValues(alpha: 0.8),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Light level indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _lightCategories.map((cat) {
                    final isActive = cat == category;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? cat.color : cat.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _lightCategories.map((cat) => Text(
                    cat.emoji,
                    style: const TextStyle(fontSize: 16),
                  )).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _luxReadings.length >= 5 ? _saveReading : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: category.color,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Use This Reading',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (_luxReadings.length < 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Gathering readings... ${_luxReadings.length}/5',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: AppTheme.soilBrown.withValues(alpha: 0.5),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class LightCategory {
  final String name;
  final String emoji;
  final double minLux;
  final double maxLux;
  final Color color;
  final List<String> plants;

  const LightCategory({
    required this.name,
    required this.emoji,
    required this.minLux,
    required this.maxLux,
    required this.color,
    required this.plants,
  });
}