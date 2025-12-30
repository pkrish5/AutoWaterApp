class WeeklyTasks {
  final String userId;
  final int weekNumber;
  final int year;
  final List<PlantPhotoTask> plantPhotoTasks;
  final int pointsEarned;
  final int userTotalPoints;
  final int totalPointsPossible;
  final DateTime weekStart;
  final DateTime weekEnd;

  WeeklyTasks({
    required this.userId,
    required this.weekNumber,
    required this.year,
    required this.userTotalPoints, 
    required this.plantPhotoTasks,
    required this.pointsEarned,
    required this.totalPointsPossible,
    required this.weekStart,
    required this.weekEnd,
  });

  factory WeeklyTasks.fromJson(Map<String, dynamic> json) {
    return WeeklyTasks(
      userId: json['userId'] ?? '',
      weekNumber: json['weekNumber'] ?? _getCurrentWeekNumber(),
      year: json['year'] ?? DateTime.now().year,
      plantPhotoTasks: (json['plantPhotoTasks'] as List?)
              ?.map((e) => PlantPhotoTask.fromJson(e))
              .toList() ??
          [],
      pointsEarned: json['pointsEarned'] ?? 0,
      userTotalPoints: json['userTotalPoints'] ?? 0,
      totalPointsPossible: json['totalPointsPossible'] ?? 0,
      weekStart: json['weekStart'] != null
          ? DateTime.parse(json['weekStart'])
          : _getWeekStart(),
      weekEnd: json['weekEnd'] != null
          ? DateTime.parse(json['weekEnd'])
          : _getWeekEnd(),
    );
  }

  static int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final days = now.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday) / 7).ceil();
  }

  static DateTime _getWeekStart() {
    final now = DateTime.now();
    final daysFromMonday = now.weekday - 1;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  static DateTime _getWeekEnd() {
    final start = _getWeekStart();
    return start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  double get completionPercentage {
    if (plantPhotoTasks.isEmpty) return 0;
    final completed = plantPhotoTasks.where((t) => t.completed).length;
    return completed / plantPhotoTasks.length;
  }

  int get completedTaskCount => plantPhotoTasks.where((t) => t.completed).length;
  int get totalTaskCount => plantPhotoTasks.length;

  String get daysRemaining {
    final now = DateTime.now();
    final diff = weekEnd.difference(now);
    if (diff.isNegative) return 'Week ended';
    if (diff.inDays == 0) return 'Less than a day';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
  }
}

class PlantPhotoTask {
  final String plantId;
  final String plantNickname;
  final String plantEmoji;
  final bool completed;
  final DateTime? completedAt;
  final int points;

  PlantPhotoTask({
    required this.plantId,
    required this.plantNickname,
    required this.plantEmoji,
    required this.completed,
    this.completedAt,
    this.points = 500,
  });

  factory PlantPhotoTask.fromJson(Map<String, dynamic> json) {
    return PlantPhotoTask(
      plantId: json['plantId'] ?? '',
      plantNickname: json['plantNickname'] ?? 'Unknown',
      plantEmoji: json['plantEmoji'] ?? '🪴',
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      points: json['points'] ?? 500,
    );
  }
}

class UserPoints {
  final String odIn;
  final int totalPoints;
  final int weeklyPoints;
  final int allTimePoints;
  final List<PointsHistoryEntry> recentHistory;

  UserPoints({
    required this.odIn,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.allTimePoints,
    this.recentHistory = const [],
  });

  factory UserPoints.fromJson(Map<String, dynamic> json) {
    return UserPoints(
      odIn: json['userId'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      weeklyPoints: json['weeklyPoints'] ?? 0,
      allTimePoints: json['allTimePoints'] ?? 0,
      recentHistory: (json['recentHistory'] as List?)
              ?.map((e) => PointsHistoryEntry.fromJson(e))
              .toList() ??
          [],
    );
  }

  String get formattedPoints {
    if (totalPoints >= 1000000) {
      return '${(totalPoints / 1000000).toStringAsFixed(1)}M';
    } else if (totalPoints >= 1000) {
      return '${(totalPoints / 1000).toStringAsFixed(1)}K';
    }
    return '$totalPoints';
  }
}

class PointsHistoryEntry {
  final String reason;
  final int points;
  final DateTime earnedAt;
  final String? plantId;

  PointsHistoryEntry({
    required this.reason,
    required this.points,
    required this.earnedAt,
    this.plantId,
  });

  factory PointsHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PointsHistoryEntry(
      reason: json['reason'] ?? '',
      points: json['points'] ?? 0,
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'])
          : DateTime.now(),
      plantId: json['plantId'],
    );
  }
}