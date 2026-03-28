import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Service - Unified authentication layer for all platforms
/// Solves iOS H5 OAuth interception issues by using Firebase Authentication
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  /// Initialize Firebase - must be called before using any Firebase services
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      _log('Firebase initialized successfully');
    } catch (e) {
      _log('Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Get Firebase Auth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;

  static void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[FirebaseService] $message');
  }
}

/// Firebase configuration for different platforms
/// TODO: Replace with actual Firebase project configuration
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
          apiKey: "AIzaSyB3f2FsRBxYp4dl92BPKoOBegvaqnWVBfs",
          authDomain: "adroit-outlet-444914-m0.firebaseapp.com",
          projectId: "adroit-outlet-444914-m0",
          storageBucket: "adroit-outlet-444914-m0.firebasestorage.app",
          messagingSenderId: "1065683669109",
          appId: "1:1065683669109:web:5b56910ea9f9953f7a283c",
          measurementId: "G-Y4FD1G7Q1H"
      );
    }

    // For native platforms, configuration will be loaded from:
    // - Android: android/app/google-services.json
    // - iOS: ios/Runner/GoogleService-Info.plist
    // These files should be downloaded from Firebase Console
    throw UnsupportedError(
      'Firebase options not configured for this platform. '
      'Please download google-services.json (Android) or GoogleService-Info.plist (iOS) '
      'from Firebase Console.',
    );
  }
}