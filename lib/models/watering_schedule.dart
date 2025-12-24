class WateringSchedule {
  final String plantId;
  final bool enabled;
  final int amountML;
  final int moistureThreshold;
  final RecurringSchedule? recurringSchedule;
  final String? lastWatered;
  final String? lastUpdated;
  final String? timezone;
  final int? scheduleVersion;

  WateringSchedule({
    required this.plantId,
    required this.enabled,
    required this.amountML,
    required this.moistureThreshold,
    this.recurringSchedule,
    this.lastWatered,
    this.lastUpdated,
    this.timezone,
    this.scheduleVersion,
  });

  factory WateringSchedule.fromJson(Map<String, dynamic> json) {
    return WateringSchedule(
      plantId: json['plantId'] ?? '',
      enabled: json['enabled'] ?? false,
      amountML: json['amountML'] ?? 100,
      moistureThreshold: json['moistureThreshold'] ?? 30,
      recurringSchedule: json['recurringSchedule'] != null
          ? RecurringSchedule.fromJson(json['recurringSchedule'])
          : null,
      lastWatered: json['lastWatered'],
      lastUpdated: json['lastUpdated'],
      timezone: json['timezone'],
      scheduleVersion: json['scheduleVersion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'amountML': amountML,
      'moistureThreshold': moistureThreshold,
      if (recurringSchedule != null) 'recurringSchedule': recurringSchedule!.toJson(),
      if (timezone != null) 'timezone': timezone,
    };
  }
}

class RecurringSchedule {
  final List<int> daysOfWeek; // 0=Sunday, 1=Monday, etc.
  final String timeOfDay; // "HH:MM" format

  RecurringSchedule({
    required this.daysOfWeek,
    required this.timeOfDay,
  });

  factory RecurringSchedule.fromJson(Map<String, dynamic> json) {
    return RecurringSchedule(
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      timeOfDay: json['timeOfDay'] ?? '08:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daysOfWeek': daysOfWeek,
      'timeOfDay': timeOfDay,
    };
  }

  String get formattedDays {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (daysOfWeek.isEmpty) return 'No days selected';
    if (daysOfWeek.length == 7) return 'Every day';
    return daysOfWeek.map((d) => dayNames[d]).join(', ');
  }
}
