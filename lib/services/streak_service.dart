import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const _lastLoginKey = 'last_login_date';
  static const _hasShownTodayKey = 'has_shown_welcome_today';

  /// Check if this is a new day login and update streak accordingly.
  /// Returns a StreakCheckResult with whether to show popup and the new streak.
  
  static Future<StreakCheckResult> checkAndUpdateDailyLogin({
  required int currentStreak,
  required Future<Map<String, dynamic>> Function() updateStreakOnServer,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final hasShownToday = prefs.getBool(_hasShownTodayKey) ?? false;
  
  // Always call server - it handles deduplication
  final result = await updateStreakOnServer();
  final newStreak = result['streak'] as int? ?? currentStreak;
  final serverUpdated = result['updated'] as bool? ?? false;
  
  // Only show popup if server actually updated streak AND we haven't shown today
  if (hasShownToday || !serverUpdated) {
    return StreakCheckResult(
      shouldShowPopup: false,
      newStreak: newStreak,
      isNewDay: false,
    );
  }
  
  await prefs.setBool(_hasShownTodayKey, true);
  
  return StreakCheckResult(
    shouldShowPopup: true,
    newStreak: newStreak,
    isNewDay: true,
    previousStreak: currentStreak,
  );
}

  /// Reset the daily flag (call at midnight or app restart next day)
  static Future<void> resetDailyFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _dateToString(now);
    final lastLoginStr = prefs.getString(_lastLoginKey);
    
    // If it's a new day, reset the shown flag
    if (lastLoginStr != todayStr) {
      await prefs.setBool(_hasShownTodayKey, false);
    }
  }
  
  static String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class StreakCheckResult {
  final bool shouldShowPopup;
  final int newStreak;
  final bool isNewDay;
  final int? previousStreak;
  
  StreakCheckResult({
    required this.shouldShowPopup,
    required this.newStreak,
    required this.isNewDay,
    this.previousStreak,
  });
  
  bool get streakIncreased => previousStreak != null && newStreak > previousStreak!;
}