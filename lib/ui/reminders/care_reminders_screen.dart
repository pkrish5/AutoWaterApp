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

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    await _service.initialize();
    setState(() {
      _grouped = _service.getGroupedReminders();
      _isLoading = false;
    });
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
            _buildSectionHeader('TODAY', AppTheme.leafGreen, isToday: true),
            ..._grouped!.today.map((r) => _buildTimelineItem(r, isToday: true)),
          ],

          // Upcoming section
          if (_grouped!.upcoming.isNotEmpty) ...[
            _buildSectionHeader('UPCOMING', AppTheme.soilBrown),
            ..._buildUpcomingByDate(),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, Color color, {bool isOverdue = false, bool isToday = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isToday ? color : Colors.transparent,
              border: Border.all(color: color, width: 2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          if (isOverdue) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_grouped!.overdue.length}',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingByDate() {
    final byDate = <String, List<CareReminder>>{};
    
    for (final r in _grouped!.upcoming) {
      final dateKey = _formatDateHeader(r.nextDue);
      byDate.putIfAbsent(dateKey, () => []).add(r);
    }

    final widgets = <Widget>[];
    for (final entry in byDate.entries) {
      widgets.add(_buildDateLabel(entry.key));
      for (final r in entry.value) {
        widgets.add(_buildTimelineItem(r));
      }
    }

    return widgets;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[date.weekday % 7];
    }
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildDateLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.softSage,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(CareReminder reminder, {bool isOverdue = false, bool isToday = false}) {
    final highlightColor = isOverdue 
        ? AppTheme.terracotta 
        : isToday 
            ? AppTheme.leafGreen 
            : null;

    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 40,
                  color: highlightColor?.withValues(alpha: 0.3) ?? AppTheme.softSage,
                ),
              ],
            ),
          ),
          
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: highlightColor != null
                    ? Border.all(color: highlightColor.withValues(alpha: 0.3), width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (highlightColor ?? AppTheme.leafGreen).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showReminderOptions(reminder),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Plant emoji
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (highlightColor ?? AppTheme.softSage).withValues(alpha: 0.15),
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
                                  Expanded(
                                    child: Text(
                                      reminder.displayLabel,
                                      style: GoogleFonts.comfortaa(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.soilBrown,
                                      ),
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
                              if (isOverdue) ...[
                                const SizedBox(height: 4),
                                Text(
                                  reminder.dueLabel,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 12,
                                    color: AppTheme.terracotta,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Complete button
                        _CompleteButton(
                          onTap: () => _completeReminder(reminder),
                          isHighlighted: isOverdue || isToday,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderOptions(CareReminder reminder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReminderOptionsSheet(
        reminder: reminder,
        onComplete: () {
          Navigator.pop(ctx);
          _completeReminder(reminder);
        },
        onEdit: () {
          Navigator.pop(ctx);
          _showEditReminder(reminder);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          await _service.deleteReminder(reminder.id);
          _showSnackBar('Reminder deleted');
          _loadReminders();
        },
      ),
    );
  }

  void _showEditReminder(CareReminder reminder) {
    // TODO: Implement edit reminder dialog
    _showSnackBar('Edit coming soon');
  }
}

class _CompleteButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isHighlighted;

  const _CompleteButton({required this.onTap, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? AppTheme.leafGreen : AppTheme.softSage.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Complete',
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? Colors.white : AppTheme.leafGreen,
          ),
        ),
      ),
    );
  }
}

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
          
          // Header
          Row(
            children: [
              Text(reminder.plantEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reminder.displayEmoji} ${reminder.displayLabel}',
                      style: GoogleFonts.comfortaa(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    Text(
                      reminder.plantNickname,
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
          
          const SizedBox(height: 8),
          Text(
            reminder.frequencyLabel,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: AppTheme.leafGreen,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          _OptionTile(
            icon: Icons.check_circle,
            label: 'Mark as Complete',
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
                          return _buildPlantTile(plant);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTile(Plant plant) {
    final reminderService = CareReminderService();
    final hasReminders = reminderService.hasRemindersForPlant(plant.plantId);
    
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