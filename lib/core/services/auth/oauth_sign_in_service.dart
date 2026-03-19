import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/config/app_config.dart';
import 'package:flutter_app/core/models/auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class OauthCancelledException implements Exception {
  final String message;
  OauthCancelledException(this.message);

  @override
  String toString() => message;
}

class OauthSignInService {
  OauthSignInService._();

  static bool _googleInitialized = false;
  static bool _facebookInitialized = false;

  static bool get canShowGoogleButton {
    if (!kIsWeb) return true;
    return AppConfig.googleWebClientId.isNotEmpty;
  }

  static bool get canShowFacebookButton {
    if (!kIsWeb) return true;
    return AppConfig.facebookWebAppId.isNotEmpty;
  }

  static bool get canShowAppleButton {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static Future<GoogleOauthLoginParams> signInWithGoogle({
    String? inviteCode,
  }) async {
    if (!canShowGoogleButton) {
      throw UnsupportedError(
        'Google sign-in is unavailable. Configure GOOGLE_WEB_CLIENT_ID for Web.',
      );
    }

    await _ensureGoogleInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google idToken is empty');
      }

      return GoogleOauthLoginParams(
        idToken: idToken,
        inviteCode: _normalizedInviteCode(inviteCode),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw OauthCancelledException('Google sign-in cancelled');
      }
      rethrow;
    }
  }

  static Future<FacebookOauthLoginParams> signInWithFacebook({
    String? inviteCode,
  }) async {
    if (!canShowFacebookButton) {
      throw UnsupportedError(
        'Facebook sign-in is unavailable. Configure FACEBOOK_WEB_APP_ID for Web.',
      );
    }

    if (kIsWeb) {
      await _ensureFacebookInitialized();
    }

    final result = await FacebookAuth.instance.login();
    if (result.status == LoginStatus.cancelled) {
      throw OauthCancelledException('Facebook sign-in cancelled');
    }

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw StateError(result.message ?? 'Facebook sign-in failed');
    }

    return FacebookOauthLoginParams(
      accessToken: result.accessToken!.token,
      userId: result.accessToken!.userId,
      inviteCode: _normalizedInviteCode(inviteCode),
    );
  }

  static Future<AppleOauthLoginParams> signInWithApple({
    String? inviteCode,
  }) async {
    if (!canShowAppleButton) {
      throw UnsupportedError('Apple sign-in is not supported on this platform');
    }

    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw StateError('Apple sign-in is not available on this device');
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email],
    );

    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Apple idToken is empty');
    }

    final code = credential.authorizationCode;

    return AppleOauthLoginParams(
      idToken: idToken,
      code: code.isEmpty ? null : code,
      inviteCode: _normalizedInviteCode(inviteCode),
    );
  }

  static String? _normalizedInviteCode(String? code) {
    final trimmed = code?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    if (kIsWeb) {
      await GoogleSignIn.instance.initialize(
        clientId: AppConfig.googleWebClientId,
      );
    } else {
      await GoogleSignIn.instance.initialize();
    }
    _googleInitialized = true;
  }

  static Future<void> _ensureFacebookInitialized() async {
    if (_facebookInitialized) return;
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: AppConfig.facebookWebAppId,
      cookie: true,
      xfbml: true,
      version: AppConfig.facebookWebSdkVersion,
    );
    _facebookInitialized = true;
  }
}

