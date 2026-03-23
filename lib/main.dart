import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/support_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'widgets/global_error_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const TokenHubApp(),
    ),
  );
}

class TokenHubApp extends StatelessWidget {
  const TokenHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Token Hub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          builder: (context, widget) {
            ErrorWidget.builder =
                (details) => GlobalErrorWidget(errorDetails: details);
            return widget!;
          },
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/support': (context) => const SupportScreen(),
          },
        );
      },
    );
  }
}