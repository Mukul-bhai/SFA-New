import 'package:flutter_test/flutter_test.dart';
import 'package:sfa_mobile/main.dart';
import 'package:sfa_mobile/services/salesforce_sync_service.dart';

void main() {
  testWidgets('SFA App smoke test and UI rendering', (WidgetTester tester) async {
    final syncService = SalesforceSyncService();
    await syncService.init();

    await tester.pumpWidget(SfaApp(syncService: syncService));
    await tester.pumpAndSettle();

    expect(find.text('SFA Mobile App'), findsOneWidget);
    expect(find.text('TODAY\'S ASSIGNED BEAT'), findsOneWidget);
  });
}
