import 'package:flutter/material.dart';
import '../services/salesforce_auth_service.dart';
import '../services/salesforce_dynamic_service.dart';
import '../services/salesforce_sync_service.dart';
import 'home_dashboard_screen.dart';
import 'pjp_screen.dart';
import 'targets_screen.dart';
import 'support_tickets_screen.dart';
import 'attendance_expenses_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final SalesforceAuthService authService;
  final SalesforceSyncService syncService;
  final SalesforceDynamicService dynamicService;

  const MainNavigationScreen({
    super.key,
    required this.authService,
    required this.syncService,
    required this.dynamicService,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _navigateToPjpTab() {
    setState(() {
      _currentIndex = 1; // Tab 1: My PJPs
    });
  }

  void _navigateToTargetsTab() {
    setState(() {
      _currentIndex = 2; // Tab 2: Targets
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(
        authService: widget.authService,
        dynamicService: widget.dynamicService,
        onNavigateToPjp: _navigateToPjpTab,
        onNavigateToTargets: _navigateToTargetsTab,
      ),
      PjpScreen(
        dynamicService: widget.dynamicService,
        syncService: widget.syncService,
        authService: widget.authService,
      ),
      TargetsScreen(
        syncService: widget.syncService,
        dynamicService: widget.dynamicService,
        authService: widget.authService,
      ),
      SupportTicketsScreen(
        dynamicService: widget.dynamicService,
      ),
      AttendanceExpensesScreen(
        syncService: widget.syncService,
        dynamicService: widget.dynamicService,
        authService: widget.authService,
      ),
      ProfileScreen(
        authService: widget.authService,
        syncService: widget.syncService,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        elevation: 6,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF0B5CAB)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route, color: Color(0xFF0B5CAB)),
            label: 'My PJPs',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes, color: Color(0xFF0B5CAB)),
            label: 'Targets',
          ),
          NavigationDestination(
            icon: Icon(Icons.headset_mic_outlined),
            selectedIcon: Icon(Icons.headset_mic, color: Color(0xFF0B5CAB)),
            label: 'Support',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge, color: Color(0xFF0B5CAB)),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF0B5CAB)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
