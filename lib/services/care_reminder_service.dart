import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/care_reminder.dart';
import '../models/plant.dart';
import 'api_service.dart';

/// Service for managing plant care reminders
/// Syncs with DynamoDB backend, with local cache for offline support
class CareReminderService {
  static final CareReminderService _instance = CareReminderService._internal();
  factory CareReminderService() => _instance;
  CareReminderService._internal();

  static const String _cacheKey = 'care_reminders_cache';
  static const String _lastSyncKey = 'care_reminders_last_sync';

  SharedPreferences? _prefs;
  List<CareReminder> _reminders = [];
  bool _initialized = false;
  
  ApiService? _api;
  String? _userId;

  /// Check if service has valid API connection
  bool get hasApiConnection => _api != null && _userId != null;

  /// Initialize the service with API for cloud sync
  /// IMPORTANT: Always pass api and userId for proper DynamoDB sync
  Future<void> initialize({ApiService? api, String? userId}) async {
    _prefs = await SharedPreferences.getInstance();
    
    // Update API credentials if provided
    if (api != null && userId != null) {
      final needsResync = _api != api || _userId != userId;
      _api = api;
      _userId = userId;
      
      // Always sync with server when credentials are provided
      if (needsResync || !_initialized) {
        await syncWithServer();
      }
    } else if (!_initialized) {
      // Fallback to cache only if no credentials and first init
      _loadFromCache();
    }
    
    _initialized = true;
  }

  /// Force re-sync with server (call after auth changes)
  Future<void> forceSync({required ApiService api, required String userId}) async {
    _api = api;
    _userId = userId;
    await syncWithServer();
  }

  /// Sync local cache with server
  Future<void> syncWithServer() async {
    if (_api == null || _userId == null) {
      debugPrint('⚠️ Cannot sync reminders: API or userId not set');
      return;
    }
    
    try {
      final serverReminders = await _api!.getCareRemindersForUser(_userId!);
      _reminders = serverReminders;
      _saveToCache();
      debugPrint('✅ Synced ${_reminders.length} reminders from server');
    } catch (e) {
      debugPrint('⚠️ Failed to sync reminders: $e - using local cache');
      // Load from cache as fallback
      _loadFromCache();
    }
  }

  void _loadFromCache() {
    final data = _prefs?.getString(_cacheKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        _reminders = decoded.map((e) => CareReminder.fromJson(e)).toList();
        debugPrint('📦 Loaded ${_reminders.length} reminders from cache');
      } catch (e) {
        debugPrint('Failed to load reminders from cache: $e');
        _reminders = [];
      }
    }
  }

  void _saveToCache() {
    final data = jsonEncode(_reminders.map((r) => r.toJson()).toList());
    _prefs?.setString(_cacheKey, data);
    _prefs?.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get all reminders
  List<CareReminder> get reminders => List.unmodifiable(_reminders);

  /// Get reminders for a specific plant
  List<CareReminder> getRemindersForPlant(String plantId) {
    return _reminders.where((r) => r.plantId == plantId).toList()
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
  }

  /// Check if plant has any reminders
  bool hasRemindersForPlant(String plantId) {
    return _reminders.any((r) => r.plantId == plantId);
  }

  /// Get grouped reminders for timeline display
  GroupedReminders getGroupedReminders({String? plantId}) {
    var filtered = plantId != null 
        ? _reminders.where((r) => r.plantId == plantId).toList()
        : _reminders;
    return GroupedReminders.fromList(filtered);
  }

  /// Get upcoming reminders within specified days
  List<CareReminder> getUpcomingReminders({int days = 7, String? plantId}) {
    final cutoff = DateTime.now().add(Duration(days: days));
    var filtered = _reminders.where((r) => 
      r.enabled && 
      r.nextDue.isBefore(cutoff) &&
      (plantId == null || r.plantId == plantId)
    ).toList();
    filtered.sort((a, b) => a.nextDue.compareTo(b.nextDue));
    return filtered;
  }

  /// Count of actionable reminders (overdue + today)
  int get actionableCount {
    final grouped = getGroupedReminders();
    return grouped.overdue.length + grouped.today.length;
  }

  /// Add a new reminder
  Future<CareReminder> addReminder({
    required String plantId,
    required String plantNickname,
    required String plantEmoji,
    required CareType careType,
    String? customLabel,
    required int frequencyDays,
    DateTime? startDate,
    String? notes,
  }) async {
    final now = DateTime.now();
    final nextDue = startDate ?? now;

    // Try to create on server first
    if (_api != null && _userId != null) {
      try {
        final serverReminder = await _api!.createCareReminder(
          plantId: plantId,
          userId: _userId!,
          plantNickname: plantNickname,
          plantEmoji: plantEmoji,
          careType: careType.name,
          customLabel: customLabel,
          frequencyDays: frequencyDays,
          nextDue: nextDue.toIso8601String(),
          notes: notes,
        );
        _reminders.add(serverReminder);
        _saveToCache();
        return serverReminder;
      } catch (e) {
        debugPrint('Failed to create reminder on server: $e');
        throw Exception('Failed to save reminder. Please check your connection.');
      }
    }

    // No API connection - throw error instead of silent local fallback
    throw Exception('Cannot create reminder: Not connected to server');
  }

  /// Update an existing reminder
  Future<CareReminder> updateReminder(String id, {
    CareType? careType,
    String? customLabel,
    int? frequencyDays,
    DateTime? nextDue,
    bool? enabled,
    String? notes,
  }) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reminder not found');

    final old = _reminders[index];
    
    // Try to update on server
    if (_api != null) {
      try {
        final serverReminder = await _api!.updateCareReminder(
          reminderId: id,
          careType: careType?.name,
          customLabel: customLabel,
          frequencyDays: frequencyDays,
          nextDue: nextDue?.toIso8601String(),
          enabled: enabled,
          notes: notes,
        );
        _reminders[index] = serverReminder;
        _saveToCache();
        return serverReminder;
      } catch (e) {
        debugPrint('Failed to update reminder on server: $e');
        throw Exception('Failed to update reminder. Please check your connection.');
      }
    }

    throw Exception('Cannot update reminder: Not connected to server');
  }

  /// Mark a reminder as complete and reschedule
  Future<CareReminder> completeReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reminder not found');

    // Try server first
    if (_api != null) {
      try {
        final serverReminder = await _api!.completeCareReminder(id);
        _reminders[index] = serverReminder;
        _saveToCache();
        return serverReminder;
      } catch (e) {
        debugPrint('Failed to complete reminder on server: $e');
        throw Exception('Failed to complete reminder. Please check your connection.');
      }
    }

    throw Exception('Cannot complete reminder: Not connected to server');
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    // Try server first
    if (_api != null) {
      try {
        await _api!.deleteCareReminder(id);
        _reminders.removeWhere((r) => r.id == id);
        _saveToCache();
        return;
      } catch (e) {
        debugPrint('Failed to delete reminder on server: $e');
        throw Exception('Failed to delete reminder. Please check your connection.');
      }
    }

    throw Exception('Cannot delete reminder: Not connected to server');
  }

  /// Toggle reminder enabled/disabled
  Future<CareReminder> toggleReminder(String id) async {
    final reminder = _reminders.firstWhere((r) => r.id == id);
    return updateReminder(id, enabled: !reminder.enabled);
  }

  /// Add default reminders for a plant based on its watering schedule
  /// Called automatically when a plant is created without a sensor
  Future<List<CareReminder>> addDefaultRemindersForPlant(Plant plant) async {
    // Check if reminders already exist
    final existing = getRemindersForPlant(plant.plantId);
    if (existing.isNotEmpty) {
      debugPrint('ℹ️ Plant ${plant.nickname} already has ${existing.length} reminders');
      return existing;
    }

    // Require API connection for creating defaults
    if (_api == null || _userId == null) {
      debugPrint('⚠️ Cannot create default reminders: API not connected');
      throw Exception('Cannot create reminders: Not connected to server');
    }

    try {
      final serverReminders = await _api!.createDefaultCareReminders(
        plantId: plant.plantId,
        userId: _userId!,
        plantNickname: plant.nickname,
        plantEmoji: plant.emoji,
        hasDevice: plant.hasDevice,
        waterFrequencyDays: plant.wateringRecommendation.frequencyDays,
      );
      _reminders.addAll(serverReminders);
      _saveToCache();
      debugPrint('✅ Created ${serverReminders.length} default reminders for ${plant.nickname}');
      return serverReminders;
    } catch (e) {
      debugPrint('Failed to create default reminders on server: $e');
      throw Exception('Failed to create reminders: $e');
    }
  }

  /// Update reminders when a plant's sensor status changes
  Future<void> updateRemindersForSensorChange(Plant plant) async {
    if (_api == null || _userId == null) {
      throw Exception('Cannot update reminders: Not connected to server');
    }

    final existing = getRemindersForPlant(plant.plantId);
    
    // Remove existing water/refill reminders
    for (final reminder in existing) {
      if (reminder.careType == CareType.water || reminder.careType == CareType.refill) {
        await deleteReminder(reminder.id);
      }
    }

    // Add appropriate reminder based on new sensor status
    if (plant.hasDevice) {
      await addReminder(
        plantId: plant.plantId,
        plantNickname: plant.nickname,
        plantEmoji: plant.emoji,
        careType: CareType.refill,
        frequencyDays: 14,
        notes: 'Refill the water tank for automatic watering',
      );
    } else {
      final waterFreq = plant.wateringRecommendation.frequencyDays;
      await addReminder(
        plantId: plant.plantId,
        plantNickname: plant.nickname,
        plantEmoji: plant.emoji,
        careType: CareType.water,
        frequencyDays: waterFreq,
        notes: 'Water your ${plant.nickname}',
      );
    }
  }

  /// Update refill reminder to be due now (called when water level is low)
  Future<void> triggerRefillReminder(String plantId) async {
    final reminders = getRemindersForPlant(plantId);
    final refillReminder = reminders.where((r) => r.careType == CareType.refill).firstOrNull;

    if (refillReminder != null) {
      await updateReminder(
        refillReminder.id,
        nextDue: DateTime.now(),
        notes: 'Water tank is low - refill needed!',
      );
    }
  }

  /// Delete all reminders for a plant
  Future<void> deleteRemindersForPlant(String plantId) async {
    if (_api != null) {
      try {
        await _api!.deleteRemindersForPlant(plantId);
      } catch (e) {
        debugPrint('Failed to delete reminders on server: $e');
      }
    }

    _reminders.removeWhere((r) => r.plantId == plantId);
    _saveToCache();
  }

  /// Clear all local data
  Future<void> clearAll() async {
    _reminders.clear();
    await _prefs?.remove(_cacheKey);
    await _prefs?.remove(_lastSyncKey);
    _initialized = false;
  }
}