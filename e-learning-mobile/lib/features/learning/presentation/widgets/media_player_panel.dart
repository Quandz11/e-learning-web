import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

final learningMediaPlayerBuilderProvider = Provider<LearningMediaPlayerBuilder>(
  (ref) =>
      ({required url, required title, required duration, embedUrl}) =>
          LearningMediaPlayer(
            url: url,
            title: title,
            duration: duration,
            embedUrl: embedUrl,
          ),
);

typedef LearningMediaPlayerBuilder =
    Widget Function({
      required Uri url,
      required String title,
      required double duration,
      Uri? embedUrl,
    });

class MediaPlayerPanel extends ConsumerWidget {
  const MediaPlayerPanel({required this.part, super.key});

  final LearningLessonPart part;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackUrl = part.playbackUrl?.trim();
    final url = playbackUrl == null ? null : Uri.tryParse(playbackUrl);
    final embedUrl = part.embedUrl?.trim();
    final embedUri = embedUrl == null ? null : Uri.tryParse(embedUrl);
    if (url == null || !_isSupportedNetworkUrl(url)) {
      if (embedUri != null && _isSupportedNetworkUrl(embedUri)) {
        return LearningVideoEmbedPlayer(url: embedUri, title: part.title);
      }

      return const _InvalidMediaUrlCard();
    }

    final builder = ref.watch(learningMediaPlayerBuilderProvider);
    return builder(
      url: url,
      title: part.title,
      duration: part.videoDuration,
      embedUrl: embedUri,
    );
  }
}

class LearningMediaPlayer extends StatefulWidget {
  const LearningMediaPlayer({
    required this.url,
    required this.title,
    required this.duration,
    this.embedUrl,
    super.key,
  });

  final Uri url;
  final String title;
  final double duration;
  final Uri? embedUrl;

  @override
  State<LearningMediaPlayer> createState() => _LearningMediaPlayerState();
}

class _LearningMediaPlayerState extends State<LearningMediaPlayer> {
  VideoPlayerController? _controller;
  Object? _error;

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
    setState(() {
      _error = null;
    });

    final controller = VideoPlayerController.networkUrl(widget.url);
    _controller = controller;
    controller.addListener(_onControllerChanged);

    try {
      await controller.initialize();
      if (!mounted || _controller != controller) {
        return;
      }
      setState(() {});
    } catch (error) {
      if (!mounted || _controller != controller) {
        return;
      }
      setState(() {
        _error = error;
      });
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _retry() async {
    _disposeController();
    await _initialize();
  }

  void _disposeController() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      final embedUrl = widget.embedUrl;
      if (embedUrl != null) {
        return LearningVideoEmbedPlayer(url: embedUrl, title: widget.title);
      }

      return AppErrorView(
        message: 'Không thể phát video trực tiếp. Vui lòng thử lại sau.',
        onRetry: _retry,
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const AppLoadingView(label: 'Đang tải video...');
    }

    final value = controller.value;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  if (value.isBuffering)
                    const ColoredBox(
                      color: Color(0x66000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  IconButton.filled(
                    tooltip: value.isPlaying ? 'Tạm dừng video' : 'Phát video',
                    onPressed: () {
                      value.isPlaying ? controller.pause() : controller.play();
                    },
                    icon: Icon(
                      value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          ),
          Row(
            children: [
              IconButton(
                tooltip: value.isPlaying ? 'Tạm dừng' : 'Phát',
                onPressed: () {
                  value.isPlaying ? controller.pause() : controller.play();
                },
                icon: Icon(
                  value.isPlaying
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'Tiến độ video',
                  child: Text(
                    '${formatLearningDuration(value.position)} / ${formatLearningDuration(value.duration)}',
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LearningVideoEmbedPlayer extends StatefulWidget {
  const LearningVideoEmbedPlayer({required this.url, required this.title, super.key});

  final Uri url;
  final String title;

  @override
  State<LearningVideoEmbedPlayer> createState() => _LearningVideoEmbedPlayerState();
}

class _LearningVideoEmbedPlayerState extends State<LearningVideoEmbedPlayer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}

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

bool _isSupportedNetworkUrl(Uri uri) {
  return uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http');
}
