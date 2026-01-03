import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/care_reminder.dart';
import '../../models/plant.dart';
import '../../services/care_reminder_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class AddReminderSheet extends StatefulWidget {
  final Plant plant;

  const AddReminderSheet({super.key, required this.plant});

  static Future<CareReminder?> show(BuildContext context, Plant plant) {
    return showModalBottomSheet<CareReminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReminderSheet(plant: plant),
    );
  }

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  CareType _selectedType = CareType.water;
  int _frequencyDays = 7;
  DateTime _startDate = DateTime.now();
  final _customLabelController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _frequencyDays = _selectedType.defaultFrequencyDays;
    
    // If plant has a device, default to refill instead of water
    if (widget.plant.hasDevice) {
      _selectedType = CareType.refill;
      _frequencyDays = CareType.refill.defaultFrequencyDays;
    }
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validate custom label if needed
    if (_selectedType == CareType.custom && _customLabelController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a task name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get auth context
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      
      final service = CareReminderService();
      await service.initialize(api: api, userId: auth.userId!);

      final reminder = await service.addReminder(
        plantId: widget.plant.plantId,
        plantNickname: widget.plant.nickname,
        plantEmoji: widget.plant.emoji,
        careType: _selectedType,
        customLabel: _selectedType == CareType.custom
            ? _customLabelController.text.trim()
            : null,
        frequencyDays: _frequencyDays,
        startDate: _startDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context, reminder);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(widget.plant.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Reminder',
                        style: GoogleFonts.comfortaa(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.leafGreen,
                        ),
                      ),
                      Text(
                        widget.plant.nickname,
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          color: AppTheme.soilBrown.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.quicksand(
                      color: AppTheme.soilBrown.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.terracotta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.terracotta.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.terracotta, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        color: AppTheme.terracotta,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // Care type selector
                  Text(
                    'What type of care?',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: CareType.values.map((type) => _buildTypeChip(type)).toList(),
                  ),

                  // Custom label field
                  if (_selectedType == CareType.custom) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _customLabelController,
                      decoration: InputDecoration(
                        labelText: 'Custom Task Name',
                        hintText: 'e.g., Check for pests',
                        prefixIcon: const Icon(Icons.edit),
                        errorText: _error != null && _selectedType == CareType.custom 
                            ? null // Error shown above
                            : null,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Frequency selector
                  Text(
                    'How often?',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFrequencySelector(),

                  const SizedBox(height: 24),

                  // Start date
                  Text(
                    'First reminder',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDateSelector(),

                  const SizedBox(height: 24),

                  // Notes
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Any special instructions...',
                      prefixIcon: const Icon(Icons.note_add),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_selectedType.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            'Add Reminder',
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
        ],
      ),
    );
  }

  Widget _buildTypeChip(CareType type) {
    final isSelected = _selectedType == type;
    
    // Hide water option for plants with devices, hide refill for plants without
    if (type == CareType.water && widget.plant.hasDevice) return const SizedBox.shrink();
    if (type == CareType.refill && !widget.plant.hasDevice) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _frequencyDays = type.defaultFrequencyDays;
          _error = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.leafGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.leafGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              type.label,
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

  Widget _buildFrequencySelector() {
    final presets = [
      (1, 'Daily'),
      (2, '2 days'),
      (7, 'Weekly'),
      (14, '2 weeks'),
      (30, 'Monthly'),
      (90, '3 months'),
    ];

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((p) {
            final isSelected = _frequencyDays == p.$1;
            return GestureDetector(
              onTap: () => setState(() => _frequencyDays = p.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.waterBlue
                      : AppTheme.waterBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p.$2,
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.waterBlue,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Custom frequency
        Row(
          children: [
            Text(
              'Or every',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                controller: TextEditingController(text: _frequencyDays.toString()),
                onChanged: (v) {
                  final days = int.tryParse(v);
                  if (days != null && days > 0) {
                    setState(() => _frequencyDays = days);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'days',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final isToday = _startDate.year == DateTime.now().year &&
        _startDate.month == DateTime.now().month &&
        _startDate.day == DateTime.now().day;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _startDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.softSage.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.leafGreen),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? 'Today' : _formatDate(_startDate),
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                      Text(
                        'Tap to change',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: AppTheme.soilBrown.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}