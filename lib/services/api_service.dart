import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth
  static Future<http.Response> login(String phone, String password) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
  }

  static Future<http.Response> register(Map<String, dynamic> userData) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
  }

  static Future<http.Response> syncBalance(String userId) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/sync-balance'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId}),
    );
  }

  static Future<http.Response> setupMeter(String userId, double initialUnits) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/setup-meter'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId, 'initialUnits': initialUnits}),
    );
  }

  // Meters
  static Future<http.Response> getMeters() async {
    return await http.get(
      Uri.parse('$baseUrl/meters'),
      headers: await _getHeaders(),
    );
  }

  static Future<http.Response> addMeter(String name, String number) async {
    return await http.post(
      Uri.parse('$baseUrl/meters'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name, 'number': number}),
    );
  }

  // Transactions
  static Future<http.Response> getTransactions() async {
    return await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: await _getHeaders(),
    );
  }

  static Future<http.Response> initiateStkPush(double amount, String meterNumber, String phoneNumber) async {
    return await http.post(
      Uri.parse('$baseUrl/transactions/stkpush'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'amount': amount,
        'meterNumber': meterNumber,
        'phoneNumber': phoneNumber,
      }),
    );
  }

  static Future<http.Response> requestSos(String meterNumber) async {
    return await http.post(
      Uri.parse('$baseUrl/transactions/sos'),
      headers: await _getHeaders(),
      body: jsonEncode({'meterNumber': meterNumber}),
    );
  }
}
