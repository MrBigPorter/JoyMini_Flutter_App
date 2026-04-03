/// OAuth 取消异常
/// 当用户取消 OAuth 登录时抛出此异常
class OauthCancelledException implements Exception {
  final String message;
  OauthCancelledException(this.message);

  @override
  String toString() => message;
}

/// 通用 OAuth 异常（非取消类）
class OauthException implements Exception {
  final String message;
  OauthException(this.message);

  @override
  String toString() => message;
}
