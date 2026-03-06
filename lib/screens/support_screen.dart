import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, Colors.white],
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
                _buildContactHero(),
                const SizedBox(height: 32),
                const Text("Frequently Asked Questions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildFAQTile("How do I sync my meter?", "Ensure you are connected to the internet and tap 'Connect to Meter' on the dashboard."),
                _buildFAQTile("What is a token purchase?", "Tokens are digital units that power your smart meter. You can buy them via M-Pesa, Card, or Bank."),
                _buildFAQTile("Is my data secure?", "Yes, we use hardware-level encryption to protect your balance and personal information."),
                const SizedBox(height: 40),
                _buildLiveChatButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.support_agent_rounded, color: Colors.white, size: 48),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("24/7 Assistance", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("We are here to help you manage your energy better.", style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChatButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connecting to a live agent... (Simulation)")),
        );
      },
      icon: const Icon(Icons.chat_bubble_rounded),
      label: const Text("Start Live Chat"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentColor,
        minimumSize: const Size(double.infinity, 60),
      ),
    );
  }
}
