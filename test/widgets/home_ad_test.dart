import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/home_components/home_ad.dart';
import 'package:flutter_app/core/models/ad_res.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _wrap(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );
  }

  AdRes _gridAdWithTwoItems() {
    return AdRes(
      img: 'https://example.com/main.jpg',
      videoUrl: null,
      gridId: null,
      id: 'ad-grid-1',
      jumpCate: 1,
      jumpUrl: '',
      relatedTitleId: null,
      sortOrder: 1,
      sortType: 2,
      status: 1,
      fileType: 1,
      bannerArray: [
        BannerItem(
          img: 'https://example.com/1.jpg',
          imgStyleType: 1,
          jumpCate: 2,
          jumpUrl: 'https://example.com',
          title: 'ad-1',
        ),
        BannerItem(
          img: 'https://example.com/2.jpg',
          imgStyleType: 1,
          jumpCate: 2,
          jumpUrl: 'https://example.com',
          title: 'ad-2',
        ),
      ],
    );
  }

  group('HomeAd rendering', () {
    testWidgets('renders empty widget for empty list', (tester) async {
      await tester.pumpWidget(_wrap(const HomeAd(list: [])));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('does not throw when grid ad has less than 3 items', (tester) async {
      final ad = _gridAdWithTwoItems();
      await tester.pumpWidget(_wrap(HomeAd(list: [ad])));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeAd), findsOneWidget);
    });
  });
}

