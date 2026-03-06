import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_tile.dart';
import '../services/storage_service.dart';
import 'buy_token_screen.dart';
import 'history_screen.dart';
import 'add_meter_screen.dart';
import 'profile_screen.dart';
import 'support_screen.dart';
import '../services/smart_meter_service.dart';
import '../services/security_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  String _userName = "User";
  double _balance = 45.2;
  List<Map<String, String>> _meters = [];
  List<Map<String, String>> _transactions = [];
  String _lastLogin = "";
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isOnline = true;
  MeterConnectionStatus _connectionStatus = MeterConnectionStatus.disconnected;
  MeterData? _liveData;
  final _smartMeterService = SmartMeterService();
  StreamSubscription? _statusSubscription;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _networkSubscription;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    SecurityService().performIntegrityCheck(); // Trigger security audit
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadData();
    _initMeterService();
    _setupNotifications();
  }

  void _setupNotifications() {
    _notificationSubscription = NotificationService().notificationStream.listen((notification) {
      if (mounted) {
        _showAppNotification(notification);
      }
    });

    _refreshSubscription = NotificationService().refreshStream.listen((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _showAppNotification(AppNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(notification.message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: notification.type == NotificationType.paymentSuccess 
            ? AppTheme.successColor 
            : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusSubscription?.cancel();
    _dataSubscription?.cancel();
    _networkSubscription?.cancel();
    _notificationSubscription?.cancel();
    _refreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initMeterService() async {
    await _smartMeterService.init();
    
    _statusSubscription = _smartMeterService.statusStream.listen((status) {
      if (mounted) setState(() => _connectionStatus = status);
    });

    _dataSubscription = _smartMeterService.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          _liveData = data;
          _balance = data.currentUnits;
        });
      }
    });

    _networkSubscription = _smartMeterService.networkStream.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
      }
    });

    if (mounted) {
      setState(() {
        _connectionStatus = _smartMeterService.currentStatus;
        _isOnline = _smartMeterService.isOnline;
      });
    }
  }

  Future<void> _loadData() async {
    final userData = await StorageService.getUserData();
    final balance = await StorageService.getBalance();
    final meters = await StorageService.getMeters();
    final transactions = await StorageService.getTransactions();
    final history = await StorageService.getLoginHistory();
    
    String lastLoginText = "";
    if (history.isNotEmpty) {
      final lastLoginDate = DateTime.parse(history.first);
      lastLoginText = "${lastLoginDate.day}/${lastLoginDate.month}/${lastLoginDate.year} ${lastLoginDate.hour}:${lastLoginDate.minute.toString().padLeft(2, '0')}";
    }

    if (mounted) {
      setState(() {
        _userName = userData['name']!;
        _balance = balance;
        _meters = meters;
        _transactions = transactions;
        _lastLogin = lastLoginText;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    if (_meters.isNotEmpty) ...[
                      _buildMetersSection(context),
                      const SizedBox(height: 32),
                    ],
                    const Text(
                      "Recent Transactions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTransactionList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "My Meters",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddMeterScreen()),
                );
                if (result == true) _loadData();
              },
              child: const Text("Add New"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _meters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final meter = _meters[index];
              return Container(
                width: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: _connectionStatus == MeterConnectionStatus.remote && meter['number'] == _smartMeterService.connectedMeterNumber
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.08),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.flash_on, color: AppTheme.primaryColor, size: 16),
                        ),
                        if (_connectionStatus == MeterConnectionStatus.remote && meter['number'] == _smartMeterService.connectedMeterNumber)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      meter['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meter['number']!,
                      style: TextStyle(color: AppTheme.subTextColor.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Hello, $_userName!",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildNetworkIndicator(),
                    ],
                  ),
                  if (_lastLogin.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Text(
                        "Last login: $_lastLogin",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const Text(
                    "Token Hub Premium",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen())),
                    icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
                    tooltip: "Support",
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                    icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
                    tooltip: "Profile",
                  ),
                  const SizedBox(width: 4),
                  _buildConnectionBadge(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildBalanceCard(),
          if (_connectionStatus == MeterConnectionStatus.remote && _liveData != null)
            _buildLiveUsageTicker(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassBoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Available Balance",
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _balance.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Units",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          _buildSyncButton(),
        ],
      ),
    );
  }

  Widget _buildLiveUsageTicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTickerItem(Icons.bolt, "${_liveData!.voltage.toStringAsFixed(1)}V", "Voltage"),
          _buildTickerItem(Icons.speed, "${_liveData!.load.toStringAsFixed(2)}kW", "Load"),
          _buildTickerItem(Icons.update, "Live", "Status", isLive: true),
        ],
      ),
    );
  }

  Widget _buildTickerItem(IconData icon, String value, String label, {bool isLive = false}) {
    return Column(
      children: [
        Row(
          children: [
            if (isLive)
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                ),
              ),
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_connectionStatus == MeterConnectionStatus.disconnected) ...[
          _buildConnectMeterHero(context),
          const SizedBox(height: 32),
        ],
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionCard(
              "Buy Token",
              Icons.bolt_rounded,
              AppTheme.primaryColor,
              () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyTokenScreen()));
                _loadData(); 
              },
            ),
            _buildActionCard(
              "History",
              Icons.receipt_long_rounded,
              Colors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen())),
            ),
            _buildActionCard(
              "Add Meter",
              Icons.settings_input_component_rounded,
              Colors.teal,
              () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMeterScreen()));
                if (result == true) _loadData();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectMeterHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.link_off_rounded, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            "No Active Meter Connection",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
          ),
          const SizedBox(height: 8),
          const Text(
            "Connect now to enable real-time tracking and remote management from any distance.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.subTextColor, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              if (_meters.isNotEmpty) {
                try {
                   await _smartMeterService.connect(_meters.first['number']!);
                } catch (e) {
                   if (!context.mounted) return;
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMeterScreen()));
              }
            },
            icon: const Icon(Icons.flash_on),
            label: const Text("Connect to Meter"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              elevation: 4,
              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text("No recent transactions", style: TextStyle(color: AppTheme.subTextColor)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length > 3 ? 3 : _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        return TransactionTile(
          title: tx['title'] ?? "Token Purchase",
          date: tx['date'] ?? "",
          amount: tx['amount'] ?? "",
          isSuccess: tx['isSuccess'] == 'true',
        );
      },
    );
  }

  Widget _buildNetworkIndicator() {
    final security = SecurityService();
    final isSecure = !security.isSystemIntegrityCompromised;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusPill(
          _isOnline ? "Online" : "Offline",
          _isOnline ? Colors.blueAccent : Colors.redAccent,
          _isOnline ? Icons.wifi : Icons.wifi_off,
        ),
        const SizedBox(width: 8),
        _buildStatusPill(
          isSecure ? "Secure" : "At Risk",
          isSecure ? Colors.tealAccent[400]! : Colors.orangeAccent,
          isSecure ? Icons.verified_user : Icons.warning_amber_rounded,
        ),
      ],
    );
  }

  Widget _buildStatusPill(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge() {
    Color color;
    String text;
    IconData icon;

    switch (_connectionStatus) {
      case MeterConnectionStatus.remote:
      case MeterConnectionStatus.connected:
        color = Colors.greenAccent[400]!;
        text = "Remote Linked";
        icon = Icons.sensors;
        break;
      case MeterConnectionStatus.connecting:
        color = Colors.orangeAccent;
        text = "Pairing...";
        icon = Icons.sync;
        break;
      case MeterConnectionStatus.disconnected:
        color = Colors.white.withValues(alpha: 0.3);
        text = "No Link";
        icon = Icons.link_off;
        break;
    }

    return GestureDetector(
      onTap: () async {
        if (_connectionStatus == MeterConnectionStatus.remote || _connectionStatus == MeterConnectionStatus.connected) {
          final disconnected = await _smartMeterService.disconnect(context);
          if (disconnected && mounted) {
             _loadData(); // Update UI
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: AppTheme.glassBoxDecoration(color: color),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    final bool canSync = (_connectionStatus == MeterConnectionStatus.remote || _connectionStatus == MeterConnectionStatus.connected) && _isOnline;
    
    return GestureDetector(
      onTap: canSync && !_isSyncing
          ? () async {
              setState(() => _isSyncing = true);
              try {
                final newBalance = await _smartMeterService.syncBalance();
                if (mounted) {
                  setState(() {
                    _balance = newBalance;
                    _isSyncing = false;
                  });
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isSyncing = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: canSync ? 0.2 : 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: canSync ? 0.3 : 0.1)),
        ),
        child: _isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                Icons.refresh_rounded, 
                color: canSync ? Colors.white : Colors.white24, 
                size: 28
              ),
      ),
    );
  }
}
