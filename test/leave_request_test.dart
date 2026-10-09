import 'package:flutter_test/flutter_test.dart';
import 'package:sfa_mobile/models/models.dart';

void main() {
  group('LeaveRequestModel Unit Tests', () {
    test('Customer / Retailer Leave parses JSON correctly from Salesforce Apex REST', () {
      final json = {
        'id': 'a0B800000012345EAA',
        'name': 'LR-00000',
        'leaveCategory': 'Customer / Retailer Leave',
        'leaveType': 'Customer / Shop Closed',
        'outletId': 'a0980000001ABCDEAA',
        'outletName': 'Balaji stores',
        'beatId': 'a0880000001XYZWEAA',
        'beatName': 'Beat 1 - North Market',
        'startDate': '2026-10-10',
        'endDate': '2026-10-12',
        'totalDays': 3.0,
        'status': 'Approved',
        'reason': 'Shop renovation and holiday',
        'createdDate': '2026-10-08T10:00:00.000Z',
      };

      final leave = LeaveRequestModel.fromJson(json);

      expect(leave.id, 'a0B800000012345EAA');
      expect(leave.name, 'LR-00000');
      expect(leave.leaveCategory, 'Customer / Retailer Leave');
      expect(leave.leaveType, 'Customer / Shop Closed');
      expect(leave.outletName, 'Balaji stores');
      expect(leave.beatName, 'Beat 1 - North Market');
      expect(leave.totalDays, 3.0);
      expect(leave.status, 'Approved');
      expect(leave.reason, 'Shop renovation and holiday');
    });

    test('Sales Executive Leave parses JSON correctly from Salesforce Apex REST', () {
      final json = {
        'id': 'a0B800000012346EAA',
        'name': 'LR-00001',
        'leaveCategory': 'Sales Executive Leave',
        'leaveType': 'Casual Leave',
        'outletId': null,
        'outletName': null,
        'beatId': null,
        'beatName': null,
        'startDate': '2026-10-15',
        'endDate': '2026-10-16',
        'totalDays': 2.0,
        'status': 'Pending Approval',
        'reason': 'Family emergency',
        'createdDate': '2026-10-08T11:00:00.000Z',
      };

      final leave = LeaveRequestModel.fromJson(json);

      expect(leave.id, 'a0B800000012346EAA');
      expect(leave.name, 'LR-00001');
      expect(leave.leaveCategory, 'Sales Executive Leave');
      expect(leave.leaveType, 'Casual Leave');
      expect(leave.outletId, isNull);
      expect(leave.totalDays, 2.0);
      expect(leave.status, 'Pending Approval');
    });
  });
}
