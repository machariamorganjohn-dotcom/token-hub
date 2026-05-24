import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAllPermissions() async {
    // Request multiple permissions at once
    await [
      Permission.camera,
      Permission.notification,
      Permission.locationWhenInUse,
      Permission.systemAlertWindow,
    ].request();

    // Specific handling for System Alert Window (Overlay) on Android
    if (await Permission.systemAlertWindow.isDenied) {
      // On some Android versions, this might need manual redirection to settings
      // for now we just request it.
    }
  }

  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  static Future<bool> hasLocationPermission() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  static Future<bool> hasOverlayPermission() async {
    return await Permission.systemAlertWindow.isGranted;
  }
}
