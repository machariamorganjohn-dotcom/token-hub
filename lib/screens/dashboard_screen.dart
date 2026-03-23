import 'dart:convert';
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
import '../services/api_service.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/network_service.dart';
import 'package:flutter/services.dart';

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
  bool _isOnline = true;
  MeterConnectionStatus _connectionStatus = MeterConnectionStatus.disconnected;
  MeterData? _liveData;
  final _smartMeterService = SmartMeterService();
  StreamSubscription? _statusSubscription;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _networkSubscription;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _refreshSubscription;
  Timer? _consumptionTimer;

  @override
  void initState() {
    super.initState();
    SecurityService().performIntegrityCheck(); // Trigger security audit
    NetworkService().checkConnectivity().then((online) {
      if (mounted) setState(() => _isOnline = online);
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadData();
    _initMeterService();
    _setupNotifications();
    _startConsumptionSimulation();
  }

  void _startConsumptionSimulation() {
    // Simulate real meter behavior: reduce units slightly over time
    // Roughly 0.01 units every 5 minutes for simulation
    _consumptionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted && _balance > 0.01) {
        setState(() {
          _balance -= 0.01;
        });
        StorageService.saveBalance(_balance);
      }
    });
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
    _consumptionTimer?.cancel();
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
    final history = await StorageService.getLoginHistory();
    
    // Deterministic Sync: Fetch accurate balance from backend (accounts for consumption while app was closed)
    final balance = await _smartMeterService.syncBalance();
    
    // Sync meters from backend
    final meters = await _smartMeterService.syncMetersFromBackend();
    
    // Sync transactions from backend
    List<Map<String, String>> transactions = [];
    try {
      final response = await ApiService.getTransactions();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        transactions = data.map((t) => {
          'title': t['title'].toString(),
          'date': t['timestamp'].toString(),
          'amount': 'KES ${t['amount']}',
          'units': '${t['unitsReceived']} Units',
          'meter': t['meterNumber'].toString(),
          'token': t['tokenPayload'].toString(),
          'isSuccess': t['isSuccess'].toString(),
        }).toList();
      } else {
        transactions = await StorageService.getTransactions();
      }
    } catch (e) {
      transactions = await StorageService.getTransactions();
    }

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
      _checkSmartReminders();
    }
  }

  void _checkSmartReminders() {
    if (_balance < 4.0 && _meters.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Text("Low Balance Alert"),
            ],
          ),
          content: Text("You have less than 4 Units remaining (${_balance.toStringAsFixed(2)} Units). Please recharge to avoid disconnection."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Dismiss", style: TextStyle(color: AppTheme.subTextColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyTokenScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text("BUY NOW"),
            ),
          ],
        )
      );
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
                  Row(
                    children: [
                      const Text(
                        "Token Hub Premium",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded, color: Colors.amber, size: 12),
                            SizedBox(width: 4),
                            Text("1,250 Pts", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
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
    // Format balance into segments like a physical meter
    String balanceStr = _balance.toStringAsFixed(2);
    List<String> segments = balanceStr.split('.');
    String whole = segments[0].padLeft(4, '0');
    String decimal = segments[1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "DIGITAL ENERGY METER",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              _buildLivePulseIndicator(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _buildMeterSegment(whole),
              const Text(".", style: TextStyle(color: Colors.amber, fontSize: 40, fontWeight: FontWeight.bold)),
              _buildMeterSegment(decimal, isDecimal: true),
              const SizedBox(width: 12),
              const Text(
                "kWh",
                style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSyncStatus(),
        ],
      ),
    );
  }

  Widget _buildMeterSegment(String text, {bool isDecimal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDecimal ? Colors.redAccent : Colors.amber,
          fontSize: 44,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildLivePulseIndicator() {
    return Row(
      children: [
        FadeTransition(
          opacity: _pulseController,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        const Text("LIVE", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSyncStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.history, color: Colors.white24, size: 12),
        const SizedBox(width: 6),
        Text(
          "Last synced with KPLC: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          style: const TextStyle(color: Colors.white24, fontSize: 10),
        ),
      ],
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
        const SizedBox(height: 24),
        if (_meters.isNotEmpty) _buildSmartFeatures(),
      ],
    );
  }

  Widget _buildSmartFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Smart Power",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                "One-Tap Buy",
                Icons.touch_app_rounded,
                Colors.blue,
                () => _showOneTapBuyDialog(),
                isVertical: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                "SOS KSh 150",
                Icons.health_and_safety_rounded,
                Colors.redAccent,
                () => _handleEmergencyToken(),
                isVertical: false,
              ),
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
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap, {bool isVertical = true}) {
    return GestureDetector(
      onTap: onTap,
      child: isVertical ? Column(
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
      ) : Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
           color: color.withValues(alpha: 0.1),
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
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
          token: tx['token'],
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


  // ── Smart Feature Handlers ────────────────────────────────────────────────
  void _showOneTapBuyDialog() {
    String selectedMeter = _meters.isNotEmpty ? _meters.first['number']! : "No Meter Found";
    final amtController = TextEditingController(text: "500");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("One-Tap Token", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Buy tokens instantly via M-Pesa. Select your target meter below:", style: TextStyle(color: AppTheme.subTextColor, fontSize: 13)),
                  const SizedBox(height: 16),
                  if (_meters.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: selectedMeter,
                      decoration: InputDecoration(
                        labelText: "Select Meter",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _meters.map((m) => DropdownMenuItem(
                        value: m['number']!,
                        child: Text("${m['name']} (${m['number']})", style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedMeter = val);
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amtController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount (KES)",
                      prefixIcon: const Icon(Icons.payments_rounded, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton.icon(
                  onPressed: () {
                    final amt = double.tryParse(amtController.text) ?? 0;
                    if (amt >= 50) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _processFastPurchase(amt, selectedMeter);
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimum KES 50 required")));
                    }
                  },
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text("Buy Now"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _processFastPurchase(double amount, String targetMeter) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Processing M-Pesa STK..."),
          ],
        ),
      )
    );
    
    try {
      final userData = await StorageService.getUserData();
      final response = await ApiService.initiateStkPush(amount, targetMeter, userData['phone'] ?? '');
      final data = jsonDecode(response.body);

      if (!mounted) return;
      Navigator.pop(context); // close loading arg

      if (response.statusCode == 200) {
         final tx = data['transaction'];
         final token = tx['tokenPayload'];
         final newBalance = (data['newBalance'] ?? 0).toDouble();
         final debtDeducted = (data['debtDeducted'] ?? 0).toDouble();

         await StorageService.saveBalance(newBalance);
         
         if (debtDeducted > 0) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Emergency Debt of KES $debtDeducted automatically deducted."),
              backgroundColor: Colors.orange,
            ));
         }

         _loadData();
         _showTokenDialog(token, tx['unitsReceived'].toString(), amount.toStringAsFixed(0));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Purchase failed")));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchase failed. Server connection error.")));
      }
    }
  }

  void _showTokenDialog(String token, String units, String paid) {
     showDialog(
       context: context, 
       builder: (_) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text("You purchased $units Units for KES $paid."),
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(token, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                   GestureDetector(
                     onTap: () {
                         Clipboard.setData(ClipboardData(text: token.replaceAll('-', '')));
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                     },
                     child: const Icon(Icons.copy_rounded, color: AppTheme.primaryColor, size: 20),
                   )
                 ],
               ),
             )
           ],
         ),
         actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Done"))],
       )
     );
  }

  Future<void> _handleEmergencyToken() async {
    final debt = await StorageService.getEmergencyDebt();
    if (debt > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Clear your existing emergency debt before requesting another SOS token."),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Get Emergency Token", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("You will instantly receive KES 150 worth of units. This amount will be automatically deducted from your next token purchase."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
               Navigator.pop(context);
               
               showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text("Generating SOS Token..."),
                      ],
                    ),
                  )
               );

               await Future.delayed(const Duration(seconds: 2)); // simulate generating token
               final currentBalance = await StorageService.getBalance();
               final newUnits = 150 * 0.05;
               await StorageService.saveBalance(currentBalance + newUnits);
               await StorageService.saveEmergencyDebt(150.0);

               String token = "";
               final random = math.Random();
               for (int i = 0; i < 20; i++) {
                   token += random.nextInt(10).toString();
                   if ((i + 1) % 4 == 0 && i != 19) token += "-";
               }

               final now = DateTime.now();
               final dateStr = "${now.day} ${_getMonth(now.month)}, ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
               await StorageService.saveTransaction({
                 'title': 'SOS Emergency Token',
                 'date': dateStr,
                 'amount': 'KES 150 (Credit)',
                 'units': '${newUnits.toStringAsFixed(2)} Units',
                 'meter': _meters.first['number']!,
                 'token': token,
                 'isSuccess': 'true',
               });

               if (!context.mounted) return;
               Navigator.pop(context); // close loader
               _loadData();
               _showTokenDialog(token, newUnits.toStringAsFixed(2), "150 (Credit)");
            }, 
            child: const Text("Get SOS Token", style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
