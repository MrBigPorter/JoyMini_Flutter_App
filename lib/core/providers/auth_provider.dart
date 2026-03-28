import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// 1) 发送 OTP
@Riverpod(keepAlive: true)
class SendOtpCtrl extends _$SendOtpCtrl {
  @override
  AsyncValue<OtpRequest?> build() => const AsyncData(null);

  Future<OtpRequest> run(String phone) async {
    state = const AsyncLoading();

    try {
      final res = await Api.otpRequestApi(phone);
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

/// 2) 校验 OTP
@Riverpod(keepAlive: true)
class VerifyOtpCtrl extends _$VerifyOtpCtrl {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> run(String phone, String code) async {
    state = const AsyncLoading();

    try {
      await Api.optVerifyApi(phone: phone, code: code);
      state = const AsyncData(null);
      return true;
    } catch (e, s) {
      state = AsyncError(e, s);
      return false;
    }
  }

  void reset() => state = const AsyncData(null);
}

/// 3) 登录参数
typedef LoginWithOtpParams = ({
String phone,
});

/// 4) OTP 登录
@Riverpod(keepAlive: true)
class AuthLoginOtpCtrl extends _$AuthLoginOtpCtrl {
  @override
  AsyncValue<AuthLoginOtp?> build() => const AsyncData(null);

  Future<AuthLoginOtp> run(LoginWithOtpParams params) async {
    state = const AsyncLoading();

    try {
      final res = await Api.loginWithOtpApi(
        phone: params.phone,
      );
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

@Riverpod(keepAlive: true)
class SendEmailCodeCtrl extends _$SendEmailCodeCtrl {
  @override
  AsyncValue<EmailSendCodeResponse?> build() => const AsyncData(null);

  Future<EmailSendCodeResponse> run(String email) async {
    state = const AsyncLoading();

    try {
      final res = await Api.sendEmailCodeApi(email: email);
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

typedef LoginWithEmailCodeParams = ({
  String email,
  String code,
});

@Riverpod(keepAlive: true)
class AuthLoginEmailCtrl extends _$AuthLoginEmailCtrl {
  @override
  AsyncValue<AuthLoginEmail?> build() => const AsyncData(null);

  Future<AuthLoginEmail> run(LoginWithEmailCodeParams params) async {
    state = const AsyncLoading();

    try {
      final res = await Api.loginWithEmailCodeApi(
        email: params.email,
        code: params.code,
      );
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

typedef LoginWithGoogleOauthParams = ({
  String idToken,
  String? inviteCode,
});

@Riverpod(keepAlive: true)
class AuthLoginGoogleCtrl extends _$AuthLoginGoogleCtrl {
  @override
  AsyncValue<AuthLoginOauth?> build() => const AsyncData(null);

  Future<AuthLoginOauth> run(LoginWithGoogleOauthParams params) async {
    state = const AsyncLoading();

    try {
      // Use Firebase unified login endpoint
      final res = await Api.loginWithFirebaseApi(
        idToken: params.idToken,
        inviteCode: params.inviteCode,
      );
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

typedef LoginWithFacebookOauthParams = ({
  String? idToken,
  String? accessToken,
  String? userId,
  String? inviteCode,
});

@Riverpod(keepAlive: true)
class AuthLoginFacebookCtrl extends _$AuthLoginFacebookCtrl {
  @override
  AsyncValue<AuthLoginOauth?> build() => const AsyncData(null);

  Future<AuthLoginOauth> run(LoginWithFacebookOauthParams params) async {
    state = const AsyncLoading();

    try {
      // Check if it's iOS native login (accessToken + userId) or Firebase (idToken)
      if (params.accessToken != null && params.userId != null) {
        // iOS: Use native Facebook SDK - send to /auth/oauth/facebook
        final res = await Api.loginWithFacebookOauthApi(
          FacebookOauthLoginParams(
            accessToken: params.accessToken!,
            userId: params.userId!,
            inviteCode: params.inviteCode,
          ),
        );
        state = AsyncData(res);
        return res;
      } else {
        // Android/Web: Use Firebase - send to /auth/firebase
        final res = await Api.loginWithFirebaseApi(
          idToken: params.idToken!,
          inviteCode: params.inviteCode,
        );
        state = AsyncData(res);
        return res;
      }
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

typedef LoginWithAppleOauthParams = ({
  String idToken,
  String? inviteCode,
});

@Riverpod(keepAlive: true)
class AuthLoginAppleCtrl extends _$AuthLoginAppleCtrl {
  @override
  AsyncValue<AuthLoginOauth?> build() => const AsyncData(null);

  Future<AuthLoginOauth> run(LoginWithAppleOauthParams params) async {
    state = const AsyncLoading();

    try {
      // Use Firebase unified login endpoint
      final res = await Api.loginWithFirebaseApi(
        idToken: params.idToken,
        inviteCode: params.inviteCode,
      );
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

/// 5) Profile Provider（函数式写法：注意是小写 @riverpod）
@riverpod
Future<Profile> profile(ProfileRef ref) async {
  return Api.profileApi();
}