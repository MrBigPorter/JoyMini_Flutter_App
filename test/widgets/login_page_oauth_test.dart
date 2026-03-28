import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/login_page/login_page.dart';
import 'package:flutter_app/core/services/auth/firebase_oauth_sign_in_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _wrap(Widget child) {
    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(home: child),
      ),
    );
  }

  group('LoginPage OAuth buttons', () {
    testWidgets('Google/Facebook visibility follows platform support flags',
        (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
      });

      await tester.pumpWidget(_wrap(const LoginPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final googleExpected = FirebaseOauthSignInService.canShowGoogleButton
          ? findsOneWidget
          : findsNothing;
      final facebookExpected = FirebaseOauthSignInService.canShowFacebookButton
          ? findsOneWidget
          : findsNothing;

      expect(find.text('login.oauth.google'), googleExpected);
      expect(find.text('login.oauth.facebook'), facebookExpected);
    });

    testWidgets('apple button visibility follows platform support flag',
        (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
      });

      await tester.pumpWidget(_wrap(const LoginPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final expected = FirebaseOauthSignInService.canShowAppleButton
          ? findsOneWidget
          : findsNothing;
      expect(find.text('login.oauth.apple'), expected);
    });

    testWidgets('can switch to email code login branch', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
      });

      await tester.pumpWidget(_wrap(const LoginPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final toggleFinder = find.text('login.mode.email_code');
      await tester.ensureVisible(toggleFinder);
      await tester.tap(toggleFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('login.email.label'), findsOneWidget);
      expect(find.text('login.email_code.hint'), findsOneWidget);
      expect(find.text('login.mode.phone_code'), findsOneWidget);
    });
  });
}

