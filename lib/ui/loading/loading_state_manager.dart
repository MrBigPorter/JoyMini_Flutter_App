import 'package:flutter/material.dart';
import 'unified_loading_widget.dart';

/// Loading state manager
/// Provides centralized loading state management for the app
class LoadingStateManager {
  static final LoadingStateManager _instance = LoadingStateManager._internal();
  factory LoadingStateManager() => _instance;
  LoadingStateManager._internal();

  final Map<String, bool> _loadingStates = {};
  final Map<String, String?> _loadingMessages = {};
  final Map<String, double?> _loadingProgress = {};

  /// Check if a specific key is loading
  bool isLoading(String key) => _loadingStates[key] ?? false;

  /// Get loading message for a key
  String? getMessage(String key) => _loadingMessages[key];

  /// Get loading progress for a key
  double? getProgress(String key) => _loadingProgress[key];

  /// Set loading state
  void setLoading(
    String key, {
    required bool isLoading,
    String? message,
    double? progress,
  }) {
    _loadingStates[key] = isLoading;
    _loadingMessages[key] = message;
    _loadingProgress[key] = progress;
  }

  /// Clear loading state
  void clearLoading(String key) {
    _loadingStates.remove(key);
    _loadingMessages.remove(key);
    _loadingProgress.remove(key);
  }

  /// Clear all loading states
  void clearAll() {
    _loadingStates.clear();
    _loadingMessages.clear();
    _loadingProgress.clear();
  }

  /// Get all loading keys
  List<String> get loadingKeys => _loadingStates.keys.toList();

  /// Check if any loading is active
  bool get hasActiveLoading => _loadingStates.values.any((loading) => loading);
}

/// Loading state widget
/// Automatically updates based on loading state
class LoadingStateWidget extends StatefulWidget {
  final String loadingKey;
  final Widget child;
  final Widget Function(BuildContext context, String? message, double? progress)? loadingBuilder;
  final LoadingType loadingType;
  final bool showProgress;

  const LoadingStateWidget({
    super.key,
    required this.loadingKey,
    required this.child,
    this.loadingBuilder,
    this.loadingType = LoadingType.skeleton,
    this.showProgress = false,
  });

  @override
  State<LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

class _LoadingStateWidgetState extends State<LoadingStateWidget> {
  final LoadingStateManager _manager = LoadingStateManager();

  @override
  void initState() {
    super.initState();
    // Listen to loading state changes
    _addListener();
  }

  void _addListener() {
    // This would ideally use a proper state management solution
    // For now, we'll use a simple polling mechanism
    _startPolling();
  }

  void _startPolling() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() {});
      return mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _manager.isLoading(widget.loadingKey);
    final message = _manager.getMessage(widget.loadingKey);
    final progress = _manager.getProgress(widget.loadingKey);

    if (!isLoading) {
      return widget.child;
    }

    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, message, progress);
    }

    return UnifiedLoadingWidget(
      type: widget.loadingType,
      message: message,
      progress: widget.showProgress ? progress : null,
    );
  }
}

/// Loading overlay widget
/// Shows loading overlay on top of content
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? loadingWidget;
  final Color? barrierColor;
  final String? loadingMessage;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingWidget,
    this.barrierColor,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: barrierColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: loadingWidget ??
                  UnifiedLoadingWidget(
                    type: LoadingType.spinner,
                    message: loadingMessage ?? 'Loading...',
                  ),
            ),
          ),
      ],
    );
  }
}

/// Loading button widget
/// Shows loading state in button
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? loadingChild;
  final ButtonStyle? style;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.loadingChild,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? (loadingChild ??
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ))
          : child,
    );
  }
}

/// Loading list widget
/// Shows skeleton loading for lists
class LoadingListWidget extends StatelessWidget {
  final int itemCount;
  final bool isLoading;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? skeletonBuilder;
  final Axis scrollDirection;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LoadingListWidget({
    super.key,
    this.itemCount = 5,
    required this.isLoading,
    required this.itemBuilder,
    this.skeletonBuilder,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ListView.builder(
        scrollDirection: scrollDirection,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (skeletonBuilder != null) {
            return skeletonBuilder!(context, index);
          }
          return const SkeletonListItem();
        },
      );
    }

    return ListView.builder(
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Loading grid widget
/// Shows skeleton loading for grids
class LoadingGridWidget extends StatelessWidget {
  final int itemCount;
  final bool isLoading;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? skeletonBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const LoadingGridWidget({
    super.key,
    this.itemCount = 6,
    required this.isLoading,
    required this.itemBuilder,
    this.skeletonBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (skeletonBuilder != null) {
            return skeletonBuilder!(context, index);
          }
          return const SkeletonGridItem();
        },
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}