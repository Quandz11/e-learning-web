import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thư viện Sức khỏe & Phục hồi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Category chips bar
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
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Resource List
          Expanded(
            child: state.isLoading && allItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Chưa có bài hướng dẫn nào trong mục này',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref
                              .read(wellnessControllerProvider.notifier)
                              .loadDashboard();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return _buildResourceCard(context, item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    WellnessResourceItem item,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner / Thumbnail placeholder with Category badge
          Container(
            height: 110,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.mint, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getResourceIcon(item.resourceType),
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.resourceType.isNotEmpty
                          ? item.resourceType
                          : 'Sức khỏe',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
                  item.title.isNotEmpty ? item.title : 'Bài thực hành',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // Button Action
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đang mở bài thực hành "${item.title}"',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                    label: const Text(
                      'Bắt Đầu Thực Hành',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
