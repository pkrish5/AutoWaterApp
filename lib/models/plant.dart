class Plant {
  final String plantId;
  final String odIn;
  final String nickname;
  final String species;
  final String? esp32DeviceId;
  final double waterPercentage;
  final int streak;
  final PlantHealth? currentHealth;
  final PlantEnvironment? environment;
  final int? addedAt;

  Plant({
    required this.plantId,
    required this.odIn,
    required this.nickname,
    required this.species,
    this.esp32DeviceId,
    required this.waterPercentage,
    required this.streak,
    this.currentHealth,
    this.environment,
    this.addedAt,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      plantId: json['plantId'] ?? '',
      odIn: json['userId'] ?? '',
      nickname: json['nickname'] ?? 'Unnamed Plant',
      species: json['species'] ?? json['archetype'] ?? 'Unknown',
      esp32DeviceId: json['esp32DeviceId'],
      waterPercentage: _parseWaterPercentage(json),
      streak: json['streak'] ?? 0,
      currentHealth: json['currentHealth'] != null 
          ? PlantHealth.fromJson(json['currentHealth']) 
          : null,
      environment: json['environment'] != null
          ? PlantEnvironment.fromJson(json['environment'])
          : null,
      addedAt: json['addedAt'],
    );
  }

  static double _parseWaterPercentage(Map<String, dynamic> json) {
    // Try multiple sources for water percentage
    if (json['waterPercentage'] != null) {
      return (json['waterPercentage'] as num).toDouble();
    }
    if (json['currentHealth'] != null && json['currentHealth']['moisture'] != null) {
      return (json['currentHealth']['moisture'] as num).toDouble();
    }
    return 0.0;
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

  // Check if device is linked
  bool get hasDevice => esp32DeviceId != null && esp32DeviceId!.isNotEmpty;

  // Get archetype for backwards compatibility
  String get archetype => species;
}

class PlantHealth {
  final double? moisture;
  final double? light;
  final double? temperature;
  final double? humidity;
  final double? ph;
  final int? lastUpdate;

  PlantHealth({
    this.moisture,
    this.light,
    this.temperature,
    this.humidity,
    this.ph,
    this.lastUpdate,
  });

  factory PlantHealth.fromJson(Map<String, dynamic> json) {
    return PlantHealth(
      moisture: (json['moisture'] as num?)?.toDouble(),
      light: (json['light'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      ph: (json['ph'] as num?)?.toDouble(),
      lastUpdate: json['lastUpdate'],
    );
  }
}

class PlantEnvironment {
  final String? type;
  final PlantLocation? location;

  PlantEnvironment({this.type, this.location});

  factory PlantEnvironment.fromJson(Map<String, dynamic> json) {
    return PlantEnvironment(
      type: json['type'],
      location: json['location'] != null 
          ? PlantLocation.fromJson(json['location']) 
          : null,
    );
  }
}

class PlantLocation {
  final String? room;
  final String? windowProximity;
  final String? sunExposure;
  final PlantPosition? position;

  PlantLocation({
    this.room,
    this.windowProximity,
    this.sunExposure,
    this.position,
  });

  factory PlantLocation.fromJson(Map<String, dynamic> json) {
    return PlantLocation(
      room: json['room'],
      windowProximity: json['windowProximity'],
      sunExposure: json['sunExposure'],
      position: json['position'] != null 
          ? PlantPosition.fromJson(json['position']) 
          : null,
    );
  }
}

class PlantPosition {
  final double x;
  final double y;
  final double rotation;

  PlantPosition({
    required this.x,
    required this.y,
    this.rotation = 0,
  });

  factory PlantPosition.fromJson(Map<String, dynamic> json) {
    return PlantPosition(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }
}
