// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileHash() => r'4735d11297367d1c60385ceb5bf1b4f9fe31979a';

/// 5) Profile Provider（函数式写法：注意是小写 @riverpod）
///
/// Copied from [profile].
@ProviderFor(profile)
final profileProvider = AutoDisposeFutureProvider<Profile>.internal(
  profile,
  name: r'profileProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$profileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProfileRef = AutoDisposeFutureProviderRef<Profile>;
String _$sendOtpCtrlHash() => r'7c9a3b5bbd1180952d7982e08ed85d4af6d0f67d';

/// 1) 发送 OTP
///
/// Copied from [SendOtpCtrl].
@ProviderFor(SendOtpCtrl)
final sendOtpCtrlProvider =
    NotifierProvider<SendOtpCtrl, AsyncValue<OtpRequest?>>.internal(
  SendOtpCtrl.new,
  name: r'sendOtpCtrlProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sendOtpCtrlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SendOtpCtrl = Notifier<AsyncValue<OtpRequest?>>;
String _$verifyOtpCtrlHash() => r'ac379466866445e0fafaaf62286a99d78566cbb3';

/// 2) 校验 OTP
///
/// Copied from [VerifyOtpCtrl].
@ProviderFor(VerifyOtpCtrl)
final verifyOtpCtrlProvider =
    NotifierProvider<VerifyOtpCtrl, AsyncValue<void>>.internal(
  VerifyOtpCtrl.new,
  name: r'verifyOtpCtrlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$verifyOtpCtrlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VerifyOtpCtrl = Notifier<AsyncValue<void>>;
String _$authLoginOtpCtrlHash() => r'7ac963e6dd2a1153c976c58e28bc09993a29e763';

/// 4) OTP 登录
///
/// Copied from [AuthLoginOtpCtrl].
@ProviderFor(AuthLoginOtpCtrl)
final authLoginOtpCtrlProvider =
    NotifierProvider<AuthLoginOtpCtrl, AsyncValue<AuthLoginOtp?>>.internal(
  AuthLoginOtpCtrl.new,
  name: r'authLoginOtpCtrlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authLoginOtpCtrlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthLoginOtpCtrl = Notifier<AsyncValue<AuthLoginOtp?>>;
String _$sendEmailCodeCtrlHash() => r'4d6cc3c113ce7d226b51119f6de60249e04a4132';

/// See also [SendEmailCodeCtrl].
@ProviderFor(SendEmailCodeCtrl)
final sendEmailCodeCtrlProvider = NotifierProvider<SendEmailCodeCtrl,
    AsyncValue<EmailSendCodeResponse?>>.internal(
  SendEmailCodeCtrl.new,
  name: r'sendEmailCodeCtrlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sendEmailCodeCtrlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SendEmailCodeCtrl = Notifier<AsyncValue<EmailSendCodeResponse?>>;
String _$authLoginEmailCtrlHash() =>
    r'276d318cf84e69fb9ba243d2e186fcd6d16431fd';

/// See also [AuthLoginEmailCtrl].
@ProviderFor(AuthLoginEmailCtrl)
final authLoginEmailCtrlProvider =
    NotifierProvider<AuthLoginEmailCtrl, AsyncValue<AuthLoginEmail?>>.internal(
  AuthLoginEmailCtrl.new,
  name: r'authLoginEmailCtrlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authLoginEmailCtrlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthLoginEmailCtrl = Notifier<AsyncValue<AuthLoginEmail?>>;
String _$authLoginGoogleCtrlHash() =>
    r'ede9beaca90f587eda92be38daf527851500ff8e';

/// See also [AuthLoginGoogleCtrl].
@ProviderFor(AuthLoginGoogleCtrl)
final authLoginGoogleCtrlProvider =
    NotifierProvider<AuthLoginGoogleCtrl, AsyncValue<AuthLoginOauth?>>.internal(
  AuthLoginGoogleCtrl.new,
  name: r'authLoginGoogleCtrlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authLoginGoogleCtrlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthLoginGoogleCtrl = Notifier<AsyncValue<AuthLoginOauth?>>;
String _$authLoginFacebookCtrlHash() =>
    r'0e0f22fc7b03e14c29ce3757aa2fc31b775fde3e';

/// See also [AuthLoginFacebookCtrl].
@ProviderFor(AuthLoginFacebookCtrl)
final authLoginFacebookCtrlProvider = NotifierProvider<AuthLoginFacebookCtrl,
    AsyncValue<AuthLoginOauth?>>.internal(
  AuthLoginFacebookCtrl.new,
  name: r'authLoginFacebookCtrlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authLoginFacebookCtrlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthLoginFacebookCtrl = Notifier<AsyncValue<AuthLoginOauth?>>;
String _$authLoginAppleCtrlHash() =>
    r'8b6adb1286138946fae6c3892f9d3fe40140694e';

/// See also [AuthLoginAppleCtrl].
@ProviderFor(AuthLoginAppleCtrl)
final authLoginAppleCtrlProvider =
    NotifierProvider<AuthLoginAppleCtrl, AsyncValue<AuthLoginOauth?>>.internal(
  AuthLoginAppleCtrl.new,
  name: r'authLoginAppleCtrlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authLoginAppleCtrlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthLoginAppleCtrl = Notifier<AsyncValue<AuthLoginOauth?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
