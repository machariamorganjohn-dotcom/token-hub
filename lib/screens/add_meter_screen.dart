import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../theme/app_theme.dart';

import '../services/storage_service.dart';
import '../services/smart_meter_service.dart';

class AddMeterScreen extends StatefulWidget {
  const AddMeterScreen({super.key});

  @override
  State<AddMeterScreen> createState() => _AddMeterScreenState();
}

class _AddMeterScreenState extends State<AddMeterScreen> {
  final meterController = TextEditingController();
  final nickNameController = TextEditingController();
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Meter"),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundColor, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings_input_component_rounded, size: 48, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Register a Meter",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      "Link aew meter to your account for real-time remote management from any distance.",
                      style: TextStyle(color: AppTheme.subTextColor, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      controller: meterController,
                      label: "Meter Number",
                      icon: Icons.offline_bolt_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: nickNameController,
                      label: "Meter Nickname",
                      icon: Icons.label_important_rounded,
                    ),
                    const SizedBox(height: 60),
                    ElevatedButton(
                      onPressed: _isConnecting ? null : _handleAddMeter,
                      style: ElevatedButton.styleFrom(
                        elevation: 8,
                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                      child: const Text("Add & Connect"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isConnecting)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    SizedBox(height: 24),
                    Text(
                      "Initializing Remote Link...",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Securing connection over network",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleAddMeter() async {
    final meterNumber = meterController.text.trim();
    final nickName = nickNameController.text.trim();

    if (meterNumber.isEmpty || nickName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      await StorageService.saveMeter(nickName, meterNumber);
      // Connect immediately (Remote IoT-style)
      await SmartMeterService().connect(meterNumber);
      
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Meter added and linked successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}
