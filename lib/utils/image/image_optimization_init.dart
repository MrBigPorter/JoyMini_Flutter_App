import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/image/image_preloader.dart';
import 'package:flutter_app/utils/image/image_cache_manager.dart';
import 'package:flutter_app/utils/image/responsive_image_service.dart';
import 'package:flutter_app/utils/image/performance_monitor.dart';

class ImageOptimizationInit {
  static final ImageOptimizationInit _instance = ImageOptimizationInit._internal();
  factory ImageOptimizationInit() => _instance;
  ImageOptimizationInit._internal();

  bool _initialized = false;
  late final ImagePreloader preloader;
  late final ImageCacheManager cacheManager;
  late final ResponsiveImageService responsiveService;
  late final ImagePerformanceMonitor performanceMonitor;

  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;

    performanceMonitor = ImagePerformanceMonitor();
    await performanceMonitor.initialize();
    cacheManager = ImageCacheManager();
    await cacheManager.initialize();
    responsiveService = ResponsiveImageService();
    await responsiveService.initialize();
    preloader = ImagePreloader();

    _initialized = true;
    debugPrint('[ImageOptimizationInit] Done.');
  }

  // 【核心方法】统一 URL 生成入口
  String generateResponsiveUrl({
    required String originalUrl,
    required double width,
    required double height,
    bool allowUpscaling = false, // 【修复】增加此参数
  }) {
    if (!_initialized) return originalUrl;

    return responsiveService.generateImageUrl(
      originalUrl: originalUrl,
      logicalWidth: width,
      logicalHeight: height,
      allowUpscaling: allowUpscaling, // 传递给 service
    );
  }

  Future<void> preloadImages(List<String> urls, BuildContext context) async {
    if (!_initialized) return;
    await preloader.preloadUrls(urls, context);
  }
}