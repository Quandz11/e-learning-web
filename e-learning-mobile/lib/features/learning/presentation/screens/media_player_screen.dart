import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_state.dart';
import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:e_learning_mobile/features/learning/presentation/widgets/media_player_panel.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MediaPlayerScreen extends ConsumerStatefulWidget {
  const MediaPlayerScreen({
    required this.courseId,
    required this.lessonPartId,
    super.key,
  });

  final String courseId;
  final String lessonPartId;

  @override
  ConsumerState<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends ConsumerState<MediaPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isValidId(widget.courseId) && _isValidId(widget.lessonPartId)) {
        ref.read(_provider.notifier).ensureLoaded();
      }
    });
  }

  LessonRouteArgs get _args => LessonRouteArgs(
    courseId: widget.courseId,
    lessonPartId: widget.lessonPartId,
  );

  AutoDisposeStateNotifierProvider<LessonController, LessonState>
  get _provider => lessonControllerProvider(_args);

  @override
  Widget build(BuildContext context) {
    if (!_isValidId(widget.courseId) || !_isValidId(widget.lessonPartId)) {
      return const SafeArea(
        bottom: false,
        child: AppErrorView(
          message: 'KhÃ´ng tÃ¬m tháº¥y video cáº§n hiá»ƒn thá»‹.',
        ),
      );
    }

    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: _MediaPlayerContent(
                state: state,
                onRetry: controller.load,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPlayerContent extends StatelessWidget {
  const _MediaPlayerContent({required this.state, required this.onRetry});

  final LessonState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const AppLoadingView(label: 'Äang táº£i video...');
    }

    final detail = state.detail;
    if (state.status == LessonStatus.failure || detail == null) {
      return AppErrorView(
        message: learningFailureMessage(
          state.primaryFailure,
          fallback: 'KhÃ´ng thá»ƒ táº£i video lÃºc nÃ y.',
        ),
        onRetry: onRetry,
      );
    }

    if (!detail.part.isVideo) {
      return const AppErrorView(
        message: 'Ná»™i dung nÃ y khÃ´ng pháº£i video.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Quay láº¡i bÃ i há»c',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.course.title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                header: true,
                child: Text(
                  detail.part.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (detail.part.videoDuration > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Thá»i lÆ°á»£ng: ${formatLearningDuration(Duration(seconds: detail.part.videoDuration.round()))}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        MediaPlayerPanel(part: detail.part),
      ],
    );
  }
}

bool _isValidId(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
