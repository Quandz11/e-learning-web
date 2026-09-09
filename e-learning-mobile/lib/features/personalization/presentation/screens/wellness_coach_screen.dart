import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WellnessCoachScreen extends ConsumerStatefulWidget {
  const WellnessCoachScreen({super.key});

  @override
  ConsumerState<WellnessCoachScreen> createState() =>
      _WellnessCoachScreenState();
}

class _WellnessCoachScreenState extends ConsumerState<WellnessCoachScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mood Coach State
  int _selectedMood = 3;
  int _selectedEnergy = 3;
  final TextEditingController _moodPromptController = TextEditingController();

  // Meal Planner State
  final TextEditingController _ingredientsController =
      TextEditingController(text: 'Ức gà, Rau xanh, Cà rốt, Trứng, Gạo lứt');
  String _dietaryPreference = 'Eat Clean';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _moodPromptController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Trợ lý AI Wellness',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.psychology_rounded),
              text: 'Tư vấn Thể trạng',
            ),
            Tab(
              icon: Icon(Icons.restaurant_menu_rounded),
              text: 'Thực đơn Eat Clean',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoodCoachTab(context, state),
          _buildMealPlannerTab(context, state),
        ],
      ),
    );
  }

  Widget _buildMoodCoachTab(BuildContext context, WellnessState state) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Huấn luyện viên Tâm trí & Năng lượng',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chia sẻ cảm xúc hiện tại để nhận tư vấn phục hồi cá nhân hóa từ AI.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Mood selector
          Text(
            'Tâm trạng hiện tại của bạn?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEmojiOption(1, '😩', 'Mệt mỏi'),
              _buildEmojiOption(2, '😟', 'Căng thẳng'),
              _buildEmojiOption(3, '😐', 'Bình thường'),
              _buildEmojiOption(4, '😊', 'Vui vẻ'),
              _buildEmojiOption(5, '🤩', 'Năng lượng'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Energy selector
          Text(
            'Mức năng lượng cơ thể (1 - 5):',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Slider(
            value: _selectedEnergy.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.mint,
            label: 'Mức $_selectedEnergy',
            onChanged: (val) {
              setState(() {
                _selectedEnergy = val.toInt();
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Note prompt textfield
          TextField(
            controller: _moodPromptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Ví dụ: Hôm nay tôi hơi đau đầu nhẹ và thiếu tập trung sau khi nhịn ăn 14 tiếng...',
              labelText: 'Ghi chú thêm (không bắt buộc)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: state.isCoachLoading
                  ? null
                  : () {
                      ref
                          .read(wellnessControllerProvider.notifier)
                          .askMoodCoach(
                            WellnessCoachMoodRequest(
                              mood: _getMoodString(_selectedMood),
                              energy: _getEnergyString(_selectedEnergy),
                              hunger: 'Normal',
                              thirst: 'Normal',
                              notes: _moodPromptController.text,
                            ),
                          );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: state.isCoachLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              label: Text(
                state.isCoachLoading ? 'Đang phân tích...' : 'Gửi cho AI Coach',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Coach Reply Section
          if (state.lastCoachReply != null)
            _buildCoachReplyCard(context, state.lastCoachReply!),
        ],
      ),
    );
  }

  String _getMoodString(int score) {
    switch (score) {
      case 1:
        return 'Fatigued';
      case 2:
        return 'Stressed';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Energetic';
      default:
        return 'Neutral';
    }
  }

  String _getEnergyString(int level) {
    switch (level) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Moderate';
      case 4:
        return 'High';
      case 5:
        return 'Peak';
      default:
        return 'Moderate';
    }
  }

  Widget _buildEmojiOption(int score, String emoji, String label) {
    final isSelected = _selectedMood == score;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMood = score;
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachReplyCard(BuildContext context, WellnessCoachReply reply) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Tư vấn từ AI Coach:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Text(
            reply.reply,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlannerTab(BuildContext context, WellnessState state) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thiết Kế Thực Đơn Dinh Dưỡng',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nhập nguyên liệu sẵn có để AI lập thực đơn dinh dưỡng Eat Clean.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Ingredients Input
          TextField(
            controller: _ingredientsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Danh sách nguyên liệu sẵn có',
              hintText: 'Phân cách bằng dấu phẩy...',
              prefixIcon: const Icon(Icons.shopping_bag_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Dietary preference dropdown
          DropdownButtonFormField<String>(
            value: _dietaryPreference,
            decoration: InputDecoration(
              labelText: 'Chế độ ăn mong muốn',
              prefixIcon: const Icon(Icons.set_meal_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            items: ['Eat Clean', 'Low Carb', 'Keto', 'Chay thanh lọc']
                .map((pref) => DropdownMenuItem(value: pref, child: Text(pref)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _dietaryPreference = val;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: state.isCoachLoading
                  ? null
                  : () {
                      final rawIngs = _ingredientsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      ref
                          .read(wellnessControllerProvider.notifier)
                          .generateMeal(
                            WellnessCoachMealRequest(
                              ingredients: rawIngs,
                              dietaryPreference: _dietaryPreference,
                              goal: 'Eat Clean',
                            ),
                          );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: state.isCoachLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              label: Text(
                state.isCoachLoading ? 'Đang lập thực đơn...' : 'Tạo Thực Đơn AI',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Meal Suggestion Display
          if (state.lastMealSuggestion != null)
            _buildMealSuggestionCard(context, state.lastMealSuggestion!),
        ],
      ),
    );
  }

  Widget _buildMealSuggestionCard(
    BuildContext context,
    WellnessMealSuggestion suggestion,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gợi ý Thực đơn trong ngày',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${suggestion.servings} Khẩu phần',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Text(
            suggestion.menu,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (suggestion.nutritionNotes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Lưu ý dinh dưỡng: ${suggestion.nutritionNotes}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
