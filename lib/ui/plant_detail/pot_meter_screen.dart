import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/plant.dart';
import 'pot_meter_ar_ios_screen.dart' as ios_ar;
import 'pot_meter_ar_android_screen.dart' as android_ar;
import 'pot_meter_manual_screen.dart';

/// Result from the PotMeter measurement flow
class PotMeterResult {
  final double potHeightInches;
  final double potWidthInches;
  final double? potVolumeML;
  final double? plantHeightInches;
  final String measurementMethod;

  PotMeterResult({
    required this.potHeightInches,
    required this.potWidthInches,
    this.potVolumeML,
    this.plantHeightInches,
    required this.measurementMethod,
  });

  Map<String, dynamic> toJson() => {
        'potHeightInches': potHeightInches,
        'potWidthInches': potWidthInches,
        if (potVolumeML != null) 'potVolumeML': potVolumeML,
        if (plantHeightInches != null) 'plantHeightInches': plantHeightInches,
        'measurementMethod': measurementMethod,
      };
}

/// Entry point that checks camera permission and routes to platform-specific AR screen
class PotMeterScreen extends StatefulWidget {
  final Plant plant;
  const PotMeterScreen({super.key, required this.plant});

  @override
  State<PotMeterScreen> createState() => _PotMeterScreenState();
}

class _PotMeterScreenState extends State<PotMeterScreen> {
  bool _isChecking = true;
  bool _hasPermission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('🌱 PotMeterScreen initState - Platform: ${Platform.operatingSystem}');
    debugPrint('🌱 Plant: ${widget.plant.nickname} (${widget.plant.plantId})');
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    debugPrint('🌱 Starting permission check...');
    
    try {
      final cameraStatus = await Permission.camera.request();
      debugPrint('🌱 Camera permission status: $cameraStatus');
      debugPrint('🌱 isGranted: ${cameraStatus.isGranted}');
      debugPrint('🌱 isDenied: ${cameraStatus.isDenied}');
      debugPrint('🌱 isPermanentlyDenied: ${cameraStatus.isPermanentlyDenied}');

      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasPermission = cameraStatus.isGranted;
          if (!cameraStatus.isGranted) {
            _error = 'Camera permission required for AR measurement';
            debugPrint('🌱 Permission NOT granted, error: $_error');
          } else {
            debugPrint('🌱 Permission granted!');
          }
        });
      }
    } catch (e, stack) {
      debugPrint('🌱 Permission check EXCEPTION: $e');
      debugPrint('🌱 Stack trace: $stack');
      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasPermission = false;
          _error = 'Permission check failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🌱 Build called - isChecking: $_isChecking, hasPermission: $_hasPermission, error: $_error');
    
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking permissions...'),
            ],
          ),
        ),
      );
    }

    // If no permission, go to manual screen
    if (!_hasPermission) {
      debugPrint('🌱 Routing to MANUAL screen (no permission)');
      return PotMeterManualScreen(
        plant: widget.plant,
        arUnavailableReason: _error,
      );
    }

    // Route to platform-specific AR screen
    if (Platform.isIOS) {
      debugPrint('🌱 Routing to iOS AR screen');
      return ios_ar.PotMeterARiOS(plant: widget.plant);
    } else if (Platform.isAndroid) {
      debugPrint('🌱 Routing to Android AR screen');
      return android_ar.PotMeterARAndroid(plant: widget.plant);
    } else {
      debugPrint('🌱 Routing to MANUAL screen (unsupported platform)');
      return PotMeterManualScreen(
        plant: widget.plant,
        arUnavailableReason: 'AR not supported on this platform',
      );
    }
  }
}