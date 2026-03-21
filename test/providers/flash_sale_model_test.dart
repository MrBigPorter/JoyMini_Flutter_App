import 'package:flutter_app/core/models/flash_sale.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Unit tests: FlashSale model parsing + provider state
// ---------------------------------------------------------------------------
void main() {
  group('FlashSaleSession.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'session-1',
        'title': 'Big Sale',
        'startTime': 1700000000000,
        'endTime': 1700003600000,
        'status': 1,
        'productCount': 5,
        'remainingMs': 120000,
      };
      final session = FlashSaleSession.fromJson(json);

      expect(session.id, 'session-1');
      expect(session.title, 'Big Sale');
      expect(session.remainingMs, 120000);
      expect(session.productCount, 5);
    });

    test('defaults to 0 for missing numeric fields', () {
      final session = FlashSaleSession.fromJson({'id': 'x', 'title': 't'});
      expect(session.remainingMs, 0);
      expect(session.productCount, 0);
    });
  });

  group('FlashSaleProductItem.fromJson', () {
    test('parses isSoldOut correctly', () {
      final json = {
        'id': 'p-1',
        'sessionId': 's-1',
        'treasureId': 't-1',
        'flashStock': 3,
        'flashPrice': '199.00',
        'sortOrder': 1,
        'isSoldOut': true,
        'product': {
          'treasureId': 't-1',
          'treasureName': 'AirPods',
          'unitAmount': '499.00',
        },
      };
      final item = FlashSaleProductItem.fromJson(json);
      expect(item.isSoldOut, true);
      expect(item.flashPrice, '199.00');
      expect(item.flashStock, 3);
    });

    test('isSoldOut defaults to false when missing', () {
      final json = {
        'id': 'p-2',
        'sessionId': 's-1',
        'treasureId': 't-2',
        'flashStock': 10,
        'flashPrice': '99.00',
        'sortOrder': 2,
        'product': {'treasureId': 't-2', 'treasureName': 'Watch', 'unitAmount': '299.00'},
      };
      final item = FlashSaleProductItem.fromJson(json);
      expect(item.isSoldOut, false);
    });
  });

  group('FlashSaleSessionProducts.fromJson', () {
    test('parses session and list', () {
      final json = {
        'session': {
          'id': 's-1',
          'title': 'Flash',
          'startTime': 0,
          'endTime': 9999999,
          'status': 1,
          'productCount': 1,
          'remainingMs': 5000,
        },
        'list': [
          {
            'id': 'p-1',
            'sessionId': 's-1',
            'treasureId': 't-1',
            'flashStock': 5,
            'flashPrice': '99.00',
            'sortOrder': 1,
            'isSoldOut': false,
            'product': {'treasureId': 't-1', 'treasureName': 'Item', 'unitAmount': '199.00'},
          }
        ],
      };
      final result = FlashSaleSessionProducts.fromJson(json);
      expect(result.session.id, 's-1');
      expect(result.list.length, 1);
      expect(result.list.first.flashPrice, '99.00');
    });
  });

  group('FlashSaleProductDetail.fromJson', () {
    test('parses nested session and product detail', () {
      final json = {
        'id': 'fp-1',
        'sessionId': 's-1',
        'treasureId': 't-1',
        'flashStock': 2,
        'flashPrice': '150.00',
        'sortOrder': 1,
        'isSoldOut': false,
        'session': {
          'id': 's-1',
          'title': 'Flash Deal',
          'startTime': 0,
          'endTime': 9999999,
          'status': 1,
          'productCount': 1,
          'remainingMs': 3600000,
        },
        'product': {
          'treasureId': 't-1',
          'treasureName': 'Smart Speaker',
          'unitAmount': '350.00',
          'shippingType': 1,
          'groupSize': 1,
          'state': 1,
          'mainImageList': ['https://example.com/img.jpg'],
        },
      };
      final detail = FlashSaleProductDetail.fromJson(json);
      expect(detail.flashPrice, '150.00');
      expect(detail.session.remainingMs, 3600000);
      expect(detail.product.mainImageList.length, 1);
    });
  });
}

