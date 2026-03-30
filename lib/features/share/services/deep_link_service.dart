import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // Track the last processed link and time to prevent duplicate jumps within a short window
  static String? _lastProcessedLink;
  static DateTime? _lastProcessTime;

  void init() {
    _appLinks = AppLinks();
    _handleInitialUri();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep Link detected (Hot Start): $uri');
      _handleDeepLinkTarget(uri);
    }, onError: (err) {
      debugPrint('Deep Link Error: $err');
    });
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        debugPrint('JoyMini [DeepLink] Cold Start detected: $uri');
        // IMPORTANT: _handleDeepLinkTarget is NO LONGER called here.
        // GoRouter's redirect logic in app_router.dart handles native links on cold starts.
        // We only record the link to prevent the Hot Start listener from triggering again.
        _lastProcessedLink = uri.toString();
        _lastProcessTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('Failed to get Initial Link: $e');
    }
  }

  static void _handleDeepLinkTarget(Uri uri, {bool isColdStart = false}) {
    // If the scheme is joymini://, exit immediately.
    // GoRouter's redirect logic has already handled this protocol.
    if (uri.scheme == 'joymini') {
      debugPrint('JoyMini [DeepLink] Scheme handled by GoRouter Redirect, Service exiting');
      return;
    }
    
    // Ignore Firebase OAuth callback URLs - these are handled internally by Firebase SDK
    // Pattern: com.googleusercontent.apps.*://firebaseauth/link?...
    // Check both scheme and full URL for firebaseauth
    if (uri.scheme.startsWith('com.googleusercontent.apps') || 
        uri.toString().contains('firebaseauth')) {
      debugPrint('JoyMini [DeepLink] Ignoring Firebase OAuth callback URL: ${uri.toString().substring(0, 100)}...');
      return;
    }
    
    // Ignore other Firebase auth callback URLs
    if (uri.toString().contains('firebaseauth/link')) {
      debugPrint('JoyMini [DeepLink] Ignoring Firebase auth callback URL');
      return;
    }

    // Handle HTTPS (Web sharing pages) logic here
    final currentLink = uri.toString();
    final now = DateTime.now();
    if (_lastProcessedLink == currentLink &&
        _lastProcessTime != null &&
        now.difference(_lastProcessTime!).inMilliseconds < 1500) {
      return;
    }
    _lastProcessedLink = currentLink;
    _lastProcessTime = now;

    String? pid;
    String? gid;

    if (uri.queryParameters.containsKey('pid')) {
      pid = uri.queryParameters['pid'];
      gid = uri.queryParameters['groupId'] ?? uri.queryParameters['gid'];
    }

    if (pid != null && pid.isNotEmpty) {
      _safeJump(pid, gid, isColdStart);
    }
  }

  static void _safeJump(String pid, String? gid, bool isColdStart) {
    if (!isAppRouterReady) {
      debugPrint('JoyMini [DeepLink] Waiting for router initialization...');
      Future.delayed(const Duration(milliseconds: 500), () => _safeJump(pid, gid, isColdStart));
      return;
    }

    // Anti-redirection check: Verify the current path displayed by GoRouter.
    final String currentLocation = appRouter.routerDelegate.currentConfiguration.uri.toString();

    // If the current path already contains the product ID, redirect has already reached the destination.
    if (currentLocation.contains(pid)) {
      debugPrint('JoyMini [DeepLink] Already on target page $pid, intercepting secondary jump');
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      debugPrint('JoyMini [DeepLink] Executing jump: $pid');
      try {
        appRouter.pushNamed(
          'productDetail',
          pathParameters: {'id': pid},
          queryParameters: gid != null ? {'groupId': gid} : {},
        );
      } catch (e) {
        debugPrint('JoyMini [DeepLink] Jump exception: $e');
      }
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}