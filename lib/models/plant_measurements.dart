class PlantMeasurements {
  final double? potHeightInches;
  final double? potWidthInches;
  final double? potVolumeML;
  final double? plantHeightInches;
  final String? measurementMethod;
  final String? measuredAt;

  PlantMeasurements({
    this.potHeightInches,
    this.potWidthInches,
    this.potVolumeML,
    this.plantHeightInches,
    this.measurementMethod,
    this.measuredAt,
  });

  factory PlantMeasurements.fromJson(Map<String, dynamic> json) {
    return PlantMeasurements(
      potHeightInches: (json['potHeightInches'] as num?)?.toDouble(),
      potWidthInches: (json['potWidthInches'] as num?)?.toDouble(),
      potVolumeML: (json['potVolumeML'] as num?)?.toDouble(),
      plantHeightInches: (json['plantHeightInches'] as num?)?.toDouble(),
      measurementMethod: json['measurementMethod'],
      measuredAt: json['measuredAt'],
    );
  }

    bool get hasMeasurements =>
        plantHeightInches != null ||
        potWidthInches != null ||
        potHeightInches != null ||
        potVolumeML != null;

  String get potSizeFormatted {
    if (potHeightInches == null || potWidthInches == null) return 'Not measured';
    return '${potHeightInches!.toStringAsFixed(1)}" × ${potWidthInches!.toStringAsFixed(1)}"';
  }

  String get volumeFormatted {
    if (potVolumeML == null) return '--';
    if (potVolumeML! >= 1000) {
      return '${(potVolumeML! / 1000).toStringAsFixed(1)}L';
    }
    return '${potVolumeML!.round()}mL';
  }

  String get plantHeightFormatted {
    if (plantHeightInches == null) return '--';
    return '${plantHeightInches!.toStringAsFixed(1)}"';
  }
}