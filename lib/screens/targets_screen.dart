import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/salesforce_auth_service.dart';
import '../services/salesforce_dynamic_service.dart';
import '../services/salesforce_sync_service.dart';

class TargetsScreen extends StatefulWidget {
  final SalesforceSyncService syncService;
  final SalesforceDynamicService? dynamicService;
  final SalesforceAuthService? authService;

  const TargetsScreen({
    super.key,
    required this.syncService,
    this.dynamicService,
    this.authService,
  });

  @override
  State<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends State<TargetsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTargets();
  }

  Future<void> _refreshTargets() async {
    if (widget.dynamicService == null) return;
    setState(() => _isLoading = true);
    final user = widget.authService?.currentUser;
    await widget.dynamicService!.fetchTargets(
      email: user?.email,
      userId: user?.id,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicTargets = widget.dynamicService?.targets ?? [];
    final targets = dynamicTargets.isNotEmpty ? dynamicTargets : widget.syncService.targets;

    final monthlyTargets = targets.where((t) => t.type.toLowerCase().contains('month')).toList();
    final daywiseTargets = targets.where((t) => t.type.toLowerCase().contains('day')).toList();
    final outletTargets = targets.where((t) => t.type.toLowerCase().contains('outlet')).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Targets & Performance'),
        backgroundColor: const Color(0xFF0B5CAB),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Sync Targets from Salesforce',
            onPressed: _refreshTargets,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'Monthly'),
            Tab(text: 'Daywise'),
            Tab(text: 'Outlet Type'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTargetList(monthlyTargets.isNotEmpty ? monthlyTargets : targets, 'Monthly Target Overview', 'October 2026 MTD'),
          _buildTargetList(daywiseTargets.isNotEmpty ? daywiseTargets : targets, 'Daywise Beat Route Target', 'Today\'s Route Execution'),
          _buildTargetList(outletTargets.isNotEmpty ? outletTargets : targets, 'Outlet Channel Targets', 'Supermarket, Kirana & Wholesalers'),
        ],
      ),
    );
  }

  Widget _buildTargetList(List<TargetModel> list, String title, String subtitle) {
    return RefreshIndicator(
      onRefresh: _refreshTargets,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF001E3C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...list.map((target) {
          final pct = target.achievementPercent > 0
              ? target.achievementPercent
              : (target.targetRevenue > 0 ? (target.achievedRevenue / target.targetRevenue * 100) : 75.0);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          target.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pct >= 80 ? Colors.green.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: pct >= 80 ? Colors.green.shade300 : Colors.blue.shade300),
                        ),
                        child: Text(
                          '${pct.toStringAsFixed(1)}% Done',
                          style: TextStyle(
                            color: pct >= 80 ? const Color(0xFF16A34A) : const Color(0xFF0070D2),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation(
                        pct >= 80 ? const Color(0xFF16A34A) : const Color(0xFF0070D2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3-Metric Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _metricBox(
                        'Revenue',
                        '₹${target.achievedRevenue.toStringAsFixed(0)}',
                        'Target: ₹${target.targetRevenue.toStringAsFixed(0)}',
                        const Color(0xFF0070D2),
                      ),
                      _metricBox(
                        'Volume (Cases)',
                        '${target.achievedVolume.toInt()}',
                        'Target: ${target.targetVolume.toInt()}',
                        Colors.purple,
                      ),
                      _metricBox(
                        'Visits',
                        '${target.achievedVisits.toInt()}',
                        'Target: ${target.targetVisits.toInt()}',
                        const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}

  Widget _metricBox(String title, String achieved, String target, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        Text(achieved, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(target, style: const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }
}
