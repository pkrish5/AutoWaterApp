import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:ambient_light/ambient_light.dart';
import '../../core/theme.dart';

/// Lux meter screen for onboarding - returns the measured lux value
/// Adapted from PlantLightCheckScreen but without Plant dependency
class OnboardingLuxMeterScreen extends StatefulWidget {
  const OnboardingLuxMeterScreen({super.key});

  @override
  State<OnboardingLuxMeterScreen> createState() => _OnboardingLuxMeterScreenState();
}

class _OnboardingLuxMeterScreenState extends State<OnboardingLuxMeterScreen> {
  CameraController? _cameraController;
  bool _isInitializing = true;

  // Live reading (smoothed)
  double _currentLux = 0.0;

  // Optional rolling average (kept for stability/stats, but UI uses _currentLux to match top)
  double _averageLux = 0.0;
  final List<double> _luxReadings = [];

  Timer? _readingTimer;

  bool _isCalibrating = false;
  int _calibrationCountdown = 0;
  bool _showInstructions = true;

  AmbientLight? _ambientLight;

  @override
  void initState() {
    super.initState();
    _initializeLightSensor();
    _initializeCamera();

    // Auto-hide instructions after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showInstructions = false);
      }
    });
  }

  // Keep list + compute average WITHOUT setState (we will update state once per tick)
  double _addReading(double lux) {
    _luxReadings.add(lux);
    if (_luxReadings.length > 20) {
      _luxReadings.removeAt(0);
    }

    if (_luxReadings.isEmpty) return 0.0;
    return _luxReadings.reduce((a, b) => a + b) / _luxReadings.length;
  }

  Future<void> _initializeLightSensor() async {
    try {
      _ambientLight = AmbientLight();

      // Test initial reading
      final testReading = await _ambientLight!.currentAmbientLight();
      debugPrint('📊 Initial ambient light reading: $testReading lux');

      // Poll ambient light sensor
      _readingTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
        try {
          final rawLux = await _ambientLight!.currentAmbientLight();
          if (!mounted || rawLux == null) return;

          final prevLux = _currentLux;

          // Apply calibration multiplier
          final double calibratedLux = rawLux * 2000.0;

          // Exponential smoothing
          final double smoothedLux = prevLux == 0
              ? calibratedLux
              : (prevLux * 0.7) + (calibratedLux * 0.3);

          // Rolling average (optional)
          final double avg = _addReading(smoothedLux);

          // ✅ ONE setState so top + bottom remain in sync
          setState(() {
            _currentLux = smoothedLux;
            _averageLux = avg;
          });

          // Debug log (doesn't affect UI cadence)
          final diff = (smoothedLux - prevLux).abs();
          if (diff > 200 || prevLux == 0) {
            debugPrint(
              '💡 Raw: $rawLux lux → Smoothed: ${smoothedLux.toInt()} lux (avg ${avg.toInt()})',
            );
          }
        } catch (e) {
          debugPrint('Error reading ambient light: $e');
        }
      });

      debugPrint('✅ Ambient light sensor initialized');
    } catch (e) {
      debugPrint('❌ Ambient light sensor not available: $e');
      if (mounted) {
        setState(() {
          _currentLux = 0.0;
          _averageLux = 0.0;
        });
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

  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _calibrationCountdown = 5;
      _luxReadings.clear();
      _averageLux = 0.0;
      // Optional: reset current too if you want a clean start:
      // _currentLux = 0.0;
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

  String _getLightCategory(double lux) {
    if (lux < 1000) return 'Low Light';
    if (lux < 10000) return 'Bright Indirect';
    if (lux < 25000) return 'Partial Sun';
    return 'Full Sun';
  }

  Color _getLightColor(double lux) {
    if (lux < 1000) return AppTheme.soilBrown;
    if (lux < 10000) return AppTheme.leafGreen;
    if (lux < 25000) return AppTheme.sunYellow;
    return AppTheme.terracotta;
  }

  void _saveAndReturn() {
    // ✅ Save exactly what the user sees (top + bottom)
    final valueToSave = _currentLux < 0 ? 0.0 : _currentLux;
    Navigator.pop(context, valueToSave);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.terracotta,
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

                  // Center circle indicator (dot)
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha:0.6),
                          width: 3,
                        ),
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
                  else
                    ...[
                      _buildHeader(),
                      if (_showInstructions) Center(child: _buildInstructions()),

                      if (!_showInstructions)
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.sunYellow,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha:0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(_currentLux < 0 ? 0 : _currentLux).toInt()} lux',
                                  style: GoogleFonts.comfortaa(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.sunYellow,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

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
          Text(
            'Initializing camera...',
            style: GoogleFonts.quicksand(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha:0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_sunny, color: AppTheme.sunYellow, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Light Meter',
                    style: GoogleFonts.comfortaa(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _showInstructions = !_showInstructions),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.help_outline, color: Colors.white, size: 22),
              ),
            ),
          ],
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
                  'Point at the light source',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.comfortaa(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aim at the window, lamp, or skylight from where your plant will be placed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha:0.8),
                    fontSize: 14,
                  ),
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
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
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
                  style: GoogleFonts.comfortaa(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sunYellow,
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
              'Hold your phone steady',
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha:0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementPanel() {
    // ✅ Bottom tracks top exactly
    final displayLux = _currentLux < 0 ? 0.0 : _currentLux;

    final category = _getLightCategory(displayLux);
    final color = _getLightColor(displayLux);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${displayLux.toInt()} lux',
              style: GoogleFonts.comfortaa(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha:0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_sunny, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
                    child: Text(
                      'Recalibrate',
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: displayLux > 0 ? _saveAndReturn : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.leafGreen,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Use This Reading',
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Optional: keep this if you want to verify average in debug UI (remove if not needed)
            // const SizedBox(height: 10),
            // Text('Avg: ${_averageLux.toInt()} lux', style: GoogleFonts.quicksand(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
