import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';
import '../providers/theme_provider.dart';
import 'referral_screen.dart';
import 'agent_dashboard_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "";
  String _phone = "";
  String _email = "";
  int _meterCount = 0;
  double _totalSpent = 0;
  bool _biometricsEnabled = SecurityService().biometricsEnabled;
  bool _notificationsEnabled = true;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userData = await StorageService.getUserData();
    final meters = await StorageService.getMeters();
    final transactions = await StorageService.getTransactions();
    final imagePath = await StorageService.getProfileImage();

    double spent = 0;
    for (var tx in transactions) {
      final amountStr = tx['amount']?.replaceAll('KES ', '') ?? "0";
      spent += double.tryParse(amountStr) ?? 0;
    }

    if (mounted) {
      setState(() {
        _userName = userData['name'] ?? "User";
        _phone = userData['phone'] ?? "";
        _email = userData['email'] ?? "";
        _meterCount = meters.length;
        _totalSpent = spent;
        _imagePath = imagePath;
      });
    }
  }

  // ── Image picker ────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked != null && mounted) {
      await StorageService.saveProfileImage(picked.path);
      setState(() => _imagePath = picked.path);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Change Profile Photo",
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _photoSourceButton(
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  _photoSourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: "Camera",
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    final bgGradient = isDark
        ? [AppTheme.darkBackground, AppTheme.darkSurface]
        : [AppTheme.backgroundColor, Colors.white];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAvatarSection(isDark),
                const SizedBox(height: 32),
                _buildStatsSection(isDark),
                const SizedBox(height: 32),
                _buildSettingsSection(isDark, themeProvider),
                const SizedBox(height: 40),
                _buildLogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Avatar ──────────────────────────────────────────────────────────────────
  Widget _buildAvatarSection(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _imagePath != null ? FileImage(File(_imagePath!)) : null,
                  child: _imagePath == null
                      ? const Icon(Icons.person_rounded,
                          size: 60, color: AppTheme.primaryColor)
                      : null,
                ),
              ),
              // Camera badge
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _userName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (_email.isNotEmpty)
          Text(
            _email,
            style: TextStyle(
              color: isDark ? AppTheme.darkSubText : AppTheme.subTextColor,
              fontSize: 14,
            ),
          ),
        Text(
          _phone,
          style: TextStyle(
            color: isDark ? AppTheme.darkSubText : AppTheme.subTextColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // ── Stats ───────────────────────────────────────────────────────────────────
  Widget _buildStatsSection(bool isDark) {
    return Row(
      children: [
        Expanded(
            child: _statCard(
                "Total Spent",
                "KES ${_totalSpent.toStringAsFixed(0)}",
                Icons.payments_rounded,
                isDark)),
        const SizedBox(width: 16),
        Expanded(
            child: _statCard(
                "Active Meters", "$_meterCount", Icons.speed_rounded, isDark)),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color:
                      isDark ? AppTheme.darkSubText : AppTheme.subTextColor,
                  fontSize: 12)),
        ],
      ),
    );
  }

  // ── Settings ────────────────────────────────────────────────────────────────
  Widget _buildSettingsSection(bool isDark, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _settingsTile(
            "Dark Mode",
            "Switch to dark theme",
            isDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            themeProvider.isDarkMode,
            (_) => themeProvider.toggleTheme(),
          ),
          const Divider(height: 1),
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
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.group_add_rounded, color: Colors.amber, size: 20),
            ),
            title: const Text("Refer & Earn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text("Invite friends, get free units", style: TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.subTextColor),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_rounded, color: Colors.purple, size: 20),
            ),
            title: const Text("Agent Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text("Manage bulk operations", style: TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.subTextColor),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentDashboardScreen())),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title,
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              color: AppTheme.subTextColor, fontSize: 12)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryColor,
      ),
    );
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      },
      icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
      label: const Text("Sign Out",
          style: TextStyle(
              color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
    );
  }
}
