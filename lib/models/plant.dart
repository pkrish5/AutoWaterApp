class Plant {
  final String plantId;
  final String userId;
  final String nickname;
  final String species;
  final String? esp32DeviceId;
  final double waterPercentage;
  final int streak;
  final PlantHealth? currentHealth;
  final PlantEnvironment? environment;
  final int? addedAt;
  final PlantSpeciesInfo? speciesInfo;

  Plant({
    required this.plantId,
    required this.userId,
    required this.nickname,
    required this.species,
    this.esp32DeviceId,
    required this.waterPercentage,
    required this.streak,
    this.currentHealth,
    this.environment,
    this.addedAt,
    this.speciesInfo,
  });
  static int? _parseEpoch(dynamic v) {
  if (v == null) return null;
  final n = (v as num).toInt();
  // if it's seconds, convert to ms
  return n < 10_000_000_000 ? n * 1000 : n;
}

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      plantId: json['plantId'] ?? '',
      userId: json['userId'] ?? '',
      nickname: json['nickname'] ?? 'Unnamed Plant',
      species: json['species'] ?? json['archetype'] ?? 'Unknown',
      esp32DeviceId: json['esp32DeviceId'],
      waterPercentage: _parseWaterPercentage(json),
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      currentHealth: json['currentHealth'] != null 
          ? PlantHealth.fromJson(json['currentHealth']) 
          : null,
      environment: json['environment'] != null
          ? PlantEnvironment.fromJson(json['environment'])
          : null,
      addedAt: _parseEpoch(json['addedAt']),
      speciesInfo: json['speciesInfo'] != null
          ? PlantSpeciesInfo.fromJson(json['speciesInfo'])
          : null,
    );
  }

  static double _parseWaterPercentage(Map<String, dynamic> json) {
    if (json['waterPercentage'] != null) {
      return (json['waterPercentage'] as num).toDouble();
    }
    if (json['currentHealth'] != null && json['currentHealth']['moisture'] != null) {
      return (json['currentHealth']['moisture'] as num).toDouble();
    }
    return 0.0;
  }

  double get waterLevel => (waterPercentage / 100).clamp(0.0, 1.0);

  String get waterStatus {
    if (waterPercentage >= 70) return 'Thriving';
    if (waterPercentage >= 40) return 'Happy';
    if (waterPercentage >= 20) return 'Thirsty';
    return 'Critical';
  }

  bool get hasDevice => esp32DeviceId != null && esp32DeviceId!.isNotEmpty;

  String get archetype => species;
  
  /// Get the emoji for this plant from speciesInfo or derive from species name
  String get emoji {
    // If emoji is stored in speciesInfo, use it
    if (speciesInfo?.emoji != null && speciesInfo!.emoji!.isNotEmpty) {
      return speciesInfo!.emoji!;
    }
    // Otherwise derive from species name
    return _getEmojiFromSpecies(species);
  }
  
  static String _getEmojiFromSpecies(String species) {
    final s = species.toLowerCase();
    if (s.contains('pothos') || s.contains('philodendron') || s.contains('vine')) return '🌿';
    if (s.contains('snake') || s.contains('sansevieria')) return '🌵';
    if (s.contains('monstera')) return '🌴';
    if (s.contains('peace lily') || s.contains('spathiphyllum')) return '🌸';
    if (s.contains('fiddle') || s.contains('ficus')) return '🌳';
    if (s.contains('spider')) return '🌿';
    if (s.contains('aloe')) return '🌵';
    if (s.contains('cactus') || s.contains('succulent')) return '🌵';
    if (s.contains('fern')) return '🌿';
    if (s.contains('palm') || s.contains('dracaena')) return '🌴';
    if (s.contains('rubber')) return '🌳';
    if (s.contains('jade') || s.contains('zz')) return '🌿';
    if (s.contains('calathea') || s.contains('prayer')) return '🌴';
    if (s.contains('orchid')) return '🌸';
    if (s.contains('rose')) return '🌹';
    if (s.contains('tomato')) return '🍅';
    if (s.contains('pepper')) return '🌶️';
    if (s.contains('herb') || s.contains('basil') || s.contains('mint')) return '🌱';
    if (s.contains('tropical')) return '🌴';
    if (s.contains('spiky')) return '🌵';
    return '🪴';
  }
  
  // Get watering recommendation for plants without devices
  WateringRecommendation get wateringRecommendation {
    if (speciesInfo != null) {
      return WateringRecommendation.fromSpeciesInfo(speciesInfo!);
    }
    // Default recommendation based on archetype
    switch (species.toLowerCase()) {
      case 'cactus':
      case 'succulent':
      case 'spiky':
        return WateringRecommendation(
          frequencyDays: 14,
          amountML: 50,
          description: 'Water sparingly every 2 weeks',
        );
      case 'fern':
      case 'tropical':
        return WateringRecommendation(
          frequencyDays: 3,
          amountML: 150,
          description: 'Keep soil consistently moist',
        );
      default:
        return WateringRecommendation(
          frequencyDays: 7,
          amountML: 100,
          description: 'Water weekly when soil is dry',
        );
    }
  }
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
      lastUpdate: json['lastUpdate'] ?? json['timestamp'],
    );
  }
  
  String get lastUpdateFormatted {
    if (lastUpdate == null) return 'Never';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(lastUpdate!);
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
  static const Map<String, String> _roomEmojis = {
    'Living Room': '🛋️',
    'Kitchen': '🍳',
    'Bedroom': '🛏️',
    'Bathroom': '🚿',
    'Office': '💻',
    'Balcony': '🌅',
    'Patio': '☀️',
    'Back Garden': '🌳',
    'Front Yard': '🏡',
    'Greenhouse': '🌱',
  };

  String get displayName {
    if (room == null || room!.trim().isEmpty) {
      return '📍 Location not set';
    }

    final emoji = _roomEmojis[room!] ?? '📍';

    final parts = <String>[
      '$emoji $room',
    ];

    if (windowProximity != null && windowProximity!.trim().isNotEmpty) {
      parts.add(windowProximity!);
    }

    return parts.join(' • ');
  }


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

class PlantSpeciesInfo {
  final String commonName;
  final String scientificName;
  final String? description;
  final String? careLevel;
  final int? waterFrequencyDays;
  final int? waterAmountML;
  final String? lightRequirement;
  final String? temperatureRange;
  final String? humidityPreference;
  final List<String>? tips;
  final String? emoji; // Added emoji field

  PlantSpeciesInfo({
    required this.commonName,
    required this.scientificName,
    this.description,
    this.careLevel,
    this.waterFrequencyDays,
    this.waterAmountML,
    this.lightRequirement,
    this.temperatureRange,
    this.humidityPreference,
    this.tips,
    this.emoji,
  });

  factory PlantSpeciesInfo.fromJson(Map<String, dynamic> json) {
    return PlantSpeciesInfo(
      commonName: json['commonName'] ?? '',
      scientificName: json['scientificName'] ?? '',
      description: json['description'],
      careLevel: json['careLevel'],
      waterFrequencyDays: json['waterFrequencyDays'],
      waterAmountML: json['waterAmountML'],
      lightRequirement: json['lightRequirement'],
      temperatureRange: json['temperatureRange'],
      humidityPreference: json['humidityPreference'],
      tips: json['tips'] != null ? List<String>.from(json['tips']) : null,
      emoji: json['emoji'],
    );
  }
}

class WateringRecommendation {
  final int frequencyDays;
  final int amountML;
  final String description;

  WateringRecommendation({
    required this.frequencyDays,
    required this.amountML,
    required this.description,
  });

  factory WateringRecommendation.fromSpeciesInfo(PlantSpeciesInfo info) {
    return WateringRecommendation(
      frequencyDays: info.waterFrequencyDays ?? 7,
      amountML: info.waterAmountML ?? 100,
      description: 'Based on ${info.commonName} care requirements',
    );
  }
}