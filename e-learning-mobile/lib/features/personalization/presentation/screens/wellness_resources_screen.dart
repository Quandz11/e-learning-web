import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WellnessResourcesScreen extends ConsumerStatefulWidget {
  const WellnessResourcesScreen({super.key});

  @override
  ConsumerState<WellnessResourcesScreen> createState() =>
      _WellnessResourcesScreenState();
}

class _WellnessResourcesScreenState
    extends ConsumerState<WellnessResourcesScreen> {
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = const [
    'Tất cả',
    'Thiền định',
    'Thực hành thở',
    'Vận động nhẹ',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider);
    final resourceSet = state.dashboard?.todayResources;

    final List<WellnessResourceItem> allItems = [];
    if (resourceSet?.meditation != null) {
      allItems.add(resourceSet!.meditation!);
    }
    if (resourceSet?.breathing != null) {
      allItems.add(resourceSet!.breathing!);
    }
    if (resourceSet?.workout != null) {
      allItems.add(resourceSet!.workout!);
    }

    final filteredItems = _selectedCategory == 'Tất cả'
        ? allItems
        : allItems.where((item) {
            final cat = _selectedCategory.toLowerCase();
            final title = item.title.toLowerCase();
            final type = item.resourceType.toLowerCase();
            return title.contains(cat) || type.contains(cat);
          }).toList();

    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: Text(
          'Thư viện Phục hồi & Sức khỏe',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: -0.3,
            color: context.textPrimary(),
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FBF9),
        iconTheme: IconThemeData(color: context.textPrimary()),
      ),
      body: Column(
        children: [
          // Horizontal Floating Pill Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0F5B38)
                            : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F5B38)
                              : context.cardBorder(),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w300,
                          color: isSelected
                              ? Colors.white
                              : context.textPrimary(),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Resource List
          Expanded(
            child: state.isLoading && allItems.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.spa_outlined,
                                size: 26,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Không có nội dung trong mục này',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: context.textPrimary(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vui lòng chọn danh mục khác hoặc kéo xuống để làm mới.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: context.textSecondary(),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF0F5B38),
                        onRefresh: () async {
                          await ref
                              .read(wellnessControllerProvider.notifier)
                              .loadDashboard();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return _buildEditorialResourceCard(context, item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialResourceCard(
    BuildContext context,
    WellnessResourceItem item,
  ) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.cardBorder(),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Magazine-style banner preview
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [context.colorScheme.surfaceContainerHighest, context.colorScheme.surfaceContainerHigh]
                    : const [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getResourceIcon(item.resourceType),
                    size: 40,
                    color: isDark ? const Color(0xFF34D399).withValues(alpha: 0.5) : const Color(0xFF0F5B38).withValues(alpha: 0.4),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.chipBg(false),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.cardBorder(),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      item.resourceType.isNotEmpty
                          ? item.resourceType
                          : 'Sức khỏe',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.chipText(false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isNotEmpty ? item.title : 'Bài thực hành phục hồi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary(),
                    letterSpacing: -0.2,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w300,
                      color: context.textSecondary(),
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // Button Action: Editorial pill button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      GoRouter.of(context).push('/app/articles');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Bắt Đầu Thực Hành',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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

  IconData _getResourceIcon(String resourceType) {
    final lower = resourceType.toLowerCase();
    if (lower.contains('meditation') || lower.contains('thiền')) {
      return Icons.self_improvement_rounded;
    } else if (lower.contains('breathing') || lower.contains('thở')) {
      return Icons.air_rounded;
    } else if (lower.contains('workout') || lower.contains('vận động')) {
      return Icons.fitness_center_rounded;
    }
    return Icons.menu_book_rounded;
  }
}

