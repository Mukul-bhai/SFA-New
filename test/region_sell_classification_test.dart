import 'package:flutter_test/flutter_test.dart';
import 'package:sfa_mobile/models/models.dart';
import 'package:sfa_mobile/services/salesforce_dynamic_service.dart';

void main() {
  group('Region-Wise Product Sell Classifications (Must Sell, Focused Sell, Suggested Sell)', () {
    test('Parle-G resolves dynamically between Madhya Pradesh and Karnataka', () {
      final parleG = ProductModel(
        id: 'prod-001',
        name: 'Parle-G Gold 100g',
        code: 'PG-GLD-100',
        brand: 'Parle',
        category: 'Biscuits',
        mrp: 20.0,
        basePrice: 16.5,
        sellClassification: 'Must Sell',
        regionClassifications: {
          'Madhya Pradesh': 'Must Sell',
          'Karnataka': 'Focused Sell',
          'Maharashtra': 'Must Sell',
          'Gujarat': 'Suggested Sell',
        },
      );

      // In Madhya Pradesh -> Must Sell
      expect(parleG.getSellClassificationForRegion('Madhya Pradesh'), equals('Must Sell'));
      expect(parleG.isMustSellInRegion('Madhya Pradesh'), isTrue);
      expect(parleG.isFocusedSellInRegion('Madhya Pradesh'), isFalse);

      // In Karnataka -> Focused Sell
      expect(parleG.getSellClassificationForRegion('Karnataka'), equals('Focused Sell'));
      expect(parleG.isMustSellInRegion('Karnataka'), isFalse);
      expect(parleG.isFocusedSellInRegion('Karnataka'), isTrue);

      // In Gujarat -> Suggested Sell
      expect(parleG.getSellClassificationForRegion('Gujarat'), equals('Suggested Sell'));
      expect(parleG.isSuggestedSellInRegion('Gujarat'), isTrue);

      // In unknown region -> fallback to base sellClassification
      expect(parleG.getSellClassificationForRegion('Punjab'), equals('Must Sell'));
    });

    test('Malkist is Focused Sell in Madhya Pradesh and Must Sell in Karnataka', () {
      final malkist = ProductModel(
        id: 'prod-002',
        name: 'Malkist Cheese Cracker 120g',
        code: 'MLK-CHS-120',
        brand: 'Malkist',
        category: 'Crackers',
        mrp: 35.0,
        basePrice: 28.0,
        sellClassification: 'Focused Sell',
        regionClassifications: {
          'Madhya Pradesh': 'Focused Sell',
          'Karnataka': 'Must Sell',
        },
      );

      // MP: Focused Sell
      expect(malkist.getSellClassificationForRegion('Madhya Pradesh'), equals('Focused Sell'));
      expect(malkist.isFocusedSellInRegion('Madhya Pradesh'), isTrue);
      expect(malkist.isMustSellInRegion('Madhya Pradesh'), isFalse);

      // Karnataka: Must Sell
      expect(malkist.getSellClassificationForRegion('Karnataka'), equals('Must Sell'));
      expect(malkist.isMustSellInRegion('Karnataka'), isTrue);
      expect(malkist.isFocusedSellInRegion('Karnataka'), isFalse);
    });

    test('Multi Cookie / Hide & Seek is Suggested Sell across regions', () {
      final multiCookie = ProductModel(
        id: 'prod-003',
        name: 'Parle Hide & Seek / Multi Cookie 120g',
        code: 'HNS-MLT-120',
        brand: 'Parle',
        category: 'Cookies',
        mrp: 50.0,
        basePrice: 42.0,
        sellClassification: 'Suggested Sell',
        regionClassifications: {
          'Madhya Pradesh': 'Suggested Sell',
          'Karnataka': 'Suggested Sell',
        },
      );

      expect(multiCookie.isSuggestedSellInRegion('Madhya Pradesh'), isTrue);
      expect(multiCookie.isSuggestedSellInRegion('Karnataka'), isTrue);
    });

    test('ProductModel JSON parsing from Salesforce Apex REST payload', () {
      final jsonPayload = {
        'id': '01tg8000000XYZ1',
        'name': 'Parle-G 100g',
        'productCode': 'PG-100',
        'brand': 'Parle',
        'category': 'Biscuits',
        'mrp': 10.0,
        'basePrice': 8.5,
        'sellClassification': 'Must Sell',
        'regionClassifications': {
          'Madhya Pradesh': 'Must Sell',
          'Karnataka': 'Focused Sell',
        },
        'nonPurchaseReasons': [
          'Stock Available',
          'Low demand',
          'Season expired',
          'No product demand',
          'Non movable',
          'Other'
        ],
      };

      final parsed = ProductModel.fromJson(jsonPayload);
      expect(parsed.id, equals('01tg8000000XYZ1'));
      expect(parsed.name, equals('Parle-G 100g'));
      expect(parsed.sellClassification, equals('Must Sell'));
      expect(parsed.regionClassifications['Madhya Pradesh'], equals('Must Sell'));
      expect(parsed.regionClassifications['Karnataka'], equals('Focused Sell'));
      expect(parsed.nonPurchaseReasons.contains('Stock Available'), isTrue);
      expect(parsed.nonPurchaseReasons.contains('Non movable'), isTrue);
    });

    test('SalesforceDynamicService default sample products contain accurate BRD region mappings', () {
      final prods = SalesforceDynamicService.defaultSampleProducts;
      expect(prods.isNotEmpty, isTrue);

      final parleG = prods.firstWhere((p) => p.name.contains('Parle-G'));
      expect(parleG.isMustSellInRegion('Madhya Pradesh'), isTrue);
      expect(parleG.isFocusedSellInRegion('Karnataka'), isTrue);

      final malkist = prods.firstWhere((p) => p.name.contains('Malkist'));
      expect(malkist.isFocusedSellInRegion('Madhya Pradesh'), isTrue);
      expect(malkist.isMustSellInRegion('Karnataka'), isTrue);
    });
  });
}
