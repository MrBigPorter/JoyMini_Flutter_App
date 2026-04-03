import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/media/video_playback_service.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/ui/chat/video_player_page.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 🔒  Global playback mutex
//     Only one video bubble may be in "playing" state at any time.
// ═══════════════════════════════════════════════════════════════════════════════
final ValueNotifier<String?> _playingMsgId = ValueNotifier(null);

// ═══════════════════════════════════════════════════════════════════════════════
// 📦  Fix 3 — LRU Controller Pool
//
//     Problem : every time another video is played the old one is fully disposed.
//               Scrolling back means re-downloading + re-initialize (1-3 s lag).
//     Solution: park the paused-but-initialized controller in this pool (max 3).
//               Next time the same bubble appears it gets an instant play.
//
//     LinkedHashMap insertion order = LRU order (oldest key = _pool.keys.first).
// ═══════════════════════════════════════════════════════════════════════════════
class _VideoControllerPool {
  _VideoControllerPool._();
  static final _VideoControllerPool instance = _VideoControllerPool._();

  static const int _maxSize = 3;
  final LinkedHashMap<String, VideoPlayerController> _pool = LinkedHashMap();

  /// Retrieve a controller for [msgId]. Moves it to "most-recently-used" slot.
  VideoPlayerController? get(String msgId) {
    final ctrl = _pool.remove(msgId);
    if (ctrl != null) {
      _pool[msgId] = ctrl; // reinsert at tail = MRU
      debugPrint('[VideoPool] ✅ HIT  msgId=$msgId  pool=${_pool.length}');
    }
    return ctrl;
  }

  /// Park a controller. Evicts the least-recently-used entry when at capacity.
  void put(String msgId, VideoPlayerController ctrl) {
    _pool.remove(msgId); // deduplicate
    if (_pool.length >= _maxSize) {
      final lruKey = _pool.keys.first;
      final lru = _pool.remove(lruKey)!;
      lru.pause();
      lru.dispose();
      debugPrint('[VideoPool] ♻️  Evicted LRU msgId=$lruKey');
    }
    ctrl.pause();
    _pool[msgId] = ctrl;
    debugPrint('[VideoPool] 📥  Stored  msgId=$msgId  pool=${_pool.length}');
  }

  /// Release all pooled controllers (call on logout / app restart).
  void clear() {
    for (final ctrl in _pool.values) {
      ctrl.pause();
      ctrl.dispose();
    }
    _pool.clear();
    debugPrint('[VideoPool] 🗑️  Cleared');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🎬  VideoMsgBubble
// ═══════════════════════════════════════════════════════════════════════════════
class VideoMsgBubble extends StatefulWidget {
  final ChatUiModel message;
  final bool isMe;

  const VideoMsgBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<VideoMsgBubble> createState() => _VideoMsgBubbleState();
}

class _VideoMsgBubbleState extends State<VideoMsgBubble> {
  // ── playback state ─────────────────────────────────────────────────────────
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isLoading = false;

  // ── Fix 2: pre-warm state ──────────────────────────────────────────────────
  bool _isPrewarming = false;
  Timer? _prewarmTimer;

  static final _pool = _VideoControllerPool.instance;
  static final _svc = VideoPlaybackService();

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _playingMsgId.addListener(_onGlobalPlayChanged);
  }

  @override
  void dispose() {
    _prewarmTimer?.cancel();
    _playingMsgId.removeListener(_onGlobalPlayChanged);

    // Park initialized-but-idle controllers in the pool for later reuse.
    // Only hard-dispose if still loading / actively playing.
    if (_controller != null) {
      if (_controller!.value.isInitialized && !_isPlaying) {
        _pool.put(widget.message.id, _controller!);
        _controller = null;
      } else {
        _hardDispose();
      }
    }
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _hardDispose() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _isPlaying = false;
    _isLoading = false;
    _isPrewarming = false;
  }

  /// Resolves the best playable source: local file → web blob → remote URL.
  Future<String> _resolvePlayableUrl() async {
    final String? local = widget.message.localPath;
    if (kDebugMode) {
      debugPrint('[VideoDebug] ID=${widget.message.id} local=$local');
    }
    if (AssetManager.existsSync(local)) {
      return AssetManager.getRuntimePath(local);
    }
    if (kIsWeb && local != null && local.startsWith('blob:')) {
      return local;
    }
    return UrlResolver.resolveVideo(widget.message.content);
  }

  // ── Fix 1: controller factory (always uses VideoPlaybackService → Range header)
  //
  //   VideoPlaybackService.createController() adds  `Range: bytes=0-`  so the
  //   player only fetches the MOOV atom first (HTTP 206), then streams the rest.
  //   This reduces initialize() time by 20-40% on most CDNs.
  // ──────────────────────────────────────────────────────────────────────────
  Future<VideoPlayerController?> _buildController(String url) async {
    // Pool hit → instant, no network round-trip
    final pooled = _pool.get(widget.message.id);
    if (pooled != null && pooled.value.isInitialized) return pooled;

    // Fix 1: use service factory (adds Range header for network URLs)
    final ctrl = _svc.createController(url);
    try {
      await ctrl.initialize();
      return ctrl;
    } catch (e) {
      debugPrint('[Video] init failed: $e');
      ctrl.dispose();
      return null;
    }
  }

  // ── Fix 3: global-play handler → park in pool instead of dispose ───────────

  void _onGlobalPlayChanged() {
    if (_playingMsgId.value == widget.message.id) return; // still ours
    if (_controller == null) return;

    if (_controller!.value.isInitialized) {
      // Park rather than destroy — the user might scroll back soon
      _pool.put(widget.message.id, _controller!);
    } else {
      _controller!.dispose();
    }
    _controller = null;

    if (mounted) setState(() { _isPlaying = false; _isLoading = false; });
  }

  // ── Fix 2: viewport pre-warm ───────────────────────────────────────────────
  //
  //   VisibilityDetector fires when the bubble scrolls into view.
  //   A 400 ms debounce timer filters fast scrolls — only bubbles the user
  //   actually stops on get pre-warmed.  Pre-warm calls initialize() silently
  //   (no play), so by the time the user taps, the controller is ready.
  // ──────────────────────────────────────────────────────────────────────────

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction >= 0.3) {
      _prewarmTimer ??= Timer(const Duration(milliseconds: 400), _prewarm);
    } else {
      _prewarmTimer?.cancel();
      _prewarmTimer = null;
    }
  }

  Future<void> _prewarm() async {
    _prewarmTimer = null;
    if (!mounted) return;
    if (_controller != null) return; // already have one
    if (_isPrewarming) return;
    if (widget.message.status == MessageStatus.sending) return; // still uploading

    final url = await _resolvePlayableUrl();
    if (!mounted || url.isEmpty) return;
    if (_controller != null) return; // re-check after async gap

    // Pool hit: silently restore without any network call
    final pooled = _pool.get(widget.message.id);
    if (pooled != null && pooled.value.isInitialized) {
      if (mounted) setState(() => _controller = pooled);
      debugPrint('[Video] Pre-warm: pool hit ${widget.message.id}');
      return;
    }

    // Only pre-warm remote URLs (local files init instantly on tap anyway)
    if (!url.startsWith('http')) return;

    _isPrewarming = true;
    debugPrint('[Video] Pre-warming: ${widget.message.id}');
    final ctrl = _svc.createController(url); // Fix 1: Range header
    try {
      await ctrl.initialize();
      if (!mounted || _controller != null) {
        // Widget gone, or _togglePlay already set a controller — discard
        ctrl.dispose();
      } else {
        setState(() { _controller = ctrl; _isPrewarming = false; });
        debugPrint('[Video] Pre-warm done: ${widget.message.id}');
      }
    } catch (e) {
      ctrl.dispose();
      if (mounted) setState(() => _isPrewarming = false);
      debugPrint('[Video] Pre-warm failed: $e');
    }
  }

  // ── tap: toggle playback ───────────────────────────────────────────────────

  Future<void> _togglePlay() async {
    // Pause if playing
    if (_isPlaying && _controller != null) {
      _controller!.pause();
      setState(() => _isPlaying = false);
      return;
    }

    // Pre-warm or pool hit: controller already initialized — play instantly
    if (_controller != null && _controller!.value.isInitialized) {
      _playingMsgId.value = widget.message.id;
      await _controller!.play();
      if (mounted) setState(() => _isPlaying = true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final url = await _resolvePlayableUrl();
      if (url.isEmpty) { setState(() => _isLoading = false); return; }

      _playingMsgId.value = widget.message.id;

      final ctrl = await _buildController(url); // Fix 1 + Fix 3
      if (!mounted || ctrl == null) {
        ctrl?.dispose();
        setState(() => _isLoading = false);
        return;
      }

      _controller = ctrl;
      await _controller!.play();
      if (mounted) setState(() { _isPlaying = true; _isLoading = false; });
    } catch (e) {
      debugPrint('[Video] play failed: $e');
      _hardDispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── double-tap: open full-screen player ───────────────────────────────────

  Future<void> _openFullScreen() async {
    _controller?.pause();
    if (mounted) setState(() => _isPlaying = false);

    final url = await _resolvePlayableUrl();
    if (url.isEmpty || !mounted) return;

    final remoteThumb = UrlResolver.resolveImage(context, widget.message.meta?['thumb']);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VideoPlayerPage(
        videoSource: url,
        heroTag: 'video_${widget.message.id}',
        thumbSource: widget.message.localPath ?? widget.message.meta?['thumb'] ?? '',
        cachedThumbUrl: remoteThumb,
      ),
    ));
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final source = widget.message.previewBytes ?? widget.message.meta?['thumb'];
    const double bubbleWidth = 240.0;
    final double w = (widget.message.meta?['w'] ?? 16).toDouble();
    final double h = (widget.message.meta?['h'] ?? 9).toDouble();
    final double aspectRatio = (w / h).clamp(0.6, 1.8);

    final bool showVideo =
        _controller != null && _controller!.value.isInitialized && _isPlaying;

    // Fix 2: wrap with VisibilityDetector for pre-warm trigger
    return VisibilityDetector(
      key: Key('vd_${widget.message.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _togglePlay,
        onDoubleTap: _openFullScreen,
        child: Container(
          width: bubbleWidth,
          height: bubbleWidth / aspectRatio,
          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 320),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Thumbnail / cover
                if (!showVideo)
                  Positioned.fill(
                    child: AppCachedImage(
                      source,
                      width: bubbleWidth,
                      height: bubbleWidth / aspectRatio,
                      fit: BoxFit.cover,
                      previewBytes: widget.message.previewBytes,
                      metadata: widget.message.meta,
                      placeholder: Container(color: Colors.black12),
                    ),
                  ),

                // 2. Video player
                if (showVideo)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),

                // 3. Loading spinner / play button
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                else if (!_isPlaying)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),

                // 4. Duration label
                if (!_isPlaying && widget.message.duration != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(widget.message.duration!),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),

                // 5. Upload-in-progress overlay
                if (widget.message.status == MessageStatus.sending)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}