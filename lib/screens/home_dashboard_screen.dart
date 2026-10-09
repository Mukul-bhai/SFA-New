import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/salesforce_auth_service.dart';
import '../services/salesforce_dynamic_service.dart';
import 'login_screen.dart';
import '../services/salesforce_sync_service.dart';

class HomeDashboardScreen extends StatefulWidget {
  final SalesforceAuthService authService;
  final SalesforceDynamicService dynamicService;
  final VoidCallback onNavigateToPjp;
  final VoidCallback? onNavigateToTargets;

  const HomeDashboardScreen({
    super.key,
    required this.authService,
    required this.dynamicService,
    required this.onNavigateToPjp,
    this.onNavigateToTargets,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);
  int _currentCarouselIndex = 0;
  late final PageController _pageController;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoCarouselTimer();
    _refreshDashboard();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (widget.dynamicService.schemes.isNotEmpty && _pageController.hasClients) {
        final next = (_currentCarouselIndex + 1) % widget.dynamicService.schemes.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  Future<void> _refreshDashboard() async {
    final user = widget.authService.currentUser;
    await widget.dynamicService.fetchDashboard(
      email: user?.email,
      userId: user?.id,
    );
    await widget.dynamicService.fetchSchemes();
    await widget.dynamicService.fetchPjpTree(
      email: user?.email,
      userId: user?.id,
    );
    if (mounted) setState(() {});
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to end your session and log out of the SFA Mobile App?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            authService: widget.authService,
            syncService: SalesforceSyncService(),
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final kpi = widget.dynamicService.kpi;
    final schemes = widget.dynamicService.schemes;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Employee Profile Header Section
                _buildProfileHeader(user),

                // 2. Target vs Achievement Card
                _buildTargetAchievementCard(kpi),

                const SizedBox(height: 16),

                // 3. Quick Action Shortcut to PJP
                _buildPjpBanner(),

                const SizedBox(height: 18),

                // 4. Auto-Advancing Schemes Flashcards Carousel
                _buildSchemesFlashcardSection(schemes),

                const SizedBox(height: 18),

                // 5. Daily Performance Sub-Metrics Grid
                _buildPerformanceGrid(kpi),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B5CAB), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF0B5CAB).withValues(alpha: 0.2),
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'M').toUpperCase(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Mukul Yadav',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        '${user?.employeeCode ?? "EMP-0104"} • ${user?.designation ?? "Field Executive"}',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Color(0xFFFFD54F)),
                          const SizedBox(width: 4),
                          Text(
                            user?.territoryName ?? 'Mumbai Central FMCG Beat',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFFFD54F), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
                onPressed: _handleLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetAchievementCard(DashboardKpiModel kpi) {
    final progress = (kpi.achievementPercent / 100.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onNavigateToTargets,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Target vs Achievement',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${kpi.achievementPercent.toStringAsFixed(1)}% Achieved',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Revenue Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Achieved Revenue', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    currencyFormat.format(kpi.achievedRevenue),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Monthly Target', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    currencyFormat.format(kpi.targetRevenue),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF546E7A)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Animated Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFECEFF1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B5CAB)),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPjpBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: widget.onNavigateToPjp,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.route, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Beat Visits (My PJPs)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'PJP ➔ Beats ➔ 100m Radar Outlet Check',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchemesFlashcardSection(List<SchemeModel> schemes) {
    if (schemes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    'Active Schemes (Flashcards)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                  ),
                ],
              ),
              Text(
                'Auto Playing (${_currentCarouselIndex + 1}/${schemes.length})',
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Auto-advancing Carousel Flashcards
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: schemes.length,
            onPageChanged: (index) {
              setState(() => _currentCarouselIndex = index);
            },
            itemBuilder: (context, index) {
              final scheme = schemes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildSchemeCardItem(scheme, index),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(schemes.length, (index) {
            final isActive = _currentCarouselIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive ? const Color(0xFF0B5CAB) : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSchemeCardItem(SchemeModel scheme, int index) {
    final gradients = [
      [const Color(0xFFF57C00), const Color(0xFFFF9800)],
      [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
      [const Color(0xFF00695C), const Color(0xFF00897B)],
      [const Color(0xFFC2185B), const Color(0xFFE91E63)],
    ];
    final gradient = gradients[index % gradients.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scheme.type.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 10, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    'Valid: ${scheme.validTo.isNotEmpty ? scheme.validTo : "31 Oct 2026"}',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          Text(
            scheme.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            scheme.description,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scheme Code: ${scheme.code}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const Row(
                children: [
                  Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 4),
                  Icon(Icons.check_circle, size: 14, color: Colors.white),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid(DashboardKpiModel kpi) {
    final double visitProgress = kpi.targetVisits > 0 ? (kpi.completedVisits / kpi.targetVisits).clamp(0.0, 1.0) : 0.0;
    final String todayDateStr = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Field Operations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    todayDateStr,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: widget.onNavigateToPjp,
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Daily Route Visits Progress Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0070D2).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront, color: Color(0xFF0070D2), size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Route Beat Outlets',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                        ),
                      ],
                    ),
                    Text(
                      '${kpi.completedVisits.toInt()} / ${kpi.targetVisits.toInt()} Visited',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0070D2)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: visitProgress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(
                      visitProgress >= 0.8 ? const Color(0xFF16A34A) : const Color(0xFF0070D2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B5CAB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: widget.onNavigateToPjp,
                    icon: const Icon(Icons.alt_route, size: 16),
                    label: const Text('Open Today\'s Route Outlets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3-Metric Operations Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.receipt_long,
                  color: Colors.green,
                  title: 'Orders Booked',
                  value: '${kpi.totalOrders}',
                  subText: 'Today\'s Invoices',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.speed,
                  color: Colors.purple,
                  title: 'Strike Rate',
                  value: '${kpi.strikeRatePercent.toStringAsFixed(0)}%',
                  subText: 'Productive Calls',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.verified_user_outlined,
                  color: Colors.amber.shade800,
                  title: '100m Radar',
                  value: 'Active',
                  subText: 'GPS Geofenced',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
          Text(subText, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
