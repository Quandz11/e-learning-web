import 'dart:async';
import 'dart:convert';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/data/learning_api.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

final learningMediaPlayerBuilderProvider = Provider<LearningMediaPlayerBuilder>(
  (ref) =>
      ({required url, required title, required duration, embedUrl, videoId}) =>
          LearningMediaPlayer(
            url: url,
            title: title,
            duration: duration,
            embedUrl: embedUrl,
            videoId: videoId,
          ),
);

typedef LearningMediaPlayerBuilder =
    Widget Function({
      required Uri url,
      required String title,
      required double duration,
      Uri? embedUrl,
      String? videoId,
    });

final _videoEmbedUrlProvider = FutureProvider.family<Uri?, String>(
  (ref, videoId) => ref.read(learningApiProvider).getVideoEmbedUrl(videoId),
);

// ---------------------------------------------------------------------------
// MediaPlayerPanel – dispatch based on URL type
// ---------------------------------------------------------------------------
class MediaPlayerPanel extends ConsumerWidget {
  const MediaPlayerPanel({required this.part, super.key});

  final LearningLessonPart part;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoId = part.videoId?.trim();
    final directUrl = resolveDirectPlaybackUri(part);
    final embedUrl = part.embedUrl?.trim();
    final embedUri = embedUrl == null ? null : Uri.tryParse(embedUrl);

    // If videoId is present, fetch a fresh signed token URL from backend API
    // to prevent 403 Forbidden errors caused by stale cached tokens.
    if (videoId != null && videoId.isNotEmpty) {
      return LearningVideoEmbedFallback(videoId: videoId, title: part.title);
    }

    if (directUrl != null) {
      if (_isEmbedUrl(directUrl)) {
        return LearningVideoEmbedPlayer(url: directUrl, title: part.title);
      }
      final builder = ref.watch(learningMediaPlayerBuilderProvider);
      return builder(
        url: directUrl,
        title: part.title,
        duration: part.videoDuration,
        embedUrl: embedUri,
        videoId: videoId,
      );
    }

    if (embedUri != null && _isSupportedNetworkUrl(embedUri)) {
      return LearningVideoEmbedPlayer(url: embedUri, title: part.title);
    }

    if (videoId != null && videoId.isNotEmpty) {
      return LearningVideoEmbedFallback(videoId: videoId, title: part.title);
    }

    return const _InvalidMediaUrlCard();
  }
}

// ---------------------------------------------------------------------------
// LearningMediaPlayer – native VideoPlayerController
// ---------------------------------------------------------------------------
class LearningMediaPlayer extends StatefulWidget {
  const LearningMediaPlayer({
    required this.url,
    required this.title,
    required this.duration,
    this.embedUrl,
    this.videoId,
    super.key,
  });

  final Uri url;
  final String title;
  final double duration;
  final Uri? embedUrl;
  final String? videoId;

  @override
  State<LearningMediaPlayer> createState() => _LearningMediaPlayerState();
}

class _LearningMediaPlayerState extends State<LearningMediaPlayer> {
  VideoPlayerController? _controller;
  Object? _error;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LearningMediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _initialize();
    }
  }

  Future<void> _initialize() async {
    setState(() => _error = null);
    final headers = <String, String>{
      'Referer': 'https://iframe.mediadelivery.net/',
      'Origin': 'https://iframe.mediadelivery.net',
    };
    final c = VideoPlayerController.networkUrl(widget.url, httpHeaders: headers);
    _controller = c;
    c.addListener(_onControllerChanged);
    try {
      await c.initialize();
      if (!mounted || _controller != c) return;
      _startHideTimer();
      setState(() {});
    } catch (e) {
      if (!mounted || _controller != c) return;
      setState(() => _error = e);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _retry() async {
    _disposeController();
    await _initialize();
  }

  void _disposeController() {
    _hideControlsTimer?.cancel();
    final c = _controller;
    if (c == null) return;
    c.removeListener(_onControllerChanged);
    c.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
      _startHideTimer();
    }
  }

  Future<void> _openFullScreen() async {
    final c = _controller;
    if (c == null) return;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (ctx, _, __) => _NativeFullscreenPage(
          controller: c,
          title: widget.title,
          playbackSpeed: _playbackSpeed,
          onSpeedChanged: (s) {
            _playbackSpeed = s;
            c.setPlaybackSpeed(s);
          },
        ),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    if (_error != null) {
      final embedUrl = widget.embedUrl;
      if (embedUrl != null) {
        return LearningVideoEmbedPlayer(url: embedUrl, title: widget.title);
      }
      final videoId = widget.videoId;
      if (videoId != null) {
        return LearningVideoEmbedFallback(videoId: videoId, title: widget.title);
      }
      return AppErrorView(
        message: 'Không thể phát video. Vui lòng thử lại.',
        onRetry: _retry,
      );
    }

    if (c == null || !c.value.isInitialized) {
      return const AppLoadingView(label: 'Đang tải video...');
    }

    final v = c.value;
    final position = v.position.inSeconds.toDouble();
    final duration = v.duration.inSeconds.toDouble();

    return AppCard(
      child: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(child: VideoPlayer(c)),
                if (v.isBuffering)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66000000),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                if (_showControls) ...[
                  // dim
                  Positioned.fill(child: Container(color: Colors.black26)),
                  // top bar
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: _TopBar(
                      title: widget.title,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  // center play/pause
                  Center(
                    child: _PlayPauseButton(
                      isPlaying: v.isPlaying,
                      size: 48,
                      onTap: _togglePlayPause,
                    ),
                  ),
                  // bottom bar
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: _BottomBar(
                      position: position,
                      duration: duration,
                      isPlaying: v.isPlaying,
                      speed: _playbackSpeed,
                      isFullScreen: false,
                      onPlayPause: _togglePlayPause,
                      onSeek: (val) => c.seekTo(Duration(seconds: val.round())),
                      onSpeedChanged: (s) {
                        _playbackSpeed = s;
                        c.setPlaybackSpeed(s);
                        setState(() {});
                      },
                      onFullScreen: _openFullScreen,
                      volume: v.volume,
                      onVolumeChanged: (vol) => c.setVolume(vol),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Full-screen page for native video – completely separate widget tree
class _NativeFullscreenPage extends StatefulWidget {
  const _NativeFullscreenPage({
    required this.controller,
    required this.title,
    required this.playbackSpeed,
    required this.onSpeedChanged,
  });

  final VideoPlayerController controller;
  final String title;
  final double playbackSpeed;
  final ValueChanged<double> onSpeedChanged;

  @override
  State<_NativeFullscreenPage> createState() => _NativeFullscreenPageState();
}

class _NativeFullscreenPageState extends State<_NativeFullscreenPage> {
  bool _showControls = true;
  Timer? _hideTimer;
  late double _speed;

  @override
  void initState() {
    super.initState();
    _speed = widget.playbackSpeed;
    widget.controller.addListener(_onControllerChanged);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _togglePlayPause() {
    final c = widget.controller;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
      _startHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final v = c.value;
    final position = v.position.inSeconds.toDouble();
    final duration = v.duration.inSeconds.toDouble();

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Video fills entire screen
              Positioned.fill(child: VideoPlayer(c)),
              if (v.isBuffering)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              if (_showControls) ...[
                Positioned.fill(child: Container(color: Colors.black26)),
                // top bar
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: _TopBar(
                      title: widget.title,
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                // center
                Center(
                  child: _PlayPauseButton(
                    isPlaying: v.isPlaying,
                    size: 60,
                    onTap: _togglePlayPause,
                  ),
                ),
                // bottom bar
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: _BottomBar(
                      position: position,
                      duration: duration,
                      isPlaying: v.isPlaying,
                      speed: _speed,
                      isFullScreen: true,
                      onPlayPause: _togglePlayPause,
                      onSeek: (val) => c.seekTo(Duration(seconds: val.round())),
                      onSpeedChanged: (s) {
                        _speed = s;
                        widget.onSpeedChanged(s);
                        setState(() {});
                      },
                      onFullScreen: () => Navigator.of(context).pop(),
                      volume: v.volume,
                      onVolumeChanged: (vol) => c.setVolume(vol),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LearningVideoEmbedPlayer – Bunny/WebView embed player
// ---------------------------------------------------------------------------
class LearningVideoEmbedPlayer extends StatefulWidget {
  const LearningVideoEmbedPlayer({
    required this.url,
    required this.title,
    super.key,
  });

  final Uri url;
  final String title;

  @override
  State<LearningVideoEmbedPlayer> createState() =>
      _LearningVideoEmbedPlayerState();
}

class _LearningVideoEmbedPlayerState extends State<LearningVideoEmbedPlayer> {
  late final WebViewController _wvc;
  // Use ValueNotifier so controls overlay rebuilds independently of WebView
  final _data = ValueNotifier<_VideoData>(const _VideoData());
  Timer? _hideTimer;
  OverlayEntry? _overlayEntry;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _wvc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..addJavaScriptChannel(
        'FlutterVideoPlayer',
        onMessageReceived: (msg) {
          try {
            final map = jsonDecode(msg.message) as Map<String, dynamic>;
            final cur = _data.value;
            _data.value = cur.copyWith(
              position: (map['currentTime'] as num?)?.toDouble() ?? cur.position,
              duration: (map['duration'] as num?)?.toDouble() ?? cur.duration,
              isPlaying: map['paused'] != null
                  ? !(map['paused'] as bool)
                  : cur.isPlaying,
            );
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _injectJS(),
      ))
      ..loadRequest(
        _buildUri(widget.url),
        headers: const <String, String>{
          'Referer': 'https://iframe.mediadelivery.net/',
          'Origin': 'https://iframe.mediadelivery.net',
        },
      );

    if (_wvc.platform is AndroidWebViewController) {
      (_wvc.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _startHideTimer();
  }

  static Uri _buildUri(Uri uri) {
    final p = Map<String, String>.from(uri.queryParameters)
      ..['controls'] = 'false'
      ..['responsive'] = 'true'
      ..['autoplay'] = 'true';
    return uri.replace(queryParameters: p);
  }

  void _injectJS() {
    _wvc.runJavaScript(r'''
(function() {
  function injectStyle() {
    var styleId = 'flutter-hide-controls';
    var existing = document.getElementById(styleId);
    if (!existing) {
      var s = document.createElement('style');
      s.id = styleId;
      s.textContent = `
        .plyr__control--overlaid, .plyr__controls, .plyr__poster,
        .vjs-big-play-button, .vjs-control-bar, .vjs-poster,
        button.plyr__control, .controls-container, iframe-controls,
        .bunny-watermark, .video-react-big-play-button,
        [data-plyr="play"], .plyr__control, .plyr__poster--active,
        .plyr__captions, .plyr__tooltip, .plyr__video-wrapper button,
        .plyr__video-wrapper .plyr__poster {
          display: none !important;
          opacity: 0 !important;
          visibility: hidden !important;
          pointer-events: none !important;
        }
        video {
          width: 100% !important;
          height: 100% !important;
          object-fit: contain !important;
        }
      `;
      (document.head || document.documentElement).appendChild(s);
    }
  }

  function send(v) {
    if (!window.FlutterVideoPlayer) return;
    window.FlutterVideoPlayer.postMessage(
      JSON.stringify({
        currentTime: v.currentTime || 0,
        duration: v.duration || 0,
        paused: v.paused
      })
    );
  }

  var _retries = 0;
  function trySetup() {
    injectStyle();
    var v = document.querySelector('video');
    if (!v) {
      if (++_retries < 20) setTimeout(trySetup, 150);
      return;
    }
    if (v._flutter) return;
    v._flutter = true;
    v.autoplay = true;

    v.muted = false;
    if (v.volume === 0) v.volume = 1.0;

    if (v.readyState >= 2 && v.paused) {
      var p = v.play();
      if (p && p.catch) p.catch(function() {});
    } else if (v.paused) {
      v.addEventListener('canplay', function() {
        if (v.paused) {
          v.muted = false;
          var p = v.play();
          if (p && p.catch) p.catch(function() {});
        }
      }, { once: true });
    }

    v.addEventListener('timeupdate', function() { send(v); });
    v.addEventListener('play',        function() { send(v); });
    v.addEventListener('pause',       function() { send(v); });
    v.addEventListener('durationchange', function() { send(v); });
    v.addEventListener('ended',       function() { send(v); });
    v.addEventListener('error',       function() {
      setTimeout(function() {
        v.muted = false;
        if (v.volume === 0) v.volume = 1.0;
        var p = v.play();
        if (p && p.catch) p.catch(function(){});
      }, 1000);
    });
    v.addEventListener('volumechange', function() {
      if (v.muted) {
        v.muted = false;
      }
      if (v.volume === 0) {
        v.volume = 1.0;
      }
    });

    if (!window._flutterHlsHandled) {
      window._flutterHlsHandled = true;
      ['log', 'info', 'warn', 'error'].forEach(function(fnName) {
        var origFn = console[fnName];
        if (!origFn) return;
        console[fnName] = function() {
          var str = Array.prototype.slice.call(arguments).map(String).join(' ');
          if (str.indexOf('HLS error') !== -1 || str.indexOf('HLS error occured') !== -1) {
            var v = document.querySelector('video');
            if (v && v.paused) {
              setTimeout(function() {
                v.muted = false;
                if (v.volume === 0) v.volume = 1.0;
                var p = v.play();
                if (p && p.catch) p.catch(function(){});
              }, 500);
            }
            return;
          }
          origFn.apply(console, arguments);
        };
      });
    }
    send(v);
  }

  trySetup();
})();
''');
  }

  @override
  void dispose() {
    _closeFullScreenSync();
    _hideTimer?.cancel();
    _data.dispose();
    super.dispose();
  }

  void _closeFullScreenSync() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isFullScreen = false;
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (_data.value.isPlaying) {
        _data.value = _data.value.copyWith(showControls: false);
      }
    });
  }

  void _toggleControls() {
    final next = !_data.value.showControls;
    _data.value = _data.value.copyWith(showControls: next);
    if (next) _startHideTimer();
  }

  void _togglePlayPause() {
    _wvc.runJavaScript(r'''
(function(){
  var v = document.querySelector('video');
  if (!v) return;
  if (v.paused) {
    v.muted = false;
    var p = v.play(); if (p && p.catch) p.catch(function(){});
  } else {
    v.pause();
  }
})();
''');
    _data.value = _data.value.copyWith(
      isPlaying: !_data.value.isPlaying,
      showControls: true,
    );
    _startHideTimer();
  }

  void _seekTo(double secs) {
    _data.value = _data.value.copyWith(position: secs);
    _wvc.runJavaScript(
      '(function(){var v=document.querySelector("video");if(v)v.currentTime=$secs;})();',
    );
  }

  void _setSpeed(double speed) {
    _data.value = _data.value.copyWith(speed: speed);
    _wvc.runJavaScript(
      '(function(){var v=document.querySelector("video");if(v)v.playbackRate=$speed;})();',
    );
  }

  void _setVolume(double vol) {
    _data.value = _data.value.copyWith(volume: vol);
    _wvc.runJavaScript(
      '(function(){var v=document.querySelector("video");if(v){v.volume=$vol;v.muted=(${vol == 0});}})();',
    );
  }

  void _reinjectAndResume() {
    _injectJS();
    _wvc.runJavaScript(r'''
(function(){
  var v = document.querySelector('video');
  if (v) {
    v.muted = false;
    if (v.volume === 0) v.volume = 1.0;
    if (v.paused && v.readyState >= 2) {
      var p = v.play();
      if (p && p.catch) p.catch(function(){});
    }
  }
})();
''');
  }

  Future<void> _openFullScreen() async {
    if (!mounted || _isFullScreen) return;
    _isFullScreen = true;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    if (!mounted) {
      _closeFullScreenSync();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _closeFullScreen();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: ValueListenableBuilder<_VideoData>(
            valueListenable: _data,
            builder: (_, d, __) => _FullscreenGestureOverlay(
              position: d.position,
              duration: d.duration,
              volume: d.volume,
              speed: d.speed,
              showControls: d.showControls,
              onTap: _toggleControls,
              onSeek: _seekTo,
              onVolumeChanged: _setVolume,
              onSpeedChanged: _setSpeed,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        child: WebViewWidget(controller: _wvc),
                      ),
                    ),
                  ),
                  if (d.showControls)
                    Stack(
                      children: [
                        Positioned.fill(child: Container(color: Colors.black26)),
                        Positioned(
                          top: 0, left: 0, right: 0,
                          child: SafeArea(
                            child: _TopBar(
                              title: widget.title,
                              onBack: _closeFullScreen,
                            ),
                          ),
                        ),
                        Center(
                          child: _PlayPauseButton(
                            isPlaying: d.isPlaying,
                            size: 60,
                            onTap: _togglePlayPause,
                          ),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: SafeArea(
                            child: _BottomBar(
                              position: d.position,
                              duration: d.duration,
                              isPlaying: d.isPlaying,
                              speed: d.speed,
                              isFullScreen: true,
                              onPlayPause: _togglePlayPause,
                              onSeek: _seekTo,
                              onSpeedChanged: _setSpeed,
                              onFullScreen: _closeFullScreen,
                              volume: d.volume,
                              onVolumeChanged: _setVolume,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    setState(() {});
    _reinjectAndResume();
  }

  Future<void> _closeFullScreen() async {
    if (!_isFullScreen && _overlayEntry == null) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isFullScreen = false;

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      setState(() {});
      _reinjectAndResume();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reinjectAndResume();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _reinjectAndResume();
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _reinjectAndResume();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _isFullScreen
                      ? const ColoredBox(color: Colors.black)
                      : RepaintBoundary(
                          child: IgnorePointer(
                            child: WebViewWidget(controller: _wvc),
                          ),
                        ),
                ),
                ValueListenableBuilder<_VideoData>(
                  valueListenable: _data,
                  builder: (_, d, __) {
                    if (!d.showControls || _isFullScreen) {
                      return const SizedBox.shrink();
                    }
                    return Stack(
                      children: [
                        Positioned.fill(child: Container(color: Colors.black26)),
                        Positioned(
                          top: 0, left: 0, right: 0,
                          child: _TopBar(
                            title: widget.title,
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        Center(
                          child: _PlayPauseButton(
                            isPlaying: d.isPlaying,
                            size: 48,
                            onTap: _togglePlayPause,
                          ),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: _BottomBar(
                            position: d.position,
                            duration: d.duration,
                            isPlaying: d.isPlaying,
                            speed: d.speed,
                            isFullScreen: false,
                            onPlayPause: _togglePlayPause,
                            onSeek: _seekTo,
                            onSpeedChanged: _setSpeed,
                            onFullScreen: _openFullScreen,
                            volume: d.volume,
                            onVolumeChanged: _setVolume,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _GestureDragType { none, seek, volume, brightness }

class _FullscreenGestureOverlay extends StatefulWidget {
  const _FullscreenGestureOverlay({
    required this.child,
    required this.position,
    required this.duration,
    required this.volume,
    required this.speed,
    required this.showControls,
    required this.onTap,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onSpeedChanged,
  });

  final Widget child;
  final double position;
  final double duration;
  final double volume;
  final double speed;
  final bool showControls;
  final VoidCallback onTap;
  final ValueChanged<double> onSeek;
  final ValueChanged<double>? onVolumeChanged;
  final ValueChanged<double> onSpeedChanged;

  @override
  State<_FullscreenGestureOverlay> createState() =>
      _FullscreenGestureOverlayState();
}

class _FullscreenGestureOverlayState
    extends State<_FullscreenGestureOverlay> {
  double _brightness = 1.0;
  _GestureDragType _dragType = _GestureDragType.none;
  Offset _dragStartOffset = Offset.zero;
  double _dragStartValue = 0.0;
  double _dragCurrentValue = 0.0;
  Timer? _dismissIndicatorTimer;

  bool _is2xHolding = false;
  double _speedBeforeHold = 1.0;

  void _onPanStart(DragStartDetails details) {
    _dragStartOffset = details.localPosition;
    _dragType = _GestureDragType.none;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final dx = details.localPosition.dx - _dragStartOffset.dx;
    final dy = details.localPosition.dy - _dragStartOffset.dy;

    if (_dragType == _GestureDragType.none) {
      if (dx.abs() > dy.abs() && dx.abs() > 12) {
        _dragType = _GestureDragType.seek;
        _dragStartValue = widget.position;
      } else if (dy.abs() > 12) {
        if (_dragStartOffset.dx > size.width / 2) {
          _dragType = _GestureDragType.volume;
          _dragStartValue = widget.volume;
        } else {
          _dragType = _GestureDragType.brightness;
          _dragStartValue = _brightness;
        }
      }
    }

    if (_dragType == _GestureDragType.seek) {
      if (widget.duration > 0) {
        final deltaSecs = dx * 0.25;
        _dragCurrentValue =
            (_dragStartValue + deltaSecs).clamp(0.0, widget.duration);
        setState(() {});
      }
    } else if (_dragType == _GestureDragType.volume) {
      final deltaVol = -dy / (size.height * 0.6);
      final newVol = (_dragStartValue + deltaVol).clamp(0.0, 1.0);
      _dragCurrentValue = newVol;
      widget.onVolumeChanged?.call(newVol);
      setState(() {});
    } else if (_dragType == _GestureDragType.brightness) {
      final deltaBright = -dy / (size.height * 0.6);
      _brightness = (_dragStartValue + deltaBright).clamp(0.15, 1.0);
      _dragCurrentValue = _brightness;
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragType == _GestureDragType.seek) {
      widget.onSeek(_dragCurrentValue);
    }
    _dismissIndicatorTimer?.cancel();
    _dismissIndicatorTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _dragType = _GestureDragType.none);
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    HapticFeedback.selectionClick();
    _is2xHolding = true;
    _speedBeforeHold = widget.speed;
    widget.onSpeedChanged(2.0);
    setState(() {});
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_is2xHolding) {
      _is2xHolding = false;
      widget.onSpeedChanged(_speedBeforeHold);
      setState(() {});
    }
  }

  void _onLongPressCancel() {
    if (_is2xHolding) {
      _is2xHolding = false;
      widget.onSpeedChanged(_speedBeforeHold);
      setState(() {});
    }
  }

  String _formatTime(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final h = duration.inHours.toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.black
                    .withValues(alpha: (1.0 - _brightness).clamp(0.0, 0.85)),
              ),
            ),
          ),
          if (_is2xHolding)
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amberAccent, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fast_forward_rounded,
                          color: Colors.amberAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Đang tua 2X',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_dragType != _GestureDragType.none)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dragType == _GestureDragType.seek) ...[
                      Icon(
                        _dragCurrentValue >= widget.position
                            ? Icons.fast_forward_rounded
                            : Icons.fast_rewind_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatTime(_dragCurrentValue)} / ${_formatTime(widget.duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_dragCurrentValue >= widget.position ? "+" : ""}${(_dragCurrentValue - widget.position).round()}s',
                        style: TextStyle(
                          color: _dragCurrentValue >= widget.position
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          fontSize: 13,
                        ),
                      ),
                    ] else if (_dragType == _GestureDragType.volume) ...[
                      Icon(
                        _dragCurrentValue == 0
                            ? Icons.volume_off_rounded
                            : _dragCurrentValue < 0.5
                                ? Icons.volume_down_rounded
                                : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Âm lượng: ${(_dragCurrentValue * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (_dragType == _GestureDragType.brightness) ...[
                      Icon(
                        _brightness < 0.5
                            ? Icons.brightness_medium_rounded
                            : Icons.brightness_7_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Độ sáng: ${(_brightness * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI building blocks
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cast_rounded, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.size,
    required this.onTap,
  });

  final bool isPlaying;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: IconButton(
        iconSize: size,
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.speed,
    required this.isFullScreen,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeedChanged,
    required this.onFullScreen,
    this.volume = 1.0,
    this.onVolumeChanged,
  });

  final double position;
  final double duration;
  final bool isPlaying;
  final double speed;
  final bool isFullScreen;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onFullScreen;
  final double volume;
  final ValueChanged<double>? onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    final maxDur = duration > 0 ? duration : 1.0;
    final clampedPos = position.clamp(0.0, maxDur);

    return Container(
      padding: EdgeInsets.only(
        left: isFullScreen ? 16 : 8,
        right: isFullScreen ? 16 : 8,
        bottom: isFullScreen ? 12 : 6,
        top: 6,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Play/Pause
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: onPlayPause,
          ),
          const SizedBox(width: 6),
          // Time
          Text(
            '${_fmt(position)} / ${_fmt(duration)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          // Slider
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: clampedPos,
                min: 0.0,
                max: maxDur,
                onChanged: onSeek,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Volume Control
          if (onVolumeChanged != null) ...[
            PopupMenuButton<double>(
              tooltip: 'Âm lượng',
              initialValue: volume,
              onSelected: onVolumeChanged,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 1.0, child: Text('100%')),
                PopupMenuItem(value: 0.75, child: Text('75%')),
                PopupMenuItem(value: 0.50, child: Text('50%')),
                PopupMenuItem(value: 0.25, child: Text('25%')),
                PopupMenuItem(value: 0.0, child: Text('Tắt âm')),
              ],
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  volume == 0
                      ? Icons.volume_off_rounded
                      : (volume < 0.5
                          ? Icons.volume_down_rounded
                          : Icons.volume_up_rounded),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Speed badge
          PopupMenuButton<double>(
            tooltip: 'Tốc độ',
            initialValue: speed,
            onSelected: onSpeedChanged,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 0.75, child: Text('0.75x')),
              PopupMenuItem(value: 1.0, child: Text('1.0x')),
              PopupMenuItem(value: 1.25, child: Text('1.25x')),
              PopupMenuItem(value: 1.5, child: Text('1.5x')),
              PopupMenuItem(value: 2.0, child: Text('2.0x')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${speed}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Fullscreen toggle
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: Icon(
              isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: onFullScreen,
          ),
        ],
      ),
    );
  }

  static String _fmt(double secs) {
    if (!secs.isFinite || secs < 0) return '00:00';
    final d = Duration(seconds: secs.round());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ---------------------------------------------------------------------------
// Value object for embed player state
// ---------------------------------------------------------------------------
class _VideoData {
  final double position;
  final double duration;
  final bool isPlaying;
  final bool showControls;
  final double speed;
  final double volume;

  const _VideoData({
    this.position = 0,
    this.duration = 0,
    this.isPlaying = true,
    this.showControls = true,
    this.speed = 1.0,
    this.volume = 1.0,
  });

  _VideoData copyWith({
    double? position,
    double? duration,
    bool? isPlaying,
    bool? showControls,
    double? speed,
    double? volume,
  }) =>
      _VideoData(
        position: position ?? this.position,
        duration: duration ?? this.duration,
        isPlaying: isPlaying ?? this.isPlaying,
        showControls: showControls ?? this.showControls,
        speed: speed ?? this.speed,
        volume: volume ?? this.volume,
      );
}

// ---------------------------------------------------------------------------
// Embed fallback (fetches embed URL then delegates to LearningVideoEmbedPlayer)
// ---------------------------------------------------------------------------
class LearningVideoEmbedFallback extends ConsumerWidget {
  const LearningVideoEmbedFallback({
    required this.videoId,
    required this.title,
    super.key,
  });

  final String videoId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_videoEmbedUrlProvider(videoId));
    return async.when(
      loading: () => const AppLoadingView(label: 'Đang mở trình phát…'),
      error: (_, __) => AppErrorView(
        message: 'Không thể mở trình phát. Vui lòng thử lại.',
        onRetry: () => ref.invalidate(_videoEmbedUrlProvider(videoId)),
      ),
      data: (embedUrl) {
        if (embedUrl == null || !_isSupportedNetworkUrl(embedUrl)) {
          return const _InvalidMediaUrlCard();
        }
        return LearningVideoEmbedPlayer(url: embedUrl, title: title);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers & small widgets
// ---------------------------------------------------------------------------
class _InvalidMediaUrlCard extends StatelessWidget {
  const _InvalidMediaUrlCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('Video chưa có đường dẫn phát hợp lệ. Vui lòng quay lại sau.'),
          ),
        ],
      ),
    );
  }
}

bool _isSupportedNetworkUrl(Uri uri) =>
    uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http');

bool _isEmbedUrl(Uri uri) {
  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();
  return host.contains('mediadelivery.net') ||
      host.contains('b-cdn.net') ||
      path.contains('/embed/') ||
      path.endsWith('.html');
}

Uri? resolveDirectPlaybackUri(LearningLessonPart part) {
  final raw = part.playbackUrl?.trim();
  if (raw != null && raw.isNotEmpty) {
    final uri = Uri.tryParse(raw);
    if (uri != null && _isSupportedNetworkUrl(uri)) return uri;
  }
  return null;
}
