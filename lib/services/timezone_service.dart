import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimezoneService {
  static final TimezoneService _instance = TimezoneService._internal();
  factory TimezoneService() => _instance;
  TimezoneService._internal();

  static const _storageKey = 'user_timezone';
  String? _cachedTimezone;

  /// Get the device's current timezone
  /// Returns timezone in IANA format (e.g., "America/Chicago", "Europe/London")
  Future<String?> getDeviceTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      debugPrint('Detected timezone: $timezone');
      return timezone;
    } catch (e) {
      debugPrint('Failed to get timezone: $e');
      return null;
    }
  }

  /// Get the user's saved timezone (from backend/local storage)
  Future<String?> getSavedTimezone() async {
    if (_cachedTimezone != null) return _cachedTimezone;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedTimezone = prefs.getString(_storageKey);
      return _cachedTimezone;
    } catch (e) {
      debugPrint('Failed to get saved timezone: $e');
      return null;
    }
  }

  /// Save timezone locally (call after API success)
  Future<void> saveTimezone(String timezone) async {
    _cachedTimezone = timezone;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, timezone);
    } catch (e) {
      debugPrint('Failed to save timezone: $e');
    }
  }

  /// Clear cached timezone (call on logout)
  Future<void> clearCache() async {
    _cachedTimezone = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Failed to clear timezone cache: $e');
    }
  }

  /// Get list of all available timezones for manual selection
  static List<String> get commonTimezones => [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Anchorage',
    'Pacific/Honolulu',
    'America/Phoenix',
    'America/Toronto',
    'America/Vancouver',
    'America/Mexico_City',
    'America/Sao_Paulo',
    'America/Buenos_Aires',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Rome',
    'Europe/Madrid',
    'Europe/Amsterdam',
    'Europe/Stockholm',
    'Europe/Moscow',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Asia/Bangkok',
    'Asia/Singapore',
    'Asia/Hong_Kong',
    'Asia/Shanghai',
    'Asia/Tokyo',
    'Asia/Seoul',
    'Australia/Sydney',
    'Australia/Melbourne',
    'Australia/Perth',
    'Pacific/Auckland',
    'Pacific/Fiji',
  ];

  /// Timezone offset data (approximate, doesn't account for DST)
  /// For accurate offsets, use the `timezone` package
  static final Map<String, double> _timezoneOffsets = {
    'Pacific/Honolulu': -10,
    'America/Anchorage': -9,
    'America/Los_Angeles': -8,
    'America/Phoenix': -7,
    'America/Denver': -7,
    'America/Chicago': -6,
    'America/Mexico_City': -6,
    'America/New_York': -5,
    'America/Toronto': -5,
    'America/Vancouver': -8,
    'America/Sao_Paulo': -3,
    'America/Buenos_Aires': -3,
    'Europe/London': 0,
    'Europe/Paris': 1,
    'Europe/Berlin': 1,
    'Europe/Rome': 1,
    'Europe/Madrid': 1,
    'Europe/Amsterdam': 1,
    'Europe/Stockholm': 1,
    'Europe/Moscow': 3,
    'Asia/Dubai': 4,
    'Asia/Kolkata': 5.5,
    'Asia/Bangkok': 7,
    'Asia/Singapore': 8,
    'Asia/Hong_Kong': 8,
    'Asia/Shanghai': 8,
    'Asia/Tokyo': 9,
    'Asia/Seoul': 9,
    'Australia/Perth': 8,
    'Australia/Sydney': 10,
    'Australia/Melbourne': 10,
    'Pacific/Auckland': 12,
    'Pacific/Fiji': 12,
  };

  /// Get a user-friendly display name for a timezone
  static String getDisplayName(String timezone) {
    final parts = timezone.split('/');
    if (parts.length == 2) {
      final city = parts[1].replaceAll('_', ' ');
      return '$city (${parts[0]})';
    }
    return timezone;
  }

  /// Get UTC offset string for a specific timezone
  static String getUtcOffset(String timezone) {
    final offset = _timezoneOffsets[timezone];
    if (offset == null) return '';

    final hours = offset.truncate();
    final minutes = ((offset - hours) * 60).abs().toInt();
    final sign = offset >= 0 ? '+' : '';

    if (minutes == 0) {
      return 'UTC$sign$hours';
    }
    return 'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
  }

  /// Get full display string with offset
  static String getFullDisplayName(String timezone) {
    final name = getDisplayName(timezone);
    final offset = getUtcOffset(timezone);
    if (offset.isEmpty) return name;
    return '$name ($offset)';
  }
}