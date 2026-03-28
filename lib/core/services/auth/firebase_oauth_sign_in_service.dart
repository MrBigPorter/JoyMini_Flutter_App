import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../firebase_service.dart';
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
        await FirebaseService.initialize();
      }

      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final UserCredential userCredential;

      if (kIsWeb) {
        // Web: Use signInWithPopup for better UX
        _log('Google web sign-in using popup');
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Native: Use signInWithProvider
        _log('Google native sign-in using provider');
        userCredential =
            await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }

      final user = userCredential.user;
      if (user == null) {
        _log('Google sign-in failed: no user returned');
        return null;
      }

      // Get Firebase ID Token
      final idToken = await user.getIdToken();
      _log('Google sign-in success | email=${user.email} | uid=${user.uid}');

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

  /// Facebook Sign-In using Firebase
  /// Returns Firebase ID Token for backend verification
  static Future<String?> signInWithFacebook() async {
    try {
      _log('Facebook sign-in start via Firebase');

      // Ensure Firebase is initialized
      if (!FirebaseService.isInitialized) {
        await FirebaseService.initialize();
      }

      final FacebookAuthProvider facebookProvider = FacebookAuthProvider();
      facebookProvider.addScope('email');
      facebookProvider.addScope('public_profile');

      final UserCredential userCredential;

      if (kIsWeb) {
        // Web: Use signInWithPopup
        _log('Facebook web sign-in using popup');
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(facebookProvider);
      } else {
        // Native: Use signInWithProvider
        _log('Facebook native sign-in using provider');
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

      return idToken;
    } on FirebaseAuthException catch (e) {
      _log('Facebook sign-in FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        throw OauthCancelledException('Facebook sign-in cancelled');
      }
      rethrow;
    } catch (e) {
      _log('Facebook sign-in error: $e');
      rethrow;
    }
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
        // Web: Use signInWithPopup
        _log('Apple web sign-in using popup');
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(appleProvider);
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

