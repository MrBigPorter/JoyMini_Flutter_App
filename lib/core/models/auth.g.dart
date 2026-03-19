// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthLoginOtp _$AuthLoginOtpFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AuthLoginOtp',
      json,
      ($checkedConvert) {
        final val = AuthLoginOtp(
          id: $checkedConvert('id', (v) => v as String),
          phone: $checkedConvert('phone', (v) => v as String),
          phoneMd5: $checkedConvert('phoneMd5', (v) => v as String),
          nickname: $checkedConvert('nickname', (v) => v as String),
          username: $checkedConvert('username', (v) => v as String),
          avatar: $checkedConvert(
            'avatar',
            (v) => v as String?,
            readValue: AuthLoginOtp._readAvatar,
          ),
          countryCode:
              $checkedConvert('countryCode', (v) => (v as num?)?.toInt()),
          tokens: $checkedConvert(
              'tokens', (v) => Tokens.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AuthLoginOtpToJson(AuthLoginOtp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'phoneMd5': instance.phoneMd5,
      'nickname': instance.nickname,
      'username': instance.username,
      'avatar': instance.avatar,
      'countryCode': instance.countryCode,
      'tokens': instance.tokens,
    };

Tokens _$TokensFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Tokens',
      json,
      ($checkedConvert) {
        final val = Tokens(
          accessToken: $checkedConvert('accessToken', (v) => v as String),
          refreshToken: $checkedConvert('refreshToken', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$TokensToJson(Tokens instance) => <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };

OtpRequest _$OtpRequestFromJson(Map<String, dynamic> json) => $checkedCreate(
      'OtpRequest',
      json,
      ($checkedConvert) {
        final val = OtpRequest(
          devCode: $checkedConvert('devCode', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$OtpRequestToJson(OtpRequest instance) =>
    <String, dynamic>{
      'devCode': instance.devCode,
    };

EmailSendCodeResponse _$EmailSendCodeResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'EmailSendCodeResponse',
      json,
      ($checkedConvert) {
        final val = EmailSendCodeResponse(
          sent: $checkedConvert('sent', (v) => v as bool),
          devCode: $checkedConvert('devCode', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$EmailSendCodeResponseToJson(
        EmailSendCodeResponse instance) =>
    <String, dynamic>{
      'sent': instance.sent,
      'devCode': instance.devCode,
    };

AuthLoginEmail _$AuthLoginEmailFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AuthLoginEmail',
      json,
      ($checkedConvert) {
        final val = AuthLoginEmail(
          id: $checkedConvert('id', (v) => v as String),
          phone: $checkedConvert('phone', (v) => v as String),
          phoneMd5: $checkedConvert('phoneMd5', (v) => v as String),
          nickname: $checkedConvert('nickname', (v) => v as String),
          username: $checkedConvert('username', (v) => v as String),
          avatar: $checkedConvert(
            'avatar',
            (v) => v as String?,
            readValue: AuthLoginOtp._readAvatar,
          ),
          email: $checkedConvert('email', (v) => v as String?),
          countryCode: $checkedConvert('countryCode', (v) => v as String?),
          tokens: $checkedConvert(
              'tokens', (v) => Tokens.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AuthLoginEmailToJson(AuthLoginEmail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'phoneMd5': instance.phoneMd5,
      'nickname': instance.nickname,
      'username': instance.username,
      'avatar': instance.avatar,
      'email': instance.email,
      'countryCode': instance.countryCode,
      'tokens': instance.tokens,
    };

Profile _$ProfileFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Profile',
      json,
      ($checkedConvert) {
        final val = Profile(
          id: $checkedConvert('id', (v) => v as String),
          nickname: $checkedConvert('nickname', (v) => v as String),
          avatar: $checkedConvert('avatar', (v) => v as String?),
          phoneMd5: $checkedConvert('phoneMd5', (v) => v as String),
          phone: $checkedConvert('phone', (v) => v as String),
          inviteCode: $checkedConvert('inviteCode', (v) => v as String?),
          vipLevel: $checkedConvert('vipLevel', (v) => (v as num?)?.toInt()),
          lastLoginAt:
              $checkedConvert('lastLoginAt', (v) => Profile._toIntNullable(v)),
          kycStatus: $checkedConvert('kycStatus', (v) => (v as num).toInt()),
          deliveryAddressId:
              $checkedConvert('deliveryAddressId', (v) => (v as num?)?.toInt()),
          selfExclusionExpireAt: $checkedConvert(
              'selfExclusionExpireAt', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
      'phoneMd5': instance.phoneMd5,
      'phone': instance.phone,
      'inviteCode': instance.inviteCode,
      'vipLevel': instance.vipLevel,
      'lastLoginAt': instance.lastLoginAt,
      'kycStatus': instance.kycStatus,
      'deliveryAddressId': instance.deliveryAddressId,
      'selfExclusionExpireAt': instance.selfExclusionExpireAt,
    };

AuthLoginOauth _$AuthLoginOauthFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AuthLoginOauth',
      json,
      ($checkedConvert) {
        final val = AuthLoginOauth(
          id: $checkedConvert('id', (v) => v as String),
          phone: $checkedConvert('phone', (v) => v as String),
          phoneMd5: $checkedConvert('phoneMd5', (v) => v as String),
          nickname: $checkedConvert('nickname', (v) => v as String),
          username: $checkedConvert('username', (v) => v as String),
          avatar: $checkedConvert('avatar', (v) => v as String?),
          provider: $checkedConvert('provider', (v) => v as String),
          inviteCode: $checkedConvert('inviteCode', (v) => v as String?),
          tokens: $checkedConvert(
              'tokens', (v) => Tokens.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AuthLoginOauthToJson(AuthLoginOauth instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'phoneMd5': instance.phoneMd5,
      'nickname': instance.nickname,
      'username': instance.username,
      'avatar': instance.avatar,
      'provider': instance.provider,
      'inviteCode': instance.inviteCode,
      'tokens': instance.tokens,
    };

GoogleOauthLoginParams _$GoogleOauthLoginParamsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'GoogleOauthLoginParams',
      json,
      ($checkedConvert) {
        final val = GoogleOauthLoginParams(
          idToken: $checkedConvert('idToken', (v) => v as String),
          inviteCode: $checkedConvert('inviteCode', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$GoogleOauthLoginParamsToJson(
        GoogleOauthLoginParams instance) =>
    <String, dynamic>{
      'idToken': instance.idToken,
      'inviteCode': instance.inviteCode,
    };

FacebookOauthLoginParams _$FacebookOauthLoginParamsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'FacebookOauthLoginParams',
      json,
      ($checkedConvert) {
        final val = FacebookOauthLoginParams(
          accessToken: $checkedConvert('accessToken', (v) => v as String),
          userId: $checkedConvert('userId', (v) => v as String),
          inviteCode: $checkedConvert('inviteCode', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$FacebookOauthLoginParamsToJson(
        FacebookOauthLoginParams instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'userId': instance.userId,
      'inviteCode': instance.inviteCode,
    };

AppleOauthLoginParams _$AppleOauthLoginParamsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'AppleOauthLoginParams',
      json,
      ($checkedConvert) {
        final val = AppleOauthLoginParams(
          idToken: $checkedConvert('idToken', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String?),
          inviteCode: $checkedConvert('inviteCode', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$AppleOauthLoginParamsToJson(
        AppleOauthLoginParams instance) =>
    <String, dynamic>{
      'idToken': instance.idToken,
      'code': instance.code,
      'inviteCode': instance.inviteCode,
    };
