import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class LocationService {
  // Get location from coordinates using reverse geocoding
  static Future<UserLocation?> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Using OpenStreetMap Nominatim for reverse geocoding (free, no API key)
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&addressdetails=1',
        ),
        headers: {'User-Agent': 'RootwiseApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] ?? {};

        return UserLocation(
          latitude: latitude,
          longitude: longitude,
          city: address['city'] ?? address['town'] ?? address['village'],
          state: address['state'],
          country: address['country'],
          postalCode: address['postcode'],
          timezone: await _getTimezone(latitude, longitude),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return null;
    }
  }

  // Get timezone from coordinates
  static Future<String?> _getTimezone(double latitude, double longitude) async {
    try {
      // Simple timezone estimation based on longitude
      // For production, use a proper timezone API
      final offset = (longitude / 15).round();
      if (offset >= 0) {
        return 'UTC+$offset';
      } else {
        return 'UTC$offset';
      }
    } catch (e) {
      return null;
    }
  }

  // Search for locations by query
  static Future<List<LocationSearchResult>> searchLocations(String query) async {
    if (query.length < 2) return [];

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&addressdetails=1&limit=5',
        ),
        headers: {'User-Agent': 'RootwiseApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => LocationSearchResult.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Location search error: $e');
      return [];
    }
  }

  // Convert search result to UserLocation
  static UserLocation searchResultToLocation(LocationSearchResult result) {
    return UserLocation(
      latitude: result.latitude,
      longitude: result.longitude,
      city: result.city,
      state: result.state,
      country: result.country,
      postalCode: result.postalCode,
    );
  }
}

class LocationSearchResult {
  final double latitude;
  final double longitude;
  final String displayName;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  LocationSearchResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] ?? {};
    return LocationSearchResult(
      latitude: double.parse(json['lat'] ?? '0'),
      longitude: double.parse(json['lon'] ?? '0'),
      displayName: json['display_name'] ?? '',
      city: address['city'] ?? address['town'] ?? address['village'],
      state: address['state'],
      country: address['country'],
      postalCode: address['postcode'],
    );
  }
}