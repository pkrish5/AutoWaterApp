import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _initialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  /// Initialize Firebase and notification service
  Future<void> initialize() async {
  if (_initialized) return;

  try {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    await requestPermission();

    // Set up listeners first (these don't require APNS)
    _messaging!.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token received: $newToken');
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // iOS-specific: only do token/message ops if APNS ready
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _messaging!.getAPNSToken();
      if (apnsToken != null) {
        _fcmToken = await _messaging!.getToken();
        final initialMessage = await _messaging!.getInitialMessage();
        if (initialMessage != null) _handleNotificationTap(initialMessage);
      } else {
        debugPrint('APNS not ready - token will arrive via onTokenRefresh');
      }
    } else {
      // Android
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _fcmToken = await _messaging!.getToken();
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) _handleNotificationTap(initialMessage);
    }

    _initialized = true;
    debugPrint('NotificationService initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize NotificationService: $e');
  }
}
  /// Request notification permissions
  Future<bool> requestPermission() async {
    if (_messaging == null) return false;

    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      
      debugPrint('Notification permission: ${settings.authorizationStatus}');
      return granted;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  /// Get the FCM token
  Future<String?> getToken() async {
    if (!_initialized) {
      await initialize();
    }
    _fcmToken ??= await _messaging?.getToken();
    return _fcmToken;
  }

  /// Register push token with backend
  Future<void> registerTokenWithServer({
    required String userId,
    required String authToken,
  }) async {
    final token = await getToken();
    if (token == null) {
      debugPrint('No FCM token available');
      return;
    }

    try {
      final api = ApiService(authToken);
      await api.registerPushToken(
        userId: userId,
        token: token,
        platform: _getPlatform(),
      );
      debugPrint('Push token registered with server');
    } catch (e) {
      debugPrint('Failed to register push token: $e');
    }
  }

  String _getPlatform() {
    // You can use Platform.isIOS / Platform.isAndroid if you import dart:io
    // For now, return a generic value
    return 'mobile';
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // You can show a local notification or in-app alert here
    // For now, we'll just log it
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Navigate based on notification type
    final type = message.data['type'];
    final plantId = message.data['plantId'];

    switch (type) {
      case 'water_refill':
        // Navigate to plant detail
        debugPrint('Should navigate to plant: $plantId');
        break;
      case 'streak_warning':
        // Navigate to gallery or dashboard
        debugPrint('Should prompt user to upload photo');
        break;
      case 'plant_health':
        // Navigate to plant detail
        debugPrint('Should navigate to plant: $plantId');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic: $e');
    }
  }
}

// Notification types for the app
enum NotificationType {
  waterRefill,
  streakWarning,
  plantHealth,
  friendRequest,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.waterRefill:
        return 'water_refill';
      case NotificationType.streakWarning:
        return 'streak_warning';
      case NotificationType.plantHealth:
        return 'plant_health';
      case NotificationType.friendRequest:
        return 'friend_request';
    }
  }

  String get title {
    switch (this) {
      case NotificationType.waterRefill:
        return 'Water Tank Low! 💧';
      case NotificationType.streakWarning:
        return 'Keep Your Streak! 🔥';
      case NotificationType.plantHealth:
        return 'Plant Needs Attention! 🌱';
      case NotificationType.friendRequest:
        return 'New Friend Request! 👋';
    }
  }
}