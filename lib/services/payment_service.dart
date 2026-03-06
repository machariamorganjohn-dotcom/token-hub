import 'dart:async';
import 'dart:math';

enum PaymentMethod { mpesa, card, bank }
enum PaymentStatus { idle, pending, success, failed }

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _paymentStatusController = StreamController<PaymentStatus>.broadcast();
  Stream<PaymentStatus> get paymentStatusStream => _paymentStatusController.stream;

  /// Initiates a payment simulation for the selected platform.
  Future<void> processPayment({
    required PaymentMethod method,
    required double amount,
    Map<String, String>? details,
  }) async {
    _paymentStatusController.add(PaymentStatus.pending);
    
    // Simulate gateway handshakes
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate user interaction (PIN entry, Card OTP, etc.)
    _simulateGatewayResponse(method);
  }

  void _simulateGatewayResponse(PaymentMethod method) async {
    final random = Random();
    
    // Simulate specific platform behavior
    int delaySeconds = 3;
    if (method == PaymentMethod.mpesa) delaySeconds = 8; // M-Pesa PIN takes longer
    
    await Future.delayed(Duration(seconds: delaySeconds));
    
    // 95% success rate for high-end simulation
    final isSuccess = random.nextDouble() > 0.05;
    
    if (isSuccess) {
      _paymentStatusController.add(PaymentStatus.success);
    } else {
      _paymentStatusController.add(PaymentStatus.failed);
    }
  }

  void reset() {
    _paymentStatusController.add(PaymentStatus.idle);
  }
}
