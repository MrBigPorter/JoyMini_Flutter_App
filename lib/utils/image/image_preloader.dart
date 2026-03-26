import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImagePreloader {
  static final ImagePreloader _instance = ImagePreloader._internal();
  factory ImagePreloader() => _instance;
  ImagePreloader._internal();

  final Set<String> _preloadedUrls = {};
  static const int _maxConcurrentPreloads = 3;

  Future<void> preloadUrls(List<String> urls, BuildContext context) async {
    if (urls.isEmpty) return;

    final urlsToPreload = urls.where((u) => !_preloadedUrls.contains(u)).toList();
    if (urlsToPreload.isEmpty) return;

    final semaphore = _Semaphore(_maxConcurrentPreloads);
    final futures = <Future>[];

    for (final url in urlsToPreload) {
      futures.add(semaphore.run(() async {
        try {
          // 【核心修复】直接使用传入的最终 URL，不再内部二次处理
          final provider = CachedNetworkImageProvider(url);
          await precacheImage(provider, context);
          _preloadedUrls.add(url);
          debugPrint('[ImagePreloader] Preloaded (Final): $url');
        } catch (e) {
          debugPrint('[ImagePreloader] Failed: $url - $e');
        }
      }));
    }
    await Future.wait(futures);
  }

  Future<void> preloadCriticalPath(BuildContext context) async => debugPrint('Preloading standard assets...');
  Map<String, dynamic> getStats() => { 'count': _preloadedUrls.length };
}

class _Semaphore {
  final int _max;
  int _current = 0;
  final _queue = <Completer<void>>[];
  _Semaphore(this._max);

  Future<T> run<T>(Future<T> Function() task) async {
    while (_current >= _max) {
      final c = Completer<void>();
      _queue.add(c);
      await c.future;
    }
    _current++;
    try { return await task(); } finally {
      _current--;
      if (_queue.isNotEmpty) _queue.removeAt(0).complete();
    }
  }
}