import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/plant.dart';

class ApiService {
  final String authToken;

  ApiService(this.authToken);

  Future<List<Plant>> getPlants(String userId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/users/$userId/plants'),
      headers: {'Authorization': authToken},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Plant.fromJson(json)).toList();
    } else {
      throw Exception("Failed to sync Digital Twins");
    }
  }
}