import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/store/config_store.dart';
import '../ui/chat/providers/contact_provider.dart';
import '../ui/chat/providers/conversation_provider.dart';

part 'app_startup.g.dart';

@Riverpod(keepAlive: true)
Future<void> appStartup(AppStartupRef ref) async {
  debugPrint("🚀 [AppStartup] Starting application initialization...");
  
  // 1. 监听认证状态（但不等待）
  ref.watch(authProvider);
  debugPrint("🚀 [AppStartup] Auth provider watched");

  // 异步获取配置
  Future.microtask(() async {
    try {
      debugPrint("🚀 [AppStartup] Fetching latest config...");
      final notifier = ref.read(configProvider.notifier);
      await notifier.fetchLatest();
      debugPrint("🚀 [AppStartup] Config fetched successfully");
    } catch (e) {
      debugPrint("⚠️ [AppStartup] Config fetch failed (non-critical): $e");
    }
  });

  final authState = ref.read(authProvider);
  debugPrint("🚀 [AppStartup] Auth state: isAuthenticated=${authState.isAuthenticated}");

  // 2. 如果已认证
  if (authState.isAuthenticated) {
    String? userId;
    debugPrint("🚀 [AppStartup] User is authenticated, preparing database initialization");

    // ---------------------------------------------------------
    // 快速解决方案：直接从磁盘读取UserID（绕过Store）
    // ---------------------------------------------------------
    try {
      debugPrint("🚀 [AppStartup] Reading user ID from SharedPreferences...");
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('lucky_state');

      if (jsonStr != null && jsonStr.isNotEmpty) {
        debugPrint("🚀 [AppStartup] Found lucky_state data, parsing...");
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        // 手动解析：root -> userInfo -> id
        if (data['userInfo'] != null) {
          userId = data['userInfo']['id'];
          debugPrint("✅ [AppStartup] UserID retrieved from disk: $userId");
        } else {
          debugPrint("⚠️ [AppStartup] userInfo not found in lucky_state data");
        }
      } else {
        debugPrint("⚠️ [AppStartup] No lucky_state data found in SharedPreferences");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ [AppStartup] Disk read/parse failed: $e");
      debugPrint("❌ [AppStartup] Stack trace: $stackTrace");
    }

    // ---------------------------------------------------------
    // 3. 初始化数据库（毫秒级，无延迟）
    // ---------------------------------------------------------
    if (userId != null && userId.isNotEmpty) {
      debugPrint("🚀 [AppStartup] Initializing database for user: $userId");
      try {
        // 初始化数据库
        await LocalDatabaseService.init(userId);
        debugPrint("✅ [AppStartup] Database initialized successfully");

        // 数据库初始化完成后，触发后台数据预加载
        debugPrint("🚀 [AppStartup] Starting background data pre-fetching...");
        
        // 1. 预热通讯录 (API -> DB -> 内存)
        try {
          ref.read(contactListProvider);
          debugPrint("✅ [AppStartup] Contact list pre-fetched");
        } catch (e) {
          debugPrint("⚠️ [AppStartup] Contact list pre-fetch failed: $e");
        }

        // 2. 预热会话列表
        try {
          ref.read(conversationListProvider);
          debugPrint("✅ [AppStartup] Conversation list pre-fetched");
        } catch (e) {
          debugPrint("⚠️ [AppStartup] Conversation list pre-fetch failed: $e");
        }

        // 3. 预热联系人实体
        try {
          ref.read(contactEntitiesProvider);
          debugPrint("✅ [AppStartup] Contact entities pre-fetched");
        } catch (e) {
          debugPrint("⚠️ [AppStartup] Contact entities pre-fetch failed: $e");
        }

        debugPrint("✅ [AppStartup] Background data pre-fetching completed");
      } catch (e, stackTrace) {
        debugPrint("❌ [AppStartup] Database initialization failed: $e");
        debugPrint("❌ [AppStartup] Stack trace: $stackTrace");
      }
    } else {
      // 仅在新安装或数据损坏时发生
      debugPrint("⚠️ [AppStartup] No user ID available, skipping database initialization");
      debugPrint("⚠️ [AppStartup] Database will be initialized lazily when needed");
    }
  } else {
    debugPrint("ℹ️ [AppStartup] User not authenticated, skipping database initialization");
  }
  
  debugPrint("✅ [AppStartup] Application initialization completed");
}
