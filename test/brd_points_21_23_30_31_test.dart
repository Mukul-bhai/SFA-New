import 'package:flutter_test/flutter_test.dart';
import 'package:sfa_mobile/models/models.dart';

void main() {
  group('BRD Point 21 & 31: Start Day & End Day Attendance Tests', () {
    test('AttendanceModel parses and serializes Point 21 & 31 Start Day details', () {
      final json = {
        'id': 'att-101',
        'dayType': 'ON_TOUR',
        'punchInTime': '2026-10-15T09:15:00.000Z',
        'punchOutTime': '2026-10-15T18:30:00.000Z',
        'status': 'Completed',
        'totalDistanceKm': 24.5,
        'batteryLevel': 90,
        'dayPlan': 'On Tour',
        'dayPlanOtherDetails': null,
        'tourPlan': 'Local',
        'modeOfTransport': 'Bike',
        'vehicleUsed': 'Personal/Own',
      };

      final att = AttendanceModel.fromJson(json);

      expect(att.id, equals('att-101'));
      expect(att.dayPlan, equals('On Tour'));
      expect(att.tourPlan, equals('Local'));
      expect(att.modeOfTransport, equals('Bike'));
      expect(att.vehicleUsed, equals('Personal/Own'));

      final outJson = att.toJson();
      expect(outJson['dayPlan'], equals('On Tour'));
      expect(outJson['tourPlan'], equals('Local'));
      expect(outJson['modeOfTransport'], equals('Bike'));
      expect(outJson['vehicleUsed'], equals('Personal/Own'));
    });

    test('AttendanceModel supports Day Plan "Other" with custom details', () {
      final json = {
        'id': 'att-102',
        'dayType': 'FULL_DAY',
        'punchInTime': '2026-10-15T09:00:00.000Z',
        'status': 'Present',
        'dayPlan': 'Other',
        'dayPlanOtherDetails': 'Annual National Sales Conference Mumbai',
        'modeOfTransport': 'Online Taxi',
        'vehicleUsed': 'Public Transport',
      };

      final att = AttendanceModel.fromJson(json);
      expect(att.dayPlan, equals('Other'));
      expect(att.dayPlanOtherDetails, equals('Annual National Sales Conference Mumbai'));
      expect(att.modeOfTransport, equals('Online Taxi'));
      expect(att.vehicleUsed, equals('Public Transport'));
    });

    test('AttendanceRecordModel parses Salesforce Apex REST DTO response', () {
      final salesforceRecord = {
        'id': 'a05g800000AttRec123',
        'attendanceDate': '2026-10-15',
        'startTime': '09:30 AM',
        'endTime': '06:00 PM',
        'status': 'Completed',
        'totalWorkingHours': 8.5,
        'geoLocation': '18.9322, 72.8347',
        'isDayActive': false,
        'employeeName': 'Mukul Yadav',
        'dayPlan': 'On Tour',
        'tourPlan': 'Outstation',
        'modeOfTransport': 'Car',
        'vehicleUsed': 'Office',
      };

      final record = AttendanceRecordModel.fromJson(salesforceRecord);
      expect(record.id, equals('a05g800000AttRec123'));
      expect(record.workHours, equals(8.5));
      expect(record.dayPlan, equals('On Tour'));
      expect(record.tourPlan, equals('Outstation'));
      expect(record.modeOfTransport, equals('Car'));
      expect(record.vehicleUsed, equals('Office'));
    });
  });

  group('BRD Point 23.7 & 30: Visit Completion with Mandatory Photographs & Comments', () {
    test('VisitModel properly encapsulates Selfie, Freezer photo, and Comments', () {
      final visit = VisitModel(
        retailerId: 'OUT-999',
        retailerName: 'Gupta General Store',
        checkInTime: DateTime.parse('2026-10-15 10:00:00'),
        checkOutTime: DateTime.parse('2026-10-15 10:35:00'),
        isCompleted: true,
        selfieUrl: 'https://sfa.salesforce.com/photos/selfie_OUT-999.jpg',
        freezerPhotoUrl: 'https://sfa.salesforce.com/photos/freezer_OUT-999.jpg',
        checkoutComments: 'Display cleaned, freezer organized, booked 15 cases of biscuits.',
      );

      expect(visit.isCompleted, isTrue);
      expect(visit.selfieUrl, contains('selfie_OUT-999.jpg'));
      expect(visit.freezerPhotoUrl, contains('freezer_OUT-999.jpg'));
      expect(visit.checkoutComments, contains('booked 15 cases'));

      final json = visit.toJson();
      expect(json['selfieUrl'], equals(visit.selfieUrl));
      expect(json['freezerPhotoUrl'], equals(visit.freezerPhotoUrl));
      expect(json['checkoutComments'], equals(visit.checkoutComments));
    });

    test('Visit status transitions: Check-In -> In Progress, Check-Out -> Completed, Missed -> Missed with reason', () {
      // 1. Visit Start
      final startedVisit = VisitModel(
        retailerId: 'OUT-101',
        retailerName: 'City Mart',
        checkInTime: DateTime.now(),
        isCompleted: false,
      );
      expect(startedVisit.isCompleted, isFalse);
      expect(startedVisit.isSkipped, isFalse);

      // 2. Checkout
      startedVisit.checkOutTime = DateTime.now();
      startedVisit.isCompleted = true;
      startedVisit.selfieUrl = 'https://sfa.com/selfie.jpg';
      startedVisit.freezerPhotoUrl = 'https://sfa.com/freezer.jpg';
      startedVisit.checkoutComments = 'Order booked';
      expect(startedVisit.isCompleted, isTrue);

      // 3. Missed Visit
      final missedVisit = VisitModel(
        retailerId: 'OUT-102',
        retailerName: 'Closed Shop',
        checkInTime: DateTime.now(),
        isSkipped: true,
        skipReason: 'Shop Closed / Owner on Leave',
      );
      expect(missedVisit.isSkipped, isTrue);
      expect(missedVisit.skipReason, equals('Shop Closed / Owner on Leave'));
    });
  });
}
