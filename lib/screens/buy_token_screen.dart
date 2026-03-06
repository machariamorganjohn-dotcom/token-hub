import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/smart_meter_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';

class BuyTokenScreen extends StatefulWidget {
  const BuyTokenScreen({super.key});

  @override
  State<BuyTokenScreen> createState() => _BuyTokenScreenState();
}

class _BuyTokenScreenState extends State<BuyTokenScreen> {
  final meterController = TextEditingController();
  final amountController = TextEditingController();
  final _paymentService = PaymentService();
  
  PaymentMethod _selectedMethod = PaymentMethod.mpesa;
  PaymentStatus _paymentStatus = PaymentStatus.idle;
  List<Map<String, String>> _savedMeters = [];
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadMeters();
    _statusSubscription = _paymentService.paymentStatusStream.listen((status) {
      if (mounted) {
        setState(() => _paymentStatus = status);
        if (status == PaymentStatus.success) {
          _handlePaymentSuccess();
        } else if (status == PaymentStatus.failed) {
          _handlePaymentFailure();
        }
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _paymentService.reset();
    super.dispose();
  }

  Future<void> _loadMeters() async {
    final meters = await StorageService.getMeters();
    setState(() {
      _savedMeters = meters;
      if (_savedMeters.isNotEmpty && meterController.text.isEmpty) {
        meterController.text = _savedMeters.first['number']!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Purchase Tokens"),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundColor, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildMeterSelection(),
                  const SizedBox(height: 24),
                  _buildAmountInput(),
                  const SizedBox(height: 32),
                  _buildPaymentMethods(),
                  const SizedBox(height: 24),
                  _buildSimulationButton(),
                  const SizedBox(height: 48),
                  _buildPurchaseButton(),
                ],
              ),
            ),
          ),
          
          if (_paymentStatus == PaymentStatus.pending)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Power Up",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Instant tokens for your smart meter across any platform.",
          style: TextStyle(color: AppTheme.subTextColor, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMeterSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Target Meter",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: meterController,
          label: "Meter Number",
          icon: Icons.speed_rounded,
          keyboardType: TextInputType.number,
        ),
        if (_savedMeters.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _savedMeters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final meter = _savedMeters[index];
                final isSelected = meterController.text == meter['number'];
                return ChoiceChip(
                  label: Text(meter['name']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => meterController.text = meter['number']!);
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  checkmarkColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.subTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Amount to Buy",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: amountController,
          label: "Amount (KES)",
          icon: Icons.payments_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ["500", "1000", "2000", "5000"].map((amt) => _quickAmtChip(amt)).toList(),
        ),
      ],
    );
  }

  Widget _quickAmtChip(String amount) {
    bool isSelected = amountController.text == amount;
    return GestureDetector(
      onTap: () => setState(() => amountController.text = amount),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Text(
          "KES $amount",
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.subTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Payment Platform",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _paymentTile(
          PaymentMethod.mpesa,
          "M-Pesa STK",
          "Kenya's favorite mobile wallet",
          Icons.phone_android_rounded,
          AppTheme.mpesaColor,
        ),
        const SizedBox(height: 12),
        _paymentTile(
          PaymentMethod.card,
          "Credit / Debit Card",
          "Visa, Mastercard or Amex",
          Icons.credit_card_rounded,
          AppTheme.visaColor,
        ),
        const SizedBox(height: 12),
        _paymentTile(
          PaymentMethod.bank,
          "Bank Transfer",
          "EFT & Direct Deposit",
          Icons.account_balance_rounded,
          AppTheme.bankColor,
        ),
      ],
    );
  }

  Widget _paymentTile(PaymentMethod method, String title, String subtitle, IconData icon, Color color) {
    bool isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () => _handlePaymentSuccess(isSimulation: true),
        icon: const Icon(Icons.science_rounded, size: 18),
        label: const Text("Purchase Now (Simulation Mode)"),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.subTextColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return ElevatedButton(
      onPressed: _startPayment,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 64),
        elevation: 8,
        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Connect & Pay Now"),
          SizedBox(width: 12),
          Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    String message = "Waiting for M-Pesa PIN...";
    if (_selectedMethod == PaymentMethod.card) message = "Securely Processing Card...";
    if (_selectedMethod == PaymentMethod.bank) message = "Verifying Bank Details...";

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please do not close the app",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _startPayment() {
    final amount = double.tryParse(amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid amount")));
      return;
    }
    if (meterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a meter number")));
      return;
    }

    _paymentService.processPayment(method: _selectedMethod, amount: amount);
  }

  Future<void> _handlePaymentSuccess({bool isSimulation = false}) async {
    final amount = double.parse(amountController.text);
    final currentBalance = await StorageService.getBalance();
    // 1 KES = 0.05 units simulation
    final newUnits = amount * 0.05;
    await StorageService.saveBalance(currentBalance + newUnits);

    // Save transaction
    final now = DateTime.now();
    final dateStr = "${now.day} ${_getMonth(now.month)}, ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    
    await StorageService.saveTransaction({
      'title': isSimulation ? 'Token Purchase (SIMULATED)' : 'Token Purchase (${_selectedMethod.name.toUpperCase()})',
      'date': dateStr,
      'amount': 'KES ${amount.toStringAsFixed(0)}',
      'units': '${newUnits.toStringAsFixed(2)} Units',
      'meter': meterController.text,
      'isSuccess': 'true',
    });

    // IMMEDIATE SYNERGY UPDATES
    SmartMeterService().notifyBalanceChanged();
    NotificationService().notify(AppNotification(
      title: isSimulation ? "Simulation: Success" : "Payment Successful",
      message: "KES ${amount.toStringAsFixed(0)} tokens added to meter ${meterController.text}",
      type: NotificationType.paymentSuccess,
    ));

    if (mounted) {
      _showSuccessDialog(context, amount.toStringAsFixed(0), newUnits.toStringAsFixed(2), dateStr, isSimulation: isSimulation);
    }
  }

  void _handlePaymentFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Payment failed. Please try again."),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showSuccessDialog(BuildContext context, String amount, String units, String time, {bool isSimulation = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: isSimulation ? Colors.orange : AppTheme.successColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: Center(child: Icon(isSimulation ? Icons.science_rounded : Icons.verified_rounded, color: Colors.white, size: 80)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(isSimulation ? "Simulation Success!" : "Payment Confirmed!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(isSimulation ? "Sandbox Environment" : "Platform: ${_selectedMethod.name.toUpperCase()}", style: TextStyle(color: isSimulation ? Colors.orange : AppTheme.successColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      children: [
                        _receiptRow("Amount Paid", "KES $amount"),
                        const Divider(height: 24),
                        _receiptRow("Units Added", "$units Units"),
                        const Divider(height: 24),
                        _receiptRow("Timestamp", time),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text("Done"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
