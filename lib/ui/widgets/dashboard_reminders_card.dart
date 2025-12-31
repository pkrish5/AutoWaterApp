import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/care_reminder.dart';
import '../../services/care_reminder_service.dart';
import '../reminders/care_reminders_screen.dart';

/// Dashboard card showing upcoming reminders with "View All" navigation
class DashboardRemindersCard extends StatefulWidget {
  final int maxItems;

  const DashboardRemindersCard({super.key, this.maxItems = 3});

  @override
  State<DashboardRemindersCard> createState() => _DashboardRemindersCardState();
}

class _DashboardRemindersCardState extends State<DashboardRemindersCard> {
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
    if (mounted) {
      setState(() {
        _grouped = _service.getGroupedReminders();
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

  void _navigateToReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CareRemindersScreen()),
    ).then((_) => _loadReminders());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Combine overdue + today for actionable items
    final actionable = [
      ...(_grouped?.overdue ?? []),
      ...(_grouped?.today ?? []),
    ];

    final hasAnyReminders = (_grouped?.totalCount ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.leafGreen.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - always tappable
          GestureDetector(
            onTap: _navigateToReminders,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionable.isNotEmpty
                        ? AppTheme.terracotta.withValues(alpha: 0.15)
                        : AppTheme.sunYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    actionable.isNotEmpty ? Icons.notifications_active : Icons.schedule,
                    color: actionable.isNotEmpty ? AppTheme.terracotta : AppTheme.sunYellow,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Care Schedule',
                        style: GoogleFonts.comfortaa(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                      Text(
                        actionable.isNotEmpty
                            ? '${actionable.length} task${actionable.length == 1 ? '' : 's'} need attention'
                            : hasAnyReminders
                                ? 'All caught up! 🎉'
                                : 'Set up care reminders',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: actionable.isNotEmpty 
                              ? AppTheme.terracotta 
                              : AppTheme.soilBrown.withValues(alpha: 0.6),
                          fontWeight: actionable.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
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
          ),

          if (actionable.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Show actionable reminders
            ...actionable.take(widget.maxItems).map((r) => _buildReminderRow(r)),
            
            if (actionable.length > widget.maxItems)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed: _navigateToReminders,
                    child: Text(
                      'View all ${actionable.length} tasks',
                      style: GoogleFonts.quicksand(
                        color: AppTheme.leafGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderRow(CareReminder reminder) {
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
          Text(reminder.plantEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(reminder.careType.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      reminder.displayLabel,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${reminder.plantNickname} • ${reminder.dueLabel}',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: isOverdue ? AppTheme.terracotta : AppTheme.soilBrown.withValues(alpha: 0.6),
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
}

/// Small badge showing reminder count (for use in headers/nav)
class RemindersBadge extends StatefulWidget {
  final double size;

  const RemindersBadge({super.key, this.size = 20});

  @override
  State<RemindersBadge> createState() => _RemindersBadgeState();
}

class _RemindersBadgeState extends State<RemindersBadge> {
  final _service = CareReminderService();
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    await _service.initialize();
    if (mounted) {
      setState(() => _count = _service.actionableCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.terracotta,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: BoxConstraints(minWidth: widget.size),
      child: Text(
        _count > 9 ? '9+' : '$_count',
        style: GoogleFonts.quicksand(
          fontSize: widget.size * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}