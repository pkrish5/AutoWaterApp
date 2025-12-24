import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/plant.dart';
import '../models/watering_schedule.dart';
import '../models/water_level.dart';

class ApiService {
  final String authToken;

  ApiService(this.authToken);

  Map<String, String> get _headers => {
    'Authorization': authToken,
    'Content-Type': 'application/json',
  };

  // ==================== PLANT MANAGEMENT ====================

  /// Get all plants for a user
  Future<List<Plant>> getPlants(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/plants'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((json) => Plant.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load plants: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  /// Add a new plant
  Future<Plant?> addPlant({
    required String userId,
    required String nickname,
    required String species,
    String? esp32DeviceId,
    Map<String, dynamic>? environment,
  }) async {
    try {
      final body = {
        'nickname': nickname,
        'species': species,
        if (esp32DeviceId != null && esp32DeviceId.isNotEmpty) 
          'esp32DeviceId': esp32DeviceId,
        if (environment != null) 'environment': environment,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/plants'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Plant.fromJson(data);
      } else {
        throw Exception("Failed to add plant: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Failed to add plant: $e");
    }
  }

  /// Get plant details with sensor history
  Future<Map<String, dynamic>> getPlantDetails(String plantId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId?userId=$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get plant details: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  /// Delete a plant
  Future<bool> deletePlant(String plantId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId?userId=$userId'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to delete plant: $e");
    }
  }

  /// Update plant position in room layout
  Future<bool> updatePlantPosition({
    required String plantId,
    required String userId,
    required double x,
    required double y,
    double rotation = 0,
    String? roomName,
  }) async {
    try {
      final body = {
        'userId': userId,
        'position': {
          'x': x,
          'y': y,
          'rotation': rotation,
        },
        if (roomName != null) 'roomName': roomName,
      };

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/position'),
        headers: _headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to update position: $e");
    }
  }

  /// Link an ESP32 device to a plant
  Future<bool> linkDevice({
    required String plantId,
    required String userId,
    required String esp32DeviceId,
  }) async {
    // This would require a new API endpoint or updating the plant
    // For now, we'll update via the position endpoint with device info
    // You may need to add a dedicated endpoint for this
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/device'),
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'esp32DeviceId': esp32DeviceId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to link device: $e");
    }
  }

  // ==================== WATER LEVEL ====================

  /// Get water container level
  Future<WaterLevel> getWaterLevel(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/water-level'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return WaterLevel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to get water level: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  /// Mark water container as refilled
  Future<WaterLevel> refillWater(String plantId, {bool markFull = true, int? refillAmount}) async {
    try {
      final body = {
        'markFull': markFull,
        if (refillAmount != null) 'refillAmount': refillAmount,
      };

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/water-level'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return WaterLevel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to refill water: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  // ==================== WATERING SCHEDULE ====================

  /// Get watering schedule
  Future<WateringSchedule> getWateringSchedule(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/schedule'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return WateringSchedule.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to get schedule: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  /// Update watering schedule
  Future<WateringSchedule> updateWateringSchedule({
    required String plantId,
    required String userId,
    required bool enabled,
    required int amountML,
    int moistureThreshold = 30,
    List<int>? daysOfWeek,
    String? timeOfDay,
    String? timezone,
  }) async {
    try {
      final body = {
        'userId': userId,
        'enabled': enabled,
        'amountML': amountML,
        'moistureThreshold': moistureThreshold,
        if (daysOfWeek != null && timeOfDay != null)
          'recurringSchedule': {
            'daysOfWeek': daysOfWeek,
            'timeOfDay': timeOfDay,
          },
        if (timezone != null) 'timezone': timezone,
      };

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/schedule'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return WateringSchedule.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to update schedule: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  // ==================== MANUAL WATERING ====================

  /// Trigger manual watering
  Future<Map<String, dynamic>> triggerWatering(String plantId, {int? amountML, int? duration}) async {
    try {
      final body = {
        if (amountML != null) 'amountML': amountML,
        if (duration != null) 'duration': duration,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/water'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? "Failed to trigger watering");
      }
    } catch (e) {
      throw Exception("$e");
    }
  }

  // ==================== USER & STREAK ====================

  /// Get user streak info
  Future<Map<String, dynamic>> getUserStreak(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/streak'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get streak: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  /// Update user settings
  Future<bool> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/settings'),
        headers: _headers,
        body: jsonEncode({'settings': settings}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to update settings: $e");
    }
  }

  // ==================== IMAGE UPLOAD ====================

  /// Upload plant health check image
  Future<Map<String, dynamic>> uploadPlantImage({
    required String plantId,
    required String userId,
    required String base64Image,
    String imageType = 'health-check',
  }) async {
    try {
      final body = {
        'imageData': base64Image,
        'userId': userId,
        'imageType': imageType,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/images'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to upload image: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }
}
