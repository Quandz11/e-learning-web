import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/home/data/models/home_models.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_controller.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_state.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
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
          displayName: greeting.displayName,
          avatarName: greeting.avatarName,
          avatarUrl: greeting.avatarUrl,
        ),
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
        if (state.continueLearning != null) ...[
          _ContinueLearningSection(enrollment: state.continueLearning!),
          const SizedBox(height: AppSpacing.lg),
        ] else if (state.enrollmentIssue != null) ...[
          _OptionalSectionWrapper(
            title: 'Khóa học của tôi',
            child: _SectionErrorCard(
              message: _toVietnameseMessage(
                state.enrollmentIssue!.failure,
                fallback: 'Không thể tải khóa học của bạn.',
              ),
              onRetry: onSectionRetry,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const _QuickActionsSection(),
        const SizedBox(height: AppSpacing.lg),
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
    displayName: profile?.fullName,
    avatarName: profile?.fullName,
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

    return Semantics(
      container: true,
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(greeting, style: textTheme.headlineSmall),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    displayName ?? 'Chúc bạn có một ngày học tập hiệu quả.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Semantics(
              button: true,
              label: 'Mở trang cá nhân',
              child: InkWell(
                onTap: () => context.go(AppRoutes.appProfile),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: AppAvatar(
                    name: avatarName,
                    imageUrl: avatarUrl,
                    size: AppSizes.avatarLg,
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

class _ContinueLearningSection extends StatelessWidget {
  const _ContinueLearningSection({required this.enrollment});

  final HomeEnrollment enrollment;

  @override
  Widget build(BuildContext context) {
    return _OptionalSectionWrapper(
      title: 'Tiếp tục học',
      child: AppCard(
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
        label: 'Học tập',
        icon: Icons.school_outlined,
        route: AppRoutes.appLearning,
      ),
      _QuickAction(
        label: 'Cộng đồng',
        icon: Icons.groups_2_outlined,
        route: AppRoutes.appCommunity,
      ),
      _QuickAction(
        label: 'Cá nhân',
        icon: Icons.person_outline_rounded,
        route: AppRoutes.appProfile,
      ),
    ];

    return _OptionalSectionWrapper(
      title: 'Lối tắt',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 360) {
            return Column(
              children: actions
                  .map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _QuickActionCard(action: action),
                    ),
                  )
                  .toList(growable: false),
            );
          }

          return Row(
            children: actions
                .map(
                  (action) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: action == actions.last ? 0 : AppSpacing.sm,
                      ),
                      child: _QuickActionCard(action: action),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
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
    return Semantics(
      button: true,
      label: action.label,
      child: AppCard(
        onTap: () => context.go(action.route),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(action.label, textAlign: TextAlign.center),
          ],
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
    return Semantics(
      button: true,
      label: 'Khóa học ${course.title}',
      child: AppCard(
        onTap: () => context.go(AppRoutes.appLearning),
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (course.instructorName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      course.instructorName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    course.isFree
                        ? 'Miễn phí'
                        : _currencyFormatter.format(course.price),
                    style: Theme.of(context).textTheme.labelLarge,
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
