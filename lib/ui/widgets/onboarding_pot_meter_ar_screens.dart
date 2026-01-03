import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../../core/theme.dart';

// Platform-specific imports
import 'package:arkit_plugin/arkit_plugin.dart' if (dart.library.io) 'package:arkit_plugin/arkit_plugin.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart' if (dart.library.io) 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';

import 'onboarding_pot_meter_screen.dart';

// ============================================
// iOS AR Screen for Onboarding
// ============================================

class OnboardingPotMeterARiOS extends StatefulWidget {
  final double? initialPlantHeight;
  final VoidCallback onSwitchToManual;

  const OnboardingPotMeterARiOS({
    super.key,
    this.initialPlantHeight,
    required this.onSwitchToManual,
  });

  @override
  State<OnboardingPotMeterARiOS> createState() => _OnboardingPotMeterARiOSState();
}

class _OnboardingPotMeterARiOSState extends State<OnboardingPotMeterARiOS> {
  late ARKitController _arkitController;
  
  _MeasurementStep _currentStep = _MeasurementStep.instructions;
  final List<vector.Vector3> _measurementPoints = [];
  
  double? _heightInches;
  double? _widthInches;
  double? _plantHeightInches;
  final bool _measurePlantHeight = true;
  
  bool _planesDetected = false;
  String _statusMessage = 'Initializing AR...';
  int _nodeCounter = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _arkitController.dispose();
    super.dispose();
  }

  void _onARKitViewCreated(ARKitController controller) {
    _arkitController = controller;
    _arkitController.onAddNodeForAnchor = _onAnchorAdded;
    _arkitController.onUpdateNodeForAnchor = _onAnchorUpdated;
    _arkitController.onARTap = _onARTap;
    
    setState(() {
      _statusMessage = 'Move your phone to detect surfaces...';
    });
  }

  void _onAnchorAdded(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor) {
      if (!_planesDetected && mounted) {
        setState(() {
          _planesDetected = true;
          _statusMessage = 'Surface detected! Tap to place points.';
        });
      }
    }
  }

  void _onAnchorUpdated(ARKitAnchor anchor) {}

  void _onARTap(List<ARKitTestResult> hits) {
    if (hits.isEmpty) return;
    if (_currentStep == _MeasurementStep.instructions) return;
    if (_currentStep == _MeasurementStep.complete) return;

    final hit = hits.first;
    final position = vector.Vector3(
      hit.worldTransform.getColumn(3).x,
      hit.worldTransform.getColumn(3).y,
      hit.worldTransform.getColumn(3).z,
    );

    _addMarkerNode(position);
    _measurementPoints.add(position);

    setState(() {
      if (_measurementPoints.length == 1) {
        _statusMessage = 'First point placed. Tap to set second point.';
      } else if (_measurementPoints.length == 2) {
        _calculateAndStoreMeasurement();
      }
    });
  }

  void _addMarkerNode(vector.Vector3 position) {
    final material = ARKitMaterial(
      diffuse: ARKitMaterialProperty.color(AppTheme.leafGreen),
      emission: ARKitMaterialProperty.color(AppTheme.leafGreen.withValues(alpha:0.5)),
    );
    
    final sphere = ARKitSphere(radius: 0.01, materials: [material]);
    final node = ARKitNode(
      geometry: sphere,
      position: position,
      name: 'marker_${_nodeCounter++}',
    );
    
    _arkitController.add(node);
    
    if (_measurementPoints.length == 1) {
      _drawLineBetweenPoints(_measurementPoints.first, position);
    }
  }

  void _drawLineBetweenPoints(vector.Vector3 start, vector.Vector3 end) {
    final distance = start.distanceTo(end);
    final midpoint = vector.Vector3(
      (start.x + end.x) / 2,
      (start.y + end.y) / 2,
      (start.z + end.z) / 2,
    );
    
    final material = ARKitMaterial(diffuse: ARKitMaterialProperty.color(AppTheme.leafGreen));
    final cylinder = ARKitCylinder(radius: 0.002, height: distance, materials: [material]);
    
    final direction = end - start;
    direction.normalize();
    
    final node = ARKitNode(
      geometry: cylinder,
      position: midpoint,
      eulerAngles: _calculateEulerAngles(direction),
      name: 'line_${_nodeCounter++}',
    );
    
    _arkitController.add(node);
  }

  vector.Vector3 _calculateEulerAngles(vector.Vector3 direction) {
    final yAxis = vector.Vector3(0, 1, 0);
    final cross = yAxis.cross(direction);
    final dot = yAxis.dot(direction);
    final angle = math.acos(dot.clamp(-1.0, 1.0));
    
    if (cross.length < 0.001) {
      return dot > 0 ? vector.Vector3.zero() : vector.Vector3(math.pi, 0, 0);
    }
    
    cross.normalize();
    return vector.Vector3(
      math.atan2(cross.x * math.sin(angle), math.cos(angle)),
      0,
      math.atan2(cross.z * math.sin(angle), math.cos(angle)),
    );
  }

  void _calculateAndStoreMeasurement() {
    if (_measurementPoints.length < 2) return;

    final point1 = _measurementPoints[0];
    final point2 = _measurementPoints[1];
    final distanceMeters = point1.distanceTo(point2);
    final distanceInches = distanceMeters * 39.3701;

    setState(() {
      switch (_currentStep) {
        case _MeasurementStep.measureHeight:
          _heightInches = distanceInches;
          _statusMessage = 'Height: ${distanceInches.toStringAsFixed(1)}"';
          _currentStep = _MeasurementStep.confirmHeight;
          break;
        case _MeasurementStep.measureWidth:
          _widthInches = distanceInches;
          _statusMessage = 'Width: ${distanceInches.toStringAsFixed(1)}"';
          _currentStep = _MeasurementStep.confirmWidth;
          break;
        case _MeasurementStep.measurePlantHeight:
          _plantHeightInches = distanceInches;
          _statusMessage = 'Plant Height: ${distanceInches.toStringAsFixed(1)}"';
          _currentStep = _MeasurementStep.complete;
          _showResultsDialog();
          break;
        default:
          break;
      }
    });
  }

  void _clearPoints() {
    for (int i = 0; i < _nodeCounter; i++) {
      _arkitController.remove('marker_$i');
      _arkitController.remove('line_$i');
    }
    _measurementPoints.clear();
  }

  void _confirmMeasurement() {
    _clearPoints();
    
    setState(() {
      switch (_currentStep) {
        case _MeasurementStep.confirmHeight:
          _currentStep = _MeasurementStep.measureWidth;
          _statusMessage = 'Now measure the WIDTH. Tap two points.';
          break;
        case _MeasurementStep.confirmWidth:
          _currentStep = _MeasurementStep.measurePlantHeight;
          _statusMessage = 'Now measure PLANT HEIGHT. Tap two points.';
          break;
        default:
          break;
      }
    });
  }

  void _retryCurrentMeasurement() {
    _clearPoints();
    setState(() {
      switch (_currentStep) {
        case _MeasurementStep.confirmHeight:
          _currentStep = _MeasurementStep.measureHeight;
          _heightInches = null;
          _statusMessage = 'Measure the HEIGHT. Tap two points.';
          break;
        case _MeasurementStep.confirmWidth:
          _currentStep = _MeasurementStep.measureWidth;
          _widthInches = null;
          _statusMessage = 'Measure the WIDTH. Tap two points.';
          break;
        case _MeasurementStep.measurePlantHeight:
          _plantHeightInches = null;
          _statusMessage = 'Measure PLANT HEIGHT. Tap two points.';
          break;
        default:
          break;
      }
    });
  }

  void _startMeasuring() {
    setState(() {
      _currentStep = _MeasurementStep.measureHeight;
      _statusMessage = 'Measure the HEIGHT. Tap two points on the pot.';
    });
  }

  double _calculateVolume() {
    if (_heightInches == null || _widthInches == null) return 0;
    final radiusInches = _widthInches! / 2;
    final volumeCubicInches = math.pi * radiusInches * radiusInches * _heightInches!;
    return volumeCubicInches * 16.387;
  }

  void _showResultsDialog() {
    final volumeML = _calculateVolume();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MeasurementResultsDialog(
        heightInches: _heightInches!,
        widthInches: _widthInches!,
        volumeML: volumeML,
        plantHeightInches: _plantHeightInches,
        onUse: () {
          Navigator.pop(ctx); // Close dialog
          _returnResults();
        },
        onRetry: () {
          Navigator.pop(ctx);
          _resetAll();
        },
      ),
    );
  }

  void _returnResults() {
    final volumeML = _calculateVolume();
    final result = OnboardingPotResult(
      potHeightInches: _heightInches!,
      potWidthInches: _widthInches!,
      potVolumeML: volumeML,
      plantHeightInches: _plantHeightInches,
      measurementMethod: 'ar_ios',
    );
    Navigator.pop(context, result);
  }

  void _resetAll() {
    _clearPoints();
    _nodeCounter = 0;
    setState(() {
      _currentStep = _MeasurementStep.instructions;
      _heightInches = null;
      _widthInches = null;
      _plantHeightInches = widget.initialPlantHeight;
      _statusMessage = _planesDetected 
          ? 'Surface detected! Tap to place points.'
          : 'Move your phone to detect surfaces...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARKitSceneView(
            onARKitViewCreated: _onARKitViewCreated,
            planeDetection: ARPlaneDetection.horizontalAndVertical,
            enableTapRecognizer: true,
          ),
          _buildTopBar(),
          if (_currentStep == _MeasurementStep.instructions)
            _buildInstructionsOverlay(),
          if (_currentStep != _MeasurementStep.instructions)
            _buildMeasurementUI(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildCircleButton(icon: Icons.close, onTap: () => Navigator.pop(context)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: _planesDetected ? AppTheme.leafGreen : Colors.orange, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text('Pot Meter', style: GoogleFonts.comfortaa(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              const Spacer(),
              _buildCircleButton(icon: Icons.edit, onTap: widget.onSwitchToManual, tooltip: 'Manual input'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap, String? tooltip}) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: button) : button;
  }

  Widget _buildInstructionsOverlay() {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('HOW TO MEASURE', style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInstructionStep(step: 1, icon: Icons.view_in_ar, label: 'Point at pot'),
                        _buildInstructionStep(step: 2, icon: Icons.touch_app, label: 'Tap two points'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildTipCard(icon: Icons.lightbulb_outline, text: 'Move your phone slowly to detect surfaces. Green markers appear where you tap.'),
                    const SizedBox(height: 12),
                    _buildTipCard(icon: Icons.straighten, text: 'Tap the top and bottom of the pot for height, then left and right edges for width.'),
                    const SizedBox(height: 24),
                    Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppTheme.softSage.withValues(alpha:0.2),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [
      const Icon(Icons.eco, color: AppTheme.leafGreen),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plant height measurement is required.',
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.initialPlantHeight != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'AI estimated: ${widget.initialPlantHeight!.toStringAsFixed(1)}" (you will measure to confirm)',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  ),
),

                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _planesDetected ? _startMeasuring : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.leafGreen, disabledBackgroundColor: Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: Text(_planesDetected ? 'Start Measuring' : 'Detecting surfaces...', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onSwitchToManual,
                    child: Text('Use manual input instead', style: GoogleFonts.quicksand(color: Colors.white70, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({required int step, required IconData icon, required String label}) {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.2), borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, size: 40, color: AppTheme.leafGreen),
        ),
        const SizedBox(height: 12),
        Text('Step $step', style: GoogleFonts.comfortaa(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.quicksand(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTipCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: AppTheme.leafGreen, shape: BoxShape.circle), child: Icon(icon, size: 16, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.quicksand(color: Colors.white, fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildMeasurementUI() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 10)]),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.leafGreen.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)), child: Icon(_getStepIcon(), color: AppTheme.leafGreen, size: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_statusMessage, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.soilBrown))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_isConfirmStep()) _buildConfirmButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Height', 'Width', 'Plant'];
    final currentIndex = _getCurrentStepIndex();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final label = entry.value;
          final isComplete = idx < currentIndex;
          final isCurrent = idx == currentIndex;
          
          return Row(
            children: [
              if (idx > 0) Container(width: 20, height: 2, color: isComplete ? AppTheme.leafGreen : Colors.white30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isComplete ? AppTheme.leafGreen : (isCurrent ? Colors.white : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(label, style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: isComplete || isCurrent ? (isComplete ? Colors.white : AppTheme.soilBrown) : Colors.white54)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  int _getCurrentStepIndex() {
    switch (_currentStep) {
      case _MeasurementStep.measureHeight:
      case _MeasurementStep.confirmHeight:
        return 0;
      case _MeasurementStep.measureWidth:
      case _MeasurementStep.confirmWidth:
        return 1;
      case _MeasurementStep.measurePlantHeight:
      case _MeasurementStep.complete:
        return 2;
      default:
        return 0;
    }
  }

  IconData _getStepIcon() {
    switch (_currentStep) {
      case _MeasurementStep.measureHeight:
      case _MeasurementStep.confirmHeight:
        return Icons.height;
      case _MeasurementStep.measureWidth:
      case _MeasurementStep.confirmWidth:
        return Icons.straighten;
      case _MeasurementStep.measurePlantHeight:
        return Icons.eco;
      default:
        return Icons.straighten;
    }
  }

  bool _isConfirmStep() {
    return _currentStep == _MeasurementStep.confirmHeight || _currentStep == _MeasurementStep.confirmWidth;
  }

  Widget _buildConfirmButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildActionButton(icon: Icons.refresh, label: 'Retry', color: Colors.orange, onTap: _retryCurrentMeasurement)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildActionButton(icon: Icons.check, label: 'Confirm', color: AppTheme.leafGreen, onTap: _confirmMeasurement, large: true)),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap, bool large = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: large ? 16 : 12, horizontal: 16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withValues(alpha:0.4), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: large ? 24 : 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.quicksand(fontSize: large ? 16 : 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}


// ============================================
// Android AR Screen for Onboarding
// ============================================

class OnboardingPotMeterARAndroid extends StatefulWidget {
  final double? initialPlantHeight;
  final VoidCallback onSwitchToManual;

  const OnboardingPotMeterARAndroid({
    super.key,
    this.initialPlantHeight,
    required this.onSwitchToManual,
  });

  @override
  State<OnboardingPotMeterARAndroid> createState() => _OnboardingPotMeterARAndroidState();
}

class _OnboardingPotMeterARAndroidState extends State<OnboardingPotMeterARAndroid> {
  late ArCoreController _controller;
  
  final List<vector.Vector3> _points = [];
  int _nodeCounter = 0;
  
  double? _heightInches;
  double? _widthInches;
  double? _plantHeightInches;
  final bool _measurePlantHeight = true;
  
  String _status = 'Move phone to detect surface';
  _AndroidMeasureStep _step = _AndroidMeasureStep.height;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _controller = controller;
    _controller.onPlaneTap = _onPlaneTap;
  }

  void _onPlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty) return;

    final hit = hits.first;
    final pos = vector.Vector3(
      hit.pose.translation.x,
      hit.pose.translation.y,
      hit.pose.translation.z,
    );

    _addMarker(pos);
    _points.add(pos);

    if (_points.length == 2) {
      _measure();
    } else {
      setState(() => _status = 'Tap second point');
    }
  }

  void _addMarker(vector.Vector3 pos) {
    final material = ArCoreMaterial(color: AppTheme.leafGreen);
    final sphere = ArCoreSphere(materials: [material], radius: 0.01);
    final node = ArCoreNode(shape: sphere, position: pos, name: 'marker_${_nodeCounter++}');
    _controller.addArCoreNode(node);
  }

  void _measure() {
    final dMeters = _points[0].distanceTo(_points[1]);
    final dInches = dMeters * 39.3701;
    _points.clear();

    setState(() {
      switch (_step) {
        case _AndroidMeasureStep.height:
          _heightInches = dInches;
          _status = 'Height: ${dInches.toStringAsFixed(1)}". Now measure width.';
          _step = _AndroidMeasureStep.width;
          break;
        case _AndroidMeasureStep.width:
          _widthInches = dInches;
          if (_measurePlantHeight) {
            _status = 'Width: ${dInches.toStringAsFixed(1)}". Now measure plant height.';
            _step = _AndroidMeasureStep.plantHeight;
          } else {
            _showResults();
          }
          break;
        case _AndroidMeasureStep.plantHeight:
          _plantHeightInches = dInches;
          _showResults();
          break;
      }
    });
  }

  double _calculateVolume() {
    if (_heightInches == null || _widthInches == null) return 0;
    final radiusInches = _widthInches! / 2;
    final volumeCubicInches = math.pi * radiusInches * radiusInches * _heightInches!;
    return volumeCubicInches * 16.387;
  }

  void _showResults() {
    final volumeML = _calculateVolume();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MeasurementResultsDialog(
        heightInches: _heightInches!,
        widthInches: _widthInches!,
        volumeML: volumeML,
        plantHeightInches: _plantHeightInches,
        onUse: () {
          Navigator.pop(context); // Close dialog
          _returnResults();
        },
        onRetry: () {
          Navigator.pop(context);
          _reset();
        },
      ),
    );
  }

  void _returnResults() {
    final volumeML = _calculateVolume();
    final result = OnboardingPotResult(
      potHeightInches: _heightInches!,
      potWidthInches: _widthInches!,
      potVolumeML: volumeML,
      plantHeightInches: _plantHeightInches,
      measurementMethod: 'ar_android',
    );
    Navigator.pop(context, result);
  }

  void _reset() {
    setState(() {
      _heightInches = null;
      _widthInches = null;
      _plantHeightInches = widget.initialPlantHeight;
      _step = _AndroidMeasureStep.height;
      _status = 'Measure pot height. Tap two points.';
      _points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
          ),
          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Text('AR Pot Meter', style: GoogleFonts.comfortaa(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onSwitchToManual,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom status
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.leafGreen.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_getStepIcon(), color: AppTheme.leafGreen),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_status, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: AppTheme.soilBrown))),
                      ],
                    ),
                    if (_measurePlantHeight && _step == _AndroidMeasureStep.height)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.eco, color: AppTheme.leafGreen, size: 16),
                            const SizedBox(width: 8),
                            Text('Plant height will be measured after pot', style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.6))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon() {
    switch (_step) {
      case _AndroidMeasureStep.height:
        return Icons.height;
      case _AndroidMeasureStep.width:
        return Icons.straighten;
      case _AndroidMeasureStep.plantHeight:
        return Icons.eco;
    }
  }
}

enum _AndroidMeasureStep { height, width, plantHeight }


// ============================================
// Shared Components
// ============================================

enum _MeasurementStep {
  instructions,
  measureHeight,
  confirmHeight,
  measureWidth,
  confirmWidth,
  measurePlantHeight,
  complete,
}

class _MeasurementResultsDialog extends StatelessWidget {
  final double heightInches;
  final double widthInches;
  final double volumeML;
  final double? plantHeightInches;
  final VoidCallback onUse;
  final VoidCallback onRetry;

  const _MeasurementResultsDialog({
    required this.heightInches,
    required this.widthInches,
    required this.volumeML,
    this.plantHeightInches,
    required this.onUse,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.leafGreen.withValues(alpha:0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: AppTheme.leafGreen, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Measurement Complete!', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
                      Text('Measured with AR', style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.6))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.2), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _ResultRow(icon: Icons.height, label: 'Pot Height', value: '${heightInches.toStringAsFixed(1)}"'),
                  const Divider(height: 16),
                  _ResultRow(icon: Icons.straighten, label: 'Pot Width', value: '${widthInches.toStringAsFixed(1)}"'),
                  const Divider(height: 16),
                  _ResultRow(icon: Icons.water_drop, label: 'Est. Volume', value: '${volumeML.round()} mL', highlight: true),
                  if (plantHeightInches != null) ...[
                    const Divider(height: 16),
                    _ResultRow(icon: Icons.eco, label: 'Plant Height', value: '${plantHeightInches!.toStringAsFixed(1)}"'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: AppTheme.soilBrown.withValues(alpha:0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Retry', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onUse,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.leafGreen, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Use These', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.white)),
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

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _ResultRow({required this.icon, required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: highlight ? AppTheme.waterBlue : AppTheme.soilBrown.withValues(alpha:0.6)),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.quicksand(fontSize: 14, color: AppTheme.soilBrown.withValues(alpha:0.8))),
        const Spacer(),
        Text(value, style: GoogleFonts.comfortaa(fontSize: highlight ? 18 : 16, fontWeight: FontWeight.bold, color: highlight ? AppTheme.waterBlue : AppTheme.soilBrown)),
      ],
    );
  }
}