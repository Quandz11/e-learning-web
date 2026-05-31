import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../data/repositories/learning_repository.dart';

class MyCoursesPage extends ConsumerWidget {
  const MyCoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncEnrollments = ref.watch(myCoursesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(title: const Text('Khóa học của tôi')),
      body: asyncEnrollments.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => _EnrollmentCardSkeleton(),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          message: 'Không thể tải khóa học.\nVui lòng thử lại.',
          actionLabel: 'Thử lại',
          onAction: () => ref.refresh(myCoursesProvider),
        ),
        data: (enrollments) {
          if (enrollments.isEmpty) {
            return EmptyState(
              icon: Icons.school_outlined,
              message: 'Bạn chưa đăng ký khóa học nào.',
              actionLabel: 'Khám phá khóa học',
              onAction: () => context.go(RoutePaths.courses),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: enrollments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final e = enrollments[index];
              final progress = (e['progressPercentage'] as num?)?.toDouble() ?? 0.0;
              final courseId = e['courseId']?.toString() ?? '';
              final title = e['courseTitle']?.toString() ??
                  e['title']?.toString() ??
                  'Khóa học';
              final thumbnailUrl = e['thumbnailUrl']?.toString();

              return _EnrollmentCard(
                title: title,
                thumbnailUrl: thumbnailUrl,
                progress: progress / 100,
                isDark: isDark,
                onTap: courseId.isNotEmpty
                    ? () => context.push(RoutePaths.learningPlayerPath(courseId))
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({
    required this.title,
    required this.progress,
    required this.isDark,
    this.thumbnailUrl,
    this.onTap,
  });

  final String title;
  final String? thumbnailUrl;
  final double progress;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 70,
                height: 70,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${(progress * 100).toInt()}% hoàn thành',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color:
                  isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          LoadingSkeleton(width: 70, height: 70, borderRadius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                LoadingSkeleton(width: 150, height: 14),
                const SizedBox(height: 12),
                LoadingSkeleton(width: double.infinity, height: 5, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
