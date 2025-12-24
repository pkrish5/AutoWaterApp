import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'ui/auth/login_screen.dart';
import 'ui/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const SimsForPlantsApp(),
    ),
  );
}

class SimsForPlantsApp extends StatelessWidget {
  const SimsForPlantsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sims for Plants',
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
    
    // Show dashboard if authenticated, otherwise login
    if (auth.isAuthenticated) {
      return const DashboardScreen();
    }
    return const LoginScreen();
  }
}
