import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final String _referralCode = "THUB-49X2"; // Simulated code
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final p = await StorageService.getPoints();
    setState(() => _points = p);
  }

  Future<void> _simulateSuccessfulInvite() async {
    // 1. Reward 3 Units
    final currentBalance = await StorageService.getBalance();
    await StorageService.saveBalance(currentBalance + 3.0);
    
    // 2. Increase Points (Visual only)
    await StorageService.savePoints(_points + 250);
    _loadPoints();

    if (!mounted) return;

    // 3. Show "Thank You" and Success message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              "THANK YOU!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your friend has joined Token Hub! As a token of our appreciation, we have added 3 FREE Units to your meter balance.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Awesome!"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Refer & Earn"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: AppTheme.premiumCardDecoration(isDark: isDark),
              child: Column(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    "$_points Points",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Your Loyalty Balance",
                    style: TextStyle(color: AppTheme.subTextColor),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text(
                    "Invite a friend and get 3 FREE Electricity Units instantly when they buy their first token!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _simulateSuccessfulInvite,
              icon: const Icon(Icons.celebration_rounded),
              label: const Text("Simulate Successful Invite (Reward)"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text(
              "Your Referral Code",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _referralCode));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied to clipboard!")));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _referralCode,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primaryColor),
                    ),
                    const Icon(Icons.copy_rounded, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // In a real app, use share_plus package
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening share options...")));
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text("Share Invitation Link"),
            ),
          ],
        ),
      ),
    );
  }
}
