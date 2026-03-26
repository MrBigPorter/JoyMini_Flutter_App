// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sys_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SysConfig _$SysConfigFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SysConfig',
      json,
      ($checkedConvert) {
        final val = SysConfig(
          kycAndPhoneVerification:
              $checkedConvert('kycAndPhoneVerification', (v) => v as String),
          webBaseUrl: $checkedConvert('webBaseUrl', (v) => v as String),
          exchangeRate: $checkedConvert(
              'exchangeRate', (v) => SysConfig._exchangeRateFromJson(v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SysConfigToJson(SysConfig instance) => <String, dynamic>{
      'kycAndPhoneVerification': instance.kycAndPhoneVerification,
      'webBaseUrl': instance.webBaseUrl,
      'exchangeRate': SysConfig._exchangeRateToJson(instance.exchangeRate),
    };
