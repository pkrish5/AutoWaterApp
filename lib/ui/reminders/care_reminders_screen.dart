import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/care_reminder.dart';
import '../../models/plant.dart';
import '../../services/care_reminder_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../widgets/leaf_background.dart';
import 'add_reminder_sheet.dart';

class CareRemindersScreen extends StatefulWidget {
  const CareRemindersScreen({super.key});

  @override
  State<CareRemindersScreen> createState() => _CareRemindersScreenState();
}

class _CareRemindersScreenState extends State<CareRemindersScreen> {
  final _service = CareReminderService();
  GroupedReminders? _grouped;
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
      // Get auth context and initialize with API
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      
      await _service.initialize(api: api, userId: auth.userId!);
      
      if (mounted) {
        setState(() {
          _grouped = _service.getGroupedReminders();
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
      _showSnackBar('${reminder.displayLabel} marked complete! 🎉');
      _loadReminders();
    } catch (e) {
      _showSnackBar('Failed to complete: $e', isError: true);
    }
  }

  Future<void> _deleteReminder(CareReminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Reminder?',
          style: GoogleFonts.comfortaa(
            fontWeight: FontWeight.bold,
            color: AppTheme.soilBrown,
          ),
        ),
        content: Text(
          'Remove "${reminder.displayLabel}" reminder for ${reminder.plantNickname}?',
          style: GoogleFonts.quicksand(color: AppTheme.soilBrown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.quicksand(
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
            ),
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
        _showSnackBar('Reminder deleted');
        _loadReminders();
      } catch (e) {
        _showSnackBar('Failed to delete: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.quicksand()),
      backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        leafCount: 5,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState()
                        : _grouped == null || _grouped!.totalCount == 0
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _loadReminders,
                                child: _buildTimeline(),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderSheet,
        backgroundColor: AppTheme.leafGreen,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Reminder',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showAddReminderSheet() async {
    // Show plant picker first, then add reminder
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PlantPickerSheet(),
    );
    if (result == true) {
      _loadReminders();
    }
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.leafGreen.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Text('🔔', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Care Schedule',
                  style: GoogleFonts.comfortaa(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
                if (_grouped != null && _grouped!.hasOverdue)
                  Text(
                    '${_grouped!.overdue.length} overdue',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: AppTheme.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Keep your plants happy',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: AppTheme.soilBrown.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          // Summary badge
          if (_grouped != null && _grouped!.hasTodayTasks)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.sunYellow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_grouped!.today.length} today',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              child: const Text('📅', style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 24),
            Text(
              'No reminders yet',
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add care reminders to your plants\nto keep track of watering, fertilizing, and more',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overdue section
          if (_grouped!.overdue.isNotEmpty) ...[
            _buildSectionHeader('OVERDUE', AppTheme.terracotta, isOverdue: true),
            ..._grouped!.overdue.map((r) => _buildTimelineItem(r, isOverdue: true)),
          ],

          // Today section
          if (_grouped!.today.isNotEmpty) ...[
            _buildSectionHeader('TODAY', AppTheme.sunYellow),
            ..._grouped!.today.map((r) => _buildTimelineItem(r, isToday: true)),
          ],

          // Upcoming section
          if (_grouped!.upcoming.isNotEmpty) ...[
            _buildSectionHeader('UPCOMING', AppTheme.leafGreen),
            ..._grouped!.upcoming.map((r) => _buildTimelineItem(r)),
          ],

          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, {bool isOverdue = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          if (isOverdue) ...[
            const SizedBox(width: 8),
            Icon(Icons.warning_amber_rounded, size: 16, color: color),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(CareReminder reminder, {bool isOverdue = false, bool isToday = false}) {
    final bgColor = isOverdue
        ? AppTheme.terracotta.withValues(alpha: 0.08)
        : isToday
            ? AppTheme.sunYellow.withValues(alpha: 0.08)
            : Colors.white;

    final borderColor = isOverdue
        ? AppTheme.terracotta.withValues(alpha: 0.3)
        : isToday
            ? AppTheme.sunYellow.withValues(alpha: 0.3)
            : AppTheme.softSage;

    return GestureDetector(
      onTap: () => _showReminderOptions(reminder),
      onLongPress: () => _showReminderOptions(reminder),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Plant emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.softSage.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(reminder.plantEmoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        reminder.displayEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reminder.displayLabel,
                        style: GoogleFonts.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder.plantNickname,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: AppTheme.soilBrown.withValues(alpha: 0.6),
                    ),
                  ),
                  if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reminder.notes!,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.soilBrown.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Due label + action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? AppTheme.terracotta.withValues(alpha: 0.15)
                        : isToday
                            ? AppTheme.sunYellow.withValues(alpha: 0.15)
                            : AppTheme.leafGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reminder.dueLabel,
                    style: GoogleFonts.quicksand(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOverdue
                          ? AppTheme.terracotta
                          : isToday
                              ? AppTheme.sunYellow
                              : AppTheme.leafGreen,
                    ),
                  ),
                ),
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
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderOptions(CareReminder reminder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderOptionsSheet(
        reminder: reminder,
        onComplete: () {
          Navigator.pop(context);
          _completeReminder(reminder);
        },
        onEdit: () {
          Navigator.pop(context);
          // TODO: Implement edit
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteReminder(reminder);
        },
      ),
    );
  }
}

/// Options sheet for a reminder
class _ReminderOptionsSheet extends StatelessWidget {
  final CareReminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderOptionsSheet({
    required this.reminder,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(reminder.plantEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reminder.displayEmoji} ${reminder.displayLabel}',
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                      Text(
                        '${reminder.plantNickname} • ${reminder.frequencyLabel}',
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
          _OptionTile(
            icon: Icons.check_circle,
            label: 'Mark as Done',
            color: AppTheme.leafGreen,
            onTap: onComplete,
          ),
          _OptionTile(
            icon: Icons.edit,
            label: 'Edit Reminder',
            color: AppTheme.waterBlue,
            onTap: onEdit,
          ),
          _OptionTile(
            icon: Icons.delete_outline,
            label: 'Delete Reminder',
            color: AppTheme.terracotta,
            onTap: onDelete,
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: GoogleFonts.quicksand(
          fontWeight: FontWeight.w600,
          color: AppTheme.soilBrown,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

/// Sheet to pick a plant before adding a reminder
class _PlantPickerSheet extends StatefulWidget {
  const _PlantPickerSheet();

  @override
  State<_PlantPickerSheet> createState() => _PlantPickerSheetState();
}

class _PlantPickerSheetState extends State<_PlantPickerSheet> {
  List<Plant> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      final plants = await api.getPlants(auth.userId!);
      
      // Also initialize reminder service with auth
      final reminderService = CareReminderService();
      await reminderService.initialize(api: api, userId: auth.userId!);
      
      if (mounted) {
        setState(() {
          _plants = plants;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load plants: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectPlant(Plant plant) async {
    Navigator.pop(context); // Close plant picker
    
    final added = await AddReminderSheet.show(context, plant);
    if (added != null && mounted) {
      Navigator.pop(context, true); // Return success to refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderService = CareReminderService();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                const Text('🪴', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a Plant',
                        style: GoogleFonts.comfortaa(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.leafGreen,
                        ),
                      ),
                      Text(
                        'Choose which plant to add a reminder for',
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          color: AppTheme.soilBrown.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Plant list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _plants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🌱', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'No plants yet',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                color: AppTheme.soilBrown,
                              ),
                            ),
                            Text(
                              'Add a plant first to set reminders',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                color: AppTheme.soilBrown.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _plants.length,
                        itemBuilder: (context, index) {
                          final plant = _plants[index];
                          final hasReminders = reminderService.hasRemindersForPlant(plant.plantId);
                          return _buildPlantTile(plant, hasReminders);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTile(Plant plant, bool hasReminders) {
    return ListTile(
      onTap: () => _selectPlant(plant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.softSage.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(plant.emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
      title: Text(
        plant.nickname,
        style: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.soilBrown,
        ),
      ),
      subtitle: Text(
        plant.species,
        style: GoogleFonts.quicksand(
          fontSize: 13,
          color: AppTheme.soilBrown.withValues(alpha: 0.6),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasReminders)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.leafGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Has reminders',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  color: AppTheme.leafGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: AppTheme.soilBrown.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}