import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/utils/image/image_cache_manager.dart';
import 'package:flutter_app/utils/image/performance_monitor.dart';
import 'package:flutter_app/utils/image/responsive_image_service.dart';

/// 优化图片组件 - 封装新的图片缓存系统
/// 功能：集成四级缓存、性能监控、响应式图片服务
class OptimizedImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMonitoring;
  final String componentName;
  final String? qualityPreset;
  final bool enableResponsive;
  final Map<String, dynamic>? metadata;

  const OptimizedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.enableMonitoring = true,
    this.componentName = 'OptimizedImage',
    this.qualityPreset = 'medium',
    this.enableResponsive = true,
    this.metadata,
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  late String _optimizedUrl;
  late ImageCacheManager _cacheManager;
  late ImagePerformanceMonitor _performanceMonitor;
  String? _eventId;
  DateTime? _startTime;
  bool _isLoading = false;
  bool _hasError = false;
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    
    // 初始化管理器
    _cacheManager = ImageCacheManager();
    _performanceMonitor = ImagePerformanceMonitor();
    
    // 生成优化后的URL
    _optimizedUrl = widget.url;
    if (widget.enableResponsive && widget.width != null && widget.width! > 0) {
      try {
        _optimizedUrl = ResponsiveImageService().generateImageUrl(
          originalUrl: widget.url,
          logicalWidth: widget.width!,
          logicalHeight: widget.height ?? widget.width! * 0.75,
          qualityPreset: widget.qualityPreset,
          allowUpscaling: false,
        );
      } catch (e) {
        debugPrint('[OptimizedImage] Responsive URL generation failed: $e');
      }
    }
    
    // 开始性能监控
    if (widget.enableMonitoring) {
      _startTime = DateTime.now();
      _eventId = _performanceMonitor.startImageLoad(
        url: _optimizedUrl,
        component: widget.componentName,
        source: ImageLoadSource.network,
        metadata: {
          'width': widget.width,
          'height': widget.height,
          'fit': widget.fit.toString(),
          'originalUrl': widget.url,
          'optimizedUrl': _optimizedUrl,
        },
      );
    }
    
    // 开始加载图片
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (_isLoading || _optimizedUrl.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final imageData = await _cacheManager.getImageData(
        _optimizedUrl,
        skipMemoryCache: false,
        skipDiskCache: false,
      );
      
      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
        });
        
        // 记录成功
        if (widget.enableMonitoring && _eventId != null && _startTime != null) {
          final duration = DateTime.now().difference(_startTime!);
          _performanceMonitor.recordLoadSuccess(
            eventId: _eventId!,
            loadDuration: duration,
            byteSize: imageData.length,
            cacheLevel: ImageCacheLevel.memory, // 假设是内存缓存
          );
        }
      }
    } catch (e) {
      // 详细记录错误信息
      debugPrint('[OptimizedImage] Failed to load image:');
      debugPrint('  URL: $_optimizedUrl');
      debugPrint('  Original URL: ${widget.url}');
      debugPrint('  Error: $e');
      debugPrint('  StackTrace: ${e is Error ? (e as Error).stackTrace : ''}');
      debugPrint('  EnableResponsive: ${widget.enableResponsive}');
      debugPrint('  Component: ${widget.componentName}');
      debugPrint('  ImageData length: ${_imageData?.length}');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        
        // 记录失败
        if (widget.enableMonitoring && _eventId != null && _startTime != null) {
          final duration = DateTime.now().difference(_startTime!);
          _performanceMonitor.recordLoadFailure(
            eventId: _eventId!,
            error: e.toString(),
            loadDuration: duration,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 构建容器
    Widget container = Container(
      width: widget.width,
      height: widget.height,
      decoration: widget.borderRadius != null
          ? BoxDecoration(
              borderRadius: widget.borderRadius,
            )
          : null,
      child: _buildContent(),
    );
    
    // 应用圆角裁剪
    if (widget.borderRadius != null) {
      container = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: container,
      );
    }
    
    return container;
  }

  Widget _buildContent() {
    if (_isLoading) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }
    
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }
    
    if (_imageData != null) {
      return Image.memory(
        _imageData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[OptimizedImage] Image decode error: $error');
          // 解码失败时回退到错误组件
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    }
    
    // 默认返回占位符
    return widget.placeholder ?? _buildDefaultPlaceholder();
  }

  /// 默认占位符
  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  /// 默认错误组件
  Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey[400],
          size: min(widget.width ?? 40, widget.height ?? 40) * 0.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 如果图片加载超时（假设10秒），记录为失败
    if (widget.enableMonitoring && _eventId != null && _startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      if (duration > const Duration(seconds: 10) && _isLoading) {
        _performanceMonitor.recordLoadFailure(
          eventId: _eventId!,
          error: 'Image load timeout (${duration.inSeconds}s)',
          loadDuration: duration,
        );
      }
    }
    
    super.dispose();
  }
}

/// 优化图片组件的便捷工厂方法
class OptimizedImageFactory {
  /// 创建轮播图优化的图片组件
  static Widget banner({
    required String url,
    required double width,
    required double height,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8.0)),
  }) {
    return OptimizedImage(
      url: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      componentName: 'SwiperBanner',
      qualityPreset: 'high', // 轮播图使用高质量
      enableResponsive: true,
    );
  }

  /// 创建商品图片优化的图片组件
  static Widget product({
    required String url,
    required double width,
    double? height,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(4.0)),
  }) {
    return OptimizedImage(
      url: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      componentName: 'ProductImage',
      qualityPreset: 'medium', // 商品图片使用中等质量
      enableResponsive: true,
    );
  }

  /// 创建头像优化的图片组件
  static Widget avatar({
    required String url,
    required double size,
  }) {
    return ClipOval(
      child: OptimizedImage(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        componentName: 'Avatar',
        qualityPreset: 'low', // 头像使用低质量
        enableResponsive: true,
      ),
    );
  }

  /// 创建图标优化的图片组件
  static Widget icon({
    required String url,
    required double size,
    Color? backgroundColor,
  }) {
    return Container(
      width: size,
      height: size,
      color: backgroundColor,
      child: OptimizedImage(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        componentName: 'Icon',
        qualityPreset: 'original', // 图标使用原始质量
        enableResponsive: false, // 图标不需要响应式
      ),
    );
  }
}

/// 优化图片组件的配置
class OptimizedImageConfig {
  // 默认配置
  static const BoxFit defaultFit = BoxFit.cover;
  static const String defaultComponentName = 'OptimizedImage';
  static const String defaultQualityPreset = 'medium';
  static const bool defaultEnableMonitoring = true;
  static const bool defaultEnableResponsive = true;

  // 组件类型特定的配置
  static const Map<String, OptimizedImageTypeConfig> typeConfigs = {
    'banner': OptimizedImageTypeConfig(
      qualityPreset: 'high',
      enableResponsive: true,
      fit: BoxFit.cover,
    ),
    'product': OptimizedImageTypeConfig(
      qualityPreset: 'medium',
      enableResponsive: true,
      fit: BoxFit.cover,
    ),
    'avatar': OptimizedImageTypeConfig(
      qualityPreset: 'low',
      enableResponsive: true,
      fit: BoxFit.cover,
    ),
    'icon': OptimizedImageTypeConfig(
      qualityPreset: 'original',
      enableResponsive: false,
      fit: BoxFit.contain,
    ),
  };
}

/// 优化图片类型配置
class OptimizedImageTypeConfig {
  final String qualityPreset;
  final bool enableResponsive;
  final BoxFit fit;

  const OptimizedImageTypeConfig({
    required this.qualityPreset,
    required this.enableResponsive,
    required this.fit,
  });
}