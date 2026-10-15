import 'package:flutter_test/flutter_test.dart';
import 'package:sfa_mobile/models/models.dart';

void main() {
  group('Order & Order Line Products Verification Tests', () {
    test('LocalOrderModel computes totalProductsCount, totalUnitsCount and productNamesSummary', () {
      final order = LocalOrderModel(
        localId: 'ORD-LOCAL-001',
        retailerId: 'RET-001',
        retailerName: 'Gupta Kirana Store',
        items: [
          OrderItemModel(
            productId: 'prod-001',
            productName: 'Parle-G Gold 100g',
            productCode: 'PG-GLD-100',
            quantity: 10,
            freeQuantity: 1,
            unitPrice: 16.5,
            totalAmount: 165.0,
          ),
          OrderItemModel(
            productId: 'prod-002',
            productName: 'Malkist Cheese Cracker 120g',
            productCode: 'MLK-CHS-120',
            quantity: 5,
            freeQuantity: 0,
            unitPrice: 28.0,
            totalAmount: 140.0,
          ),
        ],
        subtotal: 305.0,
        discountAmount: 0.0,
        gstAmount: 54.9,
        totalAmount: 359.9,
        orderDate: DateTime(2026, 10, 16),
      );

      // Verify Total Products Count
      expect(order.totalProductsCount, 2);

      // Verify Total Units Count
      expect(order.totalUnitsCount, 15.0);

      // Verify Product Names list
      expect(order.productNames, ['Parle-G Gold 100g', 'Malkist Cheese Cracker 120g']);

      // Verify Product Names Summary formatting
      expect(order.productNamesSummary, 'Parle-G Gold 100g (10 pcs), Malkist Cheese Cracker 120g (5 pcs)');

      // Verify JSON serialization includes product summary
      final json = order.toJson();
      expect(json['totalProductsCount'], 2);
      expect(json['totalUnitsCount'], 15.0);
      expect(json['productNamesSummary'], 'Parle-G Gold 100g (10 pcs), Malkist Cheese Cracker 120g (5 pcs)');
      expect(json['productNames'], contains('Parle-G Gold 100g'));
    });

    test('PreviousOrderModel parses totalProductsCount and productNames from Salesforce DTO', () {
      final jsonFromApex = {
        'id': 'a0Og8000001AbcDEAQ',
        'orderNumber': 'ORD-1092',
        'orderDate': '2026-10-15T18:00:00.000Z',
        'totalAmount': 1450.0,
        'status': 'Confirmed',
        'totalProductsCount': 3,
        'totalQuantity': 25.0,
        'productNames': 'Parle-G Gold 100g (15 pcs), Malkist Cheese Cracker (5 pcs), Hide & Seek (5 pcs)',
      };

      final order = PreviousOrderModel.fromJson(jsonFromApex);
      expect(order.orderNumber, 'ORD-1092');
      expect(order.totalProductsCount, 3);
      expect(order.totalQuantity, 25.0);
      expect(order.productNames, contains('Parle-G Gold 100g'));
      expect(order.productNames, contains('Hide & Seek'));
    });

    test('OrderItemModel serializes product name for order lines', () {
      final item = OrderItemModel(
        productId: 'prod-003',
        productName: 'Parle Hide & Seek / Multi Cookie 120g',
        productCode: 'HNS-MLT-120',
        quantity: 8,
        freeQuantity: 0,
        unitPrice: 42.0,
        totalAmount: 336.0,
      );

      final json = item.toJson();
      expect(json['productId'], 'prod-003');
      expect(json['productName'], 'Parle Hide & Seek / Multi Cookie 120g');
      expect(json['productCode'], 'HNS-MLT-120');
      expect(json['quantity'], 8);
    });
  });
}
