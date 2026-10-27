import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/presentation/controllers/running_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardsInventoryScreen extends ConsumerStatefulWidget {
  const RewardsInventoryScreen({super.key});

  @override
  ConsumerState<RewardsInventoryScreen> createState() => _RewardsInventoryScreenState();
}

class _RewardsInventoryScreenState extends ConsumerState<RewardsInventoryScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Tất cả', 'Thành tích', 'Kiên trì', 'Huy hiệu'];

  @override
  Widget build(BuildContext context) {
    final runningState = ref.watch(runningControllerProvider);
    final allBadges = runningState.badges;

    final filteredBadges = allBadges.where((b) {
      if (_selectedCategoryIndex == 0) return true;
      if (_selectedCategoryIndex == 1) return b.category == 'milestone';
      if (_selectedCategoryIndex == 2) return b.category == 'streak';
      if (_selectedCategoryIndex == 3) return b.category == 'badge' || b.category == 'energy';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kho phần thưởng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: const Center(
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_categories.length, (idx) {
                  final isSelected = _selectedCategoryIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_categories[idx]),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedCategoryIndex = idx);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
      body: filteredBadges.isEmpty
          ? Center(
              child: Text(
                'Chưa có phần thưởng nào trong mục này',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredBadges.length,
              itemBuilder: (context, index) {
                final badge = filteredBadges[index];
                return _buildRewardCard(context, badge);
              },
            ),
    );
  }

  Widget _buildRewardCard(BuildContext context, RunningBadge badge) {
    Color iconColor;
    IconData iconData;

    switch (badge.id) {
      case 'badge_heart_energy':
        iconColor = const Color(0xFFEF4444);
        iconData = Icons.favorite;
        break;
      case 'badge_flower_bronze_3k':
        iconColor = const Color(0xFFF59E0B);
        iconData = Icons.local_florist;
        break;
      case 'badge_flower_blue_5k':
        iconColor = const Color(0xFF3B82F6);
        iconData = Icons.local_florist;
        break;
      case 'badge_flower_red_10k':
        iconColor = const Color(0xFFDC2626);
        iconData = Icons.local_florist;
        break;
      case 'badge_flower_purple_21k':
        iconColor = const Color(0xFF8B5CF6);
        iconData = Icons.local_florist;
        break;
      case 'badge_crown_gold_42k':
        iconColor = const Color(0xFFEC4899);
        iconData = Icons.stars;
        break;
      case 'badge_silver':
        iconColor = const Color(0xFF94A3B8);
        iconData = Icons.military_tech;
        break;
      case 'badge_gold':
        iconColor = const Color(0xFFEAB308);
        iconData = Icons.emoji_events;
        break;
      default:
        iconColor = badge.category == 'streak' ? const Color(0xFFEF4444) : AppColors.primary;
        iconData = badge.category == 'streak' ? Icons.whatshot : Icons.workspace_premium;
    }

    final isUnlocked = badge.isUnlocked || badge.count > 0;

    return InkWell(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(iconData, color: isUnlocked ? iconColor : Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    badge.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Text(
                  isUnlocked ? 'Số lượng đã thu thập: ${badge.count}' : 'Chưa mở khóa',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked ? AppColors.primary : Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đóng', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked ? iconColor.withValues(alpha: 0.25) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isUnlocked ? iconColor.withValues(alpha: 0.12) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: isUnlocked ? iconColor : Colors.grey.shade400,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),

              // Count
              Text(
                isUnlocked ? '× ${badge.count}' : 'Khóa',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isUnlocked ? AppColors.textPrimary : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 2),

              // Title
              Text(
                badge.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
