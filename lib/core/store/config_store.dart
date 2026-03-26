import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/store/hydrated_state_notifier.dart';
import 'package:flutter_app/core/models/dynamic_system_config.dart';
import '../api/lucky_api.dart';

class SystemConfigNotifier extends HydratedStateNotifier<DynamicSystemConfig> {
  // 设置默认值
  SystemConfigNotifier() : super(DynamicSystemConfig(configs: {
    'kyc_and_phone_verification': '1',
    'web_base_url': '',
    'exchange_rate': '1.0',
  }));

  @override
  String get storageKey => 'sys_config_storage';

  @override
  DynamicSystemConfig fromJson(Map<String, dynamic> json) => DynamicSystemConfig.fromJson(json);

  @override
  Map<String, dynamic> toJson(DynamicSystemConfig state) => state.toJson();

  /// 获取最新配置
  Future<void> fetchLatest() async {
    try {
      final config = await Api.getDynamicSystemConfig();
      state = config;
    } catch (_) {}
  }
}

final configProvider = StateNotifierProvider<SystemConfigNotifier, DynamicSystemConfig>((ref) {
  return SystemConfigNotifier();
});