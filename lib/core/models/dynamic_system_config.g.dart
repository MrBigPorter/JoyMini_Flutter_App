// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dynamic_system_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DynamicSystemConfig _$DynamicSystemConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DynamicSystemConfig',
      json,
      ($checkedConvert) {
        final val = DynamicSystemConfig(
          configs: $checkedConvert(
              'configs', (v) => Map<String, String>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$DynamicSystemConfigToJson(
        DynamicSystemConfig instance) =>
    <String, dynamic>{
      'configs': instance.configs,
    };
