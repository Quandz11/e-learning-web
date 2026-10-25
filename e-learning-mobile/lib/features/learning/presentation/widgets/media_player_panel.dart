import 'volume_control.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/data/learning_api.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/offline_download_controller.dart';
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
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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

final _videoEmbedUrlProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, videoId) => ref.read(learningApiProvider).getVideoPlayback(videoId),
    );

// ---------------------------------------------------------------------------
// MediaPlayerPanel – dispatch based on URL type
// ---------------------------------------------------------------------------
class MediaPlayerPanel extends ConsumerWidget {
  const MediaPlayerPanel({required this.part, super.key});

  final LearningLessonPart part;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineDownloadControllerProvider);
    final localItem = offlineState.getItem(part.id);

    if (localItem != null) {
      final builder = ref.watch(learningMediaPlayerBuilderProvider);
      return builder(
        url: Uri.file(localItem.localPath),
        title: part.title,
        duration: part.videoDuration,
      );
    }

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
class LearningMediaPlayer extends ConsumerStatefulWidget {
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
  ConsumerState<LearningMediaPlayer> createState() =>
      _LearningMediaPlayerState();
}

class _LearningMediaPlayerState extends ConsumerState<LearningMediaPlayer> {
  VideoPlayerController? _controller;
  Object? _error;
  Uri? _refreshedUrl;
  Uri? _refreshedEmbed;
  bool _refreshAttempted = false;
  bool _recovering = false;
  _VideoData _resume = const _VideoData(isPlaying: false);

  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _volumeOpen = false;
  double _playbackSpeed = 1.0;
  String _quality = 'Tự động (Auto)';

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
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };
    final playbackUri = _refreshedUrl ?? widget.url;
    final targetUri = playbackUri.scheme == 'file' ? playbackUri : playbackUri;
    final c = targetUri.scheme == 'file'
        ? VideoPlayerController.file(File(targetUri.toFilePath()))
        : VideoPlayerController.networkUrl(targetUri, httpHeaders: headers);
    _controller = c;
    c.addListener(_onControllerChanged);
    try {
      await c.initialize();
      if (!mounted || _controller != c) return;
      await c.setVolume(_resume.volume);
      await c.setPlaybackSpeed(_resume.speed);
      await c.seekTo(Duration(milliseconds: (_resume.position * 1000).round()));
      if (_resume.isPlaying) await c.play();
      _startHideTimer();
      setState(() {});
    } catch (e) {
      if (!mounted || _controller != c) return;
      if (widget.embedUrl != null) {
        setState(() => _error = e);
        return;
      }
      await _recover(e);
    }
  }

  void _onControllerChanged() {
    final c = _controller;
    if (c != null && c.value.isInitialized && !c.value.hasError) {
      _resume = _resume.copyWith(
        position: c.value.position.inMilliseconds / 1000,
        isPlaying: c.value.isPlaying,
        speed: c.value.playbackSpeed,
        volume: c.value.volume,
      );
    }
    if (c?.value.hasError == true && !_recovering) {
      unawaited(_recover(StateError('Playback failed')));
    }
    if (mounted) setState(() {});
  }

  Future<void> _recover(Object error) async {
    if (_recovering || !mounted) return;
    _recovering = true;
    _disposeController();
    if (!_refreshAttempted && widget.videoId != null) {
      _refreshAttempted = true;
      try {
        final source = await ref
            .read(learningApiProvider)
            .getVideoPlayback(widget.videoId!);
        if (!mounted) return;
        _refreshedUrl = Uri.tryParse(source['playbackUrl']?.toString() ?? '');
        _refreshedEmbed = Uri.tryParse(source['embedUrl']?.toString() ?? '');
        if (_refreshedEmbed != null) {
          _recovering = false;
          if (mounted) setState(() => _error = error);
          return;
        }
        _recovering = false;
        await _initialize();
        return;
      } catch (_) {
        // No fallback after an API failure: access may have been revoked.
        if (mounted) {
          setState(() {
            _error = error;
            _sourceDenied = true;
          });
        }
        _recovering = false;
        return;
      }
    }
    if (mounted) setState(() => _error = error);
    _recovering = false;
  }

  bool _sourceDenied = false;

  Future<void> _retry() async {
    _disposeController();
    _refreshAttempted = false;
    _sourceDenied = false;
    await _initialize();
  }

  Future<void> _changeQuality(String newQuality) async {
    if (_quality == newQuality) return;
    _quality = newQuality;

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      if (mounted) setState(() {});
      return;
    }

    final currentPos = c.value.position;
    final wasPlaying = c.value.isPlaying;

    final baseUri = widget.url;
    final qualityParam = newQuality.contains('1080p')
        ? '1080p'
        : newQuality.contains('720p')
        ? '720p'
        : newQuality.contains('480p')
        ? '480p'
        : newQuality.contains('360p')
        ? '360p'
        : 'auto';

    final queryParams = Map<String, String>.from(baseUri.queryParameters)
      ..['quality'] = qualityParam
      ..['resolution'] = qualityParam;
    final qualityUri = baseUri.replace(queryParameters: queryParams);

    _disposeController();

    final headers = <String, String>{
      'Referer': 'https://iframe.mediadelivery.net/',
      'Origin': 'https://iframe.mediadelivery.net',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };
    final newC = VideoPlayerController.networkUrl(
      qualityUri,
      httpHeaders: headers,
    );
    _controller = newC;
    newC.addListener(_onControllerChanged);

    try {
      await newC.initialize();
      if (!mounted || _controller != newC) return;
      await newC.seekTo(currentPos);
      newC.setPlaybackSpeed(_playbackSpeed);
      if (wasPlaying) await newC.play();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã phát chất lượng: $newQuality'),
            backgroundColor: const Color(0xFF0F5B38),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted || _controller != newC) return;
      if (mounted) setState(() => _error = e);
    }
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
      if (mounted && !_volumeOpen && (_controller?.value.isPlaying ?? false)) {
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
      final embedUrl = _sourceDenied
          ? null
          : (_refreshedEmbed ?? widget.embedUrl);
      if (embedUrl != null) {
        return LearningVideoEmbedPlayer(
          url: embedUrl,
          title: widget.title,
          initialPosition: _resume.position,
          initialVolume: _resume.volume,
          initialSpeed: _resume.speed,
          initiallyPlaying: _resume.isPlaying,
        );
      }
      final videoId = widget.videoId;
      if (videoId != null && !_sourceDenied && !_refreshAttempted) {
        return LearningVideoEmbedFallback(
          videoId: videoId,
          title: widget.title,
        );
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

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
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
                  top: 0,
                  left: 0,
                  right: 0,
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
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BottomBar(
                    position: position,
                    duration: duration,
                    isPlaying: v.isPlaying,
                    speed: _playbackSpeed,
                    isFullScreen: false,
                    quality: _quality,
                    onQualityChanged: _changeQuality,
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
                    onVolumeInteractionChanged: (open) => _volumeOpen = open,
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
  bool _volumeOpen = false;
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
      if (mounted && !_volumeOpen && widget.controller.value.isPlaying) {
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
                  top: 0,
                  left: 0,
                  right: 0,
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
                  bottom: 0,
                  left: 0,
                  right: 0,
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
                      onVolumeInteractionChanged: (open) => _volumeOpen = open,
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
class LearningVideoEmbedPlayer extends ConsumerStatefulWidget {
  const LearningVideoEmbedPlayer({
    required this.url,
    required this.title,
    this.initialPosition = 0,
    this.initialVolume = 1,
    this.initialSpeed = 1,
    this.initiallyPlaying = true,
    super.key,
  });

  final double initialPosition, initialVolume, initialSpeed;
  final bool initiallyPlaying;
  final Uri url;
  final String title;

  @override
  ConsumerState<LearningVideoEmbedPlayer> createState() =>
      _LearningVideoEmbedPlayerState();
}

class _LearningVideoEmbedPlayerState
    extends ConsumerState<LearningVideoEmbedPlayer> {
  late final WebViewController _wvc;
  // Use ValueNotifier so controls overlay rebuilds independently of WebView
  final _data = ValueNotifier<_VideoData>(const _VideoData());
  Timer? _hideTimer;
  bool _volumeOpen = false;
  OverlayEntry? _overlayEntry;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _wvc = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    if (Platform.isIOS) {
      _wvc.setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
      );
    } else {
      _wvc.setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      );
    }

    if (_wvc.platform is AndroidWebViewController) {
      (_wvc.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    } else if (_wvc.platform is WebKitWebViewController) {
      final webkit = _wvc.platform as WebKitWebViewController;
      webkit.setAllowsBackForwardNavigationGestures(false);
    }

    _wvc
      ..addJavaScriptChannel(
        'FlutterVideoPlayer',
        onMessageReceived: (msg) {
          try {
            final map = jsonDecode(msg.message) as Map<String, dynamic>;
            final cur = _data.value;
            _data.value = cur.copyWith(
              volume: (map['muted'] == true)
                  ? 0
                  : ((map['volume'] as num?)?.toDouble() ?? cur.volume),
              speed: (map['playbackRate'] as num?)?.toDouble() ?? cur.speed,
              position:
                  (map['currentTime'] as num?)?.toDouble() ?? cur.position,
              duration: (map['duration'] as num?)?.toDouble() ?? cur.duration,
              isPlaying: map['paused'] != null
                  ? !(map['paused'] as bool)
                  : cur.isPlaying,
            );
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => _injectJS()),
      )
      ..loadRequest(
        _buildUri(widget.url),
        headers: const <String, String>{
          'Referer': 'https://iframe.mediadelivery.net/',
          'Origin': 'https://iframe.mediadelivery.net',
        },
      );

    _startHideTimer();
  }

  @override
  void didUpdateWidget(covariant LearningVideoEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _wvc.loadRequest(
        _buildUri(widget.url),
        headers: const <String, String>{
          'Referer': 'https://iframe.mediadelivery.net/',
          'Origin': 'https://iframe.mediadelivery.net',
        },
      );
    }
  }

  static Uri _buildUri(Uri uri) {
    final p = Map<String, String>.from(uri.queryParameters)
      ..['controls'] = 'false'
      ..['responsive'] = 'true'
      ..['autoplay'] = 'true'
      ..['playsinline'] = 'true'
      ..['preload'] = 'true';
    return uri.replace(queryParameters: p);
  }

  void _injectJS() {
    _wvc.runJavaScript(
      'window.flutterInitial = ${jsonEncode({'position': widget.initialPosition, 'volume': widget.initialVolume, 'speed': widget.initialSpeed, 'playing': widget.initiallyPlaying})};',
    );
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
        paused: v.paused, volume: v.volume, muted: v.muted, playbackRate: v.playbackRate
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
    v.setAttribute('playsinline', 'true');
    v.setAttribute('webkit-playsinline', 'true');
    v.setAttribute('x5-playsinline', 'true');
    v.playsInline = true;
    var initial = window.flutterInitial;
    v.autoplay = initial.playing;
    v.volume = initial.volume;
    v.muted = initial.volume === 0;
    v.playbackRate = initial.speed;
    var restore = function() { v.currentTime = initial.position; if (initial.playing) v.play().catch(function(){}); else v.pause(); send(v); };
    if (v.readyState >= 1) restore(); else v.addEventListener('loadedmetadata', restore, {once:true});

    
    

    if (initial.playing && v.readyState >= 2 && v.paused) {
      var p = v.play();
      if (p && p.catch) p.catch(function() {});
    } else if (initial.playing && v.paused) {
      v.addEventListener('canplay', function() {
        if (v.paused) {
          
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
        
        
        var p = v.play();
        if (p && p.catch) p.catch(function(){});
      }, 1000);
    });
    v.addEventListener('volumechange', function() { send(v); });
    v.addEventListener('ratechange', function() { send(v); });

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
      if (!_volumeOpen && _data.value.isPlaying) {
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

  Future<void> _setVolume(double vol) async {
    final target = vol.clamp(0.0, 1.0);
    final result = await _wvc.runJavaScriptReturningResult(
      '(function(){var v=document.querySelector("video");if(!v)return false;'
      'v.volume=$target;v.muted=(${target == 0});'
      'return Math.abs(v.volume-$target)<0.01 && v.muted===(${target == 0});})();',
    );
    if (result != true && result.toString() != 'true') {
      throw StateError('Player did not accept volume');
    }
    if (mounted) _data.value = _data.value.copyWith(volume: target);
  }

  void _reinjectAndResume() {
    _injectJS();
    _wvc.runJavaScript(r'''
(function(){
  var v = document.querySelector('video');
  if (v) {
    
    
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
                        Positioned.fill(
                          child: Container(color: Colors.black26),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
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
                          bottom: 0,
                          left: 0,
                          right: 0,
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
                              onVolumeInteractionChanged: (open) =>
                                  _volumeOpen = open,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reinjectAndResume();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _reinjectAndResume();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
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
                        top: 0,
                        left: 0,
                        right: 0,
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
                        bottom: 0,
                        left: 0,
                        right: 0,
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
                          onVolumeInteractionChanged: (open) =>
                              _volumeOpen = open,
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

class _FullscreenGestureOverlayState extends State<_FullscreenGestureOverlay> {
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
        _dragCurrentValue = (_dragStartValue + deltaSecs).clamp(
          0.0,
          widget.duration,
        );
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
                color: Colors.black.withValues(
                  alpha: (1.0 - _brightness).clamp(0.0, 0.85),
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amberAccent, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fast_forward_rounded,
                        color: Colors.amberAccent,
                        size: 20,
                      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cast_rounded, color: Colors.white, size: 20),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: const Color(0xFF1E2621),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cast_connected_rounded,
                        size: 36,
                        color: Color(0xFF34D399),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Phát ra thiết bị ngoài (AirPlay / Chromecast)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Đang tìm kiếm thiết bị tương thích trong cùng mạng Wi-Fi...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F5B38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: const Color(0xFF1E2621),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tùy chọn trình phát',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(
                          Icons.speed_rounded,
                          color: Color(0xFF34D399),
                        ),
                        title: const Text(
                          'Tốc độ phát chuẩn (1.0x)',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.repeat_rounded,
                          color: Color(0xFF34D399),
                        ),
                        title: const Text(
                          'Tự động phát bài tiếp theo',
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF34D399),
                        ),
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
              );
            },
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

class _SubtitleCue {
  const _SubtitleCue(this.startSec, this.endSec, this.text);
  final double startSec;
  final double endSec;
  final String text;
}

// ignore: unused_element
class _CaptionOverlay extends StatelessWidget {
  const _CaptionOverlay({
    required this.subtitleMode,
    required this.title,
    required this.position,
  });

  final String subtitleMode; // 'off', 'vi_ai', 'vi', 'en'
  final String title;
  final double position;

  static List<_SubtitleCue> _getViAiCues(String title) => [
    _SubtitleCue(0, 5, '✨ Chào mừng bạn đến với bài học: "$title"'),
    _SubtitleCue(
      5,
      12,
      'Hôm nay chúng ta sẽ tìm hiểu các kiến thức cốt lõi và hướng dẫn thực hành.',
    ),
    _SubtitleCue(
      12,
      20,
      'Hãy quan sát kỹ từng thao tác mẫu trên màn hình và làm theo.',
    ),
    _SubtitleCue(
      20,
      32,
      'Bạn có thể nhấn tạm dừng video bất cứ lúc nào để ghi chép nội dung.',
    ),
    _SubtitleCue(
      32,
      45,
      'Tiếp theo, chúng ta cùng đi vào các ví dụ thực tế và bài tập ứng dụng.',
    ),
    _SubtitleCue(45, 9999, 'Chúc bạn hoàn thành bài học xuất sắc!'),
  ];

  static List<_SubtitleCue> _getViCues(String title) => [
    _SubtitleCue(0, 6, 'Bài học: "$title"'),
    _SubtitleCue(6, 14, 'Tổng quan lý thuyết và minh họa từng bước.'),
    _SubtitleCue(14, 25, 'Các nguyên tắc quan trọng cần ghi nhớ khi học.'),
    _SubtitleCue(
      25,
      40,
      'Nội dung chi tiết sẽ được giải thích trong phần tiếp theo.',
    ),
    _SubtitleCue(40, 9999, 'Cảm ơn bạn đã xem bài học.'),
  ];

  static List<_SubtitleCue> _getEnCues(String title) => [
    _SubtitleCue(0, 6, 'Lesson topic: "$title"'),
    _SubtitleCue(
      6,
      14,
      'In this session, we explore key concepts and practical applications.',
    ),
    _SubtitleCue(
      14,
      25,
      'Feel free to pause and review any section at your own pace.',
    ),
    _SubtitleCue(
      25,
      40,
      'Now let us proceed to the step-by-step demonstration.',
    ),
    _SubtitleCue(40, 9999, 'Thank you for watching and happy learning!'),
  ];

  @override
  Widget build(BuildContext context) {
    if (subtitleMode == 'off') return const SizedBox.shrink();

    final isAi = subtitleMode == 'vi_ai';
    final cues = isAi
        ? _getViAiCues(title)
        : subtitleMode == 'en'
        ? _getEnCues(title)
        : _getViCues(title);

    final activeCue = cues.firstWhere(
      (c) => position >= c.startSec && position < c.endSec,
      orElse: () => cues.last,
    );

    return Positioned(
      bottom: 64,
      left: 12,
      right: 12,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: isAi
                ? Border.all(color: const Color(0xFF10B981), width: 0.8)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAi)
                const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF10B981),
                        size: 11,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Phụ đề tự động tạo (AI)',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                activeCue.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
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
    this.onVolumeInteractionChanged,
    this.quality = 'Tự động (Auto)',
    this.onQualityChanged,
    // ignore: unused_element_parameter
    this.selectedSubtitle = 'off',
    // ignore: unused_element_parameter
    this.onSubtitleChanged,
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
  final Future<void> Function(double)? onVolumeChanged;
  final ValueChanged<bool>? onVolumeInteractionChanged;
  final String quality;
  final ValueChanged<String>? onQualityChanged;
  final String selectedSubtitle;
  final ValueChanged<String>? onSubtitleChanged;

  @override
  Widget build(BuildContext context) {
    final maxDur = duration > 0 ? duration : 1.0;
    final clampedPos = position.clamp(0.0, maxDur);

    return Container(
      padding: EdgeInsets.only(
        left: isFullScreen ? 16 : 8,
        right: isFullScreen ? 16 : 8,
        bottom: isFullScreen ? 10 : 4,
        top: 2,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.black45, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tier 1: Full-width Progress Slider with Timestamps
          Row(
            children: [
              Text(
                _fmt(position),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
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
              Text(
                _fmt(duration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          // Tier 2: Action Buttons Row (Evenly Spaced Icons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Play/Pause
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: onPlayPause,
              ),
              // 2. Quality selector
              if (onQualityChanged != null)
                PopupMenuButton<String>(
                  tooltip: 'Chất lượng video',
                  initialValue: quality,
                  onSelected: onQualityChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'Tự động (Auto)',
                      child: Text('Tự động (Auto)'),
                    ),
                    PopupMenuItem(
                      value: '1080p FHD',
                      child: Text('1080p Full HD'),
                    ),
                    PopupMenuItem(value: '720p HD', child: Text('720p HD')),
                    PopupMenuItem(value: '480p SD', child: Text('480p SD')),
                    PopupMenuItem(
                      value: '360p Data Saver',
                      child: Text('360p Tiết kiệm'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.hd_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          quality.split(' ').first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // 3. Subtitle selector
              if (onSubtitleChanged != null)
                PopupMenuButton<String>(
                  tooltip: 'Phụ đề',
                  initialValue: selectedSubtitle,
                  onSelected: onSubtitleChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'vi_ai',
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text('Tiếng Việt (Tự động - AI)'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'vi',
                      child: Text('Tiếng Việt (Chuẩn)'),
                    ),
                    PopupMenuItem(value: 'en', child: Text('English (Auto)')),
                    PopupMenuItem(value: 'off', child: Text('Tắt phụ đề')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      selectedSubtitle == 'off'
                          ? Icons.closed_caption_disabled_rounded
                          : Icons.closed_caption_rounded,
                      color: selectedSubtitle == 'vi_ai'
                          ? const Color(0xFF10B981)
                          : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              // 4. Volume Control
              if (onVolumeChanged != null)
                VolumeControl(
                  volume: volume,
                  onChanged: onVolumeChanged!,
                  onInteractionChanged: onVolumeInteractionChanged,
                ),
              // 5. Speed badge
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${speed}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // 6. Fullscreen toggle
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(3),
                icon: Icon(
                  isFullScreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: onFullScreen,
              ),
            ],
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
  }) => _VideoData(
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
      data: (source) {
        final embed = Uri.tryParse(source['embedUrl']?.toString() ?? '');
        if (embed != null && _isSupportedNetworkUrl(embed)) {
          return LearningVideoEmbedPlayer(url: embed, title: title);
        }
        final direct = Uri.tryParse(source['playbackUrl']?.toString() ?? '');
        if (direct != null && _isSupportedNetworkUrl(direct)) {
          return LearningMediaPlayer(
            url: direct,
            title: title,
            duration: 0,
            embedUrl: embed,
            videoId: videoId,
          );
        }
        return const _InvalidMediaUrlCard();
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
            child: Text(
              'Video chưa có đường dẫn phát hợp lệ. Vui lòng quay lại sau.',
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSupportedNetworkUrl(Uri uri) =>
    uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http');

bool _isEmbedUrl(Uri uri) {
  final path = uri.path.toLowerCase();
  if (path.endsWith('.mp4') ||
      path.endsWith('.m3u8') ||
      path.endsWith('.m4v') ||
      path.endsWith('.webm')) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return path.contains('/embed/') ||
      path.endsWith('.html') ||
      (host.contains('mediadelivery.net') && !path.contains('/play/'));
}

Uri? resolveDirectPlaybackUri(LearningLessonPart part) {
  final raw = part.playbackUrl?.trim();
  if (raw != null && raw.isNotEmpty) {
    final uri = Uri.tryParse(raw);
    if (uri != null && _isSupportedNetworkUrl(uri)) return uri;
  }
  return null;
}
