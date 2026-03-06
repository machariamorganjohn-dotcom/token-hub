import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../screens/signup_screen.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phoneController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgGradient = isDark
        ? [AppTheme.darkBackground, AppTheme.darkSurface]
        : [AppTheme.backgroundColor, Colors.white];

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_person_rounded,
                        size: 48, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Welcome Back",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Sign in to continue your smart energy journey.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppTheme.darkSubText
                        : AppTheme.subTextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                CustomTextField(
                  controller: phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () async {
                    if (phoneController.text.isNotEmpty) {
                      await StorageService.recordLogin();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DashboardScreen()),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please enter your phone number")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 8,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: const Text("Sign In"),
                ),
                const SizedBox(height: 24),
                Center(
                  child: IconButton(
                    onPressed: () async {
                      final success =
                          await SecurityService().authenticateWithBiometrics();
                      if (success) {
                        await StorageService.recordLogin();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DashboardScreen()),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Biometric authentication failed")),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.fingerprint_rounded,
                        size: 48, color: AppTheme.primaryColor),
                    tooltip: "Login with Biometrics",
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkSubText
                            : AppTheme.subTextColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignUpScreen()),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
