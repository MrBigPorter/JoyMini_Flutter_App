import 'package:flutter/foundation.dart';

/// 静态图片预加载配置
/// 包含应用冷启动时需要预加载的关键图片URL
class StaticImagePreloadConfig {
  /// 获取静态预加载图片URL列表
  /// 这些图片在应用冷启动时立即预加载，以提升用户体验
  static List<String> getStaticPreloadUrls() {
    // 这里可以配置静态的关键图片URL
    // 例如：Logo、启动图、常用图标等
    
    final urls = <String>[

    ];
    
    // 根据平台和环境过滤URL
    return _filterUrlsByPlatform(urls);
  }
  
  /// 获取响应式优化后的静态预加载URL
  /// 根据设备特性生成优化后的URL
  static List<String> getOptimizedStaticPreloadUrls({
    double? devicePixelRatio,
    Map<String, double>? sizePresets,
  }) {
    final originalUrls = getStaticPreloadUrls();
    final optimizedUrls = <String>[];
    
    // 默认尺寸预设
    final defaultSizePresets = sizePresets ?? {
      'logo': 100.0,
      'icon': 24.0,
      'placeholder': 200.0,
      'empty_state': 150.0,
    };
    
    for (final url in originalUrls) {
      try {
        // 根据URL类型确定尺寸预设
        double width = 100.0; // 默认宽度
        double height = 100.0; // 默认高度
        
        if (url.contains('logo')) {
          width = defaultSizePresets['logo'] ?? 100.0;
          height = defaultSizePresets['logo'] ?? 100.0;
        } else if (url.contains('icon')) {
          width = defaultSizePresets['icon'] ?? 24.0;
          height = defaultSizePresets['icon'] ?? 24.0;
        } else if (url.contains('placeholder')) {
          width = defaultSizePresets['placeholder'] ?? 200.0;
          height = defaultSizePresets['placeholder'] ?? 200.0;
        } else if (url.contains('empty')) {
          width = defaultSizePresets['empty_state'] ?? 150.0;
          height = defaultSizePresets['empty_state'] ?? 150.0;
        }
        
        // 这里只是返回原始URL，实际使用时需要结合ResponsiveImageService
        // 由于ResponsiveImageService需要BuildContext，这里先返回原始URL
        // 实际预加载时会在有context的情况下生成优化URL
        optimizedUrls.add(url);
      } catch (e) {
        debugPrint('[StaticImagePreloadConfig] Error optimizing URL $url: $e');
        optimizedUrls.add(url); // 出错时返回原始URL
      }
    }
    
    return optimizedUrls;
  }
  
  /// 根据平台过滤URL
  static List<String> _filterUrlsByPlatform(List<String> urls) {
    // 这里可以根据平台特性过滤URL
    // 例如：某些图片只在特定平台需要预加载
    
    return urls;
  }
  
  /// 获取预加载配置信息
  static Map<String, dynamic> getConfigInfo() {
    return {
      'totalStaticUrls': getStaticPreloadUrls().length,
      'platform': _getPlatformInfo(),
      'lastUpdated': '2026-03-27',
      'description': '静态图片预加载配置，用于提升应用冷启动时的图片加载性能',
    };
  }
  
  static String _getPlatformInfo() {
    return 'Flutter';
  }
}

/// 静态预加载管理器
class StaticImagePreloadManager {
  static final StaticImagePreloadManager _instance = StaticImagePreloadManager._internal();
  factory StaticImagePreloadManager() => _instance;
  StaticImagePreloadManager._internal();
  
  final Set<String> _preloadedUrls = {};
  bool _initialized = false;
  
  /// 初始化静态预加载管理器
  Future<void> initialize() async {
    if (_initialized) return;
    
    _initialized = true;
    debugPrint('[StaticImagePreloadManager] Initialized');
  }
  
  /// 获取需要预加载的静态URL列表
  List<String> getUrlsToPreload() {
    final allUrls = StaticImagePreloadConfig.getStaticPreloadUrls();
    
    // 过滤掉已经预加载过的URL
    return allUrls.where((url) => !_preloadedUrls.contains(url)).toList();
  }
  
  /// 标记URL为已预加载
  void markAsPreloaded(String url) {
    _preloadedUrls.add(url);
  }
  
  /// 清除预加载记录
  void clearPreloadRecords() {
    _preloadedUrls.clear();
    debugPrint('[StaticImagePreloadManager] Cleared preload records');
  }
  
  /// 获取预加载统计信息
  Map<String, dynamic> getStats() {
    return {
      'totalPreloaded': _preloadedUrls.length,
      'totalAvailable': StaticImagePreloadConfig.getStaticPreloadUrls().length,
      'preloadRate': StaticImagePreloadConfig.getStaticPreloadUrls().isNotEmpty 
          ? _preloadedUrls.length / StaticImagePreloadConfig.getStaticPreloadUrls().length 
          : 0.0,
      'initialized': _initialized,
    };
  }
}