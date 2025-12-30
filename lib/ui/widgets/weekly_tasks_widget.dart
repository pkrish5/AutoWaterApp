import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/weekly_tasks.dart';

class WeeklyTasksCard extends StatelessWidget {
  final WeeklyTasks tasks;

  const WeeklyTasksCard({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final completedCount = tasks.plantPhotoTasks.where((t) => t.completed).length;
    final totalCount = tasks.plantPhotoTasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.leafGreen.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.leafGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.task_alt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Tasks',
                      style: GoogleFonts.comfortaa(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    Text(
                      '${tasks.daysRemaining} days left',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        color: AppTheme.soilBrown.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Completion badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progress == 1.0 
                      ? AppTheme.leafGreen 
                      : AppTheme.soilBrown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0 ? Colors.white : AppTheme.soilBrown,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toInt()}% complete',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: AppTheme.soilBrown.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '${tasks.totalPointsPossible} pts possible',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.leafGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.softSage.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? AppTheme.leafGreen : AppTheme.mossGreen,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Task list
          ...tasks.plantPhotoTasks.map((task) => _TaskItem(task: task)),

          // Points earned this week
          if (tasks.pointsEarned > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sunYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: AppTheme.sunYellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+${tasks.pointsEarned} points earned this week!',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // All complete celebration
          if (progress == 1.0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.leafGreen.withValues(alpha: 0.2),
                    AppTheme.mossGreen.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'All tasks complete!',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.leafGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final PlantPhotoTask task;

  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Checkbox
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: task.completed 
                  ? AppTheme.leafGreen 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: task.completed 
                    ? AppTheme.leafGreen 
                    : AppTheme.soilBrown.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: task.completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          // Plant emoji
          Text(task.plantEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          // Task text
          Expanded(
            child: Text(
              'Photo of ${task.plantNickname}',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: task.completed 
                    ? AppTheme.soilBrown.withValues(alpha: 0.5)
                    : AppTheme.soilBrown,
                decoration: task.completed 
                    ? TextDecoration.lineThrough 
                    : null,
              ),
            ),
          ),
          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: task.completed 
                  ? AppTheme.leafGreen.withValues(alpha: 0.15)
                  : AppTheme.sunYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.completed ? '✓ ${task.points}' : '+${task.points}',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: task.completed 
                    ? AppTheme.leafGreen 
                    : AppTheme.soilBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact points badge for profile header
class PointsBadge extends StatelessWidget {
  final int points;
  final int userTotalPoints;

  const PointsBadge({super.key, required this.points, required this.userTotalPoints});

  String get _formattedPoints {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(points >= 10000 ? 0 : 1)}K';
    }
    return points.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.sunYellow,
            AppTheme.sunYellow.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sunYellow.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 6),
          Text(
            _formattedPoints,
            style: GoogleFonts.comfortaa(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'pts',
            style: GoogleFonts.quicksand(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}