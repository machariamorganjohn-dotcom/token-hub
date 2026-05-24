import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  // ── Environment Configuration ──────────────────────────────────────────────
  static const bool isProduction = true; // SET TO TRUE FOR NATIONWIDE ACCESS
  
  // Replace with your real cloud domain (e.g., https://token-hub-backend.onrender.com)
  static const String prodUrl = "https://token-hub-backend.onrender.com/api";
  static const String devUrl = "http://192.168.8.159:5000/api";

  static String get baseUrl => isProduction ? prodUrl : devUrl;
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Clear & Fast Communication Helper
  static Future<http.Response> _safeRequest(Future<http.Response> Function() request, {int retries = 2}) async {
    int attempts = 0;
    while (attempts <= retries) {
      try {
        final response = await request();
        // If server is starting up or has a transient error, retry
        if (response.statusCode >= 500 && attempts < retries) {
          throw Exception("Server transient error");
        }
        return response;
      } catch (e) {
        attempts++;
        if (attempts > retries) {
          return http.Response(jsonEncode({'message': 'Network unstable. Please check your connection.'}), 503);
        }
        // Wait longer between each retry (2s, 4s...)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    return http.Response(jsonEncode({'message': 'Communication failed'}), 500);
  }

  // Auth
  static Future<http.Response> login(String phone, String password) async {
    return _safeRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      ).timeout(const Duration(seconds: 25));
    });
  }

  static Future<http.Response> register(Map<String, dynamic> userData) async {
    return _safeRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 40));
    });
  }

  static Future<http.Response> syncBalance(String userId) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/auth/sync-balance'),
        headers: await _getHeaders(),
        body: jsonEncode({'userId': userId}),
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      return http.Response(jsonEncode({'balance': 0.0}), 503);
    }
  }

  static Future<http.Response> setupMeter(String userId, double initialUnits) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/auth/setup-meter'),
        headers: await _getHeaders(),
        body: jsonEncode({'userId': userId, 'initialUnits': initialUnits}),
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      return http.Response(jsonEncode({'message': 'Failed to setup meter. Connection error: ${e.toString()}'}), 503);
    }
  }

  // Meters
  static Future<http.Response> getMeters() async {
    try {
      return await http.get(
        Uri.parse('$baseUrl/meters'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      return http.Response(jsonEncode([]), 503);
    }
  }

  static Future<http.Response> addMeter(String name, String number) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/meters'),
        headers: await _getHeaders(),
        body: jsonEncode({'name': name, 'number': number}),
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      return http.Response(jsonEncode({'message': 'Failed to add meter. Connection error: ${e.toString()}'}), 503);
    }
  }

  // Transactions
  static Future<http.Response> getTransactions() async {
    try {
      return await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      return http.Response(jsonEncode([]), 503);
    }
  }

  static Future<http.Response> getTransactionStatus(String transactionId) async {
    try {
      return await http.get(
        Uri.parse('$baseUrl/transactions/status/$transactionId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      return http.Response(jsonEncode({'message': 'Status check failed: ${e.toString()}'}), 503);
    }
  }

  static Future<http.Response> updateBalance(String userId, double newBalance) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/auth/update-balance'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'newBalance': newBalance,
        }),
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      return http.Response(jsonEncode({'message': 'Failed to update balance. Connection error: ${e.toString()}'}), 503);
    }
  }

  static Future<http.Response> initiateStkPush(double amount, String meterNumber, String phoneNumber) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/transactions/stkpush'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'amount': amount,
          'meterNumber': meterNumber,
          'phoneNumber': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      return http.Response(jsonEncode({'message': 'M-Pesa request failed. Connection error: ${e.toString()}'}), 503);
    }
  }

  static Future<http.Response> requestSos(String meterNumber) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/transactions/sos'),
        headers: await _getHeaders(),
        body: jsonEncode({'meterNumber': meterNumber}),
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      return http.Response(jsonEncode({'message': 'SOS request failed. Connection error: ${e.toString()}'}), 503);
    }
  }

  // Password Reset
  static Future<http.Response> forgotPassword(String email) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 30));
    } catch (e) {
      return http.Response(jsonEncode({'message': 'Request failed: ${e.toString()}'}), 503);
    }
  }

  static Future<http.Response> resetPassword(String email, String code, String newPassword) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));
    } catch (e) {
      return http.Response(jsonEncode({'message': 'Reset failed: ${e.toString()}'}), 503);
    }
  }
}
