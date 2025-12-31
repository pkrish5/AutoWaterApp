import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/care_reminder.dart';
import '../models/plant.dart';

class CareReminderService {
  static final CareReminderService _instance = CareReminderService._internal();
  factory CareReminderService() => _instance;
  CareReminderService._internal();

  static const _storageKey = 'care_reminders';

  bool _initialized = false;
  List<CareReminder> _reminders = [];

  List<CareReminder> get reminders => List.unmodifiable(_reminders);

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    await _loadReminders();
    _initialized = true;
  }

  /// Load reminders from local storage
  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _reminders = jsonList.map((j) => CareReminder.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load reminders: $e');
      _reminders = [];
    }
  }

  /// Save reminders to local storage
  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_reminders.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to save reminders: $e');
    }
  }

  /// Get reminders for a specific plant
  List<CareReminder> getRemindersForPlant(String plantId) {
    return _reminders.where((r) => r.plantId == plantId).toList()
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
  }

  /// Get all reminders grouped by status
  GroupedReminders getGroupedReminders() {
    return GroupedReminders.fromList(_reminders);
  }

  /// Get reminders due within the next N days
  List<CareReminder> getUpcomingReminders({int days = 7}) {
    final cutoff = DateTime.now().add(Duration(days: days));
    return _reminders
        .where((r) => r.enabled && r.nextDue.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
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
    final id = '${plantId}_${careType.name}_${DateTime.now().millisecondsSinceEpoch}';
    final nextDue = startDate ?? DateTime.now();

    final reminder = CareReminder(
      id: id,
      plantId: plantId,
      plantNickname: plantNickname,
      plantEmoji: plantEmoji,
      careType: careType,
      customLabel: customLabel,
      frequencyDays: frequencyDays,
      nextDue: nextDue,
      notes: notes,
    );

    _reminders.add(reminder);
    await _saveReminders();

    return reminder;
  }

  /// Add default reminders for a plant based on its watering schedule
  /// Call this when a plant is created or when a sensor is unlinked
  Future<List<CareReminder>> addDefaultRemindersForPlant(Plant plant) async {
    final reminders = <CareReminder>[];
    
    // Check if reminders already exist for this plant
    final existing = getRemindersForPlant(plant.plantId);
    if (existing.isNotEmpty) {
      return existing; // Don't duplicate
    }

    if (plant.hasDevice) {
      // For sensor plants: add refill reminder instead of water
      reminders.add(await addReminder(
        plantId: plant.plantId,
        plantNickname: plant.nickname,
        plantEmoji: plant.emoji,
        careType: CareType.refill,
        frequencyDays: 14, // Typical tank refill
        notes: 'Refill the water tank for automatic watering',
      ));
    } else {
      // For non-sensor plants: add water reminder based on plant's schedule
      final waterFreq = plant.wateringRecommendation.frequencyDays;
      
      reminders.add(await addReminder(
        plantId: plant.plantId,
        plantNickname: plant.nickname,
        plantEmoji: plant.emoji,
        careType: CareType.water,
        frequencyDays: waterFreq,
        notes: 'Water your ${plant.nickname}',
      ));
    }

    // Add rotate reminder for all plants
    reminders.add(await addReminder(
      plantId: plant.plantId,
      plantNickname: plant.nickname,
      plantEmoji: plant.emoji,
      careType: CareType.rotate,
      frequencyDays: 14,
    ));

    // Add fertilize reminder (monthly during growing season)
    reminders.add(await addReminder(
      plantId: plant.plantId,
      plantNickname: plant.nickname,
      plantEmoji: plant.emoji,
      careType: CareType.fertilize,
      frequencyDays: 30,
    ));

    return reminders;
  }

  /// Update reminders when a plant's sensor status changes
  /// Call this when linking/unlinking a device
  Future<void> updateRemindersForSensorChange(Plant plant) async {
    // Remove existing water/refill reminders
    final existing = getRemindersForPlant(plant.plantId);
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

  /// Add a refill reminder for a sensor plant based on water level usage
  Future<CareReminder> addRefillReminder({
    required String plantId,
    required String plantNickname,
    required String plantEmoji,
    required int estimatedDaysUntilEmpty,
  }) async {
    // Schedule reminder 1-2 days before estimated empty
    final daysUntilReminder = (estimatedDaysUntilEmpty - 2).clamp(1, 30);
    
    return addReminder(
      plantId: plantId,
      plantNickname: plantNickname,
      plantEmoji: plantEmoji,
      careType: CareType.refill,
      frequencyDays: daysUntilReminder,
      notes: 'Water tank running low - refill soon!',
    );
  }

  /// Update an existing reminder
  Future<void> updateReminder(CareReminder updated) async {
    final index = _reminders.indexWhere((r) => r.id == updated.id);
    if (index == -1) return;

    _reminders[index] = updated;
    await _saveReminders();
  }

  /// Mark a reminder as completed
  Future<CareReminder> completeReminder(String reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index == -1) throw Exception('Reminder not found');

    final updated = _reminders[index].markCompleted();
    _reminders[index] = updated;
    
    await _saveReminders();

    return updated;
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
    await _saveReminders();
  }

  /// Delete all reminders for a plant
  Future<void> deleteRemindersForPlant(String plantId) async {
    _reminders.removeWhere((r) => r.plantId == plantId);
    await _saveReminders();
  }

  /// Toggle reminder enabled state
  Future<void> toggleReminder(String reminderId, bool enabled) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index == -1) return;

    final updated = _reminders[index].copyWith(enabled: enabled);
    _reminders[index] = updated;
    await _saveReminders();
  }

  /// Check if a plant has any reminders
  bool hasRemindersForPlant(String plantId) {
    return _reminders.any((r) => r.plantId == plantId);
  }

  /// Get count of overdue + today reminders
  int get actionableCount {
    final grouped = getGroupedReminders();
    return grouped.overdue.length + grouped.today.length;
  }
}