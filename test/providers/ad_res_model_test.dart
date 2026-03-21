import 'package:flutter_app/core/models/ad_res.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdRes.fromJson compatibility', () {
    test('parses numeric id and relatedTitleId as strings', () {
      final ad = AdRes.fromJson({
        'id': 123,
        'img': 'https://example.com/ad.jpg',
        'fileType': 1,
        'jumpCate': 3,
        'jumpUrl': 456,
        'relatedTitleId': 789,
        'sortOrder': 1,
        'sortType': 1,
        'status': 1,
      });

      expect(ad.id, '123');
      expect(ad.jumpUrl, '456');
      expect(ad.relatedTitleId, '789');
    });

    test('bannerArray falls back to empty list when backend gives invalid type', () {
      final ad = AdRes.fromJson({
        'id': 'ad-1',
        'img': 'https://example.com/ad.jpg',
        'fileType': 1,
        'jumpCate': 1,
        'jumpUrl': '',
        'sortOrder': 1,
        'sortType': 2,
        'status': 1,
        'bannerArray': {'unexpected': true},
      });

      expect(ad.bannerArray, isEmpty);
    });

    test('bannerArray parses list items safely', () {
      final ad = AdRes.fromJson({
        'id': 'ad-2',
        'img': 'https://example.com/ad.jpg',
        'fileType': 1,
        'jumpCate': 1,
        'jumpUrl': '',
        'sortOrder': 1,
        'sortType': 2,
        'status': 1,
        'bannerArray': [
          {
            'img': 'https://example.com/1.jpg',
            'imgStyleType': 1,
            'jumpCate': 2,
            'jumpUrl': 'https://lucky.app',
            'title': 'ad item 1',
          }
        ],
      });

      expect(ad.bannerArray.length, 1);
      expect(ad.bannerArray.first.title, 'ad item 1');
    });
  });
}

