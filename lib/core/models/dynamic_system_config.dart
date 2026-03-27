import 'package:json_annotation/json_annotation.dart';

part 'dynamic_system_config.g.dart';

/// Represents a fully dynamic system configuration with key-value pairs.
/// This model supports any configuration keys returned by the backend.
@JsonSerializable(checked: true)
class DynamicSystemConfig {
  /// Map of configuration key-value pairs
  final Map<String, String> configs;

  DynamicSystemConfig({required this.configs});

  factory DynamicSystemConfig.fromJson(Map<String, dynamic> json) =>
      _$DynamicSystemConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DynamicSystemConfigToJson(this);

  /// Get a string value from configuration
  String getString(String key, {String defaultValue = ''}) {
    return configs[key] ?? defaultValue;
  }

  /// Get a double value from configuration
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = configs[key];
    if (value == null) return defaultValue;
    try {
      return double.tryParse(value) ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Get a boolean value from configuration
  bool getBool(String key, {bool defaultValue = false}) {
    final value = configs[key];
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }

  /// Get an integer value from configuration
  int getInt(String key, {int defaultValue = 0}) {
    final value = configs[key];
    if (value == null) return defaultValue;
    try {
      return int.tryParse(value) ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  // Backward compatibility properties for existing keys

  /// KYC and phone verification setting
  /// Defaults to '1' (enabled) if not found
  String get kycAndPhoneVerification =>
      getString('kyc_and_phone_verification', defaultValue: '1');

  /// Web base URL for sharing and links
  String get webBaseUrl => getString('web_base_url');

  /// Exchange rate for currency conversion
  /// Defaults to 1.0 if not found
  double get exchangeRate => getDouble('exchange_rate', defaultValue: 1.0);

  @override
  String toString() {
    return 'DynamicSystemConfig(configs: $configs)';
  }
}