import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sfa_mobile/services/salesforce_auth_service.dart';
import 'package:sfa_mobile/services/salesforce_dynamic_service.dart';
import 'package:sfa_mobile/services/salesforce_sync_service.dart';
import 'package:sfa_mobile/screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Enterprise SFA Mobile Auth Screen Initial Render Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final authService = SalesforceAuthService();
    final syncService = SalesforceSyncService();
    final dynamicService = SalesforceDynamicService();

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        authService: authService,
        syncService: syncService,
        dynamicService: dynamicService,
      ),
    ));
    await tester.pump();

    // Verify Login Screen brand header & input controls
    expect(find.text('Enterprise SFA Mobile'), findsOneWidget);
    expect(find.text('Field Sales Executive Portal • FMCG / DMS'), findsOneWidget);
    expect(find.text('Email OTP'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In with Password'), findsOneWidget);
  });
}
