import 'package:flutter/material.dart';
import '../widgets/transaction_tile.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, String>> _transactions = [];
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _refreshSubscription = NotificationService().refreshStream.listen((_) {
      if (mounted) _loadHistory();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final transactions = await StorageService.getTransactions();
    if (mounted) {
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadHistory,
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  itemCount: _transactions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 32, top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Activity Log",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Complete record of your tokens and syncs.",
                              style: TextStyle(color: AppTheme.subTextColor, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }
                    final tx = _transactions[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TransactionTile(
                        title: tx['title'] ?? "Token Purchase",
                        date: tx['date'] ?? "",
                        amount: tx['amount'] ?? "",
                        isSuccess: tx['isSuccess'] == 'true',
                        token: tx['token'],
                      ),
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          const Text(
            "Clean Slate",
            style: TextStyle(color: AppTheme.textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your transactions will appear here.",
            style: TextStyle(color: AppTheme.subTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
