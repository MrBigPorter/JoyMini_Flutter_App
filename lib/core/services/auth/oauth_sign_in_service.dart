import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/config/app_config.dart';
import 'package:flutter_app/core/models/auth.dart';
import 'oauth_web_bridge.dart' as oauth_web;
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

  // ─── Google init guard ───────────────────────────────────────────────────
  // Dart statics reset on hot-reload; use a JS-global as source of truth on
  // web so we never call google.accounts.id.initialize() twice per page-load.
  static bool _googleInitialized = false;
  static Future<void>? _googleInitFuture;
  static String? _googleInitKey;
  static Future<GoogleOauthLoginParams>? _googleSignInFuture;
  static bool _googleWebDiagnosticsLogged = false;

  // ─── Web credential cache ─────────────────────────────────────────────────
  // The authenticationEvents stream is broadcast; events fired before a
  // listener is attached are lost.  We subscribe globally right after
  // initialize() so any "auto-fired" FedCM credential is captured here and
  // can be returned immediately when the user later clicks the sign-in button.
  static GoogleSignInAccount? _webCachedAccount;
  static StreamSubscription<GoogleSignInAuthenticationEvent>? _webGlobalAuthSub;

  // Per-request waiter (set only while _authenticateGoogleOnWeb is running).
  static Completer<GoogleSignInAccount>? _webSignInWaiter;

  // ─── Facebook ─────────────────────────────────────────────────────────────
  static bool _facebookInitialized = false;

  static bool get canShowGoogleButton {
    if (!kIsWeb) return true;
    return AppConfig.googleWebClientId.isNotEmpty;
  }

  static bool get canShowFacebookButton {
    if (!kIsWeb) return true;
    return AppConfig.facebookWebAppId.isNotEmpty;
  }

  /// 诊断方法：检查 OAuth 配置状态（生产环境调试用）
  static Map<String, dynamic> getOauthDiagnostics() {
    final diagnostics = <String, dynamic>{};
    
    if (kIsWeb) {
      diagnostics['platform'] = 'web';
      diagnostics['origin'] = _safeWebOrigin();
      diagnostics['google'] = {
        'clientIdConfigured': AppConfig.googleWebClientId.isNotEmpty,
        'clientIdLength': AppConfig.googleWebClientId.length,
        'clientIdPreview': AppConfig.googleWebClientId.isNotEmpty 
            ? '${AppConfig.googleWebClientId.substring(0, 20)}...' 
            : '',
        'canShowButton': canShowGoogleButton,
        'initialized': _googleInitialized,
        'initKey': _googleInitKey,
      };
      diagnostics['facebook'] = {
        'appIdConfigured': AppConfig.facebookWebAppId.isNotEmpty,
        'appIdLength': AppConfig.facebookWebAppId.length,
        'appIdPreview': AppConfig.facebookWebAppId.isNotEmpty
            ? '${AppConfig.facebookWebAppId.substring(0, 10)}...'
            : '',
        'canShowButton': canShowFacebookButton,
        'initialized': _facebookInitialized,
        'sdkVersion': AppConfig.facebookWebSdkVersion,
      };
      diagnostics['webSpecific'] = {
        'cachedAccount': _webCachedAccount != null,
        'globalListenerActive': _webGlobalAuthSub != null,
        'pendingWaiter': _webSignInWaiter != null && !_webSignInWaiter!.isCompleted,
      };
    } else {
      diagnostics['platform'] = 'native';
      diagnostics['google'] = {'canShowButton': true};
      diagnostics['facebook'] = {'canShowButton': true};
      diagnostics['apple'] = {'canShowButton': canShowAppleButton};
    }
    
    return diagnostics;
  }

  /// Ensures Google is initialized on Web before rendering [buildGoogleSignInWebButton].
  /// No-op on native platforms. Safe to call multiple times.
  static Future<void> initializeForWeb({String trigger = 'unknown'}) async {
    if (!kIsWeb) return;
    await _ensureGoogleInitialized(trigger: trigger);
  }

  static bool get canShowAppleButton {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static Future<GoogleOauthLoginParams> signInWithGoogle({
    String? inviteCode,
  }) async {
    if (_googleSignInFuture != null) {
      _log('Google sign-in already in-flight; reusing the same request');
      return _googleSignInFuture!;
    }

    final future = _signInWithGoogleInternal(inviteCode: inviteCode);
    _googleSignInFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_googleSignInFuture, future)) {
        _googleSignInFuture = null;
      }
    }
  }

  static Future<GoogleOauthLoginParams> _signInWithGoogleInternal({
    String? inviteCode,
  }) async {
    _log(
      'Google sign-in start | isWeb=$kIsWeb | canShow=$canShowGoogleButton | clientIdLen=${AppConfig.googleWebClientId.length}',
    );

    if (!canShowGoogleButton) {
      _log('Google sign-in blocked: GOOGLE_WEB_CLIENT_ID is empty on Web');
      throw UnsupportedError(
        'Google sign-in is unavailable. Configure GOOGLE_WEB_CLIENT_ID for Web.',
      );
    }

    await _ensureGoogleInitialized(trigger: 'signInWithGoogle');

    try {
      final GoogleSignInAccount account;
      // Web 平台必须使用轻量级认证流程
      if (kIsWeb) {
        _log('Google web lightweight authentication() calling...');
        account = await _authenticateGoogleOnWeb();
      } else {
        // Native 平台使用标准认证流程
        _log('Google native authenticate() calling...');
        account = await GoogleSignIn.instance.authenticate(
          scopeHint: const ['email', 'profile'],
        );
      }

      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _log('Google authenticate() returned empty idToken');
        throw StateError('Google idToken is empty');
      }

      _log(
        'Google authenticate() success | email=${account.email} | idTokenLen=${idToken.length} | tokenHead=${_maskHead(idToken)}',
      );

      return GoogleOauthLoginParams(
        idToken: idToken,
        inviteCode: _normalizedInviteCode(inviteCode),
      );
    } on OauthCancelledException {
      rethrow;
    } on GoogleSignInException catch (e) {
      _log('GoogleSignInException | code=${e.code} | desc=${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw OauthCancelledException('Google sign-in cancelled');
      }
      rethrow;
    } catch (e) {
      _log('Google sign-in unknown error: $e');
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

    //  新增：如果是 iOS，先弹授权框
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // 延迟一下，确保 UI 渲染完毕再弹窗（苹果官方建议）
      await Future.delayed(const Duration(milliseconds: 200));

      final trackingStatus = await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('[FacebookAuth] ATT 授权状态: $trackingStatus');

      // 注意：即使 trackingStatus 是 denied (拒绝)，我们依然继续往下走
      // 只是如果拒绝了，Facebook 依然会给你发 JWT Token。
    }

    final result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
      loginBehavior: LoginBehavior.nativeWithFallback,
      //  必须加上这一行，强制获取经典 Token
      loginTracking: LoginTracking.enabled,
    );
    if (result.status == LoginStatus.cancelled) {
      throw OauthCancelledException('Facebook sign-in cancelled');
    }

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw StateError(result.message ?? 'Facebook sign-in failed');
    }

    final accessToken = result.accessToken!;
    final userId = switch (accessToken) {
      ClassicToken token => token.userId,
      LimitedToken token => token.userId,
      _ => throw StateError('Unsupported Facebook access token type'),
    };

    return FacebookOauthLoginParams(
      accessToken: accessToken.tokenString,
      userId: userId,
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

  static Future<void> _ensureGoogleInitialized({
    required String trigger,
  }) async {
    final initKey = kIsWeb ? AppConfig.googleWebClientId : '__native__';
    if (kIsWeb) {
      _logGoogleWebDiagnosticsOnce(stage: 'ensureGoogleInitialized');
      _log('Google initialize() requested | trigger=$trigger');
    }
    if (_googleInitialized && _googleInitKey == initKey) return;

    // On web: check a JS window global to survive hot-reloads without
    // calling id.initialize() a second time (which corrupts the FedCM callback).
    // JS globals survive hot-reload (same JS context) but reset on page
    // refresh (new JS context) — so GSI is correctly re-initialized after F5.
    if (kIsWeb && oauth_web.getJsGsiInitKey() == initKey) {
      _googleInitialized = true;
      _googleInitKey = initKey;
      // Re-establish Dart-side listener in case it was lost.
      _setupWebGlobalListener();
      _log(
        'Google initialize() skipped – JS global guard hit | trigger=$trigger | key=${initKey.substring(0, 12)}...',
      );
      return;
    }

    if (_googleInitFuture != null) {
      await _googleInitFuture!;
      return;
    }

    final completer = Completer<void>();
    _googleInitFuture = completer.future;

    try {
      _log('Google initialize() start | keyLen=${initKey.length}');
      if (kIsWeb) {
        await GoogleSignIn.instance.initialize(
          clientId: AppConfig.googleWebClientId,
        );
        oauth_web.setJsGsiInitKey(initKey); // persist across hot-reloads (JS global)
      } else {
        await GoogleSignIn.instance.initialize();
      }
      _googleInitialized = true;
      _googleInitKey = initKey;
      _log('Google initialize() success | trigger=$trigger');
      if (kIsWeb) _setupWebGlobalListener();
      completer.complete();
    } catch (e, s) {
      _log('Google initialize() failed: $e');
      if ('$e'.contains('origin_mismatch')) {
        _log(
          'Google initialize() origin_mismatch hint: check Google Cloud Console -> OAuth Client (Web) -> Authorized JavaScript origins',
        );
      }
      completer.completeError(e, s);
      rethrow;
    } finally {
      _googleInitFuture = null;
    }
  }

  static void _logGoogleWebDiagnosticsOnce({required String stage}) {
    if (!kIsWeb || _googleWebDiagnosticsLogged) return;
    _googleWebDiagnosticsLogged = true;
    final origin = _safeWebOrigin();
    final key = AppConfig.googleWebClientId;
    _log(
      'Google web diagnostics | stage=$stage | origin=$origin | clientIdHead=${_maskHead(key)} | clientIdLen=${key.length}',
    );
  }

  static String _safeWebOrigin() => oauth_web.safeWebOrigin();

  // ─── JS window global helpers (web-only, survives hot-reload) ─────────────
  // JS globals live in the same JS context as the GSI library. They survive
  // Dart hot-reloads (no page navigation) but are destroyed on full page
  // refresh — exactly matching the GSI library lifecycle.


  /// Establishes a long-lived subscription to [authenticationEvents] so that
  /// credentials delivered by FedCM *before* the user clicks the sign-in
  /// button (e.g. auto-triggered One Tap on page load) are cached and not lost.
  static void _setupWebGlobalListener() {
    _webGlobalAuthSub?.cancel();
    _webGlobalAuthSub = GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        _log('Google web global: event type=${event.runtimeType}');
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _log(
            'Google web global: SignIn event | email=${event.user.email}',
          );
          if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
            // An active sign-in request is waiting — deliver directly.
            _webSignInWaiter!.complete(event.user);
            _webSignInWaiter = null;
          } else {
            // Cache it; _authenticateGoogleOnWeb() will pick it up.
            _webCachedAccount = event.user;
          }
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _log('Google web global: SignOut event');
          _webCachedAccount = null;
          if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
            _webSignInWaiter!.completeError(
              OauthCancelledException('User signed out during authentication'),
            );
            _webSignInWaiter = null;
          }
        } else {
          // Other events (e.g. unknown future event types) — log and ignore.
          _log('Google web global: unhandled event type: ${event.runtimeType}');
        }
      },
      onError: (Object error, StackTrace stack) {
        // ─── DO NOT immediately cancel the waiter ───────────────────────────
        // FedCM with auto_select:true fires an automatic id.prompt() on page
        // load.  When the user then clicks our button a second concurrent
        // id.prompt() is issued.  The second prompt may emit isSkippedMoment
        // (→ GoogleSignInExceptionCode.canceled) because a prompt is already
        // running.  If we cancel the waiter here, the credential from the
        // *first* prompt (the one that shows the dialog) is lost.
        //
        // Strategy:
        //  • SignIn success events are caught in the regular handler above.
        //  • Errors are logged but only propagated after a short grace period.
        //    If a SignIn event arrives within the grace period, the timer is
        //    cancelled and we succeed.  Otherwise we fail after the grace period.
        // ────────────────────────────────────────────────────────────────────
        _log('Google web global: auth stream error (grace-period): $error');

        if (_webSignInWaiter == null || _webSignInWaiter!.isCompleted) {
          // No waiter active — nothing to do.
          return;
        }

        // Give the auto-triggered FedCM 5 seconds to deliver a credential
        // before propagating this error.
        Future.delayed(const Duration(seconds: 5), () {
          if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
            _log('Google web global: propagating deferred error: $error');
            _webSignInWaiter!.completeError(error, stack);
            _webSignInWaiter = null;
          }
        });
      },
    );
    _log('Google web: global auth listener (re)established');
  }

  static Future<GoogleSignInAccount> _authenticateGoogleOnWeb() async {
    // Fast path: a credential arrived before the user clicked (e.g. auto
    // One Tap on page load). Consume it immediately.
    if (_webCachedAccount != null) {
      final account = _webCachedAccount!;
      _webCachedAccount = null;
      _log(
        'Google web: returning pre-cached account | email=${account.email}',
      );
      return account;
    }

    // Cancel any stale waiter from a previous interrupted request.
    if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
      _log('Google web: cancelling stale waiter (superseded)');
      _webSignInWaiter!.completeError(
        OauthCancelledException('Superseded by new sign-in request'),
      );
      _webSignInWaiter = null;
    }
    _webSignInWaiter = Completer<GoogleSignInAccount>();

    try {
      _log('Google web: calling attemptLightweightAuthentication()');
      // This always returns null on web but internally calls id.prompt()
      // which triggers the FedCM / One Tap UI.  The credential response will
      // arrive via the global authenticationEvents listener above.
      GoogleSignIn.instance.attemptLightweightAuthentication(
        reportAllExceptions: true,
      );

      final result = await _webSignInWaiter!.future.timeout(
        const Duration(seconds: 60), // 减少超时时间从120秒到60秒
        onTimeout: () {
          _log('Google web: sign-in timed out after 60s');
          throw OauthCancelledException('Google sign-in timed out');
        },
      );

      _log('Google web: sign-in completed | email=${result.email}');
      return result;
    } on OauthCancelledException {
      rethrow;
    } on GoogleSignInException catch (e) {
      _logError('Google web: GoogleSignInException', e);
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw OauthCancelledException('Google sign-in cancelled');
      }
      rethrow;
    } catch (e, s) {
      _logError('Google web: sign-in error', e, s);
      rethrow;
    } finally {
      // Clean up waiter reference if it's still pending (shouldn't happen normally)
      if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
        _log('Google web: cleaning up pending waiter in finally block');
        _webSignInWaiter!.completeError(
          OauthCancelledException('Authentication process was interrupted'),
        );
        _webSignInWaiter = null;
      }
    }
  }

  static void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[OAuthSignInService] $message');
  }

  static void _logError(String message, [Object? error, StackTrace? stack]) {
    if (!kDebugMode) return;
    debugPrint('[OAuthSignInService] ERROR: $message');
    if (error != null) {
      debugPrint('[OAuthSignInService] Error details: $error');
      if (stack != null) {
        debugPrint('[OAuthSignInService] Stack trace: $stack');
      }
    }
  }

  static String _maskHead(String value, {int keep = 12}) {
    if (value.isEmpty) return '';
    if (value.length <= keep) return value;
    return '${value.substring(0, keep)}...';
  }

  static Future<void> _ensureFacebookInitialized() async {
    if (_facebookInitialized) return;
    try {
      _log('Facebook web initialization start | appId=${_maskHead(AppConfig.facebookWebAppId)} | version=${AppConfig.facebookWebSdkVersion}');
      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: AppConfig.facebookWebAppId,
        cookie: true,
        xfbml: true,
        version: AppConfig.facebookWebSdkVersion,
      );
      _facebookInitialized = true;
      _log('Facebook web initialization success');
    } catch (e, s) {
      _logError('Facebook web initialization failed', e, s);
      _facebookInitialized = false;
      rethrow;
    }
  }
}
