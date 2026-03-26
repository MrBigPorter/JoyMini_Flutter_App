import 'package:flutter/material.dart';
import 'package:flutter_app/utils/image/performance_monitor.dart';

/// 首页性能监控面板
/// 显示图片加载性能统计信息
class PerformancePanel extends StatefulWidget {
  final bool showDetailedStats;
  final VoidCallback? onRefresh;

  const PerformancePanel({
    super.key,
    this.showDetailedStats = false,
    this.onRefresh,
  });

  @override
  State<PerformancePanel> createState() => _PerformancePanelState();
}

class _PerformancePanelState extends State<PerformancePanel> {
  late ImagePerformanceMonitor _monitor;
  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _monitor = ImagePerformanceMonitor();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = _monitor.getStats();
      setState(() {
        _stats = stats.toJson();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[PerformancePanel] Failed to load stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showDetailedStats) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和刷新按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 图片性能监控',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  _loadStats();
                  widget.onRefresh?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_stats == null)
            const Text('暂无性能数据')
          else
            _buildStatsContent(),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    final stats = _stats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 总体统计
        _buildStatRow('📈 总加载次数', '${stats['totalLoads'] ?? 0}'),
        _buildStatRow('✅ 成功次数', '${stats['successfulLoads'] ?? 0}'),
        _buildStatRow('❌ 失败次数', '${stats['failedLoads'] ?? 0}'),
        _buildStatRow('🎯 成功率', '${_formatPercentage(stats['successRate'] ?? 0)}'),
        
        const SizedBox(height: 12),
        
        // 缓存命中率
        _buildStatRow('💾 缓存命中率', '${_formatPercentage(stats['cacheHitRate'] ?? 0)}'),
        _buildStatRow('⚡ 内存缓存命中', '${stats['cachedLoads'] ?? 0}'), // ImagePerformanceStats only has cachedLoads
        // _buildStatRow('💿 磁盘缓存命中', '${stats['diskCacheHits'] ?? 0}'), // Not directly available
        
        const SizedBox(height: 12),
        
        // 加载时间
        _buildStatRow('⏱️ 平均加载时间', '${_formatDuration(stats['averageLoadTime'] ?? 0)}'),
        _buildStatRow('🚀 最快加载时间', '${_formatDuration(stats['fastestLoadTime'] ?? 0)}'),
        _buildStatRow('🐌 最慢加载时间', '${_formatDuration(stats['slowestLoadTime'] ?? 0)}'),
        
        const SizedBox(height: 12),
        
        // 组件统计 (暂时移除，ImagePerformanceStats 不直接提供)
        // if (stats['componentStats'] != null && stats['componentStats'] is Map)
        //   _buildComponentStats(stats['componentStats'] as Map<String, dynamic>),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentStats(Map<String, dynamic> componentStats) {
    final entries = componentStats.entries.toList()
      ..sort((a, b) => (b.value['loadCount'] ?? 0).compareTo(a.value['loadCount'] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📱 组件统计',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...entries.take(5).map((entry) {
          final componentName = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    componentName,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${stats['loadCount'] ?? 0}次',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _formatPercentage(double percentage) {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }

  String _formatDuration(int milliseconds) {
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    } else {
      return '${(milliseconds / 1000).toStringAsFixed(2)}s';
    }
  }
}

/// 性能监控开关
class PerformanceToggle extends StatefulWidget {
  final ValueChanged<bool>? onChanged;

  const PerformanceToggle({super.key, this.onChanged});

  @override
  State<PerformanceToggle> createState() => _PerformanceToggleState();
}

class _PerformanceToggleState extends State<PerformanceToggle> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('性能监控'),
      subtitle: const Text('显示图片加载性能统计'),
      value: _isEnabled,
      onChanged: (value) {
        setState(() {
          _isEnabled = value;
        });
        widget.onChanged?.call(value);
      },
      secondary: const Icon(Icons.analytics),
    );
  }
}

/// 性能监控快捷入口
class PerformanceQuickView extends StatelessWidget {
  final VoidCallback onTap;

  const PerformanceQuickView({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text(
              '性能',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}