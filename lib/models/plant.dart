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
      nickname: json['nickname'] ?? 'Unnamed Digital Twin',
      archetype: json['archetype'] ?? 'Bushy',
      waterPercentage: (json['waterPercentage'] ?? 0.0).toDouble(),
      streak: json['streak'] ?? 0,
    );
  }
}