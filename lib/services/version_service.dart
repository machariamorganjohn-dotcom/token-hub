import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class VersionService {
  static const String currentAppVersion = "1.2.0";
  
  static Future<Map<String, dynamic>> checkUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(ApiService.baseUrl.replaceFirst('/api', '')),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version'] ?? currentAppVersion;
        final minRequired = data['minRequiredVersion'] ?? "1.0.0";

        bool needsUpdate = _isVersionLower(currentAppVersion, latestVersion);
        bool isForceUpdate = _isVersionLower(currentAppVersion, minRequired);

        return {
          'canUpdate': needsUpdate,
          'isForce': isForceUpdate,
          'latestVersion': latestVersion,
        };
      }
    } catch (_) {
      // If server is unreachable, we don't block the user unless it's a critical app error
    }
    return {'canUpdate': false, 'isForce': false};
  }

  static bool _isVersionLower(String current, String target) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> targetParts = target.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (targetParts[i] > currentParts[i]) return true;
      if (targetParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
