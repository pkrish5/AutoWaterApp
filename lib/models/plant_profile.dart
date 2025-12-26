class PlantProfile {
  final String species;
  final String commonName;
  final CareProfile? careProfile;

  PlantProfile({
    required this.species,
    required this.commonName,
    this.careProfile,
  });

  factory PlantProfile.fromJson(Map<String, dynamic> json) {
    return PlantProfile(
      species: json['species'] ?? '',
      commonName: json['commonName'] ?? json['species'] ?? '',
      careProfile: json['careProfile'] != null 
          ? CareProfile.fromJson(json['careProfile']) 
          : null,
    );
  }

  // Display name for dropdown
  String get displayName => commonName.isNotEmpty ? commonName : species;
}

class CareProfile {
  final WateringProfile watering;
  final LightProfile light;
  final SoilProfile soil;
  final EnvironmentProfile environment;
  final GrowthProfile growth;

  CareProfile({
    required this.watering,
    required this.light,
    required this.soil,
    required this.environment,
    required this.growth,
  });

  factory CareProfile.fromJson(Map<String, dynamic> json) {
    return CareProfile(
      watering: WateringProfile.fromJson(json['watering'] ?? {}),
      light: LightProfile.fromJson(json['light'] ?? {}),
      soil: SoilProfile.fromJson(json['soil'] ?? {}),
      environment: EnvironmentProfile.fromJson(json['environment'] ?? {}),
      growth: GrowthProfile.fromJson(json['growth'] ?? {}),
    );
  }
}

class WateringProfile {
  final int frequencyDays;
  final int amountML;
  final int moistureMin;
  final int moistureMax;

  WateringProfile({
    required this.frequencyDays,
    required this.amountML,
    required this.moistureMin,
    required this.moistureMax,
  });

  factory WateringProfile.fromJson(Map<String, dynamic> json) {
    final threshold = json['moistureThreshold'] ?? {};
    return WateringProfile(
      frequencyDays: json['frequencyDays'] ?? 7,
      amountML: json['amountML'] ?? 200,
      moistureMin: threshold['min'] ?? 30,
      moistureMax: threshold['max'] ?? 70,
    );
  }
}

class LightProfile {
  final String type;
  final int hoursDaily;
  final int minLux;

  LightProfile({
    required this.type,
    required this.hoursDaily,
    required this.minLux,
  });

  factory LightProfile.fromJson(Map<String, dynamic> json) {
    return LightProfile(
      type: json['type'] ?? 'partial-sun',
      hoursDaily: json['hoursDaily'] ?? 6,
      minLux: json['minLux'] ?? 10000,
    );
  }
}

class SoilProfile {
  final String type;
  final double phMin;
  final double phMax;

  SoilProfile({
    required this.type,
    required this.phMin,
    required this.phMax,
  });

  factory SoilProfile.fromJson(Map<String, dynamic> json) {
    final phRange = json['phRange'] as List<dynamic>? ?? [6.0, 7.0];
    return SoilProfile(
      type: json['type'] ?? 'Well-draining',
      phMin: (phRange[0] as num).toDouble(),
      phMax: (phRange[1] as num).toDouble(),
    );
  }
}

class EnvironmentProfile {
  final int tempMin;
  final int tempMax;
  final int humidityMin;
  final int humidityMax;

  EnvironmentProfile({
    required this.tempMin,
    required this.tempMax,
    required this.humidityMin,
    required this.humidityMax,
  });

  factory EnvironmentProfile.fromJson(Map<String, dynamic> json) {
    final tempRange = json['temperatureRange'] as List<dynamic>? ?? [15, 25];
    final humidityRange = json['humidityRange'] as List<dynamic>? ?? [40, 60];
    return EnvironmentProfile(
      tempMin: (tempRange[0] as num).toInt(),
      tempMax: (tempRange[1] as num).toInt(),
      humidityMin: (humidityRange[0] as num).toInt(),
      humidityMax: (humidityRange[1] as num).toInt(),
    );
  }
}

class GrowthProfile {
  final int avgHeightCm;
  final int maturityDays;

  GrowthProfile({
    required this.avgHeightCm,
    required this.maturityDays,
  });

  factory GrowthProfile.fromJson(Map<String, dynamic> json) {
    return GrowthProfile(
      avgHeightCm: json['avgHeightCm'] ?? 30,
      maturityDays: json['maturityDays'] ?? 60,
    );
  }
}