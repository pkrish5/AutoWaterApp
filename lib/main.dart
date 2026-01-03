import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/streak_service.dart';
import 'services/care_reminder_service.dart';
import 'services/api_service.dart';
import 'ui/auth/login_screen.dart';
import 'ui/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize notification service
  await NotificationService().initialize();
  
  // Initialize care reminder service (without API - will sync when user logs in)
  await CareReminderService().initialize();
  
  // Reset daily streak flag if needed
  await StreakService.resetDailyFlag();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const RootwiseApp(),
    ),
  );
}

class RootwiseApp extends StatelessWidget {
  const RootwiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rootwise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthService>(context, listen: false).tryRestoreSession();
    });
  }

  Future<void> _registerPushToken() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    
    // Wait for auth to be ready
    if (auth.isAuthenticated && auth.userId != null && auth.idToken != null) {
      await NotificationService().registerTokenWithServer(
        userId: auth.userId!,
        authToken: auth.idToken!,
      );
    }
  }

  Future<void> _initializeCareReminders() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    
    if (auth.isAuthenticated && auth.userId != null && auth.idToken != null) {
      final api = ApiService(auth.idToken!);
      await CareReminderService().initialize(
        api: api,
        userId: auth.userId,
      );
      debugPrint('✅ Care reminders synced with server');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (!auth.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    // Register token and sync reminders when user logs in
    if (auth.isAuthenticated) {
      _registerPushToken();
      _initializeCareReminders();
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}