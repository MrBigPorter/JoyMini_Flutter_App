import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'package:flutter_app/app/routes/app_router.dart';

class DeepLinkService {
  // Singleton pattern
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void init() {
    _appLinks = AppLinks();

    // 1. Handle [Cold Start] (App is closed when link is clicked)
    _handleInitialUri();

    // 2. Handle [Hot Start / Background] (App is running in background)
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
        debugPrint('Deep Link detected (Cold Start): $uri');
        // Delay slightly to ensure Router is ready before navigating
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLinkTarget(uri);
        });
      }
    } catch (e) {
      debugPrint('Failed to get Initial Link: $e');
    }
  }

  static void _handleDeepLinkTarget(Uri uri) {
    // 1. Security check: scheme must match our updated 'joymini'
    if (uri.scheme != 'joymini') return;

    // 2. Match joymini://product/xxx
    if (uri.host == 'product') {
      final pid = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      final gid = uri.queryParameters['groupId'];

      if (pid != null && pid.isNotEmpty) {
        // Use global appRouter for navigation
        if (gid != null) {
          appRouter.push('/product/$pid?groupId=$gid');
        } else {
          appRouter.push('/product/$pid');
        }
      }
    }
    // 3. Match joymini://home (Fallback or specific home link)
    else if (uri.host == 'home') {
      appRouter.go('/home');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}