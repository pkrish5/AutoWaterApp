class PlantImage {
  final String imageId;
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
  final raw =
      json['uploadedAt'] ??
      json['capturedAt'] ??
      0;

  final timestamp =
      raw is int && raw < 1000000000000
          ? raw * 1000
          : raw;

  return PlantImage(
    imageId: json['imageId'] ?? '',
    plantId: json['plantId'] ?? '',
    userId: json['userId'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class PlantImageAnalysis {
  final String? healthStatus;
  final double? healthScore;
  final List<String>? issues;
  final List<String>? recommendations;
  final String? analyzedAt;

  PlantImageAnalysis({
    this.healthStatus,
    this.healthScore,
    this.issues,
    this.recommendations,
    this.analyzedAt,
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
    );
  }
}