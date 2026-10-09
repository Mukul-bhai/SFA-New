import 'package:flutter/material.dart';
import 'services/salesforce_auth_service.dart';
import 'services/salesforce_dynamic_service.dart';
import 'services/salesforce_sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = SalesforceAuthService();
  final syncService = SalesforceSyncService();
  final dynamicService = SalesforceDynamicService();
  await authService.init();
  await syncService.init();
  await dynamicService.init();

  runApp(SfaEnterpriseApp(
    authService: authService,
    syncService: syncService,
    dynamicService: dynamicService,
  ));
}

class SfaEnterpriseApp extends StatelessWidget {
  final SalesforceAuthService authService;
  final SalesforceSyncService syncService;
  final SalesforceDynamicService dynamicService;

  const SfaEnterpriseApp({
    super.key,
    required this.authService,
    required this.syncService,
    required this.dynamicService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enterprise SFA Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B5CAB), // Parle Brand Blue
          primary: const Color(0xFF0B5CAB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B5CAB),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
      ),
      home: authService.isAuthenticated
          ? MainNavigationScreen(
              authService: authService,
              syncService: syncService,
              dynamicService: dynamicService,
            )
          : LoginScreen(
              authService: authService,
              syncService: syncService,
              dynamicService: dynamicService,
            ),
    );
  }
}
