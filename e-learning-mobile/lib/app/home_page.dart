import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../core/auth/session_controller.dart';
import '../core/routing/route_paths.dart';
import '../features/home/data/repositories/home_repository.dart';
import '../features/learning/data/models/course_models.dart';
import '../features/learning/data/repositories/learning_repository.dart';
import '../shared/theme/app_colors.dart';
import '../shared/widgets/course_card.dart';
import '../shared/widgets/loading_skeleton.dart';
import '../shared/widgets/section_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    ref.watch(sessionControllerProvider);
    final session = ref.read(sessionControllerProvider.notifier).sessionOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(learningRepositoryProvider);
          ref.invalidate(homeSectionProvider);
          ref.invalidate(whyChooseUsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── AppBar ───────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SKVI Learning',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                  onPressed: () => context.push(RoutePaths.chatNotification),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome Banner ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session != null
                                ? 'Xin chào, ${session.user.fullName.split(' ').last}! 👋'
                                : 'Chào mừng bạn! 👋',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tiếp tục hành trình học tập của bạn',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => context.go(RoutePaths.myCourses),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Xem khóa học của tôi →',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Quick Stats ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickStatCard(
                            icon: Icons.play_circle_outline_rounded,
                            label: 'Khóa học',
                            value: 'Của tôi',
                            onTap: () => context.go(RoutePaths.myCourses),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStatCard(
                            icon: Icons.forum_outlined,
                            label: 'Diễn đàn',
                            value: 'Cộng đồng',
                            onTap: () => context.go(RoutePaths.forum),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStatCard(
                            icon: Icons.spa_outlined,
                            label: 'Sức Khỏe',
                            value: 'AI Coach',
                            onTap: () => context.go(RoutePaths.wellnessAi),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Home Video Section (Intro) ─────────────────────
                  const SizedBox(height: 32),
                  _HomeVideoSection(isDark: isDark),

                  // ── All Courses Section (Trung tâm khóa học) ─────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                    child: SectionHeader(
                      title: 'Trung tâm khóa học',
                      onViewAll: () => context.go(RoutePaths.courses),
                    ),
                  ),
                  _FeaturedCoursesList(isDark: isDark),

                  // ── Why Choose Us ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                    child: SectionHeader(
                      title: 'Tại sao chọn chúng tôi',
                      onViewAll: () {},
                    ),
                  ),
                  _WhyChooseUsSection(isDark: isDark),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home Video Section ───────────────────────────────────────────────────────

class _HomeVideoSection extends ConsumerWidget {
  const _HomeVideoSection({required this.isDark});
  final bool isDark;

  String? _getYoutubeId(String url) {
    final regExp = RegExp(
        r'^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeSectionAsync = ref.watch(homeSectionProvider);

    return homeSectionAsync.when(
      data: (homeSection) {
        if (homeSection == null) return const SizedBox.shrink();

        String? iframeSrc;
        if (homeSection.videoType == 'youtube' &&
            homeSection.videoUrl != null) {
          final ytId = _getYoutubeId(homeSection.videoUrl!);
          if (ytId != null) {
            iframeSrc = 'https://www.youtube.com/embed/$ytId';
          }
        } else if (homeSection.videoType == 'bunny' &&
            homeSection.videoId != null &&
            homeSection.bunnyVideoId != null) {
          iframeSrc =
              'https://iframe.mediadelivery.net/embed/${homeSection.videoId}/${homeSection.bunnyVideoId}?autoplay=false&preload=false';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (homeSection.contentHtml != null)
                HtmlWidget(
                  homeSection.contentHtml!,
                  textStyle: GoogleFonts.inter(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  customStylesBuilder: (element) {
                    if (element.localName == 'h1') {
                      return {'color': '#10b981', 'font-size': '24px'}; // Emerald 500
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),
              if (iframeSrc != null)
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Opacity(
                    opacity: 0.99,
                    child: HtmlWidget(
                      '<iframe src="$iframeSrc" width="100%" height="100%" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Why Choose Us Section ────────────────────────────────────────────────────

class _WhyChooseUsSection extends ConsumerWidget {
  const _WhyChooseUsSection({required this.isDark});
  final bool isDark;

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'FiBookOpen':
        return Icons.menu_book_rounded;
      case 'FiUsers':
        return Icons.group_rounded;
      case 'FiAward':
        return Icons.emoji_events_rounded;
      case 'FiClock':
        return Icons.schedule_rounded;
      case 'FiMonitor':
        return Icons.monitor_rounded;
      case 'FiMessageCircle':
        return Icons.forum_rounded;
      case 'FiTrendingUp':
        return Icons.trending_up_rounded;
      case 'FiStar':
        return Icons.star_rounded;
      case 'FiShield':
        return Icons.security_rounded;
      case 'FiHeart':
        return Icons.favorite_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whyChooseUsAsync = ref.watch(whyChooseUsProvider);

    return whyChooseUsAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconData(item.icon),
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Featured Courses ─────────────────────────────────────────────────────────

class _FeaturedCoursesList extends ConsumerWidget {
  const _FeaturedCoursesList({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(learningRepositoryProvider);
    return FutureBuilder<List<CourseSummaryModel>>(
      future: repository.getCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const SizedBox(
                width: 200,
                child: CourseCardSkeleton(),
              ),
            ),
          );
        }

        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Chưa có khóa học nào.',
              style: GoogleFonts.inter(
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
            ),
          );
        }

        // Show up to 6 featured
        final featured = courses.take(6).toList();
        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final course = featured[index];
              return SizedBox(
                width: 200,
                child: CourseCard(
                  title: course.title,
                  isFree: course.isFree,
                  price: course.price,
                  thumbnailUrl: course.thumbnailUrl,
                  onTap: () => context.push(
                    RoutePaths.courseDetailPath(course.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Quick Stat Card ──────────────────────────────────────────────────────────

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
