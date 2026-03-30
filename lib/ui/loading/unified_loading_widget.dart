import 'package:flutter/material.dart';

/// Unified loading widget types
enum LoadingType {
  skeleton,
  spinner,
  progress,
}

/// Unified loading widget
/// Provides consistent loading states across the app
class UnifiedLoadingWidget extends StatelessWidget {
  final LoadingType type;
  final String? message;
  final double? progress;
  final Color? color;
  final double size;
  final EdgeInsetsGeometry padding;

  const UnifiedLoadingWidget({
    super.key,
    this.type = LoadingType.skeleton,
    this.message,
    this.progress,
    this.color,
    this.size = 40.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLoadingIndicator(context),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    switch (type) {
      case LoadingType.skeleton:
        return _buildSkeletonLoader();
      case LoadingType.spinner:
        return _buildSpinner(context);
      case LoadingType.progress:
        return _buildProgressIndicator(context);
    }
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: List.generate(3, (index) => _buildSkeletonItem()),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinner(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          Text(
            '${(progress! * 100).toInt()}%',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Progressive loader widget
/// Shows placeholder while loading, then transitions to child
class ProgressiveLoader extends StatefulWidget {
  final Widget child;
  final Widget placeholder;
  final Duration delay;
  final Duration transitionDuration;
  final Curve transitionCurve;

  const ProgressiveLoader({
    super.key,
    required this.child,
    required this.placeholder,
    this.delay = const Duration(milliseconds: 200),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionCurve = Curves.easeInOut,
  });

  @override
  State<ProgressiveLoader> createState() => _ProgressiveLoaderState();
}

class _ProgressiveLoaderState extends State<ProgressiveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showPlaceholder = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.transitionCurve,
    );

    // Start transition after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _showPlaceholder = false;
        });
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showPlaceholder) {
      return widget.placeholder;
    }

    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// Skeleton list item for chat/conversation lists
class SkeletonListItem extends StatelessWidget {
  final double avatarSize;
  final int lines;

  const SkeletonListItem({
    super.key,
    this.avatarSize = 50,
    this.lines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Lines skeleton
                ...List.generate(lines, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    height: 12,
                    width: index == lines - 1 ? 100 : double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Time skeleton
          Container(
            height: 12,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton grid item for product lists
class SkeletonGridItem extends StatelessWidget {
  final double imageHeight;
  final bool showPrice;
  final bool showRating;

  const SkeletonGridItem({
    super.key,
    this.imageHeight = 150,
    this.showPrice = true,
    this.showRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Container(
            height: imageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Price skeleton
                if (showPrice)
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                if (showPrice && showRating) const SizedBox(height: 8),
                // Rating skeleton
                if (showRating)
                  Row(
                    children: [
                      ...List.generate(5, (index) => Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      )),
                      const SizedBox(width: 4),
                      Container(
                        height: 12,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}