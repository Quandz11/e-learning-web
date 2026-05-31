import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../data/models/course_models.dart';
import '../../data/repositories/learning_repository.dart';

class CourseDetailPage extends ConsumerStatefulWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  bool _isEnrolling = false;

  Future<void> _enroll() async {
    setState(() => _isEnrolling = true);
    try {
      await ref.read(learningRepositoryProvider).enroll(widget.courseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đăng ký thành công!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã có lỗi xảy ra: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repository = ref.watch(learningRepositoryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: FutureBuilder<CourseDetailModel>(
        future: repository.getCourseDetail(widget.courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeleton(isDark);
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: EmptyState(
                icon: Icons.wifi_off_rounded,
                message: 'Không thể tải khóa học.',
              ),
            );
          }

          final course = snapshot.data!;
          return CustomScrollView(
            slivers: [
              // ── Hero AppBar ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: isDark ? AppColors.darkSurface : AppColors.lightBorder,
                        child: const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      // Gradient overlay for readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDark ? AppColors.darkBg : Colors.black)
                                  .withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: course.isFree
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.isFree
                              ? '🎉 Miễn phí'
                              : '💎 ${_formatPrice(course.price)} đ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: course.isFree
                                ? AppColors.primary
                                : Colors.amber.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        course.title,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? AppColors.textDark : AppColors.textLight,
                          height: 1.3,
                        ),
                      ),

                      // Description
                      if (course.description != null &&
                          course.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Mô tả',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textDark
                                : AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.description!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.6,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Enroll button
                      FilledButton.icon(
                        onPressed: _isEnrolling ? null : _enroll,
                        icon: _isEnrolling
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.rocket_launch_rounded),
                        label: Text(
                          _isEnrolling ? 'Đang đăng ký...' : 'Đăng ký học ngay',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(expandedHeight: 240, pinned: true),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(width: 100, height: 28, borderRadius: 8),
                const SizedBox(height: 12),
                LoadingSkeleton(width: double.infinity, height: 28),
                const SizedBox(height: 8),
                LoadingSkeleton(width: 200, height: 28),
                const SizedBox(height: 20),
                LoadingSkeleton(width: double.infinity, height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
