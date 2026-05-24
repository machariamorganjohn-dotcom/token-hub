import 'dart:async';
import 'dart:math';
import 'package:local_auth/local_auth.dart';

/// A service dedicated to protecting the app from theft, piracy, and system vulnerabilities.
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  bool _isSystemIntegrityCompromised = false;
  bool _biometricsEnabled = true;

  bool get isSystemIntegrityCompromised => _isSystemIntegrityCompromised;
  bool get biometricsEnabled => _biometricsEnabled;

  /// Checks for rooted/jailbroken devices and other security threats.
  Future<void> performIntegrityCheck() async {
    // Simulated deep-system checks
    await Future.delayed(const Duration(seconds: 1));
    
    // logic to detect root/jailbreak (simulated)
    // In a real app, use packages like 'flutter_jailbreak_detection'
    _isSystemIntegrityCompromised = false; 
  }

  /// Authenticates using the device's lock screen security (Biometrics/PIN/Pattern).
  Future<bool> authenticateWithBiometrics() async {
    if (!_biometricsEnabled) return false;
    
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to proceed with Token Hub security check',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  void setBiometricsEnabled(bool enabled) {
    _biometricsEnabled = enabled;
  }

  /// Simulates hardware-level encryption (Keystore/Keychain).
  String encryptData(String plainText) {
    // In a real app, this would be handled by the OS-level secure storage.
    // Here we simulate it with a Base64-style obfuscation + salt.
    final salt = "token_hub_secure_v1";
    final bytes = plainText.codeUnits;
    final salted = bytes.map((b) => b ^ 42).toList();
    return "ENC_${salted.join('.')}_$salt";
  }

  /// Simulates hardware-level decryption.
  String decryptData(String encryptedText) {
    try {
      if (!encryptedText.startsWith("ENC_")) return encryptedText;
      final parts = encryptedText.split('_');
      final numbers = parts[1].split('.').map(int.parse).toList();
      final decrypted = String.fromCharCodes(numbers.map((n) => n ^ 42));
      return decrypted;
    } catch (e) {
      return "";
    }
  }

  /// Verifies the "Encrypted Tunnel" for IoT communication.
  bool verifySecureTunnel(String packetId) {
    // logic to verify HMAC or similar (simulated)
    return packetId.startsWith("TLS_HUB_");
  }

  /// Generates a secure packet ID for IoT communication.
  String generateSecurePacketId() {
    final random = Random();
    final hex = List.generate(16, (index) => random.nextInt(16).toRadixString(16)).join();
    return "TLS_HUB_$hex";
  }
}
