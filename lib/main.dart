import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/support_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/global_error_widget.dart';

void main() {
  runApp(const TokenHubApp());
}

class TokenHubApp extends StatelessWidget {
  const TokenHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Token Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, widget) {
        ErrorWidget.builder = (details) => GlobalErrorWidget(errorDetails: details);
        return widget!;
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/support': (context) => const SupportScreen(),
      },
    );
  }
}