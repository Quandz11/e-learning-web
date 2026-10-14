import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/home/data/models/home_models.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_controller.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_state.dart';
import 'package:e_learning_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
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

class _HomeContent extends ConsumerStatefulWidget {
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
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  String _selectedLevel = 'Tất cả';
  String _selectedSort = 'Mặc định';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'Tất cả';
      _selectedLevel = 'Tất cả';
      _selectedSort = 'Mặc định';
    });
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != 'Tất cả' ||
      _selectedLevel != 'Tất cả' ||
      _selectedSort != 'Mặc định';

  void _showFilterModal(List<HomeCategory> categories) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HomeFilterBottomSheet(
        initialCategory: _selectedCategory,
        initialLevel: _selectedLevel,
        initialSort: _selectedSort,
        categories: categories,
        onApply: (cat, level, sort) {
          setState(() {
            _selectedCategory = cat;
            _selectedLevel = level;
            _selectedSort = sort;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.isInitialLoading) {
      return const _HomeLoadingSkeleton();
    }

    if (widget.state.status == HomeStatus.failure &&
        !widget.state.hasLoadedContent) {
      return AppErrorView(
        message: _toVietnameseMessage(
          widget.state.primaryFailure,
          fallback: 'Không thể tải trang chủ lúc này.',
        ),
        onRetry: widget.onRetry,
      );
    }

    final greeting = _buildGreeting(
      clock: ref.watch(homeClockProvider),
      profileState: widget.profileState,
    );

    // Filter courses
    var filteredCourses = widget.state.featuredCourses.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = c.title.toLowerCase().contains(q);
        final matchInstructor = (c.instructorName ?? '').toLowerCase().contains(
          q,
        );
        if (!matchTitle && !matchInstructor) return false;
      }
      if (_selectedCategory != 'Tất cả') {
        final cat = _selectedCategory.toLowerCase();
        final matchTitle = c.title.toLowerCase().contains(cat);
        final matchInstructor = (c.instructorName ?? '').toLowerCase().contains(
          cat,
        );
        if (!matchTitle && !matchInstructor) return false;
      }
      return true;
    }).toList();

    if (_selectedSort == 'Mới nhất') {
      filteredCourses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Filter articles
    final filteredArticles = widget.state.articles.where((a) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = a.title.toLowerCase().contains(q);
        final matchExcerpt = (a.excerpt ?? '').toLowerCase().contains(q);
        final matchCat = (a.categoryName ?? '').toLowerCase().contains(q);
        if (!matchTitle && !matchExcerpt && !matchCat) return false;
      }
      if (_selectedCategory != 'Tất cả') {
        final cat = (a.categoryName ?? '').toLowerCase();
        if (cat != _selectedCategory.toLowerCase()) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HomeHeader(
          greeting: greeting.greeting,
          displayName: greeting.displayName ?? 'Học viên',
          avatarName: greeting.avatarName ?? 'Học viên',
          avatarUrl: greeting.avatarUrl,
        ),
        const SizedBox(height: AppSpacing.md),
        _HomeSearchBar(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          onClear: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
          onOpenFilter: () => _showFilterModal(widget.state.categories),
          hasActiveFilter: _hasActiveFilters,
        ),
        const SizedBox(height: AppSpacing.md),

        // Active Filter Indicators Bar
        if (_hasActiveFilters) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4E8DC), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.filter_list_rounded,
                      size: 16,
                      color: Color(0xFF0F5B38),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kết quả: ${filteredCourses.length} khóa học, ${filteredArticles.length} bài viết',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F5B38),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearAllFilters,
                      child: const Text(
                        'Xóa bộ lọc',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      _ActiveFilterChip(
                        label: 'Tìm: "$_searchQuery"',
                        onDeleted: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    if (_selectedCategory != 'Tất cả')
                      _ActiveFilterChip(
                        label: 'Chuyên mục: $_selectedCategory',
                        onDeleted: () =>
                            setState(() => _selectedCategory = 'Tất cả'),
                      ),
                    if (_selectedLevel != 'Tất cả')
                      _ActiveFilterChip(
                        label: 'Cấp độ: $_selectedLevel',
                        onDeleted: () =>
                            setState(() => _selectedLevel = 'Tất cả'),
                      ),
                    if (_selectedSort != 'Mặc định')
                      _ActiveFilterChip(
                        label: 'Sắp xếp: $_selectedSort',
                        onDeleted: () =>
                            setState(() => _selectedSort = 'Mặc định'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (!_hasActiveFilters) ...[
          const _EditorialBanner(),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (widget.state.refreshFailure != null) ...[
          _SectionErrorCard(
            message: _toVietnameseMessage(
              widget.state.refreshFailure,
              fallback: 'Không thể làm mới nội dung.',
            ),
            onRetry: widget.onSectionRetry,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (!_hasActiveFilters) ...[
          const _QuickActionsSection(),
          const SizedBox(height: AppSpacing.lg),
          if (widget.state.continueLearning != null) ...[
            _ContinueLearningSection(
              enrollment: widget.state.continueLearning!,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],

        // Filtered results or full list
        if (_hasActiveFilters &&
            filteredCourses.isEmpty &&
            filteredArticles.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAEFE9), width: 0.8),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 44,
                  color: Color(0xFF8E9E94),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Không tìm thấy nội dung phù hợp',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E2621),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vui lòng thử từ khóa tìm kiếm khác hoặc xóa bộ lọc để xem toàn bộ danh mục.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF717873),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _clearAllFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F5B38),
                    side: const BorderSide(color: Color(0xFF0F5B38)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Xem tất cả nội dung'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else ...[
          _FeaturedCoursesSection(
            courses: filteredCourses,
            onRetry: widget.onSectionRetry,
          ),
        ],

        if (widget.state.categories.isNotEmpty ||
            widget.state.categoryIssue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _CategoriesSection(
            categories: widget.state.categories,
            selectedCategory: _selectedCategory,
            onCategoryTap: (cat) {
              setState(() {
                _selectedCategory = _selectedCategory == cat ? 'Tất cả' : cat;
              });
            },
            issue: widget.state.categoryIssue,
            onRetry: widget.onSectionRetry,
          ),
        ],

        if (filteredArticles.isNotEmpty ||
            widget.state.articleIssue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ArticlesSection(
            articles: filteredArticles,
            issue: widget.state.articleIssue,
            onRetry: widget.onSectionRetry,
          ),
        ],

        if (!_hasActiveFilters &&
            (widget.state.testimonials.isNotEmpty ||
                widget.state.testimonialIssue != null)) ...[
          const SizedBox(height: AppSpacing.lg),
          _TestimonialsSection(
            testimonials: widget.state.testimonials,
            issue: widget.state.testimonialIssue,
            onRetry: widget.onSectionRetry,
          ),
        ],
      ],
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4E8DC), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1E2621),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: Color(0xFF717873),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onOpenFilter,
    required this.hasActiveFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onOpenFilter;
  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : const Color(0xFFE2EBE5),
          width: 0.8,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF0F5B38), size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: true,
              onTap: () => context.push(AppRoutes.appSearch),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1E2621),
              ),
              decoration: const InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                hintText: 'Tìm khóa học, bài viết, thảo luận...',
                hintStyle: TextStyle(
                  color: Color(0xFF8E9E94),
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF717873),
                ),
              ),
            ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onOpenFilter,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: hasActiveFilter
                        ? const Color(0xFF0F5B38)
                        : const Color(0xFFE8F2EC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: hasActiveFilter
                        ? Colors.white
                        : const Color(0xFF0F5B38),
                  ),
                ),
                if (hasActiveFilter)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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

class _HomeFilterBottomSheet extends StatefulWidget {
  const _HomeFilterBottomSheet({
    required this.initialCategory,
    required this.initialLevel,
    required this.initialSort,
    required this.categories,
    required this.onApply,
  });

  final String initialCategory;
  final String initialLevel;
  final String initialSort;
  final List<HomeCategory> categories;
  final void Function(String category, String level, String sort) onApply;

  @override
  State<_HomeFilterBottomSheet> createState() => _HomeFilterBottomSheetState();
}

class _HomeFilterBottomSheetState extends State<_HomeFilterBottomSheet> {
  late String _selectedCategory;
  late String _selectedLevel;
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedLevel = widget.initialLevel;
    _selectedSort = widget.initialSort;
  }

  @override
  Widget build(BuildContext context) {
    final catNames = <String>[
      'Tất cả',
      ...widget.categories.map((c) => c.name),
    ];
    final levels = const ['Tất cả', 'Cơ bản', 'Nâng cao'];
    final sorts = const ['Mặc định', 'Mới nhất', 'Nổi bật nhất'];

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.isDark
            ? context.colorScheme.surfaceContainerLow
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDark
                    ? context.colorScheme.outlineVariant
                    : const Color(0xFFE2EBE5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc tìm kiếm',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary(),
                  letterSpacing: -0.3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Categories section
          Text(
            'Chuyên mục',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.isDark
                  ? context.colorScheme.onSurface
                  : const Color(0xFF0F5B38),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: catNames.map((name) {
              final isSelected = _selectedCategory == name;
              return ChoiceChip(
                label: Text(name),
                selected: isSelected,
                selectedColor: const Color(0xFF0F5B38),
                backgroundColor: context.chipBg(isSelected),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: context.chipText(isSelected),
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0F5B38)
                      : context.cardBorder(),
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (_) => setState(() => _selectedCategory = name),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Level section
          const Text(
            'Trình độ / Cấp độ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F5B38),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: levels.map((lvl) {
              final isSelected = _selectedLevel == lvl;
              return ChoiceChip(
                label: Text(lvl),
                selected: isSelected,
                selectedColor: const Color(0xFF0F5B38),
                backgroundColor: const Color(0xFFF4F6F5),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF334036),
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0F5B38)
                      : const Color(0xFFE2EBE5),
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (_) => setState(() => _selectedLevel = lvl),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Sort section
          const Text(
            'Sắp xếp',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F5B38),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sorts.map((s) {
              final isSelected = _selectedSort == s;
              return ChoiceChip(
                label: Text(s),
                selected: isSelected,
                selectedColor: const Color(0xFF0F5B38),
                backgroundColor: const Color(0xFFF4F6F5),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF334036),
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0F5B38)
                      : const Color(0xFFE2EBE5),
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (_) => setState(() => _selectedSort = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'Tất cả';
                      _selectedLevel = 'Tất cả';
                      _selectedSort = 'Mặc định';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: Color(0xFFD4E8DC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(color: Color(0xFF55645B)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onApply(
                      _selectedCategory,
                      _selectedLevel,
                      _selectedSort,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: const Color(0xFF0F5B38),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Áp dụng bộ lọc',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
          colors: [Color(0xFF0F623F), Color(0xFF1B8A5A)],
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
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.4,
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

class _HomeHeader extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final notificationsState = ref.watch(notificationsControllerProvider);
    final unreadCount = notificationsState.valueOrNull?.unreadCount ?? 0;

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
                  fontWeight: FontWeight.w300,
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  displayName ?? 'Mai Dung',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => context.push(AppRoutes.appNotifications),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
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
        onTap: () =>
            context.push(AppRoutes.courseDetailPath(enrollment.courseId)),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đã hoàn thành ${enrollment.progressPercentage} phần trăm',
                    semanticsLabel:
                        'Tiến độ học tập, đã hoàn thành ${enrollment.progressPercentage} phần trăm',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: const Color(0xFFD3E6DC),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${enrollment.progressPercentage}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: enrollment.progressPercentage / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFEFF5F1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
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
        bgColor: Color(0xFFF0F7F2),
        iconColor: Color(0xFF0F5B38),
      ),
      _QuickAction(
        label: 'Cộng đồng',
        icon: Icons.forum_outlined,
        route: AppRoutes.appCommunity,
        bgColor: Color(0xFFFFFBEB),
        iconColor: Color(0xFFD97706),
        badge: 'Mới',
      ),
      _QuickAction(
        label: 'Kiến thức',
        icon: Icons.auto_stories_outlined,
        route: AppRoutes.appArticles,
        bgColor: Color(0xFFF5F3FF),
        iconColor: Color(0xFF7C3AED),
      ),
      _QuickAction(
        label: 'Tư vấn',
        icon: Icons.support_agent_rounded,
        route: AppRoutes.appChat,
        bgColor: Color(0xFFECFDF5),
        iconColor: Color(0xFF059669),
      ),
      _QuickAction(
        label: 'Tiến độ',
        icon: Icons.insert_chart_outlined_rounded,
        route: AppRoutes.appProgress,
        bgColor: Color(0xFFEFF6FF),
        iconColor: Color(0xFF2563EB),
      ),
    ];

    return _OptionalSectionWrapper(
      title: 'Lối tắt',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: actions
              .map(
                (action) => Padding(
                  padding: EdgeInsets.only(
                    right: action == actions.last ? 0 : 10,
                  ),
                  child: SizedBox(
                    width: 82,
                    child: _QuickActionCard(action: action),
                  ),
                ),
              )
              .toList(growable: false),
        ),
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
    this.selectedCategory = 'Tất cả',
    this.onCategoryTap,
  });

  final List<HomeCategory> categories;
  final HomeSectionIssue? issue;
  final Future<void> Function() onRetry;
  final String selectedCategory;
  final ValueChanged<String>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return _OptionalSectionWrapper(
      title: 'Danh mục',
      child: categories.isNotEmpty
          ? Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: categories
                  .map((category) {
                    final isSelected = selectedCategory == category.name;
                    return ChoiceChip(
                      label: Text(category.name),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0F5B38),
                      backgroundColor: context.chipBg(isSelected),
                      labelStyle: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                        color: context.chipText(isSelected),
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0F5B38)
                            : context.cardBorder(),
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      onSelected: (_) {
                        if (onCategoryTap != null) {
                          onCategoryTap!(category.name);
                        } else {
                          context.go(AppRoutes.appLearning);
                        }
                      },
                    );
                  })
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
      trailing: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSizes.controlHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        onPressed: () => context.push(AppRoutes.appArticles),
        child: const Text('Xem tất cả'),
      ),
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
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
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
    required this.bgColor,
    required this.iconColor,
    this.badge,
  });

  final String label;
  final IconData icon;
  final String route;
  final Color bgColor;
  final Color iconColor;
  final String? badge;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: InkWell(
        onTap: () {
          if (action.route == AppRoutes.appCommunity ||
              action.route == AppRoutes.appArticles) {
            context.push(action.route);
          } else {
            context.go(action.route);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: context.cardBg(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder(), width: 0.8),
            boxShadow: context.isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? context.colorScheme.surfaceContainerHighest
                          : action.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action.icon,
                      color: context.isDark
                          ? context.colorScheme.primary
                          : action.iconColor,
                      size: 21,
                    ),
                  ),
                  if (action.badge != null)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F5B38),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          action.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: context.textPrimary(),
                  letterSpacing: -0.2,
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
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w300,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: course.isFree
                          ? AppColors.mint
                          : colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: course.isFree
                            ? const Color(0xFFD3E6DC)
                            : colorScheme.primary.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      course.isFree
                          ? 'Miễn phí'
                          : _currencyFormatter.format(course.price),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: course.isFree
                            ? AppColors.primary
                            : colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
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
        onTap: () => context.push('/app/articles/${article.slug}'),
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
