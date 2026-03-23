import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'issue_resolution_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch this action.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Support Center"),
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
                _buildContactHero(),
                const SizedBox(height: 32),
                const Text("Quick Options", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        "Live Chat",
                        Icons.chat_bubble_rounded,
                        Colors.blue,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        "Disputes",
                        Icons.gavel_rounded,
                        Colors.orange,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IssueResolutionScreen())),
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        "WhatsApp",
                        Icons.wechat_rounded,
                        Colors.green,
                        () => _launchUrl(context, "https://wa.me/254705731400"),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        "Email Us",
                        Icons.email_rounded,
                        Colors.purple,
                        () => _launchUrl(context, "mailto:support@tokenhub.co.ke"),
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text("Direct Line", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _launchUrl(context, "tel:+254705731400"),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_rounded, color: Colors.green),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Call 0705731400", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("Available 24/7", style: TextStyle(color: AppTheme.subTextColor, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const Text("FAQ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildFAQTile("What if my token delays?", "If your payment was successful but the token is delayed, go to Disputes under Quick Options to expedite resolution.", isDark),
                _buildFAQTile("Is the Emergency Token free?", "No, the KES 150 SOS Emergency token is a credit advance. It will automatically be deducted from your next purchase.", isDark),
                _buildFAQTile("How do I refer friends?", "Navigate to your Profile section and tap on 'Refer & Earn' to get your unique code.", isDark),
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
                Text("We're Here to Help", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Fast, reliable assistance for all your token needs.", style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
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
}
