import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/care_reminder.dart';
import '../../services/care_reminder_service.dart';
import '../widgets/leaf_background.dart';
import 'add_reminder_sheet.dart';

class PlantCareScheduleScreen extends StatefulWidget {
  final Plant plant;

  const PlantCareScheduleScreen({super.key, required this.plant});

  @override
  State<PlantCareScheduleScreen> createState() => _PlantCareScheduleScreenState();
}

class _PlantCareScheduleScreenState extends State<PlantCareScheduleScreen> {
  final _service = CareReminderService();
  List<CareReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    await _service.initialize();
    if (mounted) {
      setState(() {
        _reminders = _service.getRemindersForPlant(widget.plant.plantId);
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
            content: Text('${reminder.displayLabel} done! Next: ${reminder.frequencyLabel}'),
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

  Future<void> _deleteReminder(CareReminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Reminder?', style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        content: Text('Remove "${reminder.displayLabel}" reminder?', style: GoogleFonts.quicksand(color: AppTheme.soilBrown)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.terracotta),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteReminder(reminder.id);
      _loadReminders();
    }
  }

  void _addReminder() async {
    final added = await AddReminderSheet.show(context, widget.plant);
    if (added != null) {
      _loadReminders();
    }
  }

  void _addDefaultReminders() async {
    await _service.addDefaultRemindersForPlant(widget.plant);
    _loadReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Default care reminders added!'),
          backgroundColor: AppTheme.leafGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.plant.wateringRecommendation;
    
    // Separate actionable (overdue/today) from upcoming
    final actionable = _reminders.where((r) => r.isOverdue || r.isDueToday).toList();
    final upcoming = _reminders.where((r) => !r.isOverdue && !r.isDueToday).toList();

    return Scaffold(
      body: LeafBackground(
        leafCount: 4,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadReminders,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Care instructions card
                              _buildCareInstructionsCard(rec),
                              const SizedBox(height: 20),

                              // Actionable reminders (needs attention)
                              if (actionable.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Needs Attention',
                                  Icons.priority_high,
                                  AppTheme.terracotta,
                                  count: actionable.length,
                                ),
                                const SizedBox(height: 12),
                                ...actionable.map((r) => _buildReminderCard(r, isActionable: true)),
                                const SizedBox(height: 20),
                              ],

                              // Upcoming reminders
                              _buildSectionHeader(
                                'Care Schedule',
                                Icons.calendar_today,
                                AppTheme.leafGreen,
                              ),
                              const SizedBox(height: 12),

                              if (_reminders.isEmpty)
                                _buildEmptyState()
                              else if (upcoming.isEmpty && actionable.isNotEmpty)
                                _buildAllCaughtUp()
                              else
                                ...upcoming.map((r) => _buildReminderCard(r, isActionable: false)),

                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: AppTheme.leafGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.leafGreen.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Text(widget.plant.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plant.nickname,
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
                Text(
                  'Care Schedule',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    color: AppTheme.soilBrown.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareInstructionsCard(WateringRecommendation rec) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.leafGreen.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppTheme.sunYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Care Instructions',
                style: GoogleFonts.comfortaa(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.soilBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInstructionChip(Icons.water_drop, 'Every ${rec.frequencyDays} days', AppTheme.waterBlue),
              const SizedBox(width: 8),
              _buildInstructionChip(Icons.local_drink, '${rec.amountML}mL', AppTheme.leafGreen),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rec.description,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: AppTheme.soilBrown.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionChip(IconData icon, String text, Color color) {
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
          Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, {int? count}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.comfortaa(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReminderCard(CareReminder reminder, {required bool isActionable}) {
    final isOverdue = reminder.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActionable
            ? Border.all(
                color: isOverdue ? AppTheme.terracotta : AppTheme.leafGreen,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (isOverdue ? AppTheme.terracotta : AppTheme.leafGreen).withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () => _showReminderOptions(reminder),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Care type icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActionable
                        ? (isOverdue ? AppTheme.terracotta : AppTheme.leafGreen).withValues(alpha: 0.15)
                        : AppTheme.softSage.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(reminder.careType.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.displayLabel,
                        style: GoogleFonts.comfortaa(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isOverdue ? Icons.warning_amber : Icons.schedule,
                            size: 14,
                            color: isOverdue
                                ? AppTheme.terracotta
                                : isActionable
                                    ? AppTheme.leafGreen
                                    : AppTheme.soilBrown.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reminder.dueLabel,
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: isActionable ? FontWeight.w600 : FontWeight.normal,
                              color: isOverdue
                                  ? AppTheme.terracotta
                                  : isActionable
                                      ? AppTheme.leafGreen
                                      : AppTheme.soilBrown.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${reminder.frequencyLabel}',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              color: AppTheme.soilBrown.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.notes!,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            color: AppTheme.soilBrown.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action button
                if (isActionable)
                  GestureDetector(
                    onTap: () => _completeReminder(reminder),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.leafGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.soilBrown.withValues(alpha: 0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReminderOptions(CareReminder reminder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(reminder.careType.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.displayLabel,
                        style: GoogleFonts.comfortaa(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                      Text(
                        reminder.frequencyLabel,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          color: AppTheme.leafGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppTheme.leafGreen),
              title: Text('Mark as Complete', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _completeReminder(reminder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.terracotta),
              title: Text('Delete Reminder', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteReminder(reminder);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('📅', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'No care reminders yet',
            style: GoogleFonts.comfortaa(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up reminders to keep ${widget.plant.nickname} healthy',
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: AppTheme.soilBrown.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _addDefaultReminders,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Add Defaults'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.leafGreen,
                  side: const BorderSide(color: AppTheme.leafGreen),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Custom'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.leafGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllCaughtUp() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.leafGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All caught up!',
                  style: GoogleFonts.comfortaa(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
                Text(
                  'No upcoming tasks scheduled',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    color: AppTheme.soilBrown.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}