import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  Future<void> _sharePlayStoreLink(BuildContext context) async {
    final uri = Uri.parse("https://play.google.com/store/apps/details?id=com.tokenhub.app");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mock sharing: Play Store Link Sent!")));
      }
    }

    // Simulate earning the 4 Unit token because a "friend downloaded it"
    Future.delayed(const Duration(seconds: 4), () {
      NotificationService().notify(
        AppNotification(
          title: "Referral Success!",
          message: "Your friend signed up. Here is your 4 Unit Token: 1290-4821-5099-2210-9941",
          type: NotificationType.paymentSuccess,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Refer & Earn"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark ? [AppTheme.darkBackground, AppTheme.darkSurface] : [AppTheme.backgroundColor, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 80),
                ),
                const SizedBox(height: 32),
                const Text("Invite Friends, Get Free Tokens!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 12),
                const Text("Share your code and earn a FREE 4 Unit Token for every friend who downloads the app.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.subTextColor, fontSize: 16)),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Your Invite Code", style: TextStyle(color: AppTheme.subTextColor, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TH-MORGAN-2026",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: "TH-MORGAN-2026"));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied!")));
                            },
                            icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryColor),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _sharePlayStoreLink(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Share Google Play Link", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 48),
                const Row(
                  children: [
                    Icon(Icons.people_alt_rounded, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text("Successful Referrals (2)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _referralTile(name: "Jane Doe", status: "Completed", units: "+4 Units", isDark: isDark),
                _referralTile(name: "Mark T.", status: "Pending", units: "Waiting...", isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _referralTile({required String name, required String status, required String units, required bool isDark}) {
    bool isCompleted = status == "Completed";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                child: Icon(isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded, 
                  color: isCompleted ? Colors.green : Colors.orange),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(status, style: TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(units, style: TextStyle(color: isCompleted ? Colors.green : AppTheme.subTextColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
