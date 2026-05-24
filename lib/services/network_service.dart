import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_service.dart';

enum ConnectionType { wifi, mobile, none }

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get onNetworkChange => _statusController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Performs a real connectivity check by pinging a reliable endpoint.
  Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('https://clients3.google.com/generate_204'),
      ).timeout(const Duration(seconds: 5));
      _isOnline = response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      _isOnline = false;
    }
    _statusController.add(_isOnline);
    return _isOnline;
  }

  /// Forces the network state (useful for testing or manual overrides)
  void setSimulatedNetworkState(bool isOnline) {
    _isOnline = isOnline;
    _statusController.add(_isOnline);
  }

  /// Verifies if the backend server is actually reachable
  Future<bool> isBackendReachable() async {
    try {
      final response = await http.get(
        Uri.parse(ApiService.baseUrl.replaceFirst('/api', '')),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
