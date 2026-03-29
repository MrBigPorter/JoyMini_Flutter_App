import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/login_page/login_page.dart';
import 'package:flutter_app/app/page/oauth_processing_page/oauth_processing_page.dart';
import 'package:flutter_app/core/services/auth/firebase_oauth_sign_in_service.dart';
import 'package:flutter_app/core/services/auth/global_oauth_handler.dart';
import 'package:flutter_app/core/store/auth/auth_initial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, widget) => MaterialApp(home: child),
      ),
    );
  }

  group('LoginPage OAuth buttons', () {
    testWidgets('Google/Facebook visibility follows platform support flags', (
      tester,
    ) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
      });

      await tester.pumpWidget(wrapWidget(const LoginPage()));
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

    testWidgets('apple button visibility follows platform support flag', (
      tester,
    ) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
      });

      await tester.pumpWidget(wrapWidget(const LoginPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final expected = FirebaseOauthSignInService.canShowAppleButton
          ? findsOneWidget
          : findsNothing;
      expect(find.text('login.oauth.apple'), expected);
    });

    testWidgets('renders email code login form by default', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
      });

      await tester.pumpWidget(wrapWidget(const LoginPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('login.email.label'), findsOneWidget);
      expect(find.text('login.email_code.hint'), findsOneWidget);
    });

    test(
      'GlobalOAuthHandler triggers recovery-start hook immediately',
      () async {
        var recoveryStarted = false;
        GlobalOAuthHandler.debugOnRecoveryCheckStarted = () {
          recoveryStarted = true;
        };

        final recovered =
            await GlobalOAuthHandler.checkAndRecoverInterruptedOAuth();

        expect(
          recoveryStarted,
          isTrue,
          reason: 'Recovery hook should fire at method start.',
        );
        expect(recovered, isFalse);

        GlobalOAuthHandler.debugOnRecoveryCheckStarted = null;
      },
    );

    testWidgets('oauth processing page shows immediate loading UI', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          initialTokensProvider.overrideWithValue(('mock-access-token', null)),
        ],
      );
      addTearDown(container.dispose);

      GlobalOAuthHandler.initialize(container);

      await tester.pumpWidget(wrapWidget(const OauthProcessingPage()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing Google Sign-In...'), findsOneWidget);
    });
  });
}
