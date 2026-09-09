import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/home/data/models/home_models.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_controller.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_state.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_avatar.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_empty_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final homeClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).ensureLoaded();
      final profileState = ref.read(profileControllerProvider);
      if (profileState.status == ProfileStatus.initial) {
        ref.read(profileControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait<void>([
            controller.refresh(),
            ref.read(profileControllerProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _HomeContent(
                    state: homeState,
                    profileState: profileState,
                    onRetry: controller.load,
                    onSectionRetry: controller.refresh,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.state,
    required this.profileState,
    required this.onRetry,
    required this.onSectionRetry,
  });

  final HomeState state;
  final ProfileState profileState;
  final Future<void> Function() onRetry;
  final Future<void> Function() onSectionRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isInitialLoading) {
      return const _HomeLoadingSkeleton();
    }

    if (state.status == HomeStatus.failure && !state.hasLoadedContent) {
      return AppErrorView(
        message: _toVietnameseMessage(
          state.primaryFailure,
          fallback: 'Không thể tải trang chủ lúc này.',
        ),
        onRetry: onRetry,
      );
    }

    final greeting = _buildGreeting(
      clock: ref.watch(homeClockProvider),
      profileState: profileState,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HomeHeader(
          greeting: greeting.greeting,
          displayName: greeting.displayName ?? 'Mai Dung',
          avatarName: greeting.avatarName ?? 'Mai Dung',
          avatarUrl: greeting.avatarUrl,
        ),
        const SizedBox(height: AppSpacing.md),
        const _HomeSearchBar(),
        const SizedBox(height: AppSpacing.md),
        const _EditorialBanner(),
        const SizedBox(height: AppSpacing.lg),
        if (state.refreshFailure != null) ...[
          _SectionErrorCard(
            message: _toVietnameseMessage(
              state.refreshFailure,
              fallback: 'Không thể làm mới nội dung.',
            ),
            onRetry: onSectionRetry,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const _QuickActionsSection(),
        const SizedBox(height: AppSpacing.lg),
        if (state.continueLearning != null) ...[
          _ContinueLearningSection(enrollment: state.continueLearning!),
          const SizedBox(height: AppSpacing.lg),
        ],
        _FeaturedCoursesSection(
          courses: state.featuredCourses,
          onRetry: onSectionRetry,
        ),
        if (state.categories.isNotEmpty || state.categoryIssue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _CategoriesSection(
            categories: state.categories,
            issue: state.categoryIssue,
            onRetry: onSectionRetry,
          ),
        ],
        if (state.articles.isNotEmpty || state.articleIssue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ArticlesSection(
            articles: state.articles,
            issue: state.articleIssue,
            onRetry: onSectionRetry,
          ),
        ],
        if (state.testimonials.isNotEmpty ||
            state.testimonialIssue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _TestimonialsSection(
            testimonials: state.testimonials,
            issue: state.testimonialIssue,
            onRetry: onSectionRetry,
          ),
        ],
      ],
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm khóa học, bài học...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (val) => context.go(AppRoutes.appLearning),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialBanner extends StatelessWidget {
  const _EditorialBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F623F),
            Color(0xFF1B8A5A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F623F).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Kiến thức hôm nay cho một phiên bản tốt hơn của chính mình',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.35,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go(AppRoutes.appLearning),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingData {
  const _GreetingData({
    required this.greeting,
    required this.displayName,
    required this.avatarName,
    required this.avatarUrl,
  });

  final String greeting;
  final String? displayName;
  final String? avatarName;
  final String? avatarUrl;
}

_GreetingData _buildGreeting({
  required DateTime Function() clock,
  required ProfileState profileState,
}) {
  final hour = clock().hour;
  final greeting = switch (hour) {
    >= 5 && < 12 => 'Chào buổi sáng',
    >= 12 && < 18 => 'Chào buổi chiều',
    _ => 'Chào buổi tối',
  };

  final profile = profileState.profile;
  return _GreetingData(
    greeting: greeting,
    displayName: profile?.fullName ?? 'Mai Dung',
    avatarName: profile?.fullName ?? 'Mai Dung',
    avatarUrl: profile?.avatarUrl,
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.displayName,
    required this.avatarName,
    required this.avatarUrl,
  });

  final String greeting;
  final String? displayName;
  final String? avatarName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          label: 'Mở trang cá nhân',
          child: InkWell(
            onTap: () => context.go(AppRoutes.appProfile),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AppAvatar(
              name: avatarName,
              imageUrl: avatarUrl,
              size: AppSizes.avatarLg,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  displayName ?? 'Mai Dung',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => context.go(AppRoutes.appPersonalizationReminders),
          icon: Badge(
            smallSize: 8,
            child: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onSurface,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueLearningSection extends StatelessWidget {
  const _ContinueLearningSection({required this.enrollment});

  final HomeEnrollment enrollment;

  @override
  Widget build(BuildContext context) {
    return _OptionalSectionWrapper(
      title: 'Tiếp tục học',
      child: AppCard(
        onTap: () => context.push(AppRoutes.courseDetailPath(enrollment.courseId)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourseVisual(
              imageUrl: enrollment.courseThumbnail,
              label: enrollment.courseTitle,
              fallbackIcon: Icons.play_circle_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              enrollment.courseTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Đã hoàn thành ${enrollment.progressPercentage} phần trăm',
              semanticsLabel:
                  'Tiến độ học tập, đã hoàn thành ${enrollment.progressPercentage} phần trăm',
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(value: enrollment.progressPercentage / 100),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Tiếp tục học',
                fullWidth: false,
                onPressed: () => context.go(AppRoutes.appLearning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final actions = const [
      _QuickAction(
        label: 'Khóa học',
        icon: Icons.menu_book_rounded,
        route: AppRoutes.appLearning,
      ),
      _QuickAction(
        label: 'Cá nhân hoá',
        icon: Icons.autorenew_rounded,
        route: AppRoutes.appPersonalization,
      ),
      _QuickAction(
        label: 'Nhắc nhở',
        icon: Icons.notifications_none_rounded,
        route: AppRoutes.appPersonalizationReminders,
      ),
      _QuickAction(
        label: 'Tiến độ',
        icon: Icons.insert_chart_outlined_rounded,
        route: AppRoutes.appProgress,
      ),
    ];

    return _OptionalSectionWrapper(
      title: 'Lối tắt',
      child: Row(
        children: actions
            .map(
              (action) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: action == actions.last ? 0 : AppSpacing.xs,
                  ),
                  child: _QuickActionCard(action: action),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _FeaturedCoursesSection extends StatelessWidget {
  const _FeaturedCoursesSection({required this.courses, required this.onRetry});

  final List<HomeCourse> courses;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _OptionalSectionWrapper(
      title: 'Khóa học nổi bật',
      trailing: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSizes.controlHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        onPressed: () => context.go(AppRoutes.appLearning),
        child: const Text('Xem tất cả'),
      ),
      child: courses.isEmpty
          ? AppEmptyView(message: 'Chưa có khóa học phù hợp. Hãy thử lại sau.')
          : Column(
              children: courses
                  .map(
                    (course) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CourseCard(course: course),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({
    required this.categories,
    required this.issue,
    required this.onRetry,
  });

  final List<HomeCategory> categories;
  final HomeSectionIssue? issue;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _OptionalSectionWrapper(
      title: 'Danh mục',
      child: categories.isNotEmpty
          ? Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: categories
                  .map(
                    (category) => ActionChip(
                      label: Text(category.name),
                      onPressed: () => context.go(AppRoutes.appLearning),
                    ),
                  )
                  .toList(growable: false),
            )
          : issue == null
          ? const SizedBox.shrink()
          : _SectionErrorCard(
              message: _toVietnameseMessage(
                issue!.failure,
                fallback: 'Không thể tải danh mục lúc này.',
              ),
              onRetry: onRetry,
            ),
    );
  }
}

class _ArticlesSection extends StatelessWidget {
  const _ArticlesSection({
    required this.articles,
    required this.issue,
    required this.onRetry,
  });

  final List<HomeArticle> articles;
  final HomeSectionIssue? issue;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _OptionalSectionWrapper(
      title: 'Bài viết mới',
      child: articles.isNotEmpty
          ? Column(
              children: articles
                  .map(
                    (article) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ArticleCard(article: article),
                    ),
                  )
                  .toList(growable: false),
            )
          : issue == null
          ? const SizedBox.shrink()
          : _SectionErrorCard(
              message: _toVietnameseMessage(
                issue!.failure,
                fallback: 'Không thể tải bài viết lúc này.',
              ),
              onRetry: onRetry,
            ),
    );
  }
}

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection({
    required this.testimonials,
    required this.issue,
    required this.onRetry,
  });

  final List<HomeTestimonial> testimonials;
  final HomeSectionIssue? issue;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _OptionalSectionWrapper(
      title: 'Học viên chia sẻ',
      child: testimonials.isNotEmpty
          ? Column(
              children: testimonials
                  .map(
                    (testimonial) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TestimonialCard(testimonial: testimonial),
                    ),
                  )
                  .toList(growable: false),
            )
          : issue == null
          ? const SizedBox.shrink()
          : _SectionErrorCard(
              message: _toVietnameseMessage(
                issue!.failure,
                fallback: 'Không thể tải phản hồi học viên lúc này.',
              ),
              onRetry: onRetry,
            ),
    );
  }
}

class _OptionalSectionWrapper extends StatelessWidget {
  const _OptionalSectionWrapper({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: action.label,
      child: InkWell(
        onTap: () => context.go(action.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(action.icon, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final HomeCourse course;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Khóa học ${course.title}',
      child: AppCard(
        onTap: () => context.push(AppRoutes.courseDetailPath(course.id)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourseVisual(
              imageUrl: course.thumbnailUrl,
              label: course.title,
              fallbackIcon: Icons.menu_book_outlined,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (course.instructorName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            course.instructorName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: course.isFree
                          ? AppColors.mint
                          : colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      course.isFree
                          ? 'Miễn phí'
                          : _currencyFormatter.format(course.price),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: course.isFree
                                ? AppColors.primary
                                : colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final HomeArticle article;

  @override
  Widget build(BuildContext context) {
    final publishedAt = article.publishedAt ?? article.createdAt;
    final metadata = <String>[
      if (article.categoryName != null) article.categoryName!,
      _dateFormatter.format(publishedAt.toLocal()),
    ].join(' • ');

    return Semantics(
      label: 'Bài viết ${article.title}',
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourseVisual(
              imageUrl: article.featuredImageUrl,
              label: article.title,
              fallbackIcon: Icons.article_outlined,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(metadata, style: Theme.of(context).textTheme.bodySmall),
                  if (article.excerpt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _stripHtml(article.excerpt!),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});

  final HomeTestimonial testimonial;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            name: testimonial.name,
            imageUrl: testimonial.avatarUrl,
            size: 48,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  testimonial.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (testimonial.position != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    testimonial.position!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  testimonial.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseVisual extends StatelessWidget {
  const _CourseVisual({
    required this.imageUrl,
    required this.label,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final String label;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 112,
        height: 84,
        child: url == null || url.isEmpty
            ? _ImageFallback(icon: fallbackIcon, label: label)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const AppSkeleton(width: 112, height: 84),
                errorWidget: (_, __, ___) =>
                    _ImageFallback(icon: fallbackIcon, label: label),
                fadeInDuration: Duration.zero,
                memCacheWidth: 224,
                maxWidthDiskCache: 448,
              ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
      child: Center(
        child: Semantics(
          label: 'Hình minh họa mặc định cho $label',
          child: Icon(icon, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Thử lại',
            fullWidth: false,
            onPressed: () => onRetry(),
          ),
        ],
      ),
    );
  }
}

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 180, height: 28),
              SizedBox(height: AppSpacing.sm),
              AppSkeleton(width: 220),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        AppSkeleton(height: 20, width: 96),
        SizedBox(height: AppSpacing.md),
        AppCard(child: AppSkeleton(height: 120)),
        SizedBox(height: AppSpacing.lg),
        AppSkeleton(height: 20, width: 120),
        SizedBox(height: AppSpacing.md),
        AppCard(child: AppSkeleton(height: 96)),
      ],
    );
  }
}

String _toVietnameseMessage(AppFailure? failure, {required String fallback}) {
  if (failure == null) {
    return fallback;
  }

  if (failure.type == AppFailureType.validation ||
      failure.type == AppFailureType.business) {
    return failure.message;
  }

  return switch (failure.type) {
    AppFailureType.networkUnavailable ||
    AppFailureType.connectionFailure => 'Không có kết nối mạng ổn định.',
    AppFailureType.timeout => 'Máy chủ phản hồi quá chậm. Vui lòng thử lại.',
    AppFailureType.unauthorized =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    AppFailureType.forbidden => 'Bạn không có quyền truy cập nội dung này.',
    AppFailureType.notFound => 'Không tìm thấy nội dung cần hiển thị.',
    AppFailureType.server => 'Máy chủ đang bận. Vui lòng thử lại sau.',
    AppFailureType.malformedResponse =>
      'Dữ liệu trả về không hợp lệ. Vui lòng thử lại.',
    _ => fallback,
  };
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
