import 'package:json_annotation/json_annotation.dart';

part 'auth.g.dart';

@JsonSerializable(checked: true)
class AuthLoginOtp {
  final String id;
  final String phone;
  final String phoneMd5;
  final String nickname;
  final String username;
  @JsonKey(readValue: _readAvatar)
  final String? avatar;
  final int? countryCode;
  final Tokens tokens;

  AuthLoginOtp({
    required this.id,
    required this.phone,
    required this.phoneMd5,
    required this.nickname,
    required this.username,
    this.avatar,
    this.countryCode,
    required this.tokens,
  });


  factory AuthLoginOtp.fromJson(Map<String, dynamic> json) =>
      _$AuthLoginOtpFromJson(json);

  Map<String, dynamic> toJson() => _$AuthLoginOtpToJson(this);

  // Backward compatible: accept both `avatar` and legacy `avartar`.
  static Object? _readAvatar(Map json, String key) =>
      json['avatar'] ?? json['avartar'];

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class Tokens {
  final String accessToken;
  final String refreshToken;

  Tokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory Tokens.fromJson(Map<String, dynamic> json) =>
      _$TokensFromJson(json);

  Map<String, dynamic> toJson() => _$TokensToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}


@JsonSerializable(checked: true)
class OtpRequest {
  final String? devCode;

  OtpRequest({
     this.devCode,
  });

  factory OtpRequest.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OtpRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class EmailSendCodeResponse {
  final bool sent;
  final String? devCode;

  EmailSendCodeResponse({
    required this.sent,
    this.devCode,
  });

  factory EmailSendCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$EmailSendCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EmailSendCodeResponseToJson(this);
}

@JsonSerializable(checked: true)
class AuthLoginEmail {
  final String id;
  final String phone;
  final String phoneMd5;
  final String nickname;
  final String username;
  @JsonKey(readValue: AuthLoginOtp._readAvatar)
  final String? avatar;
  final String? email;
  final String? countryCode;
  final Tokens tokens;

  AuthLoginEmail({
    required this.id,
    required this.phone,
    required this.phoneMd5,
    required this.nickname,
    required this.username,
    this.avatar,
    this.email,
    this.countryCode,
    required this.tokens,
  });

  factory AuthLoginEmail.fromJson(Map<String, dynamic> json) =>
      _$AuthLoginEmailFromJson(json);

  Map<String, dynamic> toJson() => _$AuthLoginEmailToJson(this);
}

@JsonSerializable(checked: true)
class Profile {
  final String id;
  final String nickname;
  final String? avatar;
  final String phoneMd5;
  final String phone;
  final String? inviteCode;
  final int? vipLevel;
  @JsonKey(fromJson: _toIntNullable)
  final int? lastLoginAt;
  final int kycStatus;
  final int? deliveryAddressId;
  final int? selfExclusionExpireAt;

  Profile({
    required this.id,
    required this.nickname,
    this.avatar,
    required this.phoneMd5,
    required this.phone,
    this.inviteCode,
    this.vipLevel,
    this.lastLoginAt,
    required this.kycStatus,
    this.deliveryAddressId,
    this.selfExclusionExpireAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

  static int? _toIntNullable(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

}

class OtpVerifyParams {
  final String phone;
  final String code;

  OtpVerifyParams({
    required this.phone,
    required this.code,
  });
}

@JsonSerializable(checked: true)
class AuthLoginOauth {
  final String id;
  final String phone;
  final String phoneMd5;
  final String nickname;
  final String username;
  final String? avatar;
  final String provider;
  final String? inviteCode;
  final Tokens tokens;

  AuthLoginOauth({
    required this.id,
    required this.phone,
    required this.phoneMd5,
    required this.nickname,
    required this.username,
    this.avatar,
    required this.provider,
    this.inviteCode,
    required this.tokens,
  });

  factory AuthLoginOauth.fromJson(Map<String, dynamic> json) =>
      _$AuthLoginOauthFromJson(json);

  Map<String, dynamic> toJson() => _$AuthLoginOauthToJson(this);
}

@JsonSerializable(checked: true)
class GoogleOauthLoginParams {
  final String idToken;
  final String? inviteCode;

  GoogleOauthLoginParams({
    required this.idToken,
    this.inviteCode,
  });

  factory GoogleOauthLoginParams.fromJson(Map<String, dynamic> json) =>
      _$GoogleOauthLoginParamsFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleOauthLoginParamsToJson(this);
}

@JsonSerializable(checked: true)
class FacebookOauthLoginParams {
  final String accessToken;
  final String userId;
  final String? inviteCode;

  FacebookOauthLoginParams({
    required this.accessToken,
    required this.userId,
    this.inviteCode,
  });

  factory FacebookOauthLoginParams.fromJson(Map<String, dynamic> json) =>
      _$FacebookOauthLoginParamsFromJson(json);

  Map<String, dynamic> toJson() => _$FacebookOauthLoginParamsToJson(this);
}

@JsonSerializable(checked: true)
class AppleOauthLoginParams {
  final String idToken;
  final String? code;
  final String? inviteCode;

  AppleOauthLoginParams({
    required this.idToken,
    this.code,
    this.inviteCode,
  });

  factory AppleOauthLoginParams.fromJson(Map<String, dynamic> json) =>
      _$AppleOauthLoginParamsFromJson(json);

  Map<String, dynamic> toJson() => _$AppleOauthLoginParamsToJson(this);
}


