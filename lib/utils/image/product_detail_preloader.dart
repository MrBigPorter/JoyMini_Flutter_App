import 'package:flutter/widgets.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/utils/image/image_preloader.dart';
import 'package:flutter_app/utils/image/responsive_image_service.dart';

/// 商品详情页图片预取管理器
/// 功能：在用户从列表页点击进入详情页时，预取详情页的关键图片
class ProductDetailPreloader {
  static final ProductDetailPreloader _instance = ProductDetailPreloader._internal();
  factory ProductDetailPreloader() => _instance;
  ProductDetailPreloader._internal();

  final ImagePreloader _imagePreloader = ImagePreloader();
  final ResponsiveImageService _responsiveService = ResponsiveImageService();
  final Set<String> _preloadedProductIds = {};

  /// 预取商品详情页的关键图片
  /// 调用时机：在商品列表页点击商品时调用
  Future<void> preloadProductDetailImages({
    required BuildContext context,
    required ProductListItem product,
    required List<GroupForTreasureItem>? groups,
  }) async {
    final productId = product.treasureId;
    if (_preloadedProductIds.contains(productId)) {
      return;
    }

    _preloadedProductIds.add(productId);
    debugPrint('[ProductDetailPreloader] Starting preload for product: $productId');

    try {
      final urlsToPreload = <String>[];

      // 1. 商品封面图（轮播图） - 预取多个尺寸确保缓存命中
      final coverImg = product.treasureCoverImg;
      if (coverImg != null && coverImg.isNotEmpty) {
        // 预取多个尺寸：375x250（列表页尺寸）和 2160x860（详情页大图尺寸）
        final smallOptimizedUrl = _responsiveService.generateImageUrl(
          originalUrl: coverImg,
          logicalWidth: 375, // 详情页轮播图宽度（小尺寸）
          logicalHeight: 250, // 详情页轮播图高度
          qualityPreset: 'high',
          allowUpscaling: false,
        );
        urlsToPreload.add(smallOptimizedUrl);
        
        // 预取大尺寸图片（根据日志中的实际使用尺寸）
        final largeOptimizedUrl = _responsiveService.generateImageUrl(
          originalUrl: coverImg,
          logicalWidth: 2160, // 实际页面使用的大尺寸
          logicalHeight: 860, // 实际页面使用的高度
          qualityPreset: 'high',
          allowUpscaling: false,
        );
        urlsToPreload.add(largeOptimizedUrl);
        
        debugPrint('[ProductDetailPreloader] Preloading cover image sizes: 375x250 and 2160x860');
      }

      // 2. 拼团中的用户头像（最多预取前4个）
      if (groups != null && groups.isNotEmpty) {
        for (final group in groups.take(4)) {
          final avatarUrl = group.creator.avatar;
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            // 生成优化后的头像 URL
            final optimizedAvatarUrl = _responsiveService.generateImageUrl(
              originalUrl: avatarUrl,
              logicalWidth: 32, // 头像尺寸
              logicalHeight: 32,
              qualityPreset: 'low',
              allowUpscaling: false,
            );
            urlsToPreload.add(optimizedAvatarUrl);
          }
        }
      }

      // 3. 预取HTML内容中的图片（从商品描述中提取）
      _extractAndPreloadHtmlImages(product, urlsToPreload);

      if (urlsToPreload.isNotEmpty) {
        await _imagePreloader.preloadUrls(urlsToPreload, context);
        debugPrint('[ProductDetailPreloader] Preloaded ${urlsToPreload.length} images for product: $productId');
      }
    } catch (e) {
      debugPrint('[ProductDetailPreloader] Failed to preload images: $e');
    }
  }

  /// 从列表中批量预取多个商品的关键图片
  /// 适用于页面初始化时预取可能被浏览的商品
  Future<void> preloadMultipleProducts({
    required BuildContext context,
    required List<ProductListItem> products,
    int maxConcurrent = 2,
  }) async {
    if (products.isEmpty) return;

    // 限制并发数量，避免过度预取
    final productsToPreload = products.take(5).toList(); // 最多预取5个商品

    debugPrint('[ProductDetailPreloader] Batch preloading ${productsToPreload.length} products');

    for (final product in productsToPreload) {
      try {
        await preloadProductDetailImages(
          context: context,
          product: product,
          groups: null, // 批量预取时不预取用户头像
        );
      } catch (e) {
        debugPrint('[ProductDetailPreloader] Failed to preload product ${product.treasureId}: $e');
      }
    }
  }

  /// 清除预取记录（例如在用户登出时）
  void clearPreloadCache() {
    _preloadedProductIds.clear();
    debugPrint('[ProductDetailPreloader] Cleared preload cache');
  }

  /// 从商品描述HTML中提取图片URL并添加到预取列表
  void _extractAndPreloadHtmlImages(ProductListItem product, List<String> urlsToPreload) {
    try {
      // 从商品描述中提取图片URL
      final desc = product.desc ?? '';
      final ruleContent = product.ruleContent ?? '';
      
      // 合并两个HTML内容
      final htmlContent = '$desc$ruleContent';
      
      if (htmlContent.isEmpty) return;
      
      // 简单的正则表达式匹配<img>标签的src属性
      final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
      final matches = imgRegex.allMatches(htmlContent);
      
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final imgUrl = match.group(1);
          if (imgUrl != null && imgUrl.isNotEmpty) {
            // 检查是否是相对路径
            String fullUrl = imgUrl;
            if (!imgUrl.startsWith('http')) {
              // 如果是相对路径，添加CDN基础URL
              // 注意：这里需要根据实际CDN配置调整
              fullUrl = 'https://img.joyminis.com/$imgUrl';
            }
            
            // 生成优化后的URL（使用中等尺寸）
            final optimizedUrl = _responsiveService.generateImageUrl(
              originalUrl: fullUrl,
              logicalWidth: 800, // HTML图片中等尺寸
              logicalHeight: 600,
              qualityPreset: 'medium',
              allowUpscaling: false,
            );
            
            urlsToPreload.add(optimizedUrl);
            debugPrint('[ProductDetailPreloader] Extracted HTML image for preload: $fullUrl');
          }
        }
      }
      
      if (matches.isNotEmpty) {
        debugPrint('[ProductDetailPreloader] Extracted ${matches.length} HTML images from product description');
      }
    } catch (e) {
      debugPrint('[ProductDetailPreloader] Failed to extract HTML images: $e');
    }
  }

  /// 获取预取统计信息
  Map<String, dynamic> getStats() {
    return {
      'preloadedProductCount': _preloadedProductIds.length,
      'imagePreloaderStats': _imagePreloader.getStats(),
    };
  }
}
