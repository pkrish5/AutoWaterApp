import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/care_reminder.dart';
import '../../services/care_reminder_service.dart';
import '../reminders/plant_care_schedule_screen.dart';

/// Card showing care info and actionable reminders for a plant
/// Use this instead of ManualCareCard in plant_detail_screen
class PlantCareCard extends StatefulWidget {
  final Plant plant;

  const PlantCareCard({super.key, required this.plant});

  @override
  State<PlantCareCard> createState() => _PlantCareCardState();
}

class _PlantCareCardState extends State<PlantCareCard> {
  final _service = CareReminderService();
  List<CareReminder> _actionableReminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    await _service.initialize();
    if (mounted) {
      final reminders = _service.getRemindersForPlant(widget.plant.plantId);
      setState(() {
        _actionableReminders = reminders.where((r) => r.isOverdue || r.isDueToday).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _completeReminder(CareReminder reminder) async {
    try {
      await _service.completeReminder(reminder.id);
      _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reminder.displayLabel} done! 🎉'),
            backgroundColor: AppTheme.leafGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to complete reminder: $e');
    }
  }

  void _openCareSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantCareScheduleScreen(plant: widget.plant),
      ),
    ).then((_) => _loadReminders());
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.plant.wateringRecommendation;
    final hasActionable = _actionableReminders.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: hasActionable
            ? Border.all(color: AppTheme.terracotta.withValues(alpha: 0.5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: (hasActionable ? AppTheme.terracotta : AppTheme.leafGreen).withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openCareSchedule,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasActionable
                            ? AppTheme.terracotta.withValues(alpha: 0.15)
                            : AppTheme.leafGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        hasActionable ? Icons.notifications_active : Icons.eco,
                        color: hasActionable ? AppTheme.terracotta : AppTheme.leafGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasActionable ? 'Care Needed' : 'Care Schedule',
                            style: GoogleFonts.comfortaa(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasActionable ? AppTheme.terracotta : AppTheme.soilBrown,
                            ),
                          ),
                          if (hasActionable)
                            Text(
                              '${_actionableReminders.length} task${_actionableReminders.length == 1 ? '' : 's'} need attention',
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                color: AppTheme.terracotta,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.soilBrown.withValues(alpha: 0.4),
                    ),
                  ],
                ),

                // Actionable reminders
                if (hasActionable && !_isLoading) ...[
                  const SizedBox(height: 12),
                  ...(_actionableReminders.take(2).map((r) => _buildActionableItem(r))),
                  if (_actionableReminders.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${_actionableReminders.length - 2} more',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: AppTheme.terracotta,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],

                // Care instructions (when no actionable)
                if (!hasActionable) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildCareChip(Icons.water_drop, 'Every ${rec.frequencyDays} days', AppTheme.waterBlue),
                      const SizedBox(width: 8),
                      _buildCareChip(Icons.local_drink, '${rec.amountML}mL', AppTheme.leafGreen),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rec.description,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppTheme.soilBrown.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionableItem(CareReminder reminder) {
    final isOverdue = reminder.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppTheme.terracotta.withValues(alpha: 0.08)
            : AppTheme.leafGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(reminder.careType.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.displayLabel,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.soilBrown,
                  ),
                ),
                Text(
                  reminder.dueLabel,
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: isOverdue ? AppTheme.terracotta : AppTheme.leafGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _completeReminder(reminder),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.leafGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}