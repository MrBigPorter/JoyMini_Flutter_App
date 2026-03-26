
import 'package:json_annotation/json_annotation.dart';

part 'sys_config.g.dart';
@JsonSerializable(checked: true)
class SysConfig {
  @JsonKey(name: 'kycAndPhoneVerification')
  final String kycAndPhoneVerification;
  
  @JsonKey(name: 'webBaseUrl')
  final String webBaseUrl;
  
  @JsonKey(name: 'exchangeRate', fromJson: _exchangeRateFromJson, toJson: _exchangeRateToJson)
  final double exchangeRate;

  SysConfig({required this.kycAndPhoneVerification, required this.webBaseUrl, required this.exchangeRate});

  factory SysConfig.fromJson(Map<String, dynamic> json) => _$SysConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SysConfigToJson(this);
  
  // Handle both 'exchangeRate' and 'exChangeRate' field names during transition
  static double _exchangeRateFromJson(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 1.0;
    }
    return 1.0;
  }
  
  static dynamic _exchangeRateToJson(double value) => value;
  
  @override
  String toString() {
    return toJson().toString();
  }

}
