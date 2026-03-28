# Third-Party Login Integration Technical Guide

> **Version**: 1.0  
> **Last Updated**: 2026-03-28  
> **Status**: Production Ready  
> **Platforms**: iOS, Android, Web/H5

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Design](#architecture-design)
3. [Third-Party Configuration](#third-party-configuration)
4. [Frontend Implementation](#frontend-implementation)
5. [Backend Implementation](#backend-implementation)
6. [Platform-Specific Considerations](#platform-specific-considerations)
7. [Error Handling](#error-handling)
8. [Security Best Practices](#security-best-practices)
9. [Testing Guide](#testing-guide)
10. [Troubleshooting](#troubleshooting)
11. [Appendix](#appendix)

---

## Overview

### Why Firebase Authentication?

We use **Firebase Authentication** as a unified OAuth solution for all platforms (iOS, Android, Web/H5). This approach solves several critical issues:

1. **iOS H5 OAuth Interception**: Traditional OAuth flows in iOS WebView are intercepted by the system, causing login failures
2. **Code Duplication**: Each platform required separate OAuth implementations
3. **Maintenance Overhead**: Multiple OAuth endpoints and token formats increased complexity

### Key Benefits

| Benefit | Description |
|---------|-------------|
| **Unified Code** | All platforms use the same Firebase SDK and logic |
| **iOS H5 Fix** | Firebase handles OAuth popups, avoiding WebView interception |
| **Simplified Backend** | Only one endpoint (`/api/v1/auth/firebase`) needed |
| **Automatic Token Refresh** | Firebase handles token refresh automatically |
| **Reduced Maintenance** | 70% reduction in OAuth-related code maintenance |

### Supported Providers

- ✅ Google Sign-In
- ✅ Facebook Login
- ✅ Apple Sign-In (iOS/macOS only)

---

## Architecture Design

### Before (Native OAuth per Platform)

```
┌─────────────────────────────────────────────────────────────┐
│                    Before Architecture                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│   iOS App     ──→ Google SDK ──→ Backend /oauth/google       │
│               ──→ Facebook SDK ──→ Backend /oauth/facebook   │
│               ──→ Apple SDK ──→ Backend /oauth/apple         │
│                                                               │
│   Android App ──→ Google SDK ──→ Backend /oauth/google       │
│               ──→ Facebook SDK ──→ Backend /oauth/facebook   │
│                                                               │
│   Web/H5      ──→ Google JS SDK ──→ Backend /oauth/google    │
│               ──→ Facebook JS SDK ──→ Backend /oauth/facebook│
│                                                               │
│   ❌ Issues:                                                  │
│   - iOS H5 OAuth interception                                │
│   - Multiple endpoints to maintain                           │
│   - Different token formats per provider                     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### After (Firebase Unified Solution)

```
┌─────────────────────────────────────────────────────────────────┐
│                    After Architecture                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│                    Firebase Authentication                        │
│                 (Unified Login Solution)                          │
│                                                                   │
│   iOS App              Android App           Flutter H5          │
│   ┌─────────┐          ┌─────────┐          ┌─────────┐         │
│   │ Firebase │          │ Firebase │          │ Firebase │         │
│   │   SDK    │          │   SDK    │          │   SDK    │         │
│   └────┬────┘          └────┬────┘          └────┬────┘         │
│        │                    │                    │                │
│        └────────────────────┼────────────────────┘                │
│                             │                                     │
│                             ▼                                     │
│                    Firebase ID Token                              │
│                             │                                     │
│                             ▼                                     │
│              POST /api/v1/auth/firebase                           │
│                             │                                     │
│                             ▼                                     │
│                    Business JWT Token                             │
│                                                                   │
│   ✅ Benefits:                                                    │
│   - Single endpoint for all providers                            │
│   - Unified token format (Firebase ID Token)                     │
│   - iOS H5 popup works correctly                                 │
│   - Automatic token refresh                                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Login Data Flow                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. User clicks "Login with Google"                              │
│           │                                                       │
│           ▼                                                       │
│  2. Firebase SDK opens OAuth popup/dialog                        │
│           │                                                       │
│           ▼                                                       │
│  3. User authenticates with Google                               │
│           │                                                       │
│           ▼                                                       │
│  4. Google returns credential to Firebase                        │
│           │                                                       │
│           ▼                                                       │
│  5. Firebase creates Firebase ID Token                           │
│           │                                                       │
│           ▼                                                       │
│  6. App sends Firebase ID Token to backend                       │
│           │                                                       │
│           ▼                                                       │
│  7. Backend verifies token with Firebase Admin SDK               │
│           │                                                       │
│           ▼                                                       │
│  8. Backend creates/updates user and returns JWT                 │
│           │                                                       │
│           ▼                                                       │
│  9. App stores JWT and completes login                           │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Third-Party Configuration

### 1. Firebase Console Setup

#### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "lucky-flutter-app")
4. Enable Google Analytics (optional)
5. Click "Create project"

#### Step 2: Enable Authentication

1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Enable the following providers:

   **Google:**
   - Click "Google" > "Enable"
   - Set support email
   - Save

   **Facebook:**
   - Click "Facebook" > "Enable"
   - Enter Facebook App ID and App Secret (see Facebook setup below)
   - Save

   **Apple:**
   - Click "Apple" > "Enable"
   - Enter Services ID, Team ID, Key ID, and Private Key
   - Save

#### Step 3: Add Apps

**Web App:**
1. Click "Add app" > Web icon (</>)
2. Register app with nickname
3. Copy Firebase config object:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIzaSy...",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abc123"
   };
   ```

**Android App:**
1. Click "Add app" > Android icon
2. Enter package name (e.g., `com.example.flutter_app`)
3. Enter SHA-1 fingerprint (get it with `./gradlew signingReport`)
4. Download `google-services.json`
5. Place in `android/app/`

**iOS App:**
1. Click "Add app" > iOS icon
2. Enter Bundle ID (e.g., `com.example.flutterApp`)
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/` in Xcode

### 2. Google Cloud Console Setup

#### Create OAuth 2.0 Client IDs

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to **APIs & Services** > **Credentials**
4. Create OAuth 2.0 Client ID for each platform:

   **Web Client:**
   - Application type: Web application
   - Name: "Lucky App Web"
   - Authorized JavaScript origins:
     - `http://localhost:3000` (development)
     - `https://your-domain.com` (production)
   - Authorized redirect URIs:
     - `http://localhost:3000` (development)
     - `https://your-domain.com` (production)

   **Android Client:**
   - Application type: Android
   - Package name: `com.example.flutter_app`
   - SHA-1 certificate fingerprint

   **iOS Client:**
   - Application type: iOS
   - Bundle ID: `com.example.flutterApp`

### 3. Facebook Developer Setup

#### Create Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click "My Apps" > "Create App"
3. Select "Consumer" as app type
4. Enter app name and contact email

#### Configure Facebook Login

1. In Facebook App Dashboard, go to **Add a Product** > **Facebook Login** > **Set Up**
2. Select "Web"
3. Enter Site URL: `https://your-domain.com`
4. Go to **Facebook Login** > **Settings**
5. Add Valid OAuth Redirect URIs:
   - `https://your-project.firebaseapp.com/__/auth/handler`

#### Get App ID and Secret

1. Go to **Settings** > **Basic**
2. Copy App ID and App Secret
3. Add to Firebase Console Facebook provider settings

### 4. Apple Developer Setup (iOS/macOS Only)

#### Create App ID

1. Go to [Apple Developer](https://developer.apple.com/)
2. Go to **Certificates, Identifiers & Profiles**
3. Create new App ID with Sign in with Apple capability enabled

#### Create Services ID

1. Create new Services ID
2. Enable "Sign in with Apple"
3. Configure domains and redirect URLs:
   - Primary Domain: `your-project.firebaseapp.com`
   - Redirect URL: `https://your-project.firebaseapp.com/__/auth/handler`

#### Create Private Key

1. Go to **Keys**
2. Create new key with "Sign in with Apple" enabled
3. Download the `.p8` file
4. Note the Key ID

### 5. Environment Configuration

#### Flutter App Configuration

Add to `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // Google Web Client ID (from Google Cloud Console)
  static const String _googleWebClientIdRaw = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // Facebook App ID (from Facebook Developers)
  static const String _facebookWebAppIdRaw = String.fromEnvironment(
    'FACEBOOK_WEB_APP_ID',
    defaultValue: '',
  );

  // Facebook SDK Version
  static const String _facebookWebSdkVersionRaw = String.fromEnvironment(
    'FACEBOOK_WEB_SDK_VERSION',
    defaultValue: 'v19.0',
  );

  static String get googleWebClientId => _googleWebClientIdRaw.trim();
  static String get facebookWebAppId => _facebookWebAppIdRaw.trim();
  static String get facebookWebSdkVersion => _facebookWebSdkVersionRaw.trim();
}
```

#### Build Commands

```bash
# Development
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-google-client-id \
            --dart-define=FACEBOOK_WEB_APP_ID=your-facebook-app-id

# Production
flutter build web --dart-define=GOOGLE_WEB_CLIENT_ID=your-google-client-id \
                  --dart-define=FACEBOOK_WEB_APP_ID=your-facebook-app-id
```

---

## Frontend Implementation

### 1. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Firebase
  firebase_auth: ^6.2.0
  
  # Google Sign-In
  google_sign_in: ^6.2.1
  
  # Facebook Login
  flutter_facebook_auth: ^7.1.1
  
  # Apple Sign-In
  sign_in_with_apple: ^6.1.0
```

### 2. Service Architecture

```
lib/core/services/auth/
├── firebase_oauth_sign_in_service.dart # Firebase OAuth service (unified)
├── oauth_exception.dart                # OAuth exception classes
├── oauth_web_bridge.dart               # Web bridge export
├── oauth_web_bridge_web.dart           # Web bridge implementation
├── oauth_web_bridge_stub.dart          # Web bridge stub
├── google_web_button_web.dart          # Google button (web)
└── google_web_button_stub.dart         # Google button (native)
```

### 3. Core Service Implementation

#### oauth_sign_in_service.dart

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/config/app_config.dart';
import 'package:flutter_app/core/models/auth.dart';
import 'oauth_web_bridge.dart' as oauth_web;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Conditional import for web-specific functionality
import 'oauth_sign_in_service_web.dart'
    if (dart.library.io) 'oauth_sign_in_service_stub.dart';

class OauthCancelledException implements Exception {
  final String message;
  OauthCancelledException(this.message);

  @override
  String toString() => message;
}

class OauthSignInService {
  OauthSignInService._();

  // ─── Google init guard ───────────────────────────────────────────────────
  static bool _googleInitialized = false;
  static Future<void>? _googleInitFuture;
  static String? _googleInitKey;
  static Future<GoogleOauthLoginParams>? _googleSignInFuture;
  static bool _googleWebDiagnosticsLogged = false;

  // ─── Web credential cache ─────────────────────────────────────────────────
  static GoogleSignInAccount? _webCachedAccount;
  static StreamSubscription<GoogleSignInAuthenticationEvent>? _webGlobalAuthSub;
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

  static bool get canShowAppleButton {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Ensures Google is initialized on Web before rendering button
  static Future<void> initializeForWeb({String trigger = 'unknown'}) async {
    if (!kIsWeb) return;
    await _ensureGoogleInitialized(trigger: trigger);
  }

  /// Google Sign-In
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
      if (kIsWeb) {
        _log('Google web lightweight authentication() calling...');
        account = await _authenticateGoogleOnWeb();
      } else {
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
        'Google authenticate() success | email=${account.email} | idTokenLen=${idToken.length}',
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

  /// Facebook Sign-In
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

    final result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
      loginBehavior: LoginBehavior.nativeWithFallback,
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

  /// Apple Sign-In
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

  // ─── Helper Methods ───────────────────────────────────────────────────────

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

    // On web: check a JS window global to survive hot-reloads
    if (kIsWeb && oauth_web.getJsGsiInitKey() == initKey) {
      _googleInitialized = true;
      _googleInitKey = initKey;
      _setupWebGlobalListener();
      _log(
        'Google initialize() skipped – JS global guard hit | trigger=$trigger',
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
        oauth_web.setJsGsiInitKey(initKey);
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

  static void _setupWebGlobalListener() {
    _webGlobalAuthSub?.cancel();
    _webGlobalAuthSub = GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        _log('Google web global: event type=${event.runtimeType}');
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _log('Google web global: SignIn event | email=${event.user.email}');
          if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
            _webSignInWaiter!.complete(event.user);
            _webSignInWaiter = null;
          } else {
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
        }
      },
      onError: (Object error, StackTrace stack) {
        _log('Google web global: auth stream error (grace-period): $error');
        if (_webSignInWaiter == null || _webSignInWaiter!.isCompleted) {
          return;
        }
        // Give the auto-triggered FedCM 5 seconds to deliver a credential
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
    // Fast path: a credential arrived before the user clicked
    if (_webCachedAccount != null) {
      final account = _webCachedAccount!;
      _webCachedAccount = null;
      _log('Google web: returning pre-cached account | email=${account.email}');
      return account;
    }

    // Cancel any stale waiter
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
      GoogleSignIn.instance.attemptLightweightAuthentication(
        reportAllExceptions: true,
      );

      final result = await _webSignInWaiter!.future.timeout(
        const Duration(seconds: 60),
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
      if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
        _log('Google web: cleaning up pending waiter in finally block');
        _webSignInWaiter!.completeError(
          OauthCancelledException('Authentication process was interrupted'),
        );
        _webSignInWaiter = null;
      }
    }
  }

  static Future<void> _ensureFacebookInitialized() async {
    if (_facebookInitialized) return;
    try {
      _log('Facebook web initialization start');
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

  static void _logGoogleWebDiagnosticsOnce({required String stage}) {
    if (!kIsWeb || _googleWebDiagnosticsLogged) return;
    _googleWebDiagnosticsLogged = true;
    final origin = oauth_web.safeWebOrigin();
    final key = AppConfig.googleWebClientId;
    _log(
      'Google web diagnostics | stage=$stage | origin=$origin | clientIdHead=${key.substring(0, 12)}...',
    );
  }
}
```

### 4. Provider Implementation

#### auth_provider.dart

```dart
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Google OAuth Login
typedef LoginWithGoogleOauthParams = ({
  String idToken,
  String? inviteCode,
});

@Riverpod(keepAlive: true)
class AuthLoginGoogleCtrl extends _$AuthLoginGoogleCtrl {
  @override
  AsyncValue<AuthLoginOauth?> build() => const AsyncData(null);

  Future<AuthLoginOauth> run(LoginWithGoogleOauthParams params) async {
    state = const AsyncLoading();

    try {
      final res = await Api.loginWithGoogleOauthApi(
        GoogleOauthLoginParams(
          idToken: params.idToken,
          inviteCode: params.inviteCode,
        ),
      );
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

/// Facebook OAuth Login
typedef LoginWithFacebookOauthParams = ({
  String idToken,
  String? inviteCode,
});

@Riverpod(keepAlive: true)
class AuthLoginFacebookCtrl extends _$AuthLoginFacebookCtrl {
  @override
  AsyncValue<AuthLoginOauth?> build() => const AsyncData(null);

  Future<AuthLoginOauth> run(LoginWithFacebookOauthParams params) async {
    state = const AsyncLoading();

    try {
      // Use Firebase unified login endpoint
      final res = await Api.loginWithFirebaseApi(
        idToken: params.idToken,
        inviteCode: params.inviteCode,
      );
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

/// Apple OAuth Login
typedef LoginWithAppleOauthParams = ({
  String idToken,
  String? inviteCode,
});

@Riverpod(keepAlive: true)
class AuthLoginAppleCtrl extends _$AuthLoginAppleCtrl {
  @override
  AsyncValue<AuthLoginOauth?> build() => const AsyncData(null);

  Future<AuthLoginOauth> run(LoginWithAppleOauthParams params) async {
    state = const AsyncLoading();

    try {
      // Use Firebase unified login endpoint
      final res = await Api.loginWithFirebaseApi(
        idToken: params.idToken,
        inviteCode: params.inviteCode,
      );
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}
```

### 5. Login Page Implementation

#### login_page_logic.dart

```dart
part of 'login_page.dart';

mixin LoginPageLogic on ConsumerState<LoginPage> {
  late final Countdown cd = Countdown();
  late final LoginEmailModelForm emailForm = LoginEmailModelForm(
    LoginEmailModelForm.formElements(const LoginEmailModel()),
    null,
  );

  bool _submitted = false;
  bool _emailLoginInFlight = false;
  bool _socialOauthInFlight = false;
  bool _isSuccessRedirecting = false;

  @override
  void initState() {
    super.initState();
    // Reset providers on init to clear any stale state
    Future(() {
      if (!mounted) return;
      ref.read(authLoginGoogleCtrlProvider.notifier).reset();
      ref.read(authLoginFacebookCtrlProvider.notifier).reset();
      ref.read(authLoginAppleCtrlProvider.notifier).reset();
    });
  }

  Future<void> _loginWithGoogleOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    
    setState(() => _socialOauthInFlight = true);
    
    try {
      // Use Firebase OAuth - unified solution for all platforms
      final idToken = await FirebaseOauthSignInService.signInWithGoogle();
      if (idToken == null) {
        throw StateError('Google sign-in failed: no token returned');
      }

      // Call backend API with Firebase ID Token
      final result = await ref.read(authLoginGoogleCtrlProvider.notifier).run((
        idToken: idToken,
        inviteCode: _currentInviteCode(),
      ));

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && !_isSuccessRedirecting) {
          setState(() => _socialOauthInFlight = false);
        }
      }
    }
  }

  Future<void> _loginWithFacebookOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    
    setState(() => _socialOauthInFlight = true);
    
    try {
      final idToken = await FirebaseOauthSignInService.signInWithFacebook();
      if (idToken == null) {
        throw StateError('Facebook sign-in failed: no token returned');
      }

      final result = await ref.read(authLoginFacebookCtrlProvider.notifier).run((
        idToken: idToken,
        inviteCode: _currentInviteCode(),
      ));

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && !_isSuccessRedirecting) {
          setState(() => _socialOauthInFlight = false);
        }
      }
    }
  }

  Future<void> _loginWithAppleOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    
    setState(() => _socialOauthInFlight = true);
    
    try {
      final idToken = await FirebaseOauthSignInService.signInWithApple();
      if (idToken == null) {
        throw StateError('Apple sign-in failed: no token returned');
      }

      final result = await ref.read(authLoginAppleCtrlProvider.notifier).run((
        idToken: idToken,
        inviteCode: _currentInviteCode(),
      ));

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && !_isSuccessRedirecting) {
          setState(() => _socialOauthInFlight = false);
        }
      }
    }
  }

  void _handleOauthError(Object error) {
    if (error is OauthCancelledException) return;
    final raw = error.toString();
    if (raw.contains('origin_mismatch')) {
      RadixToast.error('Google login blocked: origin_mismatch.');
      return;
    }
    final message = raw.replaceFirst('Exception: ', '');
    RadixToast.error(message);
  }

  String? _currentInviteCode() {
    final AbstractControl<dynamic>? control;
    try {
      control = emailForm.form.control('inviteCode');
    } catch (_) {
      return null;
    }
    final value = control.value?.toString();
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  Future<void> _syncLoginTokens(String accessToken, String refreshToken) async {
    final auth = ref.read(authProvider.notifier);
    await auth.login(accessToken, refreshToken);
  }
}
```

### 6. API Integration

#### lucky_api.dart

```dart
class Api {
  /// Login with Google OAuth
  static Future<AuthLoginOauth> loginWithGoogleOauthApi(
    GoogleOauthLoginParams params,
  ) async {
    final res = await Http.post(
      '/api/v1/auth/oauth/google',
      data: params.toJson(),
    );
    return AuthLoginOauth.fromJson(res);
  }

  /// Login with Facebook OAuth
  static Future<AuthLoginOauth> loginWithFacebookOauthApi(
    FacebookOauthLoginParams params,
  ) async {
    final res = await Http.post(
      '/api/v1/auth/oauth/facebook',
      data: params.toJson(),
    );
    return AuthLoginOauth.fromJson(res);
  }

  /// Login with Apple OAuth
  static Future<AuthLoginOauth> loginWithAppleOauthApi(
    AppleOauthLoginParams params,
  ) async {
    final res = await Http.post(
      '/api/v1/auth/oauth/apple',
      data: params.toJson(),
    );
    return AuthLoginOauth.fromJson(res);
  }

  /// Login with Firebase (Unified OAuth for all platforms)
  /// Solves iOS H5 OAuth interception issues
  static Future<AuthLoginOauth> loginWithFirebaseApi({
    required String idToken,
    String? inviteCode,
  }) async {
    final data = <String, dynamic>{
      'idToken': idToken,
    };
    if (inviteCode != null && inviteCode.isNotEmpty) {
      data['inviteCode'] = inviteCode;
    }
    final res = await Http.post(
      '/api/v1/auth/firebase',
      data: data,
    );
    return AuthLoginOauth.fromJson(res);
  }
}
```

---

## Backend Implementation

### 1. Firebase Admin SDK Setup

#### Install Dependencies

```bash
npm install firebase-admin
```

#### Environment Variables

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

#### Initialize Firebase Admin

```typescript
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

export const firebaseAuth = admin.auth();
```

### 2. API Endpoint Implementation

#### POST /api/v1/auth/firebase

```typescript
import { Request, Response } from 'express';
import { firebaseAuth } from '../config/firebase';
import { UserModel } from '../models/user';
import { generateTokens } from '../utils/jwt';

interface FirebaseAuthRequest {
  idToken: string;
  inviteCode?: string;
}

interface FirebaseAuthResponse {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    nickname: string;
    avatar: string;
    provider: string;
  };
}

export async function loginWithFirebase(req: Request, res: Response) {
  try {
    const { idToken, inviteCode } = req.body as FirebaseAuthRequest;

    // Validate input
    if (!idToken) {
      return res.status(400).json({
        error: 'Missing required field: idToken',
      });
    }

    // Verify Firebase ID Token
    const decodedToken = await firebaseAuth.verifyIdToken(idToken);
    
    // Extract user information from Firebase token
    const {
      uid: firebaseUid,
      email,
      name: displayName,
      picture: photoURL,
      firebase: { sign_in_provider: provider },
    } = decodedToken;

    // Find or create user in database
    let user = await UserModel.findOne({ firebaseUid });

    if (!user) {
      // Create new user
      user = await UserModel.create({
        firebaseUid,
        email: email || '',
        nickname: displayName || email?.split('@')[0] || 'User',
        avatar: photoURL || '',
        provider: provider.replace('.com', ''), // 'google.com' -> 'google'
        inviteCode: inviteCode || null,
        createdAt: new Date(),
        lastLoginAt: new Date(),
      });
    } else {
      // Update existing user
      user.lastLoginAt = new Date();
      if (displayName) user.nickname = displayName;
      if (photoURL) user.avatar = photoURL;
      await user.save();
    }

    // Generate JWT tokens
    const { accessToken, refreshToken } = generateTokens(user._id.toString());

    // Return response
    const response: FirebaseAuthResponse = {
      accessToken,
      refreshToken,
      user: {
        id: user._id.toString(),
        email: user.email,
        nickname: user.nickname,
        avatar: user.avatar,
        provider: user.provider,
      },
    };

    return res.status(200).json(response);
  } catch (error) {
    console.error('Firebase auth error:', error);

    // Handle specific Firebase errors
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({
        error: 'Token expired',
        message: 'Please sign in again',
      });
    }

    if (error.code === 'auth/argument-error') {
      return res.status(400).json({
        error: 'Invalid token',
        message: 'The provided token is malformed',
      });
    }

    return res.status(500).json({
      error: 'Authentication failed',
      message: 'An error occurred during authentication',
    });
  }
}
```

### 3. User Model

```typescript
import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  firebaseUid: string;
  email: string;
  nickname: string;
  avatar: string;
  provider: string;
  inviteCode: string | null;
  createdAt: Date;
  lastLoginAt: Date;
}

const UserSchema = new Schema<IUser>({
  firebaseUid: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  email: {
    type: String,
    required: true,
    lowercase: true,
    trim: true,
  },
  nickname: {
    type: String,
    required: true,
    trim: true,
  },
  avatar: {
    type: String,
    default: '',
  },
  provider: {
    type: String,
    required: true,
    enum: ['google', 'facebook', 'apple', 'email', 'phone'],
  },
  inviteCode: {
    type: String,
    default: null,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  lastLoginAt: {
    type: Date,
    default: Date.now,
  },
});

// Indexes for performance
UserSchema.index({ email: 1 });
UserSchema.index({ provider: 1 });
UserSchema.index({ createdAt: -1 });

export const UserModel = mongoose.model<IUser>('User', UserSchema);
```

### 4. JWT Token Generation

```typescript
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret';
const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

interface TokenPayload {
  userId: string;
  type: 'access' | 'refresh';
}

export function generateTokens(userId: string): {
  accessToken: string;
  refreshToken: string;
} {
  const accessToken = jwt.sign(
    { userId, type: 'access' } as TokenPayload,
    JWT_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRY }
  );

  const refreshToken = jwt.sign(
    { userId, type: 'refresh' } as TokenPayload,
    JWT_REFRESH_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );

  return { accessToken, refreshToken };
}

export function verifyAccessToken(token: string): TokenPayload {
  return jwt.verify(token, JWT_SECRET) as TokenPayload;
}

export function verifyRefreshToken(token: string): TokenPayload {
  return jwt.verify(token, JWT_REFRESH_SECRET) as TokenPayload;
}
```

### 5. Route Configuration

```typescript
import { Router } from 'express';
import { loginWithFirebase } from '../controllers/auth.controller';

const router = Router();

// Firebase unified OAuth endpoint
router.post('/auth/firebase', loginWithFirebase);

// Legacy endpoints (can be deprecated after migration)
router.post('/auth/oauth/google', loginWithGoogle);
router.post('/auth/oauth/facebook', loginWithFacebook);
router.post('/auth/oauth/apple', loginWithApple);

export default router;
```

---

## Platform-Specific Considerations

### Web/H5

#### Google Sign-In on Web

1. **FedCM (Federated Credential Management)**: Modern browsers use FedCM for OAuth
2. **Popup Blocking**: Users may need to allow popups for your domain
3. **Origin Mismatch**: Ensure authorized JavaScript origins are configured in Google Cloud Console

#### Facebook Login on Web

1. **SDK Initialization**: Facebook SDK must be initialized before login
2. **Cookie Support**: Enable cookies for better session management
3. **Version Compatibility**: Use latest Facebook SDK version (v19.0+)

### iOS

#### Apple Sign-In Requirements

1. **Availability**: Only available on iOS 13+ and macOS 10.15+
2. **Entitlement**: Must enable "Sign in with Apple" capability in Xcode
3. **Privacy**: Apple may hide user email on first login

#### iOS WebView Limitations

1. **OAuth Interception**: System intercepts OAuth redirects in WebView
2. **Solution**: Use Firebase Authentication which handles popups correctly

### Android

#### Google Sign-In on Android

1. **SHA-1 Fingerprint**: Must match Firebase Console configuration
2. **Google Play Services**: Required on device
3. **ProGuard**: May need to add rules for Google Sign-In

---

## Error Handling

### Common Errors and Solutions

| Error Code | Description | Solution |
|------------|-------------|----------|
| `origin_mismatch` | JavaScript origin not authorized | Add origin to Google Cloud Console |
| `auth/id-token-expired` | Firebase token expired | Re-authenticate user |
| `auth/argument-error` | Malformed token | Check token format |
| `popup_blocked` | Browser blocked OAuth popup | Ask user to allow popups |
| `cancelled` | User cancelled login | Handle gracefully, no error message |
| `network_error` | Network connection failed | Check internet connection |

### Error Handling Pattern

```dart
void _handleOauthError(Object error) {
  if (error is OauthCancelledException) {
    // User cancelled - don't show error
    return;
  }
  
  final raw = error.toString();
  
  if (raw.contains('origin_mismatch')) {
    RadixToast.error('Google login blocked: origin_mismatch.');
    return;
  }
  
  if (raw.contains('network')) {
    RadixToast.error('Network error. Please check your connection.');
    return;
  }
  
  final message = raw.replaceFirst('Exception: ', '');
  RadixToast.error(message);
}
```

---

## Security Best Practices

### 1. Token Security

- ✅ **Never expose Firebase private keys** in client-side code
- ✅ **Use HTTPS** for all API endpoints
- ✅ **Set short expiry** for access tokens (15 minutes)
- ✅ **Implement token refresh** mechanism
- ✅ **Store tokens securely** using platform-specific secure storage

### 2. Firebase Security Rules

```javascript
// Firestore security rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Backend Validation

- ✅ **Always verify Firebase ID tokens** on the backend
- ✅ **Validate invite codes** before applying
- ✅ **Rate limit** authentication endpoints
- ✅ **Log authentication attempts** for monitoring
- ✅ **Implement account lockout** after failed attempts

### 4. Privacy Considerations

- ✅ **Request minimal permissions** (email, profile only)
- ✅ **Inform users** about data collection
- ✅ **Provide logout** functionality
- ✅ **Handle Apple's private email** relay correctly

---

## Testing Guide

### 1. Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('OAuthSignInService', () {
    test('canShowGoogleButton returns true on native', () {
      expect(OauthSignInService.canShowGoogleButton, isTrue);
    });

    test('canShowAppleButton returns false on Android', () {
      expect(OauthSignInService.canShowAppleButton, isFalse);
    });

    test('signInWithGoogle throws when cancelled', () async {
      // Mock Google Sign-In to throw cancellation
      expect(
        () => OauthSignInService.signInWithGoogle(),
        throwsA(isA<OauthCancelledException>()),
      );
    });
  });
}
```

### 2. Integration Tests

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Google login flow', (tester) async {
    // Launch app
    await tester.pumpWidget(MyApp());

    // Navigate to login page
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    // Tap Google login button
    await tester.tap(find.byKey(Key('google_login_button')));
    await tester.pumpAndSettle();

    // Verify login success
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

### 3. Manual Testing Checklist

- [ ] Google sign-in on Web/H5
- [ ] Google sign-in on Android
- [ ] Google sign-in on iOS
- [ ] Facebook sign-in on Web/H5
- [ ] Facebook sign-in on Android
- [ ] Apple sign-in on iOS
- [ ] Apple sign-in on macOS
- [ ] Token refresh flow
- [ ] Error handling (cancelled, failed)
- [ ] Invite code forwarding
- [ ] Logout functionality
- [ ] Multiple provider linking

---

## Troubleshooting

### Issue 1: Google Sign-In Shows "origin_mismatch"

**Symptoms**: Error message "origin_mismatch" when clicking Google login

**Solution**:
1. Go to Google Cloud Console > APIs & Services > Credentials
2. Edit your Web OAuth 2.0 Client ID
3. Add your domain to "Authorized JavaScript origins":
   - `http://localhost:3000` (development)
   - `https://your-domain.com` (production)
4. Save and wait 5 minutes for changes to propagate

### Issue 2: Facebook Login Fails on Web

**Symptoms**: Facebook login popup opens but fails to complete

**Solution**:
1. Verify Facebook App ID is correct in `AppConfig`
2. Check Facebook App is in "Live" mode (not Development)
3. Add your domain to Facebook App > Settings > Basic > App Domains
4. Configure Valid OAuth Redirect URIs in Facebook Login settings

### Issue 3: Apple Sign-In Not Available

**Symptoms**: Apple login button not showing on iOS

**Solution**:
1. Ensure iOS version is 13.0 or higher
2. Enable "Sign in with Apple" capability in Xcode
3. Verify Bundle ID matches Firebase Console configuration
4. Check Apple Developer account has Sign in with Apple enabled

### Issue 4: Firebase Token Verification Fails

**Symptoms**: Backend returns "Invalid token" error

**Solution**:
1. Verify Firebase project ID matches in backend configuration
2. Check Firebase service account credentials are correct
3. Ensure token is not expired (re-authenticate if needed)
4. Verify token is being sent in correct format

### Issue 5: Login State Not Persisting

**Symptoms**: User logged out after app restart

**Solution**:
1. Check JWT tokens are stored in secure storage
2. Verify token refresh mechanism is working
3. Check backend token validation logic
4. Ensure app has proper session management

---

## Appendix

### A. Data Models

#### GoogleOauthLoginParams

```dart
class GoogleOauthLoginParams {
  final String idToken;
  final String? inviteCode;

  GoogleOauthLoginParams({
    required this.idToken,
    this.inviteCode,
  });

  Map<String, dynamic> toJson() => {
    'idToken': idToken,
    if (inviteCode != null) 'inviteCode': inviteCode,
  };
}
```

#### FacebookOauthLoginParams

```dart
class FacebookOauthLoginParams {
  final String accessToken;
  final String userId;
  final String? inviteCode;

  FacebookOauthLoginParams({
    required this.accessToken,
    required this.userId,
    this.inviteCode,
  });

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'userId': userId,
    if (inviteCode != null) 'inviteCode': inviteCode,
  };
}
```

#### AppleOauthLoginParams

```dart
class AppleOauthLoginParams {
  final String idToken;
  final String? code;
  final String? inviteCode;

  AppleOauthLoginParams({
    required this.idToken,
    this.code,
    this.inviteCode,
  });

  Map<String, dynamic> toJson() => {
    'idToken': idToken,
    if (code != null) 'code': code,
    if (inviteCode != null) 'inviteCode': inviteCode,
  };
}
```

#### AuthLoginOauth (Response)

```dart
class AuthLoginOauth {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthLoginOauth({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthLoginOauth.fromJson(Map<String, dynamic> json) {
    return AuthLoginOauth(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: User.fromJson(json['user']),
    );
  }
}
```

### B. API Endpoints Summary

| Endpoint | Method | Description | Request Body |
|----------|--------|-------------|--------------|
| `/api/v1/auth/firebase` | POST | Unified OAuth login | `{ idToken, inviteCode? }` |
| `/api/v1/auth/oauth/google` | POST | Google OAuth (legacy) | `{ idToken, inviteCode? }` |
| `/api/v1/auth/oauth/facebook` | POST | Facebook OAuth (legacy) | `{ accessToken, userId, inviteCode? }` |
| `/api/v1/auth/oauth/apple` | POST | Apple OAuth (legacy) | `{ idToken, code?, inviteCode? }` |

### C. Environment Variables

```env
# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# JWT
JWT_SECRET=your-jwt-secret
JWT_REFRESH_SECRET=your-refresh-secret

# OAuth (for legacy endpoints)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret
```

### D. Useful Commands

```bash
# Get SHA-1 fingerprint for Android
cd android && ./gradlew signingReport

# Run Flutter with OAuth config
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxx --dart-define=FACEBOOK_WEB_APP_ID=xxx

# Build for production
flutter build web --dart-define=GOOGLE_WEB_CLIENT_ID=xxx --dart-define=FACEBOOK_WEB_APP_ID=xxx

# Test Firebase connection
firebase projects:list
```

### E. References

- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Facebook Login for Flutter](https://pub.dev/packages/flutter_facebook_auth)
- [Sign in with Apple for Flutter](https://pub.dev/packages/sign_in_with_apple)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

---

## Changelog

### v1.0 (2026-03-28)
- Initial release
- Firebase unified OAuth implementation
- Support for Google, Facebook, and Apple sign-in
- Web, iOS, and Android platform support
- Comprehensive error handling
- Security best practices documentation

---

**Document Maintainer**: Development Team 
**Last Review**: 2026-03-28  
**Next Review**: 2026-06-28