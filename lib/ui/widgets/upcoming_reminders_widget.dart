import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/care_reminder.dart';
import '../../services/care_reminder_service.dart';
import '../reminders/care_reminders_screen.dart';

/// Compact widget showing upcoming reminders - for dashboard or plant detail
class UpcomingRemindersWidget extends StatefulWidget {
  final String? plantId; // If provided, shows only this plant's reminders
  final int maxItems;

  const UpcomingRemindersWidget({
    super.key,
    this.plantId,
    this.maxItems = 3,
  });

  @override
  State<UpcomingRemindersWidget> createState() => _UpcomingRemindersWidgetState();
}

class _UpcomingRemindersWidgetState extends State<UpcomingRemindersWidget> {
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
    
    List<CareReminder> reminders;
    if (widget.plantId != null) {
      reminders = _service.getRemindersForPlant(widget.plantId!)
        ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
    } else {
      reminders = _service.getUpcomingReminders(days: 14);
    }

    setState(() {
      _reminders = reminders.take(widget.maxItems).toList();
      _isLoading = false;
    });
  }

  Future<void> _completeReminder(CareReminder reminder) async {
    await _service.completeReminder(reminder.id);
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    final overdueCount = _reminders.where((r) => r.isOverdue).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.leafGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: AppTheme.leafGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Care Reminders',
                  style: GoogleFonts.comfortaa(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.soilBrown,
                  ),
                ),
                if (overdueCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$overdueCount overdue',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CareRemindersScreen()),
                  ).then((_) => _loadReminders()),
                  child: Text(
                    'See all',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: AppTheme.leafGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reminder items
          ...List.generate(_reminders.length, (i) {
            final reminder = _reminders[i];
            final isLast = i == _reminders.length - 1;
            return _CompactReminderTile(
              reminder: reminder,
              onComplete: () => _completeReminder(reminder),
              showDivider: !isLast,
            );
          }),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CompactReminderTile extends StatelessWidget {
  final CareReminder reminder;
  final VoidCallback onComplete;
  final bool showDivider;

  const _CompactReminderTile({
    required this.reminder,
    required this.onComplete,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = reminder.isOverdue;
    final isToday = reminder.isDueToday;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Plant emoji
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isOverdue ? AppTheme.terracotta : AppTheme.softSage)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(reminder.plantEmoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(reminder.displayEmoji, style: const TextStyle(fontSize: 12)),
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
                    Row(
                      children: [
                        Text(
                          reminder.plantNickname,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            color: AppTheme.soilBrown.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.soilBrown.withValues(alpha: 0.4),
                          ),
                        ),
                        Text(
                          reminder.dueLabel,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: isOverdue || isToday ? FontWeight.w600 : FontWeight.normal,
                            color: isOverdue
                                ? AppTheme.terracotta
                                : isToday
                                    ? AppTheme.leafGreen
                                    : AppTheme.soilBrown.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Complete button
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isOverdue || isToday)
                        ? AppTheme.leafGreen
                        : AppTheme.softSage.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: (isOverdue || isToday) ? Colors.white : AppTheme.leafGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 64,
            color: AppTheme.softSage.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

/// Small badge widget showing count of due reminders
class RemindersBadge extends StatefulWidget {
  final String? plantId;

  const RemindersBadge({super.key, this.plantId});

  @override
  State<RemindersBadge> createState() => _RemindersBadgeState();
}

class _RemindersBadgeState extends State<RemindersBadge> {
  final _service = CareReminderService();
  int _overdueCount = 0;
  int _todayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    await _service.initialize();
    
    List<CareReminder> reminders;
    if (widget.plantId != null) {
      reminders = _service.getRemindersForPlant(widget.plantId!);
    } else {
      reminders = _service.reminders;
    }

    final grouped = GroupedReminders.fromList(reminders);
    setState(() {
      _overdueCount = grouped.overdue.length;
      _todayCount = grouped.today.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_overdueCount == 0 && _todayCount == 0) {
      return const SizedBox.shrink();
    }

    final total = _overdueCount + _todayCount;
    final hasOverdue = _overdueCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasOverdue ? AppTheme.terracotta : AppTheme.leafGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasOverdue ? Icons.warning : Icons.notifications,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$total',
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}