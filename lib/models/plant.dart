class Plant {
  final String plantId;
  final String nickname;
  final String archetype;
  final double waterPercentage;
  final int streak;

  Plant({
    required this.plantId,
    required this.nickname,
    required this.archetype,
    required this.waterPercentage,
    required this.streak,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      plantId: json['plantId'] ?? '',
      nickname: json['nickname'] ?? 'Unnamed Twin',
      archetype: json['archetype'] ?? 'Bushy',
      waterPercentage: (json['waterPercentage'] ?? 0.0).toDouble(),
      streak: json['streak'] ?? 0,
    );
  }

  // Helper to get normalized level (0.0 - 1.0) for gauge
  double get waterLevel => (waterPercentage / 100).clamp(0.0, 1.0);
  
  // Get status text based on water level
  String get waterStatus {
    if (waterPercentage >= 70) return 'Thriving';
    if (waterPercentage >= 40) return 'Happy';
    if (waterPercentage >= 20) return 'Thirsty';
    return 'Critical';
  }
}
