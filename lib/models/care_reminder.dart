/// Care reminder models for plants without sensors
library;

enum CareType {
  water,
  fertilize,
  rotate,
  repot,
  prune,
  mist,
  refill,  // For sensor water tank refills
  custom,
}

extension CareTypeExtension on CareType {
  String get label {
    switch (this) {
      case CareType.water: return 'Water';
      case CareType.fertilize: return 'Fertilize';
      case CareType.rotate: return 'Rotate';
      case CareType.repot: return 'Repot';
      case CareType.prune: return 'Prune';
      case CareType.mist: return 'Mist';
      case CareType.refill: return 'Refill Tank';
      case CareType.custom: return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case CareType.water: return '💧';
      case CareType.fertilize: return '🧪';
      case CareType.rotate: return '🔄';
      case CareType.repot: return '🪴';
      case CareType.prune: return '✂️';
      case CareType.mist: return '💨';
      case CareType.refill: return '🚰';
      case CareType.custom: return '📝';
    }
  }

  int get defaultFrequencyDays {
    switch (this) {
      case CareType.water: return 7;
      case CareType.fertilize: return 30;
      case CareType.rotate: return 14;
      case CareType.repot: return 365;
      case CareType.prune: return 90;
      case CareType.mist: return 2;
      case CareType.refill: return 14;  // Typical tank refill frequency
      case CareType.custom: return 7;
    }
  }
}

class CareReminder {
  final String id;
  final String plantId;
  final String plantNickname;
  final String plantEmoji;
  final CareType careType;
  final String? customLabel;
  final int frequencyDays;
  final DateTime? lastCompleted;
  final DateTime nextDue;
  final bool enabled;
  final String? notes;
  final int? notificationId;

  CareReminder({
    required this.id,
    required this.plantId,
    required this.plantNickname,
    required this.plantEmoji,
    required this.careType,
    this.customLabel,
    required this.frequencyDays,
    this.lastCompleted,
    required this.nextDue,
    this.enabled = true,
    this.notes,
    this.notificationId,
  });

  factory CareReminder.fromJson(Map<String, dynamic> json) {
    return CareReminder(
      id: json['id'] ?? '',
      plantId: json['plantId'] ?? '',
      plantNickname: json['plantNickname'] ?? '',
      plantEmoji: json['plantEmoji'] ?? '🪴',
      careType: CareType.values.firstWhere(
        (t) => t.name == json['careType'],
        orElse: () => CareType.water,
      ),
      customLabel: json['customLabel'],
      frequencyDays: json['frequencyDays'] ?? 7,
      lastCompleted: json['lastCompleted'] != null
          ? DateTime.parse(json['lastCompleted'])
          : null,
      nextDue: json['nextDue'] != null
          ? DateTime.parse(json['nextDue'])
          : DateTime.now(),
      enabled: json['enabled'] ?? true,
      notes: json['notes'],
      notificationId: json['notificationId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'plantNickname': plantNickname,
      'plantEmoji': plantEmoji,
      'careType': careType.name,
      if (customLabel != null) 'customLabel': customLabel,
      'frequencyDays': frequencyDays,
      if (lastCompleted != null) 'lastCompleted': lastCompleted!.toIso8601String(),
      'nextDue': nextDue.toIso8601String(),
      'enabled': enabled,
      if (notes != null) 'notes': notes,
      if (notificationId != null) 'notificationId': notificationId,
    };
  }

  String get displayLabel => customLabel ?? careType.label;
  String get displayEmoji => careType.emoji;

  bool get isOverdue => DateTime.now().isAfter(nextDue);
  bool get isDueToday {
    final now = DateTime.now();
    return nextDue.year == now.year &&
        nextDue.month == now.month &&
        nextDue.day == now.day;
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDue.year, nextDue.month, nextDue.day);
    return dueDate.difference(today).inDays;
  }

  String get dueLabel {
    final days = daysUntilDue;
    if (days < 0) return '${-days} day${days == -1 ? '' : 's'} overdue';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  String get frequencyLabel {
    if (frequencyDays == 1) return 'Daily';
    if (frequencyDays == 7) return 'Weekly';
    if (frequencyDays == 14) return 'Every 2 weeks';
    if (frequencyDays == 30) return 'Monthly';
    if (frequencyDays == 90) return 'Every 3 months';
    if (frequencyDays == 365) return 'Yearly';
    return 'Every $frequencyDays days';
  }

  CareReminder copyWith({
    String? id,
    String? plantId,
    String? plantNickname,
    String? plantEmoji,
    CareType? careType,
    String? customLabel,
    int? frequencyDays,
    DateTime? lastCompleted,
    DateTime? nextDue,
    bool? enabled,
    String? notes,
    int? notificationId,
  }) {
    return CareReminder(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      plantNickname: plantNickname ?? this.plantNickname,
      plantEmoji: plantEmoji ?? this.plantEmoji,
      careType: careType ?? this.careType,
      customLabel: customLabel ?? this.customLabel,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      nextDue: nextDue ?? this.nextDue,
      enabled: enabled ?? this.enabled,
      notes: notes ?? this.notes,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  /// Create a new reminder after completing the current one
  CareReminder markCompleted() {
    final now = DateTime.now();
    return copyWith(
      lastCompleted: now,
      nextDue: now.add(Duration(days: frequencyDays)),
    );
  }
}

/// Groups reminders by their due status for timeline display
class GroupedReminders {
  final List<CareReminder> overdue;
  final List<CareReminder> today;
  final List<CareReminder> upcoming;

  GroupedReminders({
    required this.overdue,
    required this.today,
    required this.upcoming,
  });

  factory GroupedReminders.fromList(List<CareReminder> reminders) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final overdue = <CareReminder>[];
    final today = <CareReminder>[];
    final upcoming = <CareReminder>[];

    for (final r in reminders) {
      if (!r.enabled) continue;
      
      if (r.nextDue.isBefore(todayStart)) {
        overdue.add(r);
      } else if (r.nextDue.isBefore(todayEnd)) {
        today.add(r);
      } else {
        upcoming.add(r);
      }
    }

    // Sort each group
    overdue.sort((a, b) => a.nextDue.compareTo(b.nextDue));
    today.sort((a, b) => a.nextDue.compareTo(b.nextDue));
    upcoming.sort((a, b) => a.nextDue.compareTo(b.nextDue));

    return GroupedReminders(
      overdue: overdue,
      today: today,
      upcoming: upcoming,
    );
  }

  int get totalCount => overdue.length + today.length + upcoming.length;
  bool get hasOverdue => overdue.isNotEmpty;
  bool get hasTodayTasks => today.isNotEmpty;
}