import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/plant.dart';

class ApiService {
  final String authToken;

  ApiService(this.authToken);

  Map<String, String> get _headers => {
    'Authorization': authToken,
    'Content-Type': 'application/json',
  };

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
    required String archetype,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/plants'),
        headers: _headers,
        body: jsonEncode({
          'nickname': nickname,
          'archetype': archetype,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Plant.fromJson(data);
      } else {
        throw Exception("Failed to add plant: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to add plant: $e");
    }
  }
}
