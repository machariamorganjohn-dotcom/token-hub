import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../screens/meter_setup_screen.dart';
import '../screens/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  String? _imagePath;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked != null && mounted) {
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
                "Choose Photo Source",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      };

      final response = await ApiService.register(userData);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await StorageService.saveToken(data['token']);
        await StorageService.saveUserId(data['_id']);
        await StorageService.saveUserData(data['name'], data['phone'], email: data['email'] ?? '');
        
        if (_imagePath != null) {
          await StorageService.saveProfileImage(_imagePath!);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MeterSetupScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Registration failed")),
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

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgGradient = isDark
        ? [AppTheme.darkBackground, AppTheme.darkSurface]
        : [AppTheme.backgroundColor, Colors.white];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Avatar picker ──────────────────────────────────────
                      Center(child: _buildAvatarPicker()),

                      const SizedBox(height: 32),

                      // ── Headline ───────────────────────────────────────────
                      Text(
                        "Get Started",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Create your account in seconds.",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppTheme.darkSubText
                              : AppTheme.subTextColor,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Fields ─────────────────────────────────────────────
                      _buildField(
                        controller: _nameController,
                        label: "Full Name",
                        icon: Icons.person_rounded,
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? "Please enter your name"
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _phoneController,
                        label: "Phone Number",
                        icon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? "Please enter your phone"
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _emailController,
                        label: "Email (optional)",
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _passwordController,
                        label: "Password",
                        isVisible: _showPassword,
                        onToggle: () =>
                            setState(() => _showPassword = !_showPassword),
                        validator: (v) =>
                            v == null || v.length < 6
                                ? "Minimum 6 characters"
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _confirmController,
                        label: "Confirm Password",
                        isVisible: _showConfirm,
                        onToggle: () =>
                            setState(() => _showConfirm = !_showConfirm),
                        validator: (v) =>
                            v != _passwordController.text
                                ? "Passwords do not match"
                                : null,
                      ),

                      const SizedBox(height: 40),

                      // ── CTA button ─────────────────────────────────────────
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Create Account"),
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
                          _socialButton(Icons.g_mobiledata_rounded, "Google", () => _submit(), isDark),
                          const SizedBox(width: 16),
                          _socialButton(Icons.apple_rounded, "Apple", () => _submit(), isDark),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Sign-in link ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
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
                                  builder: (_) => const LoginScreen()),
                            ),
                            child: const Text(
                              "Sign In",
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
          ),
        ),
      ),
    );
  }

  // ── Avatar builder ──────────────────────────────────────────────────────────
  Widget _buildAvatarPicker() {
    return GestureDetector(
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white,
              backgroundImage: _imagePath != null
                  ? FileImage(File(_imagePath!))
                  : null,
              child: _imagePath == null
                  ? const Icon(Icons.person_rounded,
                      size: 56, color: AppTheme.primaryColor)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
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
    );
  }

  // ── Input helpers ───────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: AppTheme.subTextColor,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
