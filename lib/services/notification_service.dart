import 'dart:async';

enum NotificationType { paymentSuccess, paymentFailed, meterConnected, meterDisconnected }

class AppNotification {
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;

  AppNotification({
    required this.title,
    required this.message,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _notificationController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationStream => _notificationController.stream;

  final _refreshController = StreamController<void>.broadcast();
  Stream<void> get refreshStream => _refreshController.stream;

  void notify(AppNotification notification) {
    _notificationController.add(notification);
    
    // Also trigger a global refresh for data-heavy components
    _refreshController.add(null);
  }

  void triggerRefresh() {
    _refreshController.add(null);
  }
}
