/// OAuth 取消异常
/// 当用户取消 OAuth 登录时抛出此异常
class OauthCancelledException implements Exception {
  final String message;
  OauthCancelledException(this.message);

  @override
  String toString() => message;
}