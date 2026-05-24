import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../services/version_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      try {
        await PermissionService.requestAllPermissions();
        await StorageService.init();
        
        // 1. Version Check
        final updateInfo = await VersionService.checkUpdate();
        if (updateInfo['canUpdate']) {
          if (!mounted) return;
          bool stayOnSplash = await _showUpdateDialog(
            updateInfo['latestVersion'], 
            updateInfo['isForce']
          );
          if (stayOnSplash) return; // Stop navigation if update is forced
        }

        final userData = await StorageService.getUserData();
        final hasPhone = userData['phone']?.isNotEmpty ?? false;
        final hasEverRegistered = await StorageService.hasEverRegistered();

        if (!mounted) return;

        if (hasPhone) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (hasEverRegistered) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          Navigator.pushReplacementNamed(context, '/signup');
        }
      } catch (e) {
        if (mounted) {
          // Fallback to signup screen if any error occurs during init
          Navigator.pushReplacementNamed(context, '/signup');
        }
      }
    });
  }

  Future<bool> _showUpdateDialog(String latestVersion, bool isForce) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: !isForce,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.update_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(isForce ? "Update Required" : "Update Available"),
          ],
        ),
        content: Text(
          isForce 
            ? "A critical update (v$latestVersion) is required to continue using Token Hub. Please update now to access new features and security fixes."
            : "A new version of Token Hub (v$latestVersion) is available! Would you like to update now for a better experience?"
        ),
        actions: [
          if (!isForce)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Later"),
            ),
          ElevatedButton(
            onPressed: () {
              // In a real app, launch the App Store or Play Store URL
              // For now we simulate success or just stay on screen if forced
              if (!isForce) {
                Navigator.pop(context, false);
              }
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    ) ?? isForce;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.9),
              const Color(0xFF0B192C), // Deep tech blue
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "TOKEN HUB",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          color: Colors.cyanAccent,
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "INTELLIGENT ENERGY",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent.withValues(alpha: 0.8)),
                      strokeWidth: 2,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
