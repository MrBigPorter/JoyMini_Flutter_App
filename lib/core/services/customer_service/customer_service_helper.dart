import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';

import 'package:flutter_app/core/api/lucky_api.dart';

enum CustomerServiceScene { support, business }

/// Customer Service Helper: Handles initiating customer service chats
class CustomerServiceHelper {
  static const String defaultSupportBusinessId = 'official_platform_support_v1';

  // Prevent multiple simultaneous chat initiations
  static bool _isLoading = false;

  // start customer service chat
  static Future<void> startChat({
    CustomerServiceScene scene = CustomerServiceScene.support,
    String? businessId,
  }) async {
    if (_isLoading) return;

    final resolvedBusinessId = _resolveBusinessId(
      scene: scene,
      businessId: businessId,
    );
    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      RadixToast.error('Missing customer service business id.');
      return;
    }

    _isLoading = true;
    RadixToast.showLoading(); // 全局弹窗 loading

    try {
      final conversation = await Api.chatBusinessApi(resolvedBusinessId);

      RadixToast.hide();

      appRouter.push('/chat/room/${conversation.conversationId}');
    } catch (e) {
      RadixToast.hide();
      RadixToast.error('Customer service is currently unavailable.');
      debugPrint('[CustomerService] Error: $e');
    } finally {
      _isLoading = false;
    }
  }

  static String? _resolveBusinessId({
    required CustomerServiceScene scene,
    String? businessId,
  }) {
    if (businessId != null && businessId.isNotEmpty) {
      return businessId;
    }

    if (scene == CustomerServiceScene.support) {
      return defaultSupportBusinessId;
    }

    return null;
  }
}
