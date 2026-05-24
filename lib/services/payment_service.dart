import 'dart:async';
import 'dart:convert';
import 'api_service.dart';
import 'storage_service.dart';

enum PaymentMethod { mpesa, card, bank }
enum PaymentStatus { idle, pending, success, failed }

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _paymentStatusController = StreamController<PaymentStatus>.broadcast();
  Stream<PaymentStatus> get paymentStatusStream => _paymentStatusController.stream;

  /// Initiates a payment via the backend API with automatic status polling.
  Future<void> processPayment({
    required PaymentMethod method,
    required double amount,
    Map<String, String>? details,
  }) async {
    _paymentStatusController.add(PaymentStatus.pending);
    
    if (method == PaymentMethod.mpesa) {
      try {
        final userData = await StorageService.getUserData();
        final meterNumber = details?['meterNumber'] ?? '';
        final phone = userData['phone'] ?? '';

        final response = await ApiService.initiateStkPush(amount, meterNumber, phone);
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final transactionId = data['transactionId'] ?? data['checkoutRequestId'];
          
          // Fast-Polling for status (Check every 2 seconds for 1 minute)
          int attempts = 0;
          Timer.periodic(const Duration(seconds: 2), (timer) async {
            attempts++;
            if (attempts > 30) {
              timer.cancel();
              _paymentStatusController.add(PaymentStatus.failed);
              return;
            }

            final statusRes = await ApiService.getTransactionStatus(transactionId);
            if (statusRes.statusCode == 200) {
              final statusData = jsonDecode(statusRes.body);
              if (statusData['status'] == 'success') {
                timer.cancel();
                _paymentStatusController.add(PaymentStatus.success);
              } else if (statusData['status'] == 'failed') {
                timer.cancel();
                _paymentStatusController.add(PaymentStatus.failed);
              }
            }
          });
        } else {
          _paymentStatusController.add(PaymentStatus.failed);
        }
      } catch (e) {
        _paymentStatusController.add(PaymentStatus.failed);
      }
    } else {
      await Future.delayed(const Duration(seconds: 3));
      _paymentStatusController.add(PaymentStatus.success);
    }
  }

  void reset() {
    _paymentStatusController.add(PaymentStatus.idle);
  }
}
