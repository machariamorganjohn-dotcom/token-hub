import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_service.dart';

class StorageService {
  static const String keyBalance = 'user_balance';
  static const String keyUserName = 'user_name';
  static const String keyUserPhone = 'user_phone';
  static const String keyMeters = 'saved_meters';
  static const String keyTransactions = 'user_transactions';
  static const String keyLoginHistory = 'login_history';
  static const String keyActiveMeter = 'active_meter';
  static const String keyTheme = 'app_theme_dark';
  static const String keyProfileImage = 'profile_image_path';
  static const String keyHasEverRegistered = 'has_ever_registered';
  static const String keyUserEmail = 'user_email';
  static const String keyEmergencyDebt = 'emergency_debt';
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keySetupDone = 'is_setup_done';

  static Future<void> saveBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    await prefs.setString(keyBalance, security.encryptData(balance.toString()));
  }

  static Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    final encrypted = prefs.getString(keyBalance);
    if (encrypted == null) return 45.2;
    try {
      final decrypted = security.decryptData(encrypted);
      return double.tryParse(decrypted) ?? 45.2;
    } catch (e) {
      return 45.2;
    }
  }

  // ── Emergency Debt ────────────────────────────────────────────────────────
  static Future<void> saveEmergencyDebt(double debtAmount) async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    await prefs.setString(keyEmergencyDebt, security.encryptData(debtAmount.toString()));
  }

  static Future<double> getEmergencyDebt() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(keyEmergencyDebt);
    if (encrypted == null) return 0.0;
    try {
      final security = SecurityService();
      final decrypted = security.decryptData(encrypted);
      return double.tryParse(decrypted) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<void> saveUserData(String name, String phone, {String email = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    await prefs.setString(keyUserName, security.encryptData(name));
    await prefs.setString(keyUserPhone, security.encryptData(phone));
    if (email.isNotEmpty) {
      await prefs.setString(keyUserEmail, security.encryptData(email));
    }
    // Mark that an account has ever been created on this device
    await prefs.setBool(keyHasEverRegistered, true);
  }

  static Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    final encryptedName = prefs.getString(keyUserName);
    final encryptedPhone = prefs.getString(keyUserPhone);
    final encryptedEmail = prefs.getString(keyUserEmail);
    
    return {
      'name': encryptedName != null ? security.decryptData(encryptedName) : 'User',
      'phone': encryptedPhone != null ? security.decryptData(encryptedPhone) : '',
      'email': encryptedEmail != null ? security.decryptData(encryptedEmail) : '',
    };
  }

  // ── Theme helpers ──────────────────────────────────────────────────────────
  static Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyTheme, isDark);
  }

  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyTheme) ?? true; // default to dark on first launch
  }

  // ── Profile image helpers ──────────────────────────────────────────────────
  static Future<void> saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyProfileImage, path);
  }

  static Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyProfileImage);
  }

  // ── Registration flag ──────────────────────────────────────────────────────
  /// Returns true if the user has EVER completed signup on any install of this app.
  static Future<bool> hasEverRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyHasEverRegistered) ?? false;
  }

  // Transaction Storage
  static Future<void> saveTransaction(Map<String, String> transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    List<Map<String, String>> transactions = await getTransactions();
    transactions.insert(0, transaction); // Most recent first
    
    final jsonStr = jsonEncode(transactions);
    await prefs.setString(keyTransactions, security.encryptData(jsonStr));
  }

  static Future<List<Map<String, String>>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    final String? encrypted = prefs.getString(keyTransactions);
    if (encrypted == null) return [];
    
    try {
      final decrypted = security.decryptData(encrypted);
      final List<dynamic> decoded = jsonDecode(decrypted);
      return decoded.map((m) => Map<String, String>.from(m)).toList();
    } catch (e) {
      return [];
    }
  }

  // Meter Storage
  static Future<void> saveMeter(String name, String number) async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    List<Map<String, String>> meters = await getMeters();
    
    final existingIndex = meters.indexWhere((m) => m['number'] == number);
    
    if (existingIndex != -1) {
      meters[existingIndex]['name'] = name;
    } else {
      meters.add({'name': name, 'number': number});
    }
    
    // Encrypt the entire collection or per item - per collection is easier for simulation
    final jsonStr = jsonEncode(meters);
    await prefs.setString(keyMeters, security.encryptData(jsonStr));
  }

  static Future<List<Map<String, String>>> getMeters() async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    final String? encrypted = prefs.getString(keyMeters);
    if (encrypted == null) return [];
    
    try {
      final decrypted = security.decryptData(encrypted);
      final List<dynamic> decoded = jsonDecode(decrypted);
      return decoded.map((m) => Map<String, String>.from(m)).toList();
    } catch (e) {
      return [];
    }
  }

  // Login History Storage
  static Future<void> recordLogin() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = await getLoginHistory();
    String now = DateTime.now().toIso8601String();
    history.insert(0, now);
    // Keep only last 10 logins
    if (history.length > 10) {
      history = history.sublist(0, 10);
    }
    await prefs.setStringList(keyLoginHistory, history);
  }

  static Future<List<String>> getLoginHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(keyLoginHistory) ?? [];
  }

  static Future<void> saveActiveMeter(String? number) async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    if (number == null) {
      await prefs.remove(keyActiveMeter);
    } else {
      await prefs.setString(keyActiveMeter, security.encryptData(number));
    }
  }

  static Future<String?> getActiveMeter() async {
    final prefs = await SharedPreferences.getInstance();
    final security = SecurityService();
    final encrypted = prefs.getString(keyActiveMeter);
    return encrypted != null ? security.decryptData(encrypted) : null;
  }

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await SharedPreferences.getInstance();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Token & Auth Management ────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  static Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserId, id);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserId);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  static Future<void> saveSetupDone(bool done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySetupDone, done);
  }

  static Future<bool> isSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keySetupDone) ?? false;
  }
}
