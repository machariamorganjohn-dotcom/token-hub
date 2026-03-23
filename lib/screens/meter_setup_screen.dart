import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'dashboard_screen.dart';

class MeterSetupScreen extends StatefulWidget {
  const MeterSetupScreen({super.key});

  @override
  State<MeterSetupScreen> createState() => _MeterSetupScreenState();
}

class _MeterSetupScreenState extends State<MeterSetupScreen> {
  String _units = "";
  bool _isLoading = false;

  void _onKeyPress(String value) {
    if (_units.length >= 7 && value != "back") return;
    setState(() {
      if (value == "back") {
        if (_units.isNotEmpty) _units = _units.substring(0, _units.length - 1);
      } else if (value == ".") {
        if (!_units.contains(".")) _units += value;
      } else {
        _units += value;
      }
    });
  }

  Future<void> _handleSave() async {
    if (_units.isEmpty) return;
    final units = double.tryParse(_units);
    if (units == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = await StorageService.getUserId();
      if (userId == null) throw Exception("User not logged in");

      final response = await ApiService.setupMeter(userId, units);
      if (response.statusCode == 200) {
        await StorageService.saveBalance(units);
        await StorageService.saveSetupDone(true);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        throw Exception("Failed to save units");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 64),
            const SizedBox(height: 24),
            const Text(
              "Initial Meter Setup",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Enter the current units displayed on your physical KPLC meter to sync your phone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const Spacer(),
            _buildDisplay(),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: _isLoading || _units.isEmpty ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("FINISH SETUP", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _units.isEmpty ? "0.00" : _units,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier', // Segmented feel
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Units",
            style: TextStyle(color: Colors.white38, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildRow(["1", "2", "3"]),
        const SizedBox(height: 20),
        _buildRow(["4", "5", "6"]),
        const SizedBox(height: 20),
        _buildRow(["7", "8", "9"]),
        const SizedBox(height: 20),
        _buildRow([".", "0", "back"]),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    return InkWell(
      onTap: () => _onKeyPress(key),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: key == "back"
              ? const Icon(Icons.backspace_outlined, color: Colors.white)
              : Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
