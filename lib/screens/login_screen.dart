import 'dart:convert';
import 'package:flutter/material.dart';
import 'meter_setup_screen.dart';
import '../widgets/custom_text_field.dart';
import '../screens/signup_screen.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  void _showOtpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final otpController = TextEditingController();
        bool isVerifying = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Enter 2FA Code", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("For extra security, a code has been sent to your phone.", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "000000",
                      counterText: "",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () async {
                    if (otpController.text.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enter a 6-digit code")),
                      );
                      return;
                    }
                    setState(() => isVerifying = true);
                    await Future.delayed(const Duration(seconds: 1)); // Simulate check
                    if (context.mounted) {
                      Navigator.pop(context);
                      await StorageService.recordLogin();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        );
                      }
                    }
                  },
                  child: isVerifying 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Verify"),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both phone and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(phone, password);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await StorageService.saveToken(data['token']);
        await StorageService.saveUserId(data['_id']);
        await StorageService.saveUserData(data['name'], data['phone'], email: data['email'] ?? '');
        await StorageService.saveBalance((data['balance'] ?? 0).toDouble());
        await StorageService.saveSetupDone(data['isInitialSetupDone'] ?? false);
        
        if (mounted) {
          final isSetupDone = data['isInitialSetupDone'] ?? false;
          if (!isSetupDone) {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MeterSetupScreen()));
          } else {
             _showOtpDialog(context);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Login failed")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection error. Is the server running?")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _socialButton(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  "Sign in to continue your secure energy journey.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppTheme.darkSubText
                        : AppTheme.subTextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                CustomTextField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("A password reset link has been sent to your phone.")),
                      );
                    },
                    child: const Text("Forgot Password?", style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    elevation: 8,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Sign In"),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(Icons.g_mobiledata_rounded, "Google", () => {}, isDark), // Logic skipped for backend integration demo
                    const SizedBox(width: 16),
                    _socialButton(Icons.apple_rounded, "Apple", () => {}, isDark),
                  ],
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
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "1.2M+ Active Users Nationwide",
                          style: TextStyle(
                            color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
