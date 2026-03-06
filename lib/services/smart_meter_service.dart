import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'security_service.dart';

enum MeterConnectionStatus { disconnected, connecting, connected, remote }

class MeterData {
  final double currentUnits;
  final double voltage;
  final double load;
  final String timestamp;

  MeterData({
    required this.currentUnits,
    required this.voltage,
    required this.load,
    required this.timestamp,
  });
}

class SmartMeterService {
  static final SmartMeterService _instance = SmartMeterService._internal();
  factory SmartMeterService() => _instance;
  SmartMeterService._internal();

  final _statusController = StreamController<MeterConnectionStatus>.broadcast();
  Stream<MeterConnectionStatus> get statusStream => _statusController.stream;

  final _dataController = StreamController<MeterData>.broadcast();
  Stream<MeterData> get dataStream => _dataController.stream;

  final _networkController = StreamController<bool>.broadcast();
  Stream<bool> get networkStream => _networkController.stream;

  MeterConnectionStatus _currentStatus = MeterConnectionStatus.disconnected;
  MeterConnectionStatus get currentStatus => _currentStatus;

  String? _connectedMeterNumber;
  String? get connectedMeterNumber => _connectedMeterNumber;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _heartbeatTimer;
  final Random _random = Random();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    // Simulate periodic network check
    Timer.periodic(const Duration(seconds: 10), (timer) {
      _isOnline = _random.nextDouble() > 0.05; // 95% up-time simulation
      _networkController.add(_isOnline);
    });

    final activeMeter = await StorageService.getActiveMeter();
    if (activeMeter != null) {
      await connect(activeMeter, notify: false);
    }
  }

  Future<void> connect(String meterNumber, {bool notify = true}) async {
    if (!_isOnline) {
      throw Exception("No internet connection available (WiFi/Mobile Data required)");
    }

    _currentStatus = MeterConnectionStatus.connecting;
    _statusController.add(_currentStatus);

    // Simulate high-end remote handshake (Cloud IoT)
    await Future.delayed(const Duration(seconds: 3));

    _currentStatus = MeterConnectionStatus.remote;
    _connectedMeterNumber = meterNumber;
    await StorageService.saveActiveMeter(meterNumber);
    _statusController.add(_currentStatus);
    
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_currentStatus == MeterConnectionStatus.remote && _isOnline) {
        final currentBalance = await StorageService.getBalance();
        // Simulate real-time usage (minor consumption)
        final consumption = 0.001 + _random.nextDouble() * 0.005;
        final newBalance = max(0.0, currentBalance - consumption);
        await StorageService.saveBalance(newBalance);

        _emitCurrentData(newBalance);
      }
    });
  }

  Future<bool> disconnect(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Disconnect Smart Meter?"),
        content: const Text("Remote communication will be cut off. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Connected"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(100, 40),
            ),
            child: const Text("Disconnect"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _heartbeatTimer?.cancel();
      _currentStatus = MeterConnectionStatus.disconnected;
      _connectedMeterNumber = null;
      await StorageService.saveActiveMeter(null);
      _statusController.add(_currentStatus);
      return true;
    }
    return false;
  }

  Future<double> syncBalance() async {
    if (!_isOnline) throw Exception("Network required for remote sync");
    
    // Remote fetch via "Greater Distance" IoT endpoint
    await Future.delayed(const Duration(seconds: 2));
    final balance = await StorageService.getBalance();
    _emitCurrentData(balance);
    return balance;
  }

  Future<void> notifyBalanceChanged() async {
    if (_currentStatus == MeterConnectionStatus.remote && _isOnline) {
      final balance = await StorageService.getBalance();
      _emitCurrentData(balance);
    }
  }

  void _emitCurrentData(double balance) {
    final security = SecurityService();
    final packetId = security.generateSecurePacketId();
    
    // Simulate secure tunnel validation
    if (security.verifySecureTunnel(packetId)) {
      _dataController.add(MeterData(
        currentUnits: balance,
        voltage: 230.0 + (_random.nextDouble() * 10 - 5),
        load: 0.5 + _random.nextDouble() * 2.0,
        timestamp: DateTime.now().toIso8601String(),
      ));
    }
  }
}
