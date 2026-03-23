import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class IssueResolutionScreen extends StatefulWidget {
  const IssueResolutionScreen({super.key});

  @override
  State<IssueResolutionScreen> createState() => _IssueResolutionScreenState();
}

class _IssueResolutionScreenState extends State<IssueResolutionScreen> {
  List<Map<String, String>> _transactions = [];
  bool _isLoading = true;
  String? _selectedTransactionId;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txs = await StorageService.getTransactions();
    if (mounted) {
      setState(() {
        _transactions = txs;
        _isLoading = false;
      });
    }
  }

  void _submitDispute() {
    if (_selectedTransactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a transaction first.")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Filing dispute..."),
          ],
        ),
      )
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context); // close loader
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text("Dispute Filed"),
            ],
          ),
          content: const Text("We have received your issue report. Our team will resolve this payment discrepancy within 2 hours. You will receive an SMS update shortly."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to support
              },
              child: const Text("Done"),
            )
          ],
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quick Resolution"),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark ? [AppTheme.darkBackground, AppTheme.darkSurface] : [AppTheme.backgroundColor, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Select the transaction you have an issue with. We prioritize delayed M-Pesa tokens and failed reversals.",
                              style: TextStyle(color: AppTheme.subTextColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _transactions.isEmpty
                        ? const Center(child: Text("No recent transactions found."))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              // using date + amount as a unique "id" for standard simulation
                              final txId = "${tx['date']}_${tx['amount']}";
                              final isSelected = _selectedTransactionId == txId;
                              final isSuccess = tx['isSuccess'] == 'true';

                              return GestureDetector(
                                onTap: () => setState(() => _selectedTransactionId = txId),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : (isDark ? AppTheme.darkCard : Colors.white),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white12 : Colors.black12),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSuccess ? Icons.bolt_rounded : Icons.error_outline_rounded,
                                        color: isSuccess ? Colors.green : Colors.redAccent,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(tx['title'] ?? "Token Purchase", style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text(tx['date'] ?? "", style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Text(tx['amount'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: _submitDispute,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: AppTheme.accentColor,
                  ),
                  child: const Text("Submit for Resolution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
