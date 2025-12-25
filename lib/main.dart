import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'ui/auth/login_screen.dart';
import 'ui/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize notification service
  await NotificationService().initialize();
  
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    
    if (auth.isAuthenticated) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}