import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 标准：图片性能监控系统
/// 功能：监控图片加载性能，收集关键指标，支持A/B测试
class ImagePerformanceMonitor {
  static final ImagePerformanceMonitor _instance =
  ImagePerformanceMonitor._internal();

  factory ImagePerformanceMonitor() => _instance;

  ImagePerformanceMonitor._internal();

  // 性能数据存储
  final List<ImagePerformanceEvent> _events = [];
  final Map<String, ImagePerformanceStats> _urlStats = {};
  final Map<String, Completer<void>> _pendingLoads = {};

  // 配置
  static const int _maxEvents = 1000;
  // 【修改1：拉长定时器间隔，减少性能开销】
  static const Duration _flushInterval = Duration(minutes: 15);
  static const Duration _samplingRate = Duration(seconds: 30);

  // 定时器
  Timer? _flushTimer;
  Timer? _samplingTimer;

  // 统计信息
  int _totalLoads = 0;
  int _successfulLoads = 0;
  int _failedLoads = 0;
  int _cachedLoads = 0;
  double _totalLoadTime = 0;

  /// 初始化监控系统
  Future<void> initialize() async {
    // 【修改2：只在 Debug（开发）模式下启动】
    if (!kDebugMode) {
      debugPrint('[ImagePerformanceMonitor] Running in Release mode, monitoring disabled.');
      return;
    }

    // 启动定期数据刷新
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushToStorage());

    // 启动采样定时器
    _samplingTimer = Timer.periodic(
      _samplingRate,
          (_) => _collectSampledData(),
    );

    debugPrint('[ImagePerformanceMonitor] Initialized (Debug Mode Only)');
  }

  /// 销毁监控系统
  void dispose() {
    _flushTimer?.cancel();
    _samplingTimer?.cancel();
    if (kDebugMode) _flushToStorage(); // 最后刷新一次
    debugPrint('[ImagePerformanceMonitor] Disposed');
  }

  /// 开始监控图片加载
  String startImageLoad({
    required String url,
    required String component,
    ImageLoadSource source = ImageLoadSource.network,
    Map<String, dynamic>? metadata,
  }) {
    // 【修改3：生产环境直接返回假 ID，阻断数据收集】
    if (!kDebugMode) return 'prod_dummy_event';

    final eventId =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

    final event = ImagePerformanceEvent(
      eventId: eventId,
      url: url,
      component: component,
      source: source,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
    );

    _events.add(event);

    // 记录待完成的加载
    _pendingLoads[eventId] = Completer<void>();

    // 限制事件数量
    if (_events.length > _maxEvents) {
      _events.removeRange(0, _events.length - _maxEvents);
    }

    return eventId;
  }

  /// 记录图片加载成功
  void recordLoadSuccess({
    required String eventId,
    required Duration loadDuration,
    required int byteSize,
    required ImageCacheLevel cacheLevel,
    String? error,
  }) {
    // 【修改4：非 Debug 模式或假 ID 直接拦截】
    if (!kDebugMode || eventId == 'prod_dummy_event') return;

    final event = _events.firstWhere(
          (e) => e.eventId == eventId,
      orElse: () => throw StateError('Event not found: $eventId'),
    );

    event.endTime = DateTime.now();
    event.loadDuration = loadDuration;
    event.byteSize = byteSize;
    event.cacheLevel = cacheLevel;
    event.success = true;
    event.error = error;

    // 更新统计
    _totalLoads++;
    _successfulLoads++;
    _totalLoadTime += loadDuration.inMilliseconds;

    if (cacheLevel != ImageCacheLevel.none) {
      _cachedLoads++;
    }

    // 更新URL级别统计
    _updateUrlStats(event);

    // 完成待处理的加载
    _pendingLoads[eventId]?.complete();
    _pendingLoads.remove(eventId);

    // 【修改5：如果是瞬间从内存加载的，就不打印了，保持滑动时控制台清爽】
    if (cacheLevel != ImageCacheLevel.memory || loadDuration.inMilliseconds > 20) {
      debugPrint(
        '[ImagePerformanceMonitor] Load success: ${event.url}, '
            'duration: ${loadDuration.inMilliseconds}ms, '
            'cache: ${cacheLevel.name}, size: ${byteSize ~/ 1024}KB',
      );
    }
  }

  /// 记录图片加载失败
  void recordLoadFailure({
    required String eventId,
    required String error,
    Duration? loadDuration,
  }) {
    // 【修改6：非 Debug 模式或假 ID 直接拦截】
    if (!kDebugMode || eventId == 'prod_dummy_event') return;

    final event = _events.firstWhere(
          (e) => e.eventId == eventId,
      orElse: () => throw StateError('Event not found: $eventId'),
    );

    event.endTime = DateTime.now();
    event.loadDuration = loadDuration ?? Duration.zero;
    event.success = false;
    event.error = error;

    // 更新统计
    _totalLoads++;
    _failedLoads++;

    // 完成待处理的加载（带错误）
    _pendingLoads[eventId]?.completeError(error);
    _pendingLoads.remove(eventId);

    debugPrint(
      '[ImagePerformanceMonitor] Load failed: ${event.url}, error: $error',
    );
  }

  /// 获取性能统计
  ImagePerformanceStats getStats({String? url}) {
    if (url != null && _urlStats.containsKey(url)) {
      return _urlStats[url]!;
    }

    final stats = ImagePerformanceStats(url: url);
    stats.totalLoads = _totalLoads;
    stats.successfulLoads = _successfulLoads;
    stats.failedLoads = _failedLoads;
    stats.cachedLoads = _cachedLoads;
    stats.totalLoadTime = _totalLoadTime.toInt();
    stats.lastUpdated = DateTime.now();

    return stats;
  }

  /// 获取URL级别的性能统计
  Map<String, ImagePerformanceStats> getUrlStats() {
    return Map.from(_urlStats);
  }

  /// 获取最近的事件
  List<ImagePerformanceEvent> getRecentEvents({int limit = 20}) {
    return _events.reversed.take(limit).toList();
  }

  /// 重置统计
  void resetStats() {
    _events.clear();
    _urlStats.clear();
    _pendingLoads.clear();

    _totalLoads = 0;
    _successfulLoads = 0;
    _failedLoads = 0;
    _cachedLoads = 0;
    _totalLoadTime = 0;

    debugPrint('[ImagePerformanceMonitor] Stats reset');
  }

  /// 导出性能数据（用于分析）
  Map<String, dynamic> exportData() {
    return {
      'summary': getStats().toJson(),
      'urlStats': _urlStats.map((key, value) => MapEntry(key, value.toJson())),
      'recentEvents': getRecentEvents(
        limit: 50,
      ).map((e) => e.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ========== 私有方法 ==========

  /// 更新URL级别统计
  void _updateUrlStats(ImagePerformanceEvent event) {
    final url = event.url;
    if (!_urlStats.containsKey(url)) {
      _urlStats[url] = ImagePerformanceStats(url: url);
    }

    final stats = _urlStats[url]!;
    stats.totalLoads++;

    if (event.success != null && event.success == true) {
      stats.successfulLoads++;
      stats.totalLoadTime += event.loadDuration!.inMilliseconds;

      if (event.cacheLevel != ImageCacheLevel.none) {
        stats.cachedLoads++;
      }

      // 更新最快/最慢加载时间
      if (stats.fastestLoadTime == null ||
          event.loadDuration! < stats.fastestLoadTime!) {
        stats.fastestLoadTime = event.loadDuration;
      }

      if (stats.slowestLoadTime == null ||
          event.loadDuration! > stats.slowestLoadTime!) {
        stats.slowestLoadTime = event.loadDuration;
      }
    } else {
      stats.failedLoads++;
    }

    stats.lastUpdated = DateTime.now();
  }

  /// 刷新数据到存储
  Future<void> _flushToStorage() async {
    try {
      // 这里可以实现将数据保存到本地存储或发送到服务器
      final data = exportData();
      debugPrint(
        '[ImagePerformanceMonitor] Flushed ${_events.length} events to storage',
      );

      // 示例：保存到本地（实际实现可以使用shared_preferences或sqlite）
      // await _saveToLocalStorage(data);
    } catch (e) {
      debugPrint('[ImagePerformanceMonitor] Flush failed: $e');
    }
  }

  /// 收集采样数据
  void _collectSampledData() {
    // 这里可以定期收集系统级别的性能数据
    // 如内存使用、CPU占用等
  }
}

/// 图片性能事件
class ImagePerformanceEvent {
  final String eventId;
  final String url;
  final String component;
  final ImageLoadSource source;
  final DateTime startTime;
  final Map<String, dynamic> metadata;

  DateTime? endTime;
  Duration? loadDuration;
  int? byteSize;
  ImageCacheLevel? cacheLevel;
  bool? success;
  String? error;

  ImagePerformanceEvent({
    required this.eventId,
    required this.url,
    required this.component,
    required this.source,
    required this.startTime,
    required this.metadata,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'url': url,
      'component': component,
      'source': source.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'loadDuration': loadDuration?.inMilliseconds,
      'byteSize': byteSize,
      'cacheLevel': cacheLevel?.name,
      'success': success,
      'error': error,
      'metadata': metadata,
    };
  }
}

/// 图片性能统计
class ImagePerformanceStats {
  final String? url;

  int totalLoads = 0;
  int successfulLoads = 0;
  int failedLoads = 0;
  int cachedLoads = 0;
  int totalLoadTime = 0; // milliseconds
  Duration? fastestLoadTime;
  Duration? slowestLoadTime;
  DateTime lastUpdated = DateTime.now();

  ImagePerformanceStats({this.url});

  /// 平均加载时间
  Duration get averageLoadTime {
    return successfulLoads > 0
        ? Duration(milliseconds: totalLoadTime ~/ successfulLoads)
        : Duration.zero;
  }

  /// 缓存命中率
  double get cacheHitRate {
    return totalLoads > 0 ? cachedLoads / totalLoads : 0.0;
  }

  /// 成功率
  double get successRate {
    return totalLoads > 0 ? successfulLoads / totalLoads : 0.0;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'totalLoads': totalLoads,
      'successfulLoads': successfulLoads,
      'failedLoads': failedLoads,
      'cachedLoads': cachedLoads,
      'averageLoadTime': averageLoadTime.inMilliseconds,
      'fastestLoadTime': fastestLoadTime?.inMilliseconds,
      'slowestLoadTime': slowestLoadTime?.inMilliseconds,
      'cacheHitRate': cacheHitRate,
      'successRate': successRate,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ImagePerformanceStats('
        'url: $url, '
        'total: $totalLoads, '
        'success: $successfulLoads, '
        'cache: $cachedLoads, '
        'avgTime: ${averageLoadTime.inMilliseconds}ms, '
        'hitRate: ${(cacheHitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 图片加载来源
enum ImageLoadSource {
  network('network'),
  memory('memory'),
  disk('disk'),
  asset('asset');

  final String name;

  const ImageLoadSource(this.name);
}

/// 图片缓存级别
enum ImageCacheLevel {
  none('none'),
  memory('memory'),
  disk('disk');

  final String name;

  const ImageCacheLevel(this.name);
}

/// 性能监控配置
class PerformanceMonitorConfig {
  // 数据收集
  static const bool enableEventTracking = true;
  static const bool enableUrlStats = true;
  static const bool enableSampling = true;

  // 存储限制
  static const int maxEvents = 1000;
  static const int maxUrlStats = 100;

  // 刷新间隔
  static const Duration flushInterval = Duration(minutes: 15);
  static const Duration samplingInterval = Duration(seconds: 30);

  // 上报配置
  static const bool enableRemoteReporting = false;
  static const Duration remoteReportInterval = Duration(minutes: 15);
  static const double samplingRate = 0.1; // 10%采样率
}

/// 性能监控Widget（用于包裹图片组件）
class PerformanceMonitoredImage extends StatelessWidget {
  final Widget child;
  final String url;
  final String componentName;
  final bool enableMonitoring;

  const PerformanceMonitoredImage({
    super.key,
    required this.child,
    required this.url,
    required this.componentName,
    this.enableMonitoring = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableMonitoring) return child;

    return _PerformanceMonitorWrapper(
      url: url,
      componentName: componentName,
      child: child,
    );
  }
}

class _PerformanceMonitorWrapper extends StatefulWidget {
  final String url;
  final String componentName;
  final Widget child;

  const _PerformanceMonitorWrapper({
    required this.url,
    required this.componentName,
    required this.child,
  });

  @override
  State<_PerformanceMonitorWrapper> createState() =>
      _PerformanceMonitorWrapperState();
}

class _PerformanceMonitorWrapperState
    extends State<_PerformanceMonitorWrapper> {
  String? _eventId;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();

    // 开始监控
    _startTime = DateTime.now();
    _eventId = ImagePerformanceMonitor().startImageLoad(
      url: widget.url,
      component: widget.componentName,
      source: ImageLoadSource.network,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    // 如果还没有结束，记录为失败
    if (_eventId != null && _startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      ImagePerformanceMonitor().recordLoadFailure(
        eventId: _eventId!,
        error: 'Component disposed before load completed',
        loadDuration: duration,
      );
    }

    super.dispose();
  }
}