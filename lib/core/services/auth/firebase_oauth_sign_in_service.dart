import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../firebase_service.dart';
import 'global_oauth_handler.dart';
import 'oauth_exception.dart';

/// Firebase OAuth Sign-In Service
/// Unified authentication using Firebase Authentication for all platforms
/// Solves iOS H5 OAuth interception issues
class FirebaseOauthSignInService {
  FirebaseOauthSignInService._();

  static bool _googleInitialized = false;
  static bool _facebookInitialized = false;

  /// Check if Google sign-in is available
  static bool get canShowGoogleButton {
    // Firebase handles Google sign-in on all platforms
    return true;
  }

  /// Check if Facebook sign-in is available
  static bool get canShowFacebookButton {
    // Firebase handles Facebook sign-in on all platforms
    return true;
  }

  /// Check if Apple sign-in is available
  static bool get canShowAppleButton {
    // Apple sign-in is available on iOS, macOS, and web via Firebase
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Google Sign-In using Firebase
  /// Returns Firebase ID Token for backend verification
  static Future<String?> signInWithGoogle() async {
    try {
      _log('Google sign-in start via Firebase');

      // Ensure Firebase is initialized
      if (!FirebaseService.isInitialized) {
        _log('Firebase not initialized, initializing now...');
        await FirebaseService.initialize();
      } else {
        _log('Firebase already initialized');
      }

      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final UserCredential userCredential;

      if (kIsWeb) {
        // Web: Use signInWithRedirect — avoids popup-blocked / ITP / WebView issues.
        // The page navigates away to Google; result is handled by
        // handleWebRedirectResult() called on app startup via getRedirectResult().
        _log('Google web sign-in using redirect');
        await FirebaseAuth.instance.signInWithRedirect(googleProvider);
        return null; // unreachable — page navigates away
      } else {
        // Native: Use signInWithProvider
        _log('Google native sign-in using provider');
        userCredential =
            await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }

      _log('Google sign-in completed, userCredential received');
      final user = userCredential.user;
      if (user == null) {
        _log('Google sign-in failed: no user returned');
        return null;
      }

      _log('Google user obtained: email=${user.email} | uid=${user.uid} | isAnonymous=${user.isAnonymous}');
      
      // Get Firebase ID Token
      _log('Getting Firebase ID Token...');
      final idToken = await user.getIdToken();
      _log('Google sign-in success | email=${user.email} | uid=${user.uid} | idToken length=${idToken?.length ?? 0}');

      return idToken;
    } on FirebaseAuthException catch (e) {
      _log('Google sign-in FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        throw OauthCancelledException('Google sign-in cancelled');
      }
      rethrow;
    } catch (e) {
      _log('Google sign-in error: $e');
      rethrow;
    }
  }

  /// Google Sign-In with automatic backend processing
  /// Uses GlobalOAuthHandler to handle the entire flow
  /// This is the recommended method for Native platforms
  static Future<void> signInWithGoogleAndProcess() async {
    try {
      _log('Starting Google OAuth with automatic processing...');
      
      // Get ID Token from Firebase
      final idToken = await signInWithGoogle();
      
      if (idToken == null) {
        _log('Google sign-in failed: no token returned');
        throw StateError('Google sign-in failed: no token returned');
      }

      _log('Google sign-in successful, processing with GlobalOAuthHandler...');
      
      // Use GlobalOAuthHandler to process the callback
      // This handles backend API call, token sync, and navigation
      await GlobalOAuthHandler.handleGoogleOAuthCallback(idToken: idToken);
      
      _log('Google OAuth processing completed successfully');
    } catch (e) {
      _log('Google OAuth processing failed: $e');
      rethrow;
    }
  }

  /// Facebook Sign-In
  /// iOS/Android: Use native SDK (required by Facebook TOS)
  /// Web: Use Firebase
  static Future<Map<String, String>?> signInWithFacebook() async {
    try {
      _log('Facebook sign-in start');

      if (!kIsWeb) {
        // iOS/Android: Use native Facebook SDK (required by Facebook TOS)
        return await _signInWithFacebookNative();
      } else {
        // Web: Use Firebase
        return await _signInWithFacebookFirebase();
      }
    } catch (e) {
      _log('Facebook sign-in error: $e');
      rethrow;
    }
  }

  /// Facebook sign-in using native SDK (iOS/Android)
  static Future<Map<String, String>?> _signInWithFacebookNative() async {
    _log('Facebook iOS/Android: Using native Facebook SDK');
    
    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.cancelled) {
      throw OauthCancelledException('Facebook sign-in cancelled');
    }
    
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw StateError(result.message ?? 'Facebook sign-in failed');
    }

    final accessToken = result.accessToken!;

    // 打印完整信息用于调试
    print('Facebook login result: ${accessToken.runtimeType} | ${accessToken.toJson()}');

    // 取出基础字段
    final Map<String, String> data = {
      'accessToken': accessToken.tokenString,
      'type': accessToken.type.name,
    };

    // 根据类型取出 userId 和其他字段
    if (accessToken is LimitedToken) {
      final limitedToken = accessToken;
      data['userId'] = limitedToken.userId;
      data['userName'] = limitedToken.userName;
      data['userEmail'] = limitedToken.userEmail ?? '';
      data['nonce'] = limitedToken.nonce;
      _log('LimitedToken extracted: userId=${limitedToken.userId}, userName=${limitedToken.userName}');
    } else if (accessToken is ClassicToken) {
      final classicToken = accessToken;
      data['userId'] = classicToken.userId;
      data['expires'] = classicToken.expires.toIso8601String();
      data['applicationId'] = classicToken.applicationId;
      _log('ClassicToken extracted: userId=${classicToken.userId}');
    }

    return data;
  }

  /// Facebook sign-in using Firebase (Android/Web)
  static Future<Map<String, String>?> _signInWithFacebookFirebase() async {
    _log('Facebook: Using Firebase OAuth provider');
    
    // Ensure Firebase is initialized
    if (!FirebaseService.isInitialized) {
      await FirebaseService.initialize();
    }

    final FacebookAuthProvider facebookProvider = FacebookAuthProvider();
    facebookProvider.addScope('email');
    facebookProvider.addScope('public_profile');

    final UserCredential userCredential;

    if (kIsWeb) {
      // Web: Use signInWithRedirect — avoids popup-blocked / ITP / WebView issues.
      // Result is handled by handleWebRedirectResult() on app startup.
      _log('Facebook web sign-in using redirect');
      await FirebaseAuth.instance.signInWithRedirect(facebookProvider);
      return null; // unreachable — page navigates away
    } else {
      // Android: Use signInWithProvider
      _log('Facebook Android sign-in using provider');
      userCredential =
          await FirebaseAuth.instance.signInWithProvider(facebookProvider);
    }

    final user = userCredential.user;
    if (user == null) {
      _log('Facebook sign-in failed: no user returned');
      return null;
    }

    // Get Firebase ID Token
    final idToken = await user.getIdToken();
    _log('Facebook sign-in success | email=${user.email} | uid=${user.uid}');

    // Return Firebase ID Token for backend
    return {
      'idToken': idToken!,
    };
  }

  /// Apple Sign-In using Firebase
  /// Returns Firebase ID Token for backend verification
  static Future<String?> signInWithApple() async {
    try {
      _log('Apple sign-in start via Firebase');

      // Ensure Firebase is initialized
      if (!FirebaseService.isInitialized) {
        await FirebaseService.initialize();
      }

      final AppleAuthProvider appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final UserCredential userCredential;

      if (kIsWeb) {
        // Web: Use signInWithRedirect — avoids popup-blocked / ITP / WebView issues.
        // Result is handled by handleWebRedirectResult() on app startup.
        _log('Apple web sign-in using redirect');
        await FirebaseAuth.instance.signInWithRedirect(appleProvider);
        return null; // unreachable — page navigates away
      } else {
        // Native: Use signInWithProvider
        _log('Apple native sign-in using provider');
        userCredential =
            await FirebaseAuth.instance.signInWithProvider(appleProvider);
      }

      final user = userCredential.user;
      if (user == null) {
        _log('Apple sign-in failed: no user returned');
        return null;
      }

      // Get Firebase ID Token
      final idToken = await user.getIdToken();
      _log('Apple sign-in success | email=${user.email} | uid=${user.uid}');

      return idToken;
    } on FirebaseAuthException catch (e) {
      _log('Apple sign-in FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        throw OauthCancelledException('Apple sign-in cancelled');
      }
      rethrow;
    } catch (e) {
      _log('Apple sign-in error: $e');
      rethrow;
    }
  }

  /// Web 专用：处理 signInWithRedirect 跳转回来后的 OAuth 结果。
  /// 必须在 App 启动时（Firebase 初始化 + GlobalOAuthHandler.initialize 完成后）调用一次。
  /// Native 平台调用此方法是无操作（kIsWeb guard）。
  ///
  /// 支持 Google / Apple / Facebook 三种 provider 的 redirect 结果，
  /// 统一通过 GlobalOAuthHandler.handleGoogleOAuthCallback 完成后续流程
  /// （后端 API → Token 同步 → 导航）。
  static Future<void> handleWebRedirectResult() async {
    if (!kIsWeb) return;
    try {
      _log('Web: checking getRedirectResult...');
      final userCredential = await FirebaseAuth.instance.getRedirectResult();

      if (userCredential.user == null) {
        _log('Web: no redirect result (normal cold start)');
        return;
      }

      _log('Web: redirect result received | email=${userCredential.user?.email} | uid=${userCredential.user?.uid}');

      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) {
        _log('Web: redirect result — failed to get idToken');
        return;
      }

      // 复用全局处理器：后端 API → Token 同步 → 导航
      await GlobalOAuthHandler.handleGoogleOAuthCallback(idToken: idToken);
      _log('Web: redirect result processed successfully');
    } on FirebaseAuthException catch (e) {
      _log('Web: getRedirectResult FirebaseAuthException: ${e.code} - ${e.message}');
      // 不 rethrow，避免影响正常启动流程
    } catch (e) {
      _log('Web: getRedirectResult unknown error: $e');
    }
  }

  /// Sign out from Firebase
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      _log('Firebase sign-out success');
    } catch (e) {
      _log('Firebase sign-out error: $e');
      rethrow;
    }
  }

  /// Get current Firebase user
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  /// Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  static void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[FirebaseOauthSignInService] $message');
  }
}

