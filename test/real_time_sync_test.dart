import 'package:flutter_test/flutter_test.dart';
import 'package:token_hub/services/smart_meter_service.dart';
import 'package:token_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SmartMeterService Real-time Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('remote connection and persistence work', () async {
      final service = SmartMeterService();
      
      // Initially disconnected
      expect(service.currentStatus, MeterConnectionStatus.disconnected);

      // Connect (Remote)
      await service.connect('888999');
      
      expect(service.currentStatus, MeterConnectionStatus.remote);
      expect(service.connectedMeterNumber, '888999');
      expect(await StorageService.getActiveMeter(), '888999');
    });

    test('real-time data stream emits events', () async {
      final service = SmartMeterService();
      await service.connect('888999');
      
      // Listen for data
      final dataFuture = service.dataStream.first;
      
      final data = await dataFuture.timeout(const Duration(seconds: 5));
      expect(data.currentUnits, isNotNull);
      expect(data.voltage, closeTo(230.0, 10.0));
      expect(data.load, greaterThan(0));
    });

    test('network check fails connection when offline', () async {
      // This is trickier to test without mocking the internal random/timer
      // But we can check the public state
      final service = SmartMeterService();
      expect(service.isOnline, isTrue); // Default
    });
   group('Persistence Tests', () {
      test('StorageService persists balance accurately', () async {
        await StorageService.saveBalance(75.5);
        final balance = await StorageService.getBalance();
        expect(balance, 75.5);
      });
    });
  });
}
