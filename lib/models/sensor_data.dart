class SensorData {
  final String plantId;
  final String deviceId;
  final double? moisture;
  final double? temperature;
  final double? humidity;
  final double? light;
  final double? ph;
  final int timestamp;
  final String? source;

  SensorData({
    required this.plantId,
    required this.deviceId,
    this.moisture,
    this.temperature,
    this.humidity,
    this.light,
    this.ph,
    required this.timestamp,
    this.source,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      plantId: json['plantId'] ?? '',
      deviceId: json['deviceId'] ?? json['esp32DeviceId'] ?? '',
      moisture: (json['moisture'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      light: (json['light'] as num?)?.toDouble(),
      ph: (json['ph'] as num?)?.toDouble(),
      timestamp: (() {
        final raw = json['timestamp'];
        if (raw == null) return 0;
        return raw < 1000000000000 ? raw * 1000 : raw;
      })(),
      source: json['source'],
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  String get lastUpdateFormatted {
    try {
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String get timeFormatted {
    try {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  // Determine if plant needs watering based on moisture level
  bool get needsWater => (moisture ?? 100) < 30;
  
  // Get moisture status color indicator
  MoistureStatus get moistureStatus {
    final m = moisture ?? 0;
    if (m >= 70) return MoistureStatus.optimal;
    if (m >= 40) return MoistureStatus.good;
    if (m >= 20) return MoistureStatus.low;
    return MoistureStatus.critical;
  }
}

enum MoistureStatus {
  optimal,
  good,
  low,
  critical,
}

extension MoistureStatusExtension on MoistureStatus {
  String get label {
    switch (this) {
      case MoistureStatus.optimal:
        return 'Optimal';
      case MoistureStatus.good:
        return 'Good';
      case MoistureStatus.low:
        return 'Low';
      case MoistureStatus.critical:
        return 'Water Now!';
    }
  }
}

class SensorHistory {
  final String plantId;
  final List<SensorData> readings;
  final int startTime;
  final int endTime;

  SensorHistory({
    required this.plantId,
    required this.readings,
    required this.startTime,
    required this.endTime,
  });

  factory SensorHistory.fromJson(Map<String, dynamic> json) {
    return SensorHistory(
      plantId: json['plantId'] ?? '',
      readings: (json['readings'] as List<dynamic>?)
          ?.map((r) => SensorData.fromJson(r))
          .toList() ?? [],
      startTime: json['startTime'] ?? 0,
      endTime: json['endTime'] ?? 0,
    );
  }

  SensorData? get latest => readings.isNotEmpty ? readings.first : null;
  
  double? get averageMoisture {
    final moistureReadings = readings
        .where((r) => r.moisture != null)
        .map((r) => r.moisture!)
        .toList();
    if (moistureReadings.isEmpty) return null;
    return moistureReadings.reduce((a, b) => a + b) / moistureReadings.length;
  }
}