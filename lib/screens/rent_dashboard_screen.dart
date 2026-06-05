import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/rent_api_service.dart';

class RentDashboardScreen extends StatefulWidget {
  const RentDashboardScreen({super.key});

  @override
  State<RentDashboardScreen> createState() => _RentDashboardScreenState();
}

class _RentDashboardScreenState extends State<RentDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await RentApiService.getDashboardStats();
    final payments = await RentApiService.getPayments();
    if (mounted) {
      setState(() {
        _stats = stats;
        _payments = payments;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Rent Management"),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    const Text(
                      "Rent Actions",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    ),
                    const SizedBox(height: 16),
                    _buildActionsGrid(),
                    const SizedBox(height: 32),
                    const Text(
                      "Recent Payments",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard("Properties", _stats['totalProperties']?.toString() ?? "0", Icons.domain),
        _buildStatCard("Total Units", _stats['totalUnits']?.toString() ?? "0", Icons.door_front_door),
        _buildStatCard("Occupied", _stats['occupiedUnits']?.toString() ?? "0", Icons.people, valueColor: AppTheme.successColor),
        _buildStatCard("Collected", "KES ${_stats['monthlyRentCollected'] ?? 0}", Icons.attach_money, valueColor: AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color valueColor = AppTheme.textColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.subTextColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionsGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionBtn("Property", Icons.add_business, Colors.indigo, () {}),
        _buildActionBtn("Unit", Icons.meeting_room, Colors.teal, () {}),
        _buildActionBtn("Tenant", Icons.person_add, Colors.orange, () {}),
        _buildActionBtn("Payment", Icons.payments, AppTheme.successColor, () {}),
      ],
    );
  }

  Widget _buildActionBtn(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: 85,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList() {
    if (_payments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("No recent payments", style: TextStyle(color: AppTheme.subTextColor)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _payments.length > 5 ? 5 : _payments.length,
      itemBuilder: (context, index) {
        final p = _payments[index];
        final tName = p['tenantId']?['name'] ?? 'Unknown Tenant';
        final amount = p['amount'] ?? 0;
        final date = DateTime.parse(p['date'] ?? DateTime.now().toIso8601String());
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                  const SizedBox(height: 4),
                  Text("${date.day}/${date.month}/${date.year}", style: const TextStyle(fontSize: 12, color: AppTheme.subTextColor)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("KES $amount", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                  const SizedBox(height: 4),
                  Text(p['receiptNumber'] ?? '', style: const TextStyle(fontSize: 10, color: AppTheme.subTextColor, fontFamily: 'Courier')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
