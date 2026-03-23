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

  /// Initiates a payment via the backend API.
  Future<void> processPayment({
    required PaymentMethod method,
    required double amount,
    Map<String, String>? details,
  }) async {
    _paymentStatusController.add(PaymentStatus.pending);
    
    // For now, we only handle M-Pesa backend integration
    if (method == PaymentMethod.mpesa) {
      try {
        final userData = await StorageService.getUserData();
        final meterNumber = details?['meterNumber'] ?? '';
        final phone = userData['phone'] ?? '';

        final response = await ApiService.initiateStkPush(amount, meterNumber, phone);
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // The backend returns a transaction and new balance
          await StorageService.saveBalance((data['newBalance'] ?? 0).toDouble());
          
          _paymentStatusController.add(PaymentStatus.success);
        } else {
          _paymentStatusController.add(PaymentStatus.failed);
        }
      } catch (e) {
        _paymentStatusController.add(PaymentStatus.failed);
      }
    } else {
      // Mock for others
      await Future.delayed(const Duration(seconds: 3));
      _paymentStatusController.add(PaymentStatus.success);
    }
  }

  void reset() {
    _paymentStatusController.add(PaymentStatus.idle);
  }
}
