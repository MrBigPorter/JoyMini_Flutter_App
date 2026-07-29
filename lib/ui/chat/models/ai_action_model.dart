/// 确认卡片数据（从 AI_CONFIRM 事件解析）
class AiConfirmData {
  final String action;
  final Map<String, dynamic> summary;
  final String confirmToken;
  final int expiresAt;

  AiConfirmData({
    required this.action,
    required this.summary,
    required this.confirmToken,
    required this.expiresAt,
  });

  factory AiConfirmData.fromJson(Map<String, dynamic> json) {
    return AiConfirmData(
      action: json['action'] as String,
      summary: Map<String, dynamic>.from(json['summary'] ?? {}),
      confirmToken: json['confirmToken'] as String,
      expiresAt: json['expiresAt'] as int,
    );
  }
}

/// 操作结果数据（从 AI_ACTION_RESULT 事件解析）
class AiActionResult {
  final String action;
  final bool success;
  final String message;

  AiActionResult({
    required this.action,
    required this.success,
    required this.message,
  });

  factory AiActionResult.fromJson(Map<String, dynamic> json) {
    return AiActionResult(
      action: json['action'] as String,
      success: json['success'] as bool,
      message: json['message'] as String? ?? '',
    );
  }
}

/// 卡片生命周期状态
enum ConfirmCardStatus {
  pending,    // 等待用户操作
  expired,    // 已过期
  loading,    // 确认中（调 API 中）
  success,    // 操作成功
  failed,     // 操作失败
  cancelled,  // 用户取消
}
