import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/plant.dart';
import '../models/watering_schedule.dart';
import '../models/water_level.dart';
import '../models/user.dart';
import '../models/plant_image.dart';
import '../models/sensor_data.dart';
import '../models/paginated_images.dart';
import '../models/plant_profile.dart';
class ApiService {
  final String authToken;

  ApiService(this.authToken);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $authToken',
    'Content-Type': 'application/json',
  };

  // ==================== PLANT MANAGEMENT ====================

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

  Future<Plant?> addPlant({
    required String userId,
    required String nickname,
    required String species,
    String? speciesId,
    String? esp32DeviceId,
    Map<String, dynamic>? environment,
    Map<String, dynamic>? speciesInfo,
  }) async {
    try {
      final body = {
        'nickname': nickname,
        'species': species,
        if (speciesId != null) 'speciesId': speciesId,
        if (esp32DeviceId != null && esp32DeviceId.isNotEmpty) 
          'esp32DeviceId': esp32DeviceId,
        if (environment != null) 'environment': environment,
        if (speciesInfo != null) 'speciesInfo': speciesInfo,
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
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? "Failed to add plant: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("$e");
    }
  }

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

  // ==================== DEVICE LINKING ====================

Future<void> linkDevice({
  required String plantId,
  required String userId,
  required String esp32DeviceId,
}) async {
  final response = await http.put(
    Uri.parse('${AppConstants.baseUrl}/plants/$plantId/device'),
    headers: _headers,
    body: jsonEncode({
      'userId': userId,
      'esp32DeviceId': esp32DeviceId,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to link device');
  }
}

  Future<bool> unlinkDevice({
    required String plantId,
    required String userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/device?userId=$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? "Failed to unlink device");
      }
    } catch (e) {
      throw Exception("$e");
    }
  }

  // ==================== SENSOR DATA ====================

  Future<SensorData?> getLatestSensorData(
    String plantId,
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.baseUrl}/plants/$plantId/sensor/latest?userId=$userId'
      ),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return SensorData.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception("Failed to get sensor data: ${response.statusCode}");
    }
  }

  Future<SensorHistory> getSensorHistory(String plantId, {int? hours}) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/plants/$plantId/sensor/history')
          .replace(queryParameters: hours != null ? {'hours': hours.toString()} : null);
      
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return SensorHistory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to get sensor history: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }
// Get plant
  Future<Plant> getPlant(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('🌿 getPlant environment in response: ${json['environment']}');
        return Plant.fromJson(json);
      } else {
        throw Exception('Failed to get plant: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ==================== WATER LEVEL ====================

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

  // ==================== USER MANAGEMENT ====================

  Future<User> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to get profile: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  Future<User> updateUserProfile({
    required String userId,
    String? name,
    bool? isPublicProfile,
  }) async {
    try {
      final body = {
        if (name != null) 'name': name,
        if (isPublicProfile != null) 'isPublicProfile': isPublicProfile,
      };

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/profile'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? "Failed to update profile");
      }
    } catch (e) {
      throw Exception("$e");
    }
  }

  Future<bool> updateUserLocation({
    required String userId,
    required UserLocation location,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/location'),
        headers: _headers,
        body: jsonEncode({'location': location.toJson()}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to update location: $e");
    }
  }

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

  Future<void> registerPushToken({
  required String userId,
  required String token,
  required String platform,
}) async {
  await http.post(
    Uri.parse('${AppConstants.baseUrl}/users/$userId/push-token'),
    headers: _headers,
    body: jsonEncode({
      'token': token,
      'platform': platform,
    }),
  );
}
  // ==================== IMAGE MANAGEMENT ====================

  Future<Map<String, dynamic>> uploadPlantImage({
    required String plantId,
    required String userId,
    required String base64Image,
    String imageType = 'health-check',
    String? notes,
  }) async {
    try {
      final body = {
        'imageData': base64Image,
        'userId': userId,
        'imageType': imageType,
        if (notes != null) 'notes': notes,
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
  Future<PaginatedImages> getPlantImages(
  String plantId, {
  String? lastKey,
  int limit = 30,
}) async {
  final uri = Uri.parse(
    '${AppConstants.baseUrl}/plants/$plantId/images',
  ).replace(queryParameters: {
    'limit': limit.toString(),
    if (lastKey != null) 'lastKey': lastKey,
  });

  final response = await http.get(uri, headers: _headers);

  if (response.statusCode != 200) {
    throw Exception('Failed to load images');
  }

  final decoded = jsonDecode(response.body);

  return PaginatedImages(
    items: (decoded['items'] as List)
        .map((e) => PlantImage.fromJson(e))
        .toList(),
    nextKey: decoded['nextKey'],
  );
}



  Future<bool> deletePlantImage(String plantId, String imageId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/plants/$plantId/images/$imageId'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to delete image: $e");
    }
  }

  // ==================== FRIENDS & SOCIAL ====================

  Future<List<Friend>> getFriends(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/friends'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Friend.fromJson(json)).toList();
      } else {
        throw Exception("Failed to get friends: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  Future<List<FriendRequest>> getFriendRequests(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/friend-requests'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => FriendRequest.fromJson(json)).toList();
      } else {
        throw Exception("Failed to get friend requests: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }
  Future<bool> sendFriendRequest({
    required String userId,
    required String friendUsername,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/friend-requests'),
        headers: _headers,
        body: jsonEncode({'friendUsername': friendUsername}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? "Failed to send request");
      }
    } catch (e) {
      throw Exception("$e");
    }
  }
    Future<void> updatePlant({
    required String plantId,
    String? nickname,
    String? species,
    Map<String, dynamic>? environment,
    Map<String, dynamic>? location,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (species != null) body['species'] = species;
    if (environment != null) body['environment'] = environment;
    if (location != null) body['location'] = location;

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/plants/$plantId'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update plant: ${response.body}');
    }
  }


  Future<bool> respondToFriendRequest({
  required String userId,
  required String requestId,
  required bool accept,
}) async {
  try {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/users/$userId/friend-requests/$requestId'),
      headers: _headers,
      body: jsonEncode({'accept': accept}),
    );

    return response.statusCode == 200;
  } catch (e) {
    throw Exception("Failed to respond to request: $e");
  }
}

  Future<bool> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/friends/$friendId'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to remove friend: $e");
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard(String userId, {String scope = 'friends'}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/leaderboard?userId=$userId&scope=$scope'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => LeaderboardEntry.fromJson(json, currentUserId: userId)).toList();
      } else {
        throw Exception("Failed to get leaderboard: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  // Get friend's plants (if they have shared access)
  Future<List<Plant>> getFriendPlants(String userId, String friendId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/friends/$friendId/plants'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Plant.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        throw Exception("This user's garden is private");
      } else {
        throw Exception("Failed to get friend's plants: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("$e");
    }
  }

Future<PaginatedImages> getPlantImagesPaginated(
  String plantId, {
  String? lastKey,
  int limit = 30,
}) async {
  final queryParams = <String, String>{
    'limit': limit.toString(),
  };

  if (lastKey != null) {
    queryParams['lastKey'] = lastKey;
  }

  final uri = Uri.parse(
    '${AppConstants.baseUrl}/plants/$plantId/images',
  ).replace(queryParameters: queryParams);

  final response = await http.get(
    uri,
    headers: _headers,
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load plant images');
  }

  final decoded = jsonDecode(response.body);

  final items = (decoded['items'] as List)
      .map((e) => PlantImage.fromJson(e))
      .toList();

  return PaginatedImages(
    items: items,
    nextKey: decoded['nextKey'],
  );
}

  // ==================== SPECIES INFO ====================

  Future<List<Map<String, dynamic>>> searchPlantSpecies(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/species/search?q=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception("Failed to search species: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  Future<List<PlantProfile>> getPlantProfiles() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/plant-profiles'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PlantProfile.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch plant profiles');
    }
  }



  Future<PlantProfile> getPlantProfile(String species) async {
    final encodedSpecies = Uri.encodeComponent(species);
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/plant-profiles/$encodedSpecies'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return PlantProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch plant profile');
    }
  }
}