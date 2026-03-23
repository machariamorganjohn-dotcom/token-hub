import 'dart:async';
import 'dart:math';

enum ConnectionType { wifi, mobile, none }

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get onNetworkChange => _statusController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Simulates an initial network check
  Future<bool> checkConnectivity() async {
    // 98% of the time simulate being online to prevent blocking the user constantly, 
    // but allow 2% failure for realistic mock.
    _isOnline = Random().nextDouble() > 0.02;
    _statusController.add(_isOnline);
    return _isOnline;
  }

  /// Forces the network state (useful for simulating drops in UI)
  void setSimulatedNetworkState(bool isOnline) {
    _isOnline = isOnline;
    _statusController.add(_isOnline);
  }
}
