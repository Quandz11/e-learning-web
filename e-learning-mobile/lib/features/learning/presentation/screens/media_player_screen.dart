import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_state.dart';
import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:e_learning_mobile/features/learning/presentation/widgets/media_player_panel.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
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
  int _selectedTabIndex = 0;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isValidId(widget.courseId) && _isValidId(widget.lessonPartId)) {
        ref.read(_provider.notifier).ensureLoaded();
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AppErrorView(message: 'Không tìm thấy video cần hiển thị.'),
        ),
      );
    }

    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          state.detail?.part.title ?? 'Xem Video Bài Học',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: state.isInitialLoading
            ? const AppLoadingView(label: 'Đang tải video...')
            : state.status == LessonStatus.failure || state.detail == null
            ? AppErrorView(
                message: learningFailureMessage(
                  state.primaryFailure,
                  fallback: 'Không thể tải video lúc này.',
                ),
                onRetry: controller.load,
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.contentMaxWidth,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. Video Player Container
                                MediaPlayerPanel(part: state.detail!.part),
                                const SizedBox(height: AppSpacing.md),

                                // 2. Video Title & Metadata Card
                                AppCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.detail!.course.title,
                                        style: Theme.of(context).textTheme.labelMedium
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        state.detail!.part.title,
                                        style: Theme.of(context).textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Wrap(
                                        spacing: AppSpacing.sm,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          if (state.detail!.part.videoDuration > 0)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.access_time_rounded,
                                                  size: 14,
                                                  color: AppColors.textSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Thời lượng: ${formatLearningDuration(Duration(seconds: state.detail!.part.videoDuration.round()))}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppColors.textSecondary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          if (state.detail!.partProgress?.isCompleted == true)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0FDF4),
                                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                                border: Border.all(
                                                  color: const Color(0xFFBBF7D0),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Đã hoàn thành',
                                                    style: TextStyle(
                                                      color: Color(0xFF16A34A),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // 3. Segmented Tabs (Bài học / Ghi chú / Thảo luận)
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF5F1),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildTabButton(0, 'Nội dung bài'),
                                      ),
                                      Expanded(child: _buildTabButton(1, 'Ghi chú')),
                                      Expanded(
                                        child: _buildTabButton(2, 'Thảo luận'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // 4. Tab Content Body
                                if (_selectedTabIndex == 0) ...[
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFEAEFE9),
                                        width: 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tóm tắt nội dung',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        if (state.detail!.part.content != null &&
                                            stripHtml(state.detail!.part.content!).isNotEmpty)
                                          HtmlWidget(
                                            state.detail!.part.content!,
                                            textStyle: const TextStyle(
                                              fontSize: 13.5,
                                              height: 1.55,
                                              color: Color(0xFF334138),
                                              fontWeight: FontWeight.w300,
                                            ),
                                          )
                                        else ...[
                                          Text(
                                            'Trong bài học này, bạn sẽ nắm vững các bước thực hành trực tiếp cùng sự hướng dẫn chi tiết từ chuyên gia.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w300,
                                                  height: 1.5,
                                                ),
                                          ),
                                          const SizedBox(height: AppSpacing.md),
                                          const Divider(height: 1, thickness: 0.8, color: Color(0xFFEAEFE9)),
                                          const SizedBox(height: AppSpacing.md),
                                          Text(
                                            'Điểm cốt lõi cần nhớ',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.primary,
                                                ),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          _buildTakeawayItem('Lắng nghe và thực hành chuẩn xác theo từng nhịp thở và chuyển động.'),
                                          _buildTakeawayItem('Bổ sung nước lọc đầy đủ trong suốt quá trình học tập.'),
                                          _buildTakeawayItem('Ghi chú lại những khúc mắc để thảo luận cùng chuyên gia.'),
                                        ],
                                      ],
                                    ),
                                  ),
                                ] else if (_selectedTabIndex == 1) ...[
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFEAEFE9),
                                        width: 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ghi chú cá nhân',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        TextField(
                                          controller: _noteController,
                                          maxLines: 4,
                                          style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 13),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Nhập ghi chú quan trọng trong lúc xem video...',
                                            hintStyle: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w300,
                                              fontSize: 13,
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFFF9FBF9),
                                            contentPadding: const EdgeInsets.all(12),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFEAEFE9),
                                                width: 0.8,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFEAEFE9),
                                                width: 0.8,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              if (_noteController.text.trim().isNotEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Đã lưu ghi chú thành công!'),
                                                    backgroundColor: Color(0xFF0F5B38),
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.bookmark_added_outlined, size: 16),
                                            label: const Text('Lưu ghi chú'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFEAEFE9),
                                        width: 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hỏi đáp & Thảo luận',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Bạn có thắc mắc về bài học này? Hãy gửi bài đăng trong diễn đàn cộng đồng để được trợ giúp.',
                                          style: Theme.of(context).textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w300,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        OutlinedButton.icon(
                                          onPressed: () => context.push(AppRoutes.appCommunity),
                                          icon: const Icon(Icons.forum_outlined, size: 16),
                                          label: const Text('Mở Diễn đàn Cộng đồng'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(color: AppColors.primary, width: 0.8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(AppRadius.pill),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: AppSpacing.md),
                                // 5. Next & Previous Navigation Bar
                                _buildLessonNavigation(context, state.detail!),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 6. Bottom Mark as Completed Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFEAEFE9), width: 0.8),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: state.detail!.partProgress?.isCompleted == true
                            ? Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  border: Border.all(
                                    color: const Color(0xFFBBF7D0),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Bạn đã hoàn thành bài học này',
                                      style: TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: state.isCompleting || !state.detail!.canMarkComplete
                                    ? null
                                    : () async {
                                        await controller.markComplete();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Đã hoàn thành bài học!'),
                                              backgroundColor: Color(0xFF0F5B38),
                                            ),
                                          );
                                        }
                                      },
                                icon: state.isCompleting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_rounded, size: 18),
                                label: Text(
                                  state.isCompleting ? 'Đang cập nhật...' : 'Đánh dấu hoàn thành bài học',
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLessonNavigation(BuildContext context, LessonDetailResult detail) {
    final parts = detail.course.orderedParts;
    final currentIndex = parts.indexWhere((part) => part.id == detail.part.id);
    if (currentIndex == -1 || parts.length <= 1) {
      return const SizedBox.shrink();
    }

    final previous = currentIndex > 0 ? parts[currentIndex - 1] : null;
    final next = currentIndex < parts.length - 1 ? parts[currentIndex + 1] : null;

    void openPart(LearningLessonPart part) {
      if (part.isVideo) {
        context.pushReplacement(
          AppRoutes.mediaPlayerPath(courseId: detail.course.id, lessonPartId: part.id),
        );
      } else if (part.isDocument) {
        context.pushReplacement(
          AppRoutes.documentReaderPath(courseId: detail.course.id, lessonPartId: part.id),
        );
      } else {
        context.pushReplacement(
          AppRoutes.lessonPath(courseId: detail.course.id, lessonPartId: part.id),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Điều hướng bài học',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (previous != null)
                Expanded(
                  child: InkWell(
                    onTap: () => openPart(previous),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEAEFE9), width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.chevron_left_rounded, size: 16, color: AppColors.textSecondary),
                              SizedBox(width: 2),
                              Text(
                                'Bài trước',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            previous.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (previous != null && next != null) const SizedBox(width: AppSpacing.sm),
              if (next != null)
                Expanded(
                  child: InkWell(
                    onTap: () => openPart(next),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Bài tiếp theo',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white70),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            next.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTakeawayItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w300,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

bool _isValidId(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
