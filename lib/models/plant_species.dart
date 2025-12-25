class PlantSpecies {
  final String id;
  final String commonName;
  final String scientificName;
  final String category;
  final String emoji;
  final String? imageUrl;
  final String careLevel;
  final PlantCareInfo careInfo;

  PlantSpecies({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.emoji,
    this.imageUrl,
    required this.careLevel,
    required this.careInfo,
  });

  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    return PlantSpecies(
      id: json['id'] ?? '',
      commonName: json['commonName'] ?? '',
      scientificName: json['scientificName'] ?? '',
      category: json['category'] ?? 'Other',
      emoji: json['emoji'] ?? '🪴',
      imageUrl: json['imageUrl'],
      careLevel: json['careLevel'] ?? 'Medium',
      careInfo: json['careInfo'] != null
          ? PlantCareInfo.fromJson(json['careInfo'])
          : PlantCareInfo.defaultCare(),
    );
  }

  // Predefined common plant species
  static List<PlantSpecies> get commonSpecies => [
    PlantSpecies(
      id: 'pothos',
      commonName: 'Pothos',
      scientificName: 'Epipremnum aureum',
      category: 'Vine',
      emoji: '🌿',
      careLevel: 'Easy',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 7,
        waterAmountML: 100,
        lightRequirement: 'Low to bright indirect',
        temperatureRange: '15-30°C',
        humidityPreference: 'Medium',
        description: 'Hardy trailing plant perfect for beginners',
        tips: ['Allow soil to dry between waterings', 'Tolerates low light'],
      ),
    ),
    PlantSpecies(
      id: 'snake_plant',
      commonName: 'Snake Plant',
      scientificName: 'Sansevieria trifasciata',
      category: 'Succulent',
      emoji: '🌵',
      careLevel: 'Easy',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 14,
        waterAmountML: 75,
        lightRequirement: 'Low to bright indirect',
        temperatureRange: '15-27°C',
        humidityPreference: 'Low',
        description: 'Nearly indestructible air-purifying plant',
        tips: ['Drought tolerant', 'Prone to root rot if overwatered'],
      ),
    ),
    PlantSpecies(
      id: 'monstera',
      commonName: 'Monstera',
      scientificName: 'Monstera deliciosa',
      category: 'Tropical',
      emoji: '🌴',
      careLevel: 'Medium',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 7,
        waterAmountML: 150,
        lightRequirement: 'Bright indirect',
        temperatureRange: '18-30°C',
        humidityPreference: 'High',
        description: 'Iconic tropical plant with split leaves',
        tips: ['Mist leaves regularly', 'Provide support for climbing'],
      ),
    ),
    PlantSpecies(
      id: 'peace_lily',
      commonName: 'Peace Lily',
      scientificName: 'Spathiphyllum',
      category: 'Flowering',
      emoji: '🌸',
      careLevel: 'Easy',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 5,
        waterAmountML: 125,
        lightRequirement: 'Low to medium indirect',
        temperatureRange: '18-26°C',
        humidityPreference: 'High',
        description: 'Elegant flowering plant that purifies air',
        tips: ['Droops when thirsty', 'Keep away from direct sun'],
      ),
    ),
    PlantSpecies(
      id: 'fiddle_leaf_fig',
      commonName: 'Fiddle Leaf Fig',
      scientificName: 'Ficus lyrata',
      category: 'Tree',
      emoji: '🌳',
      careLevel: 'Hard',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 10,
        waterAmountML: 200,
        lightRequirement: 'Bright indirect',
        temperatureRange: '16-24°C',
        humidityPreference: 'Medium',
        description: 'Statement plant with large violin-shaped leaves',
        tips: ['Sensitive to changes', 'Rotate for even growth'],
      ),
    ),
    PlantSpecies(
      id: 'spider_plant',
      commonName: 'Spider Plant',
      scientificName: 'Chlorophytum comosum',
      category: 'Hanging',
      emoji: '🌿',
      careLevel: 'Easy',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 7,
        waterAmountML: 100,
        lightRequirement: 'Indirect light',
        temperatureRange: '13-27°C',
        humidityPreference: 'Medium',
        description: 'Classic houseplant that produces baby plants',
        tips: ['Great for hanging baskets', 'Non-toxic to pets'],
      ),
    ),
    PlantSpecies(
      id: 'aloe_vera',
      commonName: 'Aloe Vera',
      scientificName: 'Aloe barbadensis miller',
      category: 'Succulent',
      emoji: '🌵',
      careLevel: 'Easy',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 21,
        waterAmountML: 50,
        lightRequirement: 'Bright indirect to direct',
        temperatureRange: '13-27°C',
        humidityPreference: 'Low',
        description: 'Medicinal succulent with healing gel',
        tips: ['Let soil dry completely', 'Can tolerate some direct sun'],
      ),
    ),
    PlantSpecies(
      id: 'rubber_plant',
      commonName: 'Rubber Plant',
      scientificName: 'Ficus elastica',
      category: 'Tree',
      emoji: '🌳',
      careLevel: 'Medium',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 10,
        waterAmountML: 150,
        lightRequirement: 'Medium to bright indirect',
        temperatureRange: '15-26°C',
        humidityPreference: 'Medium',
        description: 'Bold plant with glossy dark leaves',
        tips: ['Wipe leaves to keep shiny', 'Water when top inch is dry'],
      ),
    ),
    PlantSpecies(
      id: 'zz_plant',
      commonName: 'ZZ Plant',
      scientificName: 'Zamioculcas zamiifolia',
      category: 'Succulent',
      emoji: '🌿',
      careLevel: 'Easy',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 14,
        waterAmountML: 75,
        lightRequirement: 'Low to bright indirect',
        temperatureRange: '15-26°C',
        humidityPreference: 'Low',
        description: 'Ultra low-maintenance with waxy leaves',
        tips: ['Thrives on neglect', 'Stores water in rhizomes'],
      ),
    ),
    PlantSpecies(
      id: 'boston_fern',
      commonName: 'Boston Fern',
      scientificName: 'Nephrolepis exaltata',
      category: 'Fern',
      emoji: '🌿',
      careLevel: 'Medium',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 3,
        waterAmountML: 150,
        lightRequirement: 'Indirect light',
        temperatureRange: '16-24°C',
        humidityPreference: 'High',
        description: 'Lush fern with arching fronds',
        tips: ['Never let soil dry out', 'Mist daily in dry conditions'],
      ),
    ),
    PlantSpecies(
      id: 'philodendron',
      commonName: 'Philodendron',
      scientificName: 'Philodendron hederaceum',
      category: 'Vine',
      emoji: '🌿',
      careLevel: 'Easy',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 7,
        waterAmountML: 100,
        lightRequirement: 'Medium indirect',
        temperatureRange: '16-27°C',
        humidityPreference: 'Medium',
        description: 'Classic trailing plant with heart-shaped leaves',
        tips: ['Very forgiving', 'Can train to climb or trail'],
      ),
    ),
    PlantSpecies(
      id: 'calathea',
      commonName: 'Calathea',
      scientificName: 'Calathea ornata',
      category: 'Tropical',
      emoji: '🌴',
      careLevel: 'Hard',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 5,
        waterAmountML: 100,
        lightRequirement: 'Medium indirect',
        temperatureRange: '18-26°C',
        humidityPreference: 'High',
        description: 'Prayer plant with stunning striped leaves',
        tips: ['Use filtered water', 'Keep humidity above 50%'],
      ),
    ),
    PlantSpecies(
      id: 'jade_plant',
      commonName: 'Jade Plant',
      scientificName: 'Crassula ovata',
      category: 'Succulent',
      emoji: '🌵',
      careLevel: 'Easy',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 14,
        waterAmountML: 50,
        lightRequirement: 'Bright indirect to direct',
        temperatureRange: '12-24°C',
        humidityPreference: 'Low',
        description: 'Lucky money tree succulent',
        tips: ['Water thoroughly then let dry', 'Can live for decades'],
      ),
    ),
    PlantSpecies(
      id: 'dracaena',
      commonName: 'Dracaena',
      scientificName: 'Dracaena marginata',
      category: 'Tree',
      emoji: '🌴',
      careLevel: 'Easy',
      careInfo: PlantCareInfo(
        waterFrequencyDays: 10,
        waterAmountML: 100,
        lightRequirement: 'Low to bright indirect',
        temperatureRange: '18-27°C',
        humidityPreference: 'Medium',
        description: 'Dramatic dragon tree with spiky leaves',
        tips: ['Sensitive to fluoride', 'Use filtered water'],
      ),
    ),
    PlantSpecies(
      id: 'custom',
      commonName: 'Other Plant',
      scientificName: 'Custom species',
      category: 'Other',
      emoji: '🪴',
      careLevel: 'Medium',
      careInfo: PlantCareInfo.defaultCare(),
    ),
  ];

  static List<String> get categories => [
    'All',
    'Vine',
    'Succulent',
    'Tropical',
    'Flowering',
    'Tree',
    'Hanging',
    'Fern',
    'Other',
  ];
}

class PlantCareInfo {
  final int waterFrequencyDays;
  final int waterAmountML;
  final String lightRequirement;
  final String temperatureRange;
  final String humidityPreference;
  final String? description;
  final List<String>? tips;

  PlantCareInfo({
    required this.waterFrequencyDays,
    required this.waterAmountML,
    required this.lightRequirement,
    required this.temperatureRange,
    required this.humidityPreference,
    this.description,
    this.tips,
  });

  factory PlantCareInfo.fromJson(Map<String, dynamic> json) {
    return PlantCareInfo(
      waterFrequencyDays: json['waterFrequencyDays'] ?? 7,
      waterAmountML: json['waterAmountML'] ?? 100,
      lightRequirement: json['lightRequirement'] ?? 'Indirect light',
      temperatureRange: json['temperatureRange'] ?? '15-25°C',
      humidityPreference: json['humidityPreference'] ?? 'Medium',
      description: json['description'],
      tips: json['tips'] != null ? List<String>.from(json['tips']) : null,
    );
  }

  factory PlantCareInfo.defaultCare() {
    return PlantCareInfo(
      waterFrequencyDays: 7,
      waterAmountML: 100,
      lightRequirement: 'Medium indirect light',
      temperatureRange: '15-25°C',
      humidityPreference: 'Medium',
      description: 'General houseplant care',
      tips: ['Water when top inch of soil is dry'],
    );
  }
}