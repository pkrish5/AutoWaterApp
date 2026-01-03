import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/care_reminder.dart';
import '../../services/care_reminder_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initialize with auth context
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      
      await _service.initialize(api: api, userId: auth.userId!);
      
      if (mounted) {
        setState(() {
          _reminders = _service.getRemindersForPlant(widget.plant.plantId);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load reminders: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.terracotta,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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
      try {
        await _service.deleteReminder(reminder.id);
        _loadReminders();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppTheme.terracotta,
            ),
          );
        }
      }
    }
  }

  void _addReminder() async {
    final added = await AddReminderSheet.show(context, widget.plant);
    if (added != null) {
      _loadReminders();
    }
  }

  void _addDefaultReminders() async {
    setState(() => _isLoading = true);
    
    try {
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add defaults: $e'),
            backgroundColor: AppTheme.terracotta,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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
                    : _error != null
                        ? _buildErrorState()
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
                                  if (upcoming.isNotEmpty) ...[
                                    _buildSectionHeader(
                                      'Upcoming',
                                      Icons.schedule,
                                      AppTheme.leafGreen,
                                      count: upcoming.length,
                                    ),
                                    const SizedBox(height: 12),
                                    ...upcoming.map((r) => _buildReminderCard(r)),
                                  ],

                                  // Empty state with add defaults button
                                  if (_reminders.isEmpty) _buildEmptyState(),

                                  const SizedBox(height: 100), // Space for FAB
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        backgroundColor: AppTheme.leafGreen,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Reminder',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
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
                  'Care Schedule',
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😵', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Failed to load reminders',
              style: GoogleFonts.comfortaa(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReminders,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareInstructionsCard(dynamic rec) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.leafGreen.withValues(alpha: 0.1),
            AppTheme.softSage.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.leafGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: AppTheme.leafGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Care Guide',
                style: GoogleFonts.comfortaa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.leafGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCareRow('💧', 'Water', 'Every ${rec.frequencyDays} days'),
          _buildCareRow('☀️', 'Light', widget.plant.speciesInfo?.lightRequirement ?? 'Moderate'),
          _buildCareRow('🌡️', 'Humidity', widget.plant.speciesInfo?.humidityPreference ?? 'Average'),
        ],
      ),
    );
  }

  Widget _buildCareRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, {int? count}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.comfortaa(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReminderCard(CareReminder reminder, {bool isActionable = false}) {
    final bgColor = isActionable
        ? (reminder.isOverdue 
            ? AppTheme.terracotta.withValues(alpha: 0.08)
            : AppTheme.sunYellow.withValues(alpha: 0.08))
        : Colors.white;

    final borderColor = isActionable
        ? (reminder.isOverdue
            ? AppTheme.terracotta.withValues(alpha: 0.3)
            : AppTheme.sunYellow.withValues(alpha: 0.3))
        : AppTheme.softSage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.softSage.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(reminder.displayEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.displayLabel,
                        style: GoogleFonts.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reminder.frequencyLabel,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          color: AppTheme.soilBrown.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Due status & action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: reminder.isOverdue
                            ? AppTheme.terracotta.withValues(alpha: 0.15)
                            : reminder.isDueToday
                                ? AppTheme.sunYellow.withValues(alpha: 0.15)
                                : AppTheme.leafGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reminder.dueLabel,
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: reminder.isOverdue
                              ? AppTheme.terracotta
                              : reminder.isDueToday
                                  ? AppTheme.sunYellow
                                  : AppTheme.leafGreen,
                        ),
                      ),
                    ),
                    if (isActionable) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _completeReminder(reminder),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.leafGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ],
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
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(reminder.displayEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.displayLabel,
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.soilBrown,
                          ),
                        ),
                        Text(
                          reminder.frequencyLabel,
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            color: AppTheme.soilBrown.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppTheme.leafGreen),
              title: Text('Mark as Done', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _completeReminder(reminder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.terracotta),
              title: Text('Delete Reminder', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
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
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.leafGreen.withValues(alpha: 0.15),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Text('📅', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 20),
          Text(
            'No reminders set',
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add reminders to track care tasks\nfor ${widget.plant.nickname}',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _addDefaultReminders,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Add Suggested Reminders'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.leafGreen,
              side: const BorderSide(color: AppTheme.leafGreen),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}