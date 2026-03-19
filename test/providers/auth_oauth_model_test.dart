import 'package:flutter_app/core/models/auth.dart';
import 'package:flutter_app/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthLoginOtp model compatibility', () {
    test('prefers avatar when avatar and avartar both exist', () {
      final json = {
        'id': 'u1',
        'phone': '639123456789',
        'phoneMd5': 'md5',
        'nickname': 'Demo',
        'username': 'Demo',
        'avatar': 'https://example.com/new-avatar.png',
        'avartar': 'https://example.com/legacy-avatar.png',
        'countryCode': 63,
        'tokens': {
          'accessToken': 'a',
          'refreshToken': 'r',
        },
      };

      final model = AuthLoginOtp.fromJson(json);
      expect(model.avatar, 'https://example.com/new-avatar.png');
    });

    test('falls back to legacy avartar when avatar is missing', () {
      final json = {
        'id': 'u2',
        'phone': '639123456789',
        'phoneMd5': 'md5',
        'nickname': 'Demo',
        'username': 'Demo',
        'avartar': 'https://example.com/legacy-avatar.png',
        'countryCode': 63,
        'tokens': {
          'accessToken': 'a',
          'refreshToken': 'r',
        },
      };

      final model = AuthLoginOtp.fromJson(json);
      expect(model.avatar, 'https://example.com/legacy-avatar.png');
    });
  });

  group('Profile.lastLoginAt alignment', () {
    test('parses int timestamp', () {
      final json = {
        'id': 'u1',
        'nickname': 'Demo',
        'avatar': null,
        'phoneMd5': 'md5',
        'phone': '639123456789',
        'inviteCode': null,
        'vipLevel': 0,
        'lastLoginAt': 1742345678000,
        'kycStatus': 1,
        'deliveryAddressId': 0,
        'selfExclusionExpireAt': 0,
      };

      final profile = Profile.fromJson(json);
      expect(profile.lastLoginAt, 1742345678000);
    });

    test('supports nullable lastLoginAt', () {
      final json = {
        'id': 'u1',
        'nickname': 'Demo',
        'avatar': null,
        'phoneMd5': 'md5',
        'phone': '639123456789',
        'inviteCode': null,
        'vipLevel': 0,
        'lastLoginAt': null,
        'kycStatus': 1,
        'deliveryAddressId': 0,
        'selfExclusionExpireAt': 0,
      };

      final profile = Profile.fromJson(json);
      expect(profile.lastLoginAt, isNull);
    });
  });

  group('AuthLoginOauth model', () {
    test('fromJson parses oauth response payload', () {
      final json = {
        'id': 'user_1',
        'phone': 'google_xxxxx',
        'phoneMd5': 'md5_xxxxx',
        'nickname': 'Demo',
        'username': 'Demo',
        'avatar': 'https://example.com/avatar.png',
        'provider': 'google',
        'inviteCode': 'ABCD12',
        'tokens': {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
        },
      };

      final model = AuthLoginOauth.fromJson(json);

      expect(model.id, 'user_1');
      expect(model.provider, 'google');
      expect(model.avatar, 'https://example.com/avatar.png');
      expect(model.tokens.accessToken, 'access-token');
      expect(model.inviteCode, 'ABCD12');
    });
  });

  group('OAuth login params json', () {
    test('GoogleOauthLoginParams toJson keeps idToken', () {
      final params = GoogleOauthLoginParams(
        idToken: 'google-id-token',
        inviteCode: 'ABCD12',
      );

      final json = params.toJson();
      expect(json['idToken'], 'google-id-token');
      expect(json['inviteCode'], 'ABCD12');
    });

    test('FacebookOauthLoginParams toJson keeps required fields', () {
      final params = FacebookOauthLoginParams(
        accessToken: 'fb-access-token',
        userId: 'fb-user-1',
      );

      final json = params.toJson();
      expect(json['accessToken'], 'fb-access-token');
      expect(json['userId'], 'fb-user-1');
    });

    test('AppleOauthLoginParams toJson keeps idToken and optional code', () {
      final params = AppleOauthLoginParams(
        idToken: 'apple-id-token',
        code: 'auth-code',
      );

      final json = params.toJson();
      expect(json['idToken'], 'apple-id-token');
      expect(json['code'], 'auth-code');
    });
  });

  group('Email OTP auth models', () {
    test('EmailSendCodeResponse parses sent and devCode', () {
      final model = EmailSendCodeResponse.fromJson({
        'sent': true,
        'devCode': '666666',
      });

      expect(model.sent, true);
      expect(model.devCode, '666666');
    });

    test('AuthLoginEmail parses login payload', () {
      final model = AuthLoginEmail.fromJson({
        'id': 'u-email-1',
        'phone': 'mail_xxxxx',
        'phoneMd5': 'md5_xxxxx',
        'nickname': 'Email User',
        'username': 'Email User',
        'avatar': null,
        'email': 'demo@example.com',
        'countryCode': 'EMAIL',
        'tokens': {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
        },
      });

      expect(model.id, 'u-email-1');
      expect(model.email, 'demo@example.com');
      expect(model.countryCode, 'EMAIL');
      expect(model.tokens.refreshToken, 'refresh-token');
    });
  });

  group('OAuth providers initial/reset states', () {
    test('google/facebook/apple controllers default to AsyncData(null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authLoginGoogleCtrlProvider).valueOrNull, isNull);
      expect(container.read(authLoginFacebookCtrlProvider).valueOrNull, isNull);
      expect(container.read(authLoginAppleCtrlProvider).valueOrNull, isNull);
    });

    test('reset keeps controller state as AsyncData(null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authLoginGoogleCtrlProvider.notifier).reset();
      container.read(authLoginFacebookCtrlProvider.notifier).reset();
      container.read(authLoginAppleCtrlProvider.notifier).reset();

      expect(container.read(authLoginGoogleCtrlProvider).valueOrNull, isNull);
      expect(container.read(authLoginFacebookCtrlProvider).valueOrNull, isNull);
      expect(container.read(authLoginAppleCtrlProvider).valueOrNull, isNull);
    });
  });

  group('Email providers initial/reset states', () {
    test('sendEmail/loginEmail controllers default to AsyncData(null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(sendEmailCodeCtrlProvider).valueOrNull, isNull);
      expect(container.read(authLoginEmailCtrlProvider).valueOrNull, isNull);
    });

    test('sendEmail/loginEmail reset keeps AsyncData(null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sendEmailCodeCtrlProvider.notifier).reset();
      container.read(authLoginEmailCtrlProvider.notifier).reset();

      expect(container.read(sendEmailCodeCtrlProvider).valueOrNull, isNull);
      expect(container.read(authLoginEmailCtrlProvider).valueOrNull, isNull);
    });
  });
}

