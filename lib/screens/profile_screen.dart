import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "";
  String _phone = "";
  int _meterCount = 0;
  double _totalSpent = 0;
  bool _biometricsEnabled = SecurityService().biometricsEnabled;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userData = await StorageService.getUserData();
    final meters = await StorageService.getMeters();
    final transactions = await StorageService.getTransactions();
    
    double spent = 0;
    for (var tx in transactions) {
      final amountStr = tx['amount']?.replaceAll('KES ', '') ?? "0";
      spent += double.tryParse(amountStr) ?? 0;
    }

    if (mounted) {
      setState(() {
        _userName = userData['name'] ?? "User";
        _phone = userData['phone'] ?? "";
        _meterCount = meters.length;
        _totalSpent = spent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Profile"),
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
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 32),
                _buildStatsSection(),
                const SizedBox(height: 32),
                _buildSettingsSection(),
                const SizedBox(height: 40),
                _buildLogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_rounded, size: 60, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _userName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          _phone,
          style: const TextStyle(color: AppTheme.subTextColor, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(child: _statCard("Total Spent", "KES ${_totalSpent.toStringAsFixed(0)}", Icons.payments_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _statCard("Active Meters", "$_meterCount", Icons.speed_rounded)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _settingsTile(
            "Biometric Login",
            "Use Fingerprint or FaceID",
            Icons.fingerprint_rounded,
            _biometricsEnabled,
            (val) {
              setState(() => _biometricsEnabled = val);
              SecurityService().setBiometricsEnabled(val);
            },
          ),
          const Divider(height: 1),
          _settingsTile(
            "Push Notifications",
            "Get instant sync alerts",
            Icons.notifications_active_rounded,
            _notificationsEnabled,
            (val) => setState(() => _notificationsEnabled = val),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
      icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
      label: const Text("Sign Out", style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
    );
  }
}
