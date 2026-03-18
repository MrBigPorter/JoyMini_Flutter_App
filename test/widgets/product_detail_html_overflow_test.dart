import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/product_detail/detail_sections.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _wrap(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('DetailContentSection handles very long unbroken html content without overflow exception', (tester) async {
    const longWord = 'https://example.com/'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final html = '<div>$longWord $longWord $longWord</div>';

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 320,
          child: DetailContentSection(desc: html, ruleContent: html),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}

