import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const GlobalErrorWidget({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 80, color: AppTheme.errorColor),
              const SizedBox(height: 24),
              const Text(
                "Something went wrong",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "An unexpected error occurred. Our team has been notified.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.subTextColor),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
                child: const Text("Restart App"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
