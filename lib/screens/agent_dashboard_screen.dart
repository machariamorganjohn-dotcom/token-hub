import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AgentDashboardScreen extends StatelessWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Dashboard"),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome, Reseller!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Manage your bulk token sales and track commissions.", style: TextStyle(color: AppTheme.subTextColor, fontSize: 16)),
                const SizedBox(height: 32),
                
                // Stats
                Row(
                  children: [
                    Expanded(child: _statCard("Total Sales", "KES 45,200", Icons.trending_up_rounded, Colors.green, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _statCard("Commission", "KES 2,260", Icons.account_balance_wallet_rounded, Colors.purple, isDark)),
                  ],
                ),
                
                const SizedBox(height: 48),
                const Text("Quick Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _actionTile(Icons.shopping_cart_checkout_rounded, "Sell Tokens to Customer", "Purchase for any meter number", Colors.orange, isDark),
                const SizedBox(height: 12),
                _actionTile(Icons.bar_chart_rounded, "View Sales Report", "Export your daily/weekly stats", Colors.blue, isDark),
                
                const SizedBox(height: 48),
                const Text("Recent Sales", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _saleTile("Meter 14234567891", "KES 1,000", "+ KES 50", "Today, 10:24 AM", isDark),
                _saleTile("Meter 14234560002", "KES 5,000", "+ KES 250", "Yesterday, 2:15 PM", isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.subTextColor),
        ],
      ),
    );
  }

  Widget _saleTile(String meter, String amount, String commission, String time, bool isDark) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(time, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(commission, style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
