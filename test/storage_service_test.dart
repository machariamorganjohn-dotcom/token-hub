import 'package:flutter_test/flutter_test.dart';
import 'package:token_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StorageService Login History Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('recordLogin and getLoginHistory work correctly', () async {
      // Initially empty
      expect(await StorageService.getLoginHistory(), isEmpty);

      // Record first login
      await StorageService.recordLogin();
      List<String> history = await StorageService.getLoginHistory();
      expect(history.length, 1);
      
      // Wait a bit to ensure a different timestamp if we cared, but toIso8601String is precise enough
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Record second login
      await StorageService.recordLogin();
      history = await StorageService.getLoginHistory();
      expect(history.length, 2);
      
      // Verify most recent is first
      expect(DateTime.parse(history[0]).isAfter(DateTime.parse(history[1])), isTrue);
    });

    test('history limit is enforced', () async {
      for (int i = 0; i < 15; i++) {
        await StorageService.recordLogin();
      }
      
      final history = await StorageService.getLoginHistory();
      expect(history.length, 10); // Limit is 10
    });
  });
}
