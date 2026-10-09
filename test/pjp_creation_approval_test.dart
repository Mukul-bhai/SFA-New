import 'package:flutter_test/flutter_test.dart';
import 'package:sfa_mobile/services/salesforce_dynamic_service.dart';

void main() {
  group('PJP Hierarchy & Approval Lifecycle Tests', () {
    late SalesforceDynamicService service;

    setUp(() {
      service = SalesforceDynamicService();
    });

    test('Create PJP Plan creates a plan in Draft status', () async {
      final uniqueName = 'PJP-Mukul-Nov-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final res = await service.createPjp(
        name: uniqueName,
        month: 'November',
        year: 2026,
      );

      expect(res['success'], isTrue);
      expect(service.pjps.isNotEmpty, isTrue);

      final pjp = service.pjps.firstWhere(
        (p) => p.id == res['recordId'] || p.name == uniqueName,
      );
      expect(pjp.name, uniqueName);
      expect(pjp.month, 'November');
      expect(pjp.year, 2026);
      expect(pjp.status, 'Draft');
    });

    test('Submit PJP for Approval updates status to Submitted', () async {
      final uniqueName = 'PJP-Mukul-Dec-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final res = await service.createPjp(
        name: uniqueName,
        month: 'December',
        year: 2026,
      );

      expect(res['success'], isTrue);
      final pjp = service.pjps.firstWhere(
        (p) => p.id == res['recordId'] || p.name == uniqueName,
      );
      expect(pjp.status, 'Draft');

      final submitRes = await service.submitPjpForApproval(pjpId: pjp.id);
      expect(submitRes['success'], isTrue);

      final updatedPjp = service.pjps.firstWhere((p) => p.id == pjp.id);
      expect(updatedPjp.status, 'Submitted');
    });

    test('Create Beat attaches new beat to specific PJP', () async {
      final uniqueName = 'PJP-Q1-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final pjpRes = await service.createPjp(
        name: uniqueName,
        month: 'January',
        year: 2027,
      );

      expect(pjpRes['success'], isTrue);
      final pjpId = pjpRes['recordId'] as String;

      final uniqueCode = 'BT-AND-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final beatRes = await service.createBeat(
        pjpId: pjpId,
        name: 'Andheri East Industrial Beat',
        code: uniqueCode,
        dayOfWeek: 'Tuesday',
      );

      expect(beatRes['success'], isTrue);
    });

    test('Create Outlet attaches new retailer under specific Beat', () async {
      final uniqueName = 'PJP-Q2-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final pjpRes = await service.createPjp(
        name: uniqueName,
        month: 'April',
        year: 2027,
      );

      expect(pjpRes['success'], isTrue);
      final pjpId = pjpRes['recordId'] as String;

      final uniqueCode = 'BT-BAN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final beatRes = await service.createBeat(
        pjpId: pjpId,
        name: 'Bandra Retail Beat',
        code: uniqueCode,
        dayOfWeek: 'Friday',
      );

      expect(beatRes['success'], isTrue);
      final beatId = beatRes['recordId'] as String;

      final outletRes = await service.createOutlet(
        beatId: beatId,
        name: 'Shree Ganesh Supermarket',
        ownerName: 'Ganesh Patil',
        phone: '9820011223',
        address: 'Hill Road, Bandra West',
        outletType: 'Supermarket',
        creditLimit: 75000.0,
      );

      expect(outletRes['success'], isTrue);
    });

    test('Fetch Targets retrieves live Target__c records from Salesforce', () async {
      await service.fetchTargets();
      expect(service.targets.isNotEmpty, isTrue);
      final first = service.targets.first;
      expect(first.name.isNotEmpty, isTrue);
      expect(first.targetRevenue >= 0, isTrue);
    });
  });
}
