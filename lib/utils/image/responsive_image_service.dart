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

    // 如果URL已经包含CDN前缀，直接返回避免重复处理
    if (originalUrl.contains(RemoteUrlBuilder.cdnPrefix)) {
      debugPrint('[ResponsiveImageService] URL already contains CDN prefix, returning as-is: $originalUrl');
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
}