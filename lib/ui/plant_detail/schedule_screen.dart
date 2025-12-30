import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/watering_schedule.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../widgets/leaf_background.dart';

class ScheduleScreen extends StatefulWidget {
  final Plant plant;
  final WateringSchedule? schedule;
  const ScheduleScreen({super.key, required this.plant, this.schedule});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late bool _enabled;
  late int _amountML;
  late int _moistureThreshold;
  late List<int> _selectedDays;
  late TimeOfDay _timeOfDay;
  bool _isSaving = false;
  bool _isGenerating = false;
  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _enabled = widget.schedule?.enabled ?? false;
    _amountML = widget.schedule?.amountML ?? 100;
    _moistureThreshold = widget.schedule?.moistureThreshold ?? 30;
    _selectedDays = widget.schedule?.recurringSchedule?.daysOfWeek ?? [1, 3, 5];
    final timeStr = widget.schedule?.recurringSchedule?.timeOfDay ?? '08:00';
    final parts = timeStr.split(':');
    _timeOfDay = TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
  }

  Future<void> _generateAISchedule() async {
    setState(() => _isGenerating = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      
      final result = await api.generateAISchedule(
        plantId: widget.plant.plantId,
        userId: auth.userId!,
      );
      
      final schedule = result['schedule'] as Map<String, dynamic>;
      final recurring = schedule['recurringSchedule'] as Map<String, dynamic>;
      final daysOfWeek = (recurring['daysOfWeek'] as List).cast<int>();
      final timeStr = recurring['timeOfDay'] as String;
      final timeParts = timeStr.split(':');
      
      setState(() {
        _enabled = schedule['enabled'] ?? true;
        _amountML = schedule['amountML'] ?? 100;
        _moistureThreshold = schedule['moistureThreshold'] ?? 30;
        _selectedDays = daysOfWeek;
        _timeOfDay = TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? 8,
          minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
        );
      });
      
      final reasoning = schedule['reasoning'] ?? 'Schedule optimized based on plant care profile and sensor data.';
      _showAIResultDialog(reasoning, result);
      
    } catch (e) {
      _showSnackBar('$e', isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showAIResultDialog(String reasoning, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'AI Optimization',
              style: GoogleFonts.comfortaa(
                fontWeight: FontWeight.bold,
                color: AppTheme.leafGreen,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFFFB74D), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Schedule optimized!',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI Reasoning:',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.soilBrown,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reasoning,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: AppTheme.soilBrown.withValues(alpha: 0.8),
                ),
              ),
              if (result['maturityAssessment'] != null) ...[
                const SizedBox(height: 16),
                _buildInfoChip(
                  Icons.trending_up,
                  'Maturity: ${(result['maturityAssessment']['maturityPercent'] as num).toStringAsFixed(0)}%',
                  AppTheme.leafGreen,
                ),
              ],
              if (result['sensorData'] != null && result['sensorData']['has_data'] == true) ...[
                const SizedBox(height: 8),
                _buildInfoChip(
                  Icons.sensors,
                  'Current moisture: ${result['sensorData']['current_moisture']}%',
                  AppTheme.waterBlue,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got it!',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w600,
                color: AppTheme.leafGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      await api.updateWateringSchedule(plantId: widget.plant.plantId, userId: auth.userId!, enabled: _enabled,
        amountML: _amountML, moistureThreshold: _moistureThreshold, daysOfWeek: _selectedDays,
        timeOfDay: '${_timeOfDay.hour.toString().padLeft(2, '0')}:${_timeOfDay.minute.toString().padLeft(2, '0')}',
        timezone: 'America/Chicago');
      if (mounted) { Navigator.pop(context, true); _showSnackBar('Schedule updated!'); }
    } catch (e) { _showSnackBar('Failed: $e', isError: true); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg),
      backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LeafBackground(leafCount: 4, child: SafeArea(child: Column(children: [
      _buildHeader(),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildAIOptimizeButton(),
        const SizedBox(height: 20),
        _buildEnableCard(),
        if (_enabled) ...[const SizedBox(height: 20), _buildDaysSelector(), const SizedBox(height: 20), _buildTimeSelector(),
          const SizedBox(height: 20), _buildAmountSlider(), const SizedBox(height: 20), _buildMoistureThreshold()],
        const SizedBox(height: 32), _buildSaveButton(),
      ]))),
    ]))));
  }

  Widget _buildAIOptimizeButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isGenerating ? null : _generateAISchedule,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGenerating)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                else
                  const Text('✨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  _isGenerating ? 'Optimizing...' : 'AI Optimize',
                  style: GoogleFonts.comfortaa(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    IconButton(onPressed: () => Navigator.pop(context), icon: Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen))),
    const Spacer(),
    Text('Watering Schedule', style: GoogleFonts.comfortaa(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
    const Spacer(), const SizedBox(width: 48),
  ]));

  Widget _buildEnableCard() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Icon(_enabled ? Icons.auto_mode : Icons.touch_app, color: _enabled ? AppTheme.leafGreen : AppTheme.soilBrown, size: 28),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Automatic Watering', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        Text(_enabled ? 'Waters on schedule' : 'Manual only', style: GoogleFonts.quicksand(fontSize: 13, color: AppTheme.soilBrown.withValues(alpha:0.6))),
      ])),
      Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v), activeThumbColor: AppTheme.leafGreen),
    ]));

  Widget _buildDaysSelector() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Watering Days', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
        final selected = _selectedDays.contains(i);
        return GestureDetector(onTap: () => setState(() { if (selected) {
          _selectedDays.remove(i);
        } else { _selectedDays.add(i); _selectedDays.sort(); }}),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 40, height: 40,
            decoration: BoxDecoration(color: selected ? AppTheme.leafGreen : AppTheme.softSage.withValues(alpha:0.3), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(_dayNames[i][0], style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppTheme.soilBrown)))));
      })),
    ]));

  Widget _buildTimeSelector() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      const Icon(Icons.access_time, color: AppTheme.leafGreen),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Watering Time', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        Text('When to water each day', style: GoogleFonts.quicksand(fontSize: 13, color: AppTheme.soilBrown.withValues(alpha:0.6))),
      ])),
      GestureDetector(onTap: () async { final picked = await showTimePicker(context: context, initialTime: _timeOfDay); if (picked != null) setState(() => _timeOfDay = picked); },
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.3), borderRadius: BorderRadius.circular(12)),
          child: Text(_timeOfDay.format(context), style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)))),
    ]));

  Widget _buildAmountSlider() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.water_drop, color: AppTheme.waterBlue), const SizedBox(width: 8),
        Text('Water Amount', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        const Spacer(),
        Text('${_amountML}mL', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.waterBlue))]),
      const SizedBox(height: 16),
      Slider(value: _amountML.toDouble(), min: 25, max: 500, divisions: 19, activeColor: AppTheme.waterBlue,
        onChanged: (v) => setState(() => _amountML = v.toInt())),
    ]));

  Widget _buildMoistureThreshold() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.speed, color: AppTheme.terracotta), const SizedBox(width: 8),
        Text('Moisture Threshold', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        const Spacer(),
        Text('$_moistureThreshold%', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.terracotta))]),
      const SizedBox(height: 8),
      Text('Skip if moisture above this level', style: GoogleFonts.quicksand(fontSize: 13, color: AppTheme.soilBrown.withValues(alpha:0.6))),
      const SizedBox(height: 16),
      Slider(value: _moistureThreshold.toDouble(), min: 10, max: 80, divisions: 14, activeColor: AppTheme.terracotta,
        onChanged: (v) => setState(() => _moistureThreshold = v.toInt())),
    ]));

  Widget _buildSaveButton() => SizedBox(width: double.infinity, height: 56,
    child: ElevatedButton(onPressed: _isSaving ? null : _saveSchedule,
      child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.save), const SizedBox(width: 8),
          Text('Save Schedule', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w600))])));
}