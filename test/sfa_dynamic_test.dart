import 'package:flutter_test/flutter_test.dart';
import 'package:sfa_mobile/models/models.dart';
import 'package:sfa_mobile/services/salesforce_dynamic_service.dart';

void main() {
  group('SFA Dynamic Models & Business Rules Verification', () {
    test('100m Geofence distance calculation precision', () {
      final outlet = RetailerModel(
        id: 'OUT-01',
        code: 'RET-1001',
        name: 'Parle Store',
        shopName: 'Parle Store Fort',
        phone: '+91 98201 12345',
        latitude: 18.9322,
        longitude: 72.8347,
        geofenceRadius: 100.0,
        outstandingBalance: 8000.0,
        creditLimit: 50000.0,
        creditHold: false,
        primaryDistributorId: 'DIST-01',
      );

      // Same coordinates -> 0 meters
      final distanceSame = outlet.distanceInMetersTo(18.9322, 72.8347);
      expect(distanceSame, lessThan(1.0));

      // 50 meters away -> within 100m range
      final distanceNear = outlet.distanceInMetersTo(18.9325, 72.8347);
      expect(distanceNear, lessThan(100.0));

      // Far coordinates -> outside 100m range
      final distanceFar = outlet.distanceInMetersTo(19.0178, 72.8438);
      expect(distanceFar, greaterThan(1000.0));
    });

    test('Credit Limit Gatekeeper blocks order if balance exceeds limit', () {
      // Normal outlet
      final normalOutlet = RetailerModel(
        id: 'OUT-01',
        code: 'RET-01',
        name: 'Normal Store',
        shopName: 'Normal Store',
        phone: '123',
        latitude: 18.9,
        longitude: 72.8,
        outstandingBalance: 12000.0,
        creditLimit: 50000.0,
        creditHold: false,
        primaryDistributorId: 'D1',
      );
      expect(normalOutlet.isOrderBlockedDueToCredit, isFalse);

      // Overdue outlet: Outstanding 62k exceeds 50k limit
      final overdueOutlet = RetailerModel(
        id: 'OUT-02',
        code: 'RET-02',
        name: 'Overdue Store',
        shopName: 'Overdue Store',
        phone: '123',
        latitude: 18.9,
        longitude: 72.8,
        outstandingBalance: 62000.0,
        creditLimit: 50000.0,
        creditHold: true,
        primaryDistributorId: 'D1',
      );
      expect(overdueOutlet.isOrderBlockedDueToCredit, isTrue);
    });

    test('Salesforce dynamic service starts with zero mock data', () {
      final dynamicService = SalesforceDynamicService();
      expect(dynamicService.pjps.isEmpty, isTrue);
      expect(dynamicService.schemes.isEmpty, isTrue);
      expect(dynamicService.products.isEmpty, isTrue);
      expect(dynamicService.leaves.isEmpty, isTrue);
    });

    test('PJP to Beat to Outlet tree parsing and traversal from Salesforce JSON', () {
      final pjpJson = {
        'id': 'a0Tg8000005r69HEAQ',
        'name': 'PJP-Mukul-Oct-2026',
        'month': 'October',
        'year': 2026,
        'status': 'Approved',
        'totalBeats': 1,
        'totalOutlets': 1,
        'beats': [
          {
            'id': 'a01g800000xox1JAAQ',
            'name': 'MG Road Route',
            'code': 'BT-MG-01',
            'dayOfWeek': 'Monday',
            'outlets': [
              {
                'id': 'a0Sg8000000qoQXEAY',
                'name': 'Balaji stores',
                'shopName': 'Balaji stores',
                'phone': '+91 9810000000',
                'address': 'Main Market',
                'latitude': 19.076,
                'longitude': 72.877,
                'creditLimit': 35000.0,
                'outstandingBalance': 2500.0,
                'previousOrders': [
                  {
                    'id': 'ORD-01',
                    'orderNumber': 'ORD-2026-001',
                    'orderDate': '2026-10-06T10:00:00Z',
                    'totalAmount': 5400.0,
                    'status': 'Draft',
                  }
                ]
              }
            ]
          }
        ]
      };

      final pjp = PjpModel.fromJson(pjpJson);
      expect(pjp.beats.isNotEmpty, isTrue);
      expect(pjp.beats.first.name, equals('MG Road Route'));
      expect(pjp.beats.first.retailers.first.shopName, equals('Balaji stores'));
      expect(pjp.beats.first.retailers.first.previousOrders.isNotEmpty, isTrue);
    });

    test('Trade Schemes Buy 10 Get 1 Free Calculation from Salesforce', () {
      final schemeJson = {
        'id': 'a0Mg8000000p18XEAQ',
        'name': 'Parle-G 10+1 Mega Offer',
        'schemeCode': 'SCH-BUY-SAME-01',
        'schemeType': 'Buy same free',
        'buyQuantity': 10.0,
        'getQuantity': 1.0,
        'description': 'Buy 10 packets of Parle-G 250g and get 1 packet free of the same product.',
      };

      final scheme = SchemeModel.fromJson(schemeJson);
      expect(scheme.buyQuantity, equals(10.0));
      expect(scheme.getQuantity, equals(1.0));

      // If user orders 25 units: floor(25 / 10) * 1 = 2 free units
      int freeUnits = ((25 / scheme.buyQuantity).floor() * scheme.getQuantity).toInt();
      expect(freeUnits, equals(2));
    });

    test('Support Ticket model creation and serialization', () {
      final ticket = SupportTicketModel(
        id: 'TKT-001',
        ticketNumber: 'TKT-2026-101',
        outletId: 'OUT-01',
        outletName: 'Parle Store',
        beatName: 'Fort Wholesale',
        category: 'Billing & Invoice',
        priority: 'High',
        subject: 'Discount slab discrepancy',
        description: 'Invoice #102 missing 3% volume slab discount.',
        createdDate: DateTime.now(),
      );

      final json = ticket.toJson();
      expect(json['ticketNumber'], equals('TKT-2026-101'));
      expect(json['category'], equals('Billing & Invoice'));
      expect(json['priority'], equals('High'));
    });
  });
}
