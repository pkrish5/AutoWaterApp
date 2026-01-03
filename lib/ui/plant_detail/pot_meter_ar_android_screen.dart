// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:arkit_plugin/arkit_plugin.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;
// import 'package:provider/provider.dart';
// import 'dart:math' as math;
// import '../../core/theme.dart';
// import '../../models/plant.dart';
// import '../../services/auth_service.dart';
// import '../../services/api_service.dart';
// import 'pot_meter_screen.dart';
// import 'pot_meter_manual_screen.dart';

// class PotMeterARiOS extends StatefulWidget {
//   final Plant plant;
//   const PotMeterARiOS({super.key, required this.plant});

//   @override
//   State<PotMeterARiOS> createState() => _PotMeterARiOSState();
// }

// class _PotMeterARiOSState extends State<PotMeterARiOS> {
//   late ARKitController _arkitController;
  
//   // Measurement state
//   _MeasurementStep _currentStep = _MeasurementStep.instructions;
//   final List<vector.Vector3> _measurementPoints = [];
  
//   // Results
//   double? _heightInches;
//   double? _widthInches;
//   double? _plantHeightInches;
//   bool _measurePlantHeight = false;
  
//   // UI state
//   bool _planesDetected = false;
//   String _statusMessage = 'Initializing AR...';
//   bool _isSaving = false;
//   int _nodeCounter = 0;

//   @override
//   void dispose() {
//     _arkitController.dispose();
//     super.dispose();
//   }

//   void _onARKitViewCreated(ARKitController controller) {
//     _arkitController = controller;
    
//     // Enable plane detection
//     _arkitController.onAddNodeForAnchor = _onAnchorAdded;
//     _arkitController.onUpdateNodeForAnchor = _onAnchorUpdated;
    
//     // Handle taps for measurement
//     _arkitController.onARTap = _onARTap;
    
//     setState(() {
//       _statusMessage = 'Move your phone to detect surfaces...';
//     });
//   }

//   void _onAnchorAdded(ARKitAnchor anchor) {
//     if (anchor is ARKitPlaneAnchor) {
//       if (!_planesDetected && mounted) {
//         setState(() {
//           _planesDetected = true;
//           _statusMessage = 'Surface detected! Tap to place points.';
//         });
//       }
//     }
//   }

//   void _onAnchorUpdated(ARKitAnchor anchor) {
//     // Plane updates - could visualize plane extent here
//   }

//   void _onARTap(List<ARKitTestResult> hits) {
//     if (hits.isEmpty) return;
//     if (_currentStep == _MeasurementStep.instructions) return;
//     if (_currentStep == _MeasurementStep.complete) return;

//     // Get the first hit result
//     final hit = hits.first;
//     final position = vector.Vector3(
//       hit.worldTransform.getColumn(3).x,
//       hit.worldTransform.getColumn(3).y,
//       hit.worldTransform.getColumn(3).z,
//     );

//     // Add visual marker at tap point
//     _addMarkerNode(position);
    
//     // Store measurement point
//     _measurementPoints.add(position);

//     setState(() {
//       if (_measurementPoints.length == 1) {
//         _statusMessage = 'First point placed. Tap to set second point.';
//       } else if (_measurementPoints.length == 2) {
//         _calculateAndStoreMeasurement();
//       }
//     });
//   }

//   void _addMarkerNode(vector.Vector3 position) {
//     final material = ARKitMaterial(
//       diffuse: ARKitMaterialProperty.color(AppTheme.leafGreen),
//       emission: ARKitMaterialProperty.color(AppTheme.leafGreen.withOpacity(0.5)),
//     );
    
//     final sphere = ARKitSphere(
//       radius: 0.01, // 1cm radius
//       materials: [material],
//     );
    
//     final node = ARKitNode(
//       geometry: sphere,
//       position: position,
//       name: 'marker_${_nodeCounter++}',
//     );
    
//     _arkitController.add(node);
    
//     // If we have 2 points, draw a line between them
//     if (_measurementPoints.length == 1) {
//       _drawLineBetweenPoints(_measurementPoints.first, position);
//     }
//   }

//   void _drawLineBetweenPoints(vector.Vector3 start, vector.Vector3 end) {
//     // Calculate distance and midpoint
//     final distance = start.distanceTo(end);
//     final midpoint = vector.Vector3(
//       (start.x + end.x) / 2,
//       (start.y + end.y) / 2,
//       (start.z + end.z) / 2,
//     );
    
//     // Create a thin cylinder as a line
//     final material = ARKitMaterial(
//       diffuse: ARKitMaterialProperty.color(AppTheme.leafGreen),
//     );
    
//     final cylinder = ARKitCylinder(
//       radius: 0.002, // 2mm thick line
//       height: distance,
//       materials: [material],
//     );
    
//     // Calculate rotation to align cylinder with the two points
//     final direction = end - start;
//     direction.normalize();
    
//     // Default cylinder is along Y axis, rotate to align with direction
//     final node = ARKitNode(
//       geometry: cylinder,
//       position: midpoint,
//       eulerAngles: _calculateEulerAngles(direction),
//       name: 'line_${_nodeCounter++}',
//     );
    
//     _arkitController.add(node);
//   }

//   vector.Vector3 _calculateEulerAngles(vector.Vector3 direction) {
//     // Calculate rotation to align cylinder (Y-axis) with direction vector
//     final yAxis = vector.Vector3(0, 1, 0);
//     final cross = yAxis.cross(direction);
//     final dot = yAxis.dot(direction);
//     final angle = math.acos(dot.clamp(-1.0, 1.0));
    
//     if (cross.length < 0.001) {
//       // Vectors are parallel
//       return dot > 0 ? vector.Vector3.zero() : vector.Vector3(math.pi, 0, 0);
//     }
    
//     cross.normalize();
    
//     // Convert axis-angle to euler angles (simplified)
//     return vector.Vector3(
//       math.atan2(cross.x * math.sin(angle), math.cos(angle)),
//       0,
//       math.atan2(cross.z * math.sin(angle), math.cos(angle)),
//     );
//   }

//   void _calculateAndStoreMeasurement() {
//     if (_measurementPoints.length < 2) return;

//     final point1 = _measurementPoints[0];
//     final point2 = _measurementPoints[1];
    
//     // Calculate distance in meters
//     final distanceMeters = point1.distanceTo(point2);
//     // Convert to inches (1 meter = 39.3701 inches)
//     final distanceInches = distanceMeters * 39.3701;

//     setState(() {
//       switch (_currentStep) {
//         case _MeasurementStep.measureHeight:
//           _heightInches = distanceInches;
//           _statusMessage = 'Height: ${distanceInches.toStringAsFixed(1)}"';
//           _currentStep = _MeasurementStep.confirmHeight;
//           break;
//         case _MeasurementStep.measureWidth:
//           _widthInches = distanceInches;
//           _statusMessage = 'Width: ${distanceInches.toStringAsFixed(1)}"';
//           _currentStep = _MeasurementStep.confirmWidth;
//           break;
//         case _MeasurementStep.measurePlantHeight:
//           _plantHeightInches = distanceInches;
//           _statusMessage = 'Plant Height: ${distanceInches.toStringAsFixed(1)}"';
//           _currentStep = _MeasurementStep.complete;
//           _showResultsDialog();
//           break;
//         default:
//           break;
//       }
//     });
//   }

//   void _clearPoints() {
//     // Remove marker nodes from AR scene
//     for (int i = 0; i < _nodeCounter; i++) {
//       _arkitController.remove('marker_$i');
//       _arkitController.remove('line_$i');
//     }
//     _measurementPoints.clear();
//   }

//   void _confirmMeasurement() {
//     _clearPoints();
    
//     setState(() {
//       switch (_currentStep) {
//         case _MeasurementStep.confirmHeight:
//           _currentStep = _MeasurementStep.measureWidth;
//           _statusMessage = 'Now measure the WIDTH. Tap two points.';
//           break;
//         case _MeasurementStep.confirmWidth:
//           if (_measurePlantHeight) {
//             _currentStep = _MeasurementStep.measurePlantHeight;
//             _statusMessage = 'Now measure PLANT HEIGHT. Tap two points.';
//           } else {
//             _currentStep = _MeasurementStep.complete;
//             _showResultsDialog();
//           }
//           break;
//         default:
//           break;
//       }
//     });
//   }

//   void _retryCurrentMeasurement() {
//     _clearPoints();
//     setState(() {
//       switch (_currentStep) {
//         case _MeasurementStep.confirmHeight:
//           _currentStep = _MeasurementStep.measureHeight;
//           _heightInches = null;
//           _statusMessage = 'Measure the HEIGHT. Tap two points.';
//           break;
//         case _MeasurementStep.confirmWidth:
//           _currentStep = _MeasurementStep.measureWidth;
//           _widthInches = null;
//           _statusMessage = 'Measure the WIDTH. Tap two points.';
//           break;
//         case _MeasurementStep.measurePlantHeight:
//           _plantHeightInches = null;
//           _statusMessage = 'Measure PLANT HEIGHT. Tap two points.';
//           break;
//         default:
//           break;
//       }
//     });
//   }

//   void _startMeasuring() {
//     setState(() {
//       _currentStep = _MeasurementStep.measureHeight;
//       _statusMessage = 'Measure the HEIGHT. Tap two points on the pot.';
//     });
//   }

//   double _calculateVolume() {
//     if (_heightInches == null || _widthInches == null) return 0;
//     final radiusInches = _widthInches! / 2;
//     final volumeCubicInches = math.pi * radiusInches * radiusInches * _heightInches!;
//     return volumeCubicInches * 16.387;
//   }

//   void _showResultsDialog() {
//     final volumeML = _calculateVolume();
    
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => _MeasurementResultsDialog(
//         heightInches: _heightInches!,
//         widthInches: _widthInches!,
//         volumeML: volumeML,
//         plantHeightInches: _plantHeightInches,
//         onSave: () => _saveMeasurements(volumeML),
//         onRetry: () {
//           Navigator.pop(ctx);
//           _resetAll();
//         },
//       ),
//     );
//   }

//   void _resetAll() {
//     _clearPoints();
//     _nodeCounter = 0;
//     setState(() {
//       _currentStep = _MeasurementStep.instructions;
//       _heightInches = null;
//       _widthInches = null;
//       _plantHeightInches = null;
//       _statusMessage = _planesDetected 
//           ? 'Surface detected! Tap to place points.'
//           : 'Move your phone to detect surfaces...';
//     });
//   }

//   Future<void> _saveMeasurements(double volumeML) async {
//     Navigator.pop(context); // Close dialog
    
//     setState(() => _isSaving = true);
    
//     try {
//       final auth = Provider.of<AuthService>(context, listen: false);
//       final api = ApiService(auth.idToken!);
      
//       final measurements = {
//         'potHeightInches': _heightInches,
//         'potWidthInches': _widthInches,
//         'potVolumeML': volumeML.round(),
//         if (_plantHeightInches != null) 'plantHeightInches': _plantHeightInches,
//         'measurementMethod': 'ar_ios',
//         'measuredAt': DateTime.now().toIso8601String(),
//       };
      
//       await api.updatePlant(
//         plantId: widget.plant.plantId,
//         measurements: measurements,
//       );
      
//       if (mounted) {
//         Navigator.pop(context, PotMeterResult(
//           potHeightInches: _heightInches!,
//           potWidthInches: _widthInches!,
//           potVolumeML: volumeML,
//           plantHeightInches: _plantHeightInches,
//           measurementMethod: 'ar_ios',
//         ));
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Measurements saved for ${widget.plant.nickname}!'),
//             backgroundColor: AppTheme.leafGreen,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() => _isSaving = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to save: $e'),
//             backgroundColor: AppTheme.terracotta,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     }
//   }

//   void _switchToManual() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PotMeterManualScreen(
//           plant: widget.plant,
//           arUnavailableReason: 'Switched to manual input',
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // ARKit View
//           ARKitSceneView(
//             onARKitViewCreated: _onARKitViewCreated,
//             planeDetection: ARPlaneDetection.horizontalAndVertical,
//             enableTapRecognizer: true,
//           ),
          
//           // Top bar
//           _buildTopBar(),
          
//           // Instructions overlay
//           if (_currentStep == _MeasurementStep.instructions)
//             _buildInstructionsOverlay(),
          
//           // Measurement UI
//           if (_currentStep != _MeasurementStep.instructions)
//             _buildMeasurementUI(),
          
//           // Loading overlay
//           if (_isSaving)
//             Container(
//               color: Colors.black54,
//               child: const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopBar() {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             children: [
//               _buildCircleButton(
//                 icon: Icons.close,
//                 onTap: () => Navigator.pop(context),
//               ),
//               const Spacer(),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.black54,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: _planesDetected ? AppTheme.leafGreen : Colors.orange,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Pot Meter',
//                       style: GoogleFonts.comfortaa(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Spacer(),
//               _buildCircleButton(
//                 icon: Icons.edit,
//                 onTap: _switchToManual,
//                 tooltip: 'Manual input',
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCircleButton({
//     required IconData icon,
//     required VoidCallback onTap,
//     String? tooltip,
//   }) {
//     final button = GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.black54,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Icon(icon, color: Colors.white, size: 22),
//       ),
//     );
    
//     if (tooltip != null) {
//       return Tooltip(message: tooltip, child: button);
//     }
//     return button;
//   }

//   Widget _buildInstructionsOverlay() {
//     return Container(
//       color: Colors.black87,
//       child: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 60),
            
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   children: [
//                     Text(
//                       'HOW TO MEASURE',
//                       style: GoogleFonts.comfortaa(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: AppTheme.leafGreen,
//                       ),
//                     ),
//                     const SizedBox(height: 32),
                    
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _buildInstructionStep(
//                           step: 1,
//                           icon: Icons.view_in_ar,
//                           label: 'Point at pot',
//                         ),
//                         _buildInstructionStep(
//                           step: 2,
//                           icon: Icons.touch_app,
//                           label: 'Tap two points',
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 32),
                    
//                     _buildTipCard(
//                       icon: Icons.lightbulb_outline,
//                       text: 'Move your phone slowly to detect surfaces. Green markers appear where you tap.',
//                     ),
//                     const SizedBox(height: 12),
//                     _buildTipCard(
//                       icon: Icons.straighten,
//                       text: 'Tap the top and bottom of the pot for height, then left and right edges for width.',
//                     ),
                    
//                     const SizedBox(height: 24),
                    
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: AppTheme.softSage.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.eco, color: AppTheme.leafGreen),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               'Also measure plant height?',
//                               style: GoogleFonts.quicksand(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                           Switch(
//                             value: _measurePlantHeight,
//                             onChanged: (v) => setState(() => _measurePlantHeight = v),
//                             activeColor: AppTheme.leafGreen,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
            
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: _planesDetected ? _startMeasuring : null,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppTheme.leafGreen,
//                         disabledBackgroundColor: Colors.grey,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                       ),
//                       child: Text(
//                         _planesDetected ? 'Start Measuring' : 'Detecting surfaces...',
//                         style: GoogleFonts.quicksand(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   TextButton(
//                     onPressed: _switchToManual,
//                     child: Text(
//                       'Use manual input instead',
//                       style: GoogleFonts.quicksand(
//                         color: Colors.white70,
//                         decoration: TextDecoration.underline,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInstructionStep({
//     required int step,
//     required IconData icon,
//     required String label,
//   }) {
//     return Column(
//       children: [
//         Container(
//           width: 80,
//           height: 80,
//           decoration: BoxDecoration(
//             color: AppTheme.softSage.withOpacity(0.2),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Icon(icon, size: 40, color: AppTheme.leafGreen),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           'Step $step',
//           style: GoogleFonts.comfortaa(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: AppTheme.leafGreen,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: GoogleFonts.quicksand(
//             fontSize: 12,
//             color: Colors.white70,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTipCard({required IconData icon, required String text}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: const BoxDecoration(
//               color: AppTheme.leafGreen,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, size: 16, color: Colors.white),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: GoogleFonts.quicksand(
//                 color: Colors.white,
//                 fontSize: 14,
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMeasurementUI() {
//     return Positioned(
//       bottom: 0,
//       left: 0,
//       right: 0,
//       child: SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildProgressIndicator(),
//             const SizedBox(height: 12),
            
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 24),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 10,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: AppTheme.leafGreen.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(
//                       _getStepIcon(),
//                       color: AppTheme.leafGreen,
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       _statusMessage,
//                       style: GoogleFonts.quicksand(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: AppTheme.soilBrown,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 16),
            
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildActionButton(
//                     icon: Icons.refresh,
//                     label: 'Retry',
//                     color: AppTheme.terracotta,
//                     onTap: _retryCurrentMeasurement,
//                   ),
                  
//                   if (_currentStep == _MeasurementStep.confirmHeight ||
//                       _currentStep == _MeasurementStep.confirmWidth)
//                     _buildActionButton(
//                       icon: Icons.check,
//                       label: 'Confirm',
//                       color: AppTheme.leafGreen,
//                       onTap: _confirmMeasurement,
//                       large: true,
//                     ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProgressIndicator() {
//     final totalSteps = _measurePlantHeight ? 3 : 2;
//     int currentStep = 0;
    
//     if (_heightInches != null) currentStep++;
//     if (_widthInches != null) currentStep++;
//     if (_plantHeightInches != null) currentStep++;
    
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 40),
//       child: Row(
//         children: List.generate(totalSteps, (index) {
//           final isCompleted = index < currentStep;
//           final isCurrent = index == currentStep;
          
//           return Expanded(
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               height: 4,
//               decoration: BoxDecoration(
//                 color: isCompleted
//                     ? AppTheme.leafGreen
//                     : isCurrent
//                         ? AppTheme.sunYellow
//                         : Colors.white.withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }

//   IconData _getStepIcon() {
//     switch (_currentStep) {
//       case _MeasurementStep.measureHeight:
//       case _MeasurementStep.confirmHeight:
//         return Icons.height;
//       case _MeasurementStep.measureWidth:
//       case _MeasurementStep.confirmWidth:
//         return Icons.width_normal;
//       case _MeasurementStep.measurePlantHeight:
//         return Icons.eco;
//       default:
//         return Icons.straighten;
//     }
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//     bool large = false,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(
//           horizontal: large ? 32 : 20,
//           vertical: large ? 16 : 12,
//         ),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.4),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: Colors.white, size: large ? 24 : 20),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: GoogleFonts.quicksand(
//                 fontSize: large ? 16 : 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// enum _MeasurementStep {
//   instructions,
//   measureHeight,
//   confirmHeight,
//   measureWidth,
//   confirmWidth,
//   measurePlantHeight,
//   complete,
// }

// class _MeasurementResultsDialog extends StatelessWidget {
//   final double heightInches;
//   final double widthInches;
//   final double volumeML;
//   final double? plantHeightInches;
//   final VoidCallback onSave;
//   final VoidCallback onRetry;

//   const _MeasurementResultsDialog({
//     required this.heightInches,
//     required this.widthInches,
//     required this.volumeML,
//     this.plantHeightInches,
//     required this.onSave,
//     required this.onRetry,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: AppTheme.leafGreen.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(Icons.check_circle, color: AppTheme.leafGreen, size: 32),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Measurement Complete!',
//                         style: GoogleFonts.comfortaa(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.soilBrown,
//                         ),
//                       ),
//                       Text(
//                         'Measured with AR',
//                         style: GoogleFonts.quicksand(
//                           fontSize: 12,
//                           color: AppTheme.soilBrown.withOpacity(0.6),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 24),
            
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppTheme.softSage.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 children: [
//                   _ResultRow(icon: Icons.height, label: 'Pot Height', value: '${heightInches.toStringAsFixed(1)}"'),
//                   const Divider(height: 16),
//                   _ResultRow(icon: Icons.width_normal, label: 'Pot Width', value: '${widthInches.toStringAsFixed(1)}"'),
//                   const Divider(height: 16),
//                   _ResultRow(icon: Icons.water_drop, label: 'Est. Volume', value: '${volumeML.round()} mL', highlight: true),
//                   if (plantHeightInches != null) ...[
//                     const Divider(height: 16),
//                     _ResultRow(icon: Icons.eco, label: 'Plant Height', value: '${plantHeightInches!.toStringAsFixed(1)}"'),
//                   ],
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 24),
            
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: onRetry,
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       side: BorderSide(color: AppTheme.soilBrown.withOpacity(0.3)),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     ),
//                     child: Text('Retry', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   flex: 2,
//                   child: ElevatedButton(
//                     onPressed: onSave,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppTheme.leafGreen,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     ),
//                     child: Text('Save', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.white)),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ResultRow extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final bool highlight;

//   const _ResultRow({required this.icon, required this.label, required this.value, this.highlight = false});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, size: 20, color: highlight ? AppTheme.waterBlue : AppTheme.soilBrown.withOpacity(0.6)),
//         const SizedBox(width: 12),
//         Text(label, style: GoogleFonts.quicksand(fontSize: 14, color: AppTheme.soilBrown.withOpacity(0.8))),
//         const Spacer(),
//         Text(value, style: GoogleFonts.comfortaa(fontSize: highlight ? 18 : 16, fontWeight: FontWeight.bold, color: highlight ? AppTheme.waterBlue : AppTheme.soilBrown)),
//       ],
//     );
//   }
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../models/plant.dart';
import '../../core/theme.dart';
import 'pot_meter_manual_screen.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class PotMeterARAndroid extends StatefulWidget {
  final Plant plant;
  const PotMeterARAndroid({super.key, required this.plant});

  @override
  State<PotMeterARAndroid> createState() => _PotMeterARAndroidState();
}

enum _MeasureStage { potHeight, potWidth, plantHeight }

class _PotMeterARAndroidState extends State<PotMeterARAndroid> {
  late ArCoreController _controller;

  final List<vector.Vector3> _points = [];
  int _nodeCounter = 0;

  double? _heightInches;
  double? _widthInches;
  double? _plantHeightInches;

  _MeasureStage _stage = _MeasureStage.potHeight;
  bool _isSaving = false;

  String _status = 'Move phone to detect surface';

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
    if (_isSaving) return;
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
      setState(() {
        switch (_stage) {
          case _MeasureStage.potHeight:
            _status = 'Tap second point (pot height)';
            break;
          case _MeasureStage.potWidth:
            _status = 'Tap second point (pot width)';
            break;
          case _MeasureStage.plantHeight:
            _status = 'Tap second point (plant height)';
            break;
        }
      });
    }
  }

  void _addMarker(vector.Vector3 pos) {
    final material = ArCoreMaterial(color: AppTheme.leafGreen);
    final sphere = ArCoreSphere(materials: [material], radius: 0.01);

    final node = ArCoreNode(
      shape: sphere,
      position: pos,
      name: 'marker_${_nodeCounter++}',
    );

    _controller.addArCoreNode(node);
  }

  void _measure() {
  final dMeters = _points[0].distanceTo(_points[1]);
  final dInches = dMeters * 39.3701;

  setState(() {
    switch (_stage) {
      case _MeasureStage.potHeight:
        _heightInches = dInches;
        _stage = _MeasureStage.potWidth;
        _status = 'Pot height: ${dInches.toStringAsFixed(1)}". Now measure pot width.';
        _points.clear();
        break;

      case _MeasureStage.potWidth:
        _widthInches = dInches;
        _stage = _MeasureStage.plantHeight;
        _status = 'Pot width: ${dInches.toStringAsFixed(1)}". Now measure plant height.';
        _points.clear();
        break;

      case _MeasureStage.plantHeight:
        _plantHeightInches = dInches;
        _showResults();
        break;
    }
  });
}


  double _calculateVolumeML() {
  if (_heightInches == null || _widthInches == null) return 0;
  final radiusInches = _widthInches! / 2;
  final volumeCubicInches = math.pi * radiusInches * radiusInches * _heightInches!;
  return volumeCubicInches * 16.387;
}

void _showResults() {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
  title: const Text('Measurements'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Pot height: ${_heightInches!.toStringAsFixed(1)}"'),
      Text('Pot width: ${_widthInches!.toStringAsFixed(1)}"'),
      const SizedBox(height: 8),
      Text('Plant height: ${_plantHeightInches!.toStringAsFixed(1)}"'),
      const SizedBox(height: 12),
      Text('Estimated volume: ${_calculateVolumeML().round()} mL', style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  ),
  actions: [
    TextButton(
      onPressed: () => _reset(dialogCtx),
      child: const Text('Retry'),
    ),
    ElevatedButton(
      onPressed: _isSaving ? null : () => _saveMeasurements(dialogCtx),
      child: Text(_isSaving ? 'Saving...' : 'Save'),
    ),
  ],
),

    );
  }

  void _reset(BuildContext dialogCtx) {
    Navigator.of(dialogCtx).pop();
    _points.clear();
    _heightInches = null;
    _widthInches = null;
    _plantHeightInches = null;
    _stage = _MeasureStage.potHeight;
    setState(() => _status = 'Tap first point (pot height)');
  }

  Future<void> _saveMeasurements(BuildContext dialogCtx) async {
  // Close dialog first
  Navigator.of(dialogCtx).pop();

  setState(() => _isSaving = true);

  try {
    final volumeML = _calculateVolumeML();

    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth.idToken!);

    final measurements = {
      'potHeightInches': _heightInches!,
      'potWidthInches': _widthInches!,
      'potVolumeML': volumeML.round(),
      'plantHeightInches': _plantHeightInches!,
      'measurementMethod': 'ar',
      'measuredAt': DateTime.now().toIso8601String(),
    };

    await api.updatePlant(
      plantId: widget.plant.plantId,
      measurements: measurements,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Measurements saved for ${widget.plant.nickname}!'),
        backgroundColor: AppTheme.leafGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true); // close AR screen
  } catch (e) {
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to save: $e'),
        backgroundColor: AppTheme.terracotta,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


  void _switchToManual() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PotMeterManualScreen(
          plant: widget.plant,
          arUnavailableReason: 'Switched to manual',
        ),
      ),
    );
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
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _switchToManual,
                  child: const Text('Manual'),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
