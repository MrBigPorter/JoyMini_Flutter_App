import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/utils/media/remote_url_builder.dart';

class ResponsiveImageService {
  static final ResponsiveImageService _instance = ResponsiveImageService._internal();
  factory ResponsiveImageService() => _instance;
  ResponsiveImageService._internal();

  double? _devicePixelRatio;

  Future<void> initialize() async {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    _devicePixelRatio = binding.platformDispatcher.views.first.devicePixelRatio;
  }

  String generateImageUrl({
    required String originalUrl,
    required double logicalWidth,
    required double logicalHeight,
    String? qualityPreset = 'medium',
    bool allowUpscaling = false,
    Map<String, String>? additionalParams,
  }) {
    if (originalUrl.isEmpty) return originalUrl;

    // 【核心修复】: 增强CDN前缀检测，支持多种可能的格式
    // 检查URL是否已经包含CDN处理参数
    if (_isAlreadyOptimized(originalUrl)) {
      debugPrint('[ResponsiveImageService] URL already optimized, returning as-is: $originalUrl');
      return originalUrl;
    }

    final uri = Uri.tryParse(originalUrl);
    if (uri == null) {
      debugPrint('[ResponsiveImageService] Failed to parse URL: $originalUrl');
      return originalUrl;
    }

    // 逻辑宽度阶梯化 - 避免生成过多不同尺寸
    double targetW = logicalWidth;
    if (logicalWidth > 0 && logicalWidth <= 200) targetW = 240;
    else if (logicalWidth > 200 && logicalWidth <= 400) targetW = 480;
    else if (logicalWidth > 400) targetW = 720;

    final dpr = _devicePixelRatio ?? 2.0;

    // 计算物理像素尺寸
    int finalW = (targetW * dpr).toInt();
    int finalH = (logicalHeight * dpr).toInt();

    // 限制最小尺寸，避免请求过小的图片
    if (finalW < 100) finalW = 100;
    if (finalH > 0 && finalH < 100) finalH = 100;

    // 根据qualityPreset调整质量参数
    String quality = '80'; // 默认质量
    if (qualityPreset == 'high') quality = '90';
    else if (qualityPreset == 'low') quality = '60';
    else if (qualityPreset == 'original') quality = '100';

    final options = <String>[
      'width=$finalW',
      if (finalH > 0) 'height=$finalH',
      'fit=cover',
      'f=auto',
      'quality=$quality'
    ];

    final optionsStr = options.join(',');
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';

    final optimizedUrl = '${uri.scheme}://${uri.host}${RemoteUrlBuilder.cdnPrefix}$optionsStr$path';
    
    /*debugPrint('[ResponsiveImageService] Generated optimized URL:');
    debugPrint('  Original: $originalUrl');
    debugPrint('  Optimized: $optimizedUrl');
    debugPrint('  Dimensions: ${finalW}x${finalH} (logical: ${logicalWidth}x${logicalHeight})');
    debugPrint('  Quality: $quality, DPR: $dpr');*/
    
    return optimizedUrl;
  }

  /// 检查URL是否已经被优化处理过
  bool _isAlreadyOptimized(String url) {
    // 检查是否包含CDN前缀
    if (url.contains(RemoteUrlBuilder.cdnPrefix)) {
      return true;
    }
    
    // 检查是否包含常见的CDN处理参数模式
    final cdnPatterns = [
      '/cdn-cgi/image/',
      'cdn-cgi/image/',
      'fit=cover',
      'f=auto',
      'quality=',
      'width=',
      'height='
    ];
    
    int patternCount = 0;
    for (final pattern in cdnPatterns) {
      if (url.contains(pattern)) {
        patternCount++;
      }
    }
    
    // 如果包含多个CDN处理参数，则认为已经优化过
    return patternCount >= 2;
  }
}