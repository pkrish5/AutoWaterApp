class PlantImage {
  final String imageId; // This is capturedAt as string
  final String plantId;
  final String userId;
  final String imageUrl;
  final String? thumbnailUrl;
  final String imageType; // health-check, progress, general
  final int uploadedAt;
  final String? notes;
  final PlantImageAnalysis? analysis;

  PlantImage({
    required this.imageId,
    required this.plantId,
    required this.userId,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.imageType,
    required this.uploadedAt,
    this.notes,
    this.analysis,
  });

  factory PlantImage.fromJson(Map<String, dynamic> json) {
    final raw = json['uploadedAt'] ?? json['capturedAt'] ?? 0;

    final timestamp = raw is int && raw < 1000000000000 ? raw * 1000 : raw;

    // Use capturedAt as imageId if imageId not provided
    final imageId = json['imageId'] ?? json['capturedAt']?.toString() ?? '';

    return PlantImage(
      imageId: imageId,
      plantId: json['plantId'] ?? '',
      userId: json['userId'] ?? '',
      imageUrl: json['imageUrl'] ?? json['s3Url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      imageType: json['imageType'] ?? 'general',
      uploadedAt: timestamp,
      notes: json['notes'],
      analysis: json['analysis'] != null
          ? PlantImageAnalysis.fromJson(json['analysis'])
          : null,
    );
  }

  String get uploadedAtFormatted {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(uploadedAt);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';

      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String get dateLabel {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(uploadedAt);
      return '${_monthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class PlantImageAnalysis {
  final String? healthStatus;
  final double? healthScore;
  final List<String>? issues;
  final List<String>? recommendations;
  final String? analyzedAt;
  
  // New fields from API
  final double? confidence;
  final String? trend;
  final String? growthStage;
  final String? overallNotes;
  final double? estimatedHeightCm;
  final double? estimatedMaturityPercent;
  final bool? pestsSigns;
  final LeafCondition? leafCondition;
  final SoilCondition? soilCondition;

  PlantImageAnalysis({
    this.healthStatus,
    this.healthScore,
    this.issues,
    this.recommendations,
    this.analyzedAt,
    this.confidence,
    this.trend,
    this.growthStage,
    this.overallNotes,
    this.estimatedHeightCm,
    this.estimatedMaturityPercent,
    this.pestsSigns,
    this.leafCondition,
    this.soilCondition,
  });

  factory PlantImageAnalysis.fromJson(Map<String, dynamic> json) {
    return PlantImageAnalysis(
      healthStatus: json['healthStatus'],
      healthScore: (json['healthScore'] as num?)?.toDouble(),
      issues: json['issues'] != null ? List<String>.from(json['issues']) : null,
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'])
          : null,
      analyzedAt: json['analyzedAt'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      trend: json['trend'],
      growthStage: json['growthStage'],
      overallNotes: json['overallNotes'],
      estimatedHeightCm: (json['estimatedHeightCm'] as num?)?.toDouble(),
      estimatedMaturityPercent: (json['estimatedMaturityPercent'] as num?)?.toDouble(),
      pestsSigns: json['pestsSigns'],
      leafCondition: json['leafCondition'] != null
          ? LeafCondition.fromJson(json['leafCondition'])
          : null,
      soilCondition: json['soilCondition'] != null
          ? SoilCondition.fromJson(json['soilCondition'])
          : null,
    );
  }
}

class LeafCondition {
  final String? color;
  final String? texture;
  final bool? browning;
  final bool? yellowing;
  final bool? spotting;

  LeafCondition({
    this.color,
    this.texture,
    this.browning,
    this.yellowing,
    this.spotting,
  });

  factory LeafCondition.fromJson(Map<String, dynamic> json) {
    return LeafCondition(
      color: json['color'],
      texture: json['texture'],
      browning: json['browning'],
      yellowing: json['yellowing'],
      spotting: json['spotting'],
    );
  }
}

class SoilCondition {
  final bool? visible;
  final bool? matchesSensor;
  final String? visualAssessment;

  SoilCondition({
    this.visible,
    this.matchesSensor,
    this.visualAssessment,
  });

  factory SoilCondition.fromJson(Map<String, dynamic> json) {
    return SoilCondition(
      visible: json['visible'],
      matchesSensor: json['matchesSensor'],
      visualAssessment: json['visualAssessment'],
    );
  }
}