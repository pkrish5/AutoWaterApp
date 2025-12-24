class WaterLevel {
  final String plantId;
  final String? nickname;
  final int currentWaterLevel;
  final int containerSize;
  final double waterPercentage;
  final int flowRate;
  final String? lastRefilled;
  final bool needsRefill;
  final String? esp32DeviceId;

  WaterLevel({
    required this.plantId,
    this.nickname,
    required this.currentWaterLevel,
    required this.containerSize,
    required this.waterPercentage,
    required this.flowRate,
    this.lastRefilled,
    required this.needsRefill,
    this.esp32DeviceId,
  });

  factory WaterLevel.fromJson(Map<String, dynamic> json) {
    return WaterLevel(
      plantId: json['plantId'] ?? '',
      nickname: json['nickname'],
      currentWaterLevel: (json['currentWaterLevel'] as num?)?.toInt() ?? 0,
      containerSize: (json['containerSize'] as num?)?.toInt() ?? 500,
      waterPercentage: (json['waterPercentage'] as num?)?.toDouble() ?? 0.0,
      flowRate: (json['flowRate'] as num?)?.toInt() ?? 20,
      lastRefilled: json['lastRefilled'],
      needsRefill: json['needsRefill'] ?? false,
      esp32DeviceId: json['esp32DeviceId'],
    );
  }

  String get statusText {
    if (needsRefill) return 'Needs Refill!';
    if (waterPercentage >= 70) return 'Good';
    if (waterPercentage >= 40) return 'OK';
    if (waterPercentage >= 20) return 'Low';
    return 'Critical';
  }

  String get lastRefilledFormatted {
    if (lastRefilled == null) return 'Never';
    try {
      final date = DateTime.parse(lastRefilled!);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Unknown';
    }
  }
}
