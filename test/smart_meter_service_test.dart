import 'package:flutter_test/flutter_test.dart';
import 'package:token_hub/services/smart_meter_service.dart';
import 'package:token_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SmartMeterService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('connect and persistence work correctly', () async {
      final service = SmartMeterService();
      
      // Initially disconnected
      expect(service.currentStatus, MeterConnectionStatus.disconnected);
      expect(await StorageService.getActiveMeter(), isNull);

      // Connect
      await service.connect('123456');
      
      expect(service.currentStatus, MeterConnectionStatus.connected);
      expect(service.connectedMeterNumber, '123456');
      expect(await StorageService.getActiveMeter(), '123456');
    });

    test('syncBalance returns value', () async {
      final service = SmartMeterService();
      await StorageService.saveBalance(100.0);
      
      final balance = await service.syncBalance();
      expect(balance, 100.0);
    });
  });
}
