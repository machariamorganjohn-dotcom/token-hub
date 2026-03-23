import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'api_service.dart';

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
    
    // Check initial connectivity
    _isOnline = true; // assume online for backend demo
    _networkController.add(_isOnline);

    final activeMeter = await StorageService.getActiveMeter();
    if (activeMeter != null) {
      await connect(activeMeter, notify: false);
    }
  }

  Future<void> connect(String meterNumber, {bool notify = true}) async {
    _currentStatus = MeterConnectionStatus.connecting;
    _statusController.add(_currentStatus);

    // Simulate handshakes with backend/IoT
    await Future.delayed(const Duration(seconds: 2));

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
    try {
      final userId = await StorageService.getUserId();
      if (userId == null) return await StorageService.getBalance();

      final response = await ApiService.syncBalance(userId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double newBalance = (data['balance'] ?? 0).toDouble();
        await StorageService.saveBalance(newBalance);
        _emitCurrentData(newBalance);
        return newBalance;
      }
    } catch (e) {
      // fallback to local if offline
    }
    final balance = await StorageService.getBalance();
    _emitCurrentData(balance);
    return balance;
  }

  /// Syncs meters from the backend and updates local storage
  Future<List<Map<String, String>>> syncMetersFromBackend() async {
    try {
      final response = await ApiService.getMeters();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final meters = data.map((m) => {
          'name': m['name'].toString(),
          'number': m['number'].toString(),
        }).toList();
        
        // Update local storage too for fallback/cache
        for (var m in meters) {
          await StorageService.saveMeter(m['name']!, m['number']!);
        }
        return meters;
      }
    } catch (e) {
      // fallback to local
    }
    return await StorageService.getMeters();
  }

  Future<void> notifyBalanceChanged() async {
    if (_currentStatus == MeterConnectionStatus.remote && _isOnline) {
      final balance = await StorageService.getBalance();
      _emitCurrentData(balance);
    }
  }

  void _emitCurrentData(double balance) {
    _dataController.add(MeterData(
      currentUnits: balance,
      voltage: 230.0 + (_random.nextDouble() * 10 - 5),
      load: 0.5 + _random.nextDouble() * 2.0,
      timestamp: DateTime.now().toIso8601String(),
    ));
  }
}
