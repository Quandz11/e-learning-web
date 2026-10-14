import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WellnessCoachScreen extends ConsumerStatefulWidget {
  const WellnessCoachScreen({super.key});

  @override
  ConsumerState<WellnessCoachScreen> createState() =>
      _WellnessCoachScreenState();
}

class _WellnessCoachScreenState extends ConsumerState<WellnessCoachScreen> {
  int _activeTabIndex = 0; // 0: Tư vấn Thể trạng, 1: Thực đơn Dinh dưỡng

  // Mood Coach State
  int _selectedMood = 3;
  int _selectedEnergy = 3;
  final TextEditingController _moodPromptController = TextEditingController();

  // Meal Planner State
  final TextEditingController _ingredientsController = TextEditingController(
    text: 'Ức gà, Rau xanh, Cà rốt, Trứng, Gạo lứt',
  );
  String _dietaryPreference = 'Eat Clean';

  final List<String> _quickPrompts = const [
    'Cách giảm đói ở giờ thứ 14?',
    'Uống gì khi nhịn không bị phá vỡ?',
    'Cách giảm mệt mỏi buổi chiều?',
    'Tập luyện khi bụng đói có an toàn không?',
  ];

  @override
  void dispose() {
    _moodPromptController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider);
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: Text(
          'Trợ lý Sức khỏe',
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
          // iOS-style Segmented Floating Pill Switcher
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      label: 'Tư vấn Thể trạng',
                      icon: Icons.psychology_outlined,
                      isActive: _activeTabIndex == 0,
                      onTap: () => setState(() => _activeTabIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      label: 'Thực đơn Dinh dưỡng',
                      icon: Icons.restaurant_menu_outlined,
                      isActive: _activeTabIndex == 1,
                      onTap: () => setState(() => _activeTabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab View Content
          Expanded(
            child: _activeTabIndex == 0
                ? _buildMoodCoachView(context, state)
                : _buildMealPlannerView(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? context.colorScheme.surfaceContainerHigh
                    : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38))
                  : context.textSecondary(),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isActive
                    ? context.textPrimary()
                    : context.textSecondary(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCoachView(BuildContext context, WellnessState state) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zen Intro Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.cardBg(),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.cardBorder(), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.spa_outlined,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF0F5B38),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phục hồi Năng lượng & Cảm xúc',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lắng nghe cơ thể bạn trong từng chu kỳ nhịn ăn để nhận gợi ý điều hòa tốt nhất.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: context.textSecondary(),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Mood Selector: Circular Pastel Discs
          Text(
            'Tâm trạng hiện tại',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textPrimary(),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircularMoodDisc(1, '😩', 'Mệt'),
              _buildCircularMoodDisc(2, '😟', 'Căng'),
              _buildCircularMoodDisc(3, '😐', 'Ổn'),
              _buildCircularMoodDisc(4, '😊', 'Tươi'),
              _buildCircularMoodDisc(5, '✨', 'Khỏe'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Minimal Energy Stepper (1 to 5)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mức năng lượng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary(),
                ),
              ),
              Text(
                _getEnergyLabel(_selectedEnergy),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF0F5B38),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.cardBg(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.cardBorder(), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final level = index + 1;
                final isSelected = _selectedEnergy == level;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEnergy = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                ? const Color(0xFF108A55)
                                : const Color(0xFF0F5B38))
                          : (isDark
                                ? colorScheme.surfaceContainerHighest
                                : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.w300,
                        color: isSelected
                            ? Colors.white
                            : context.textSecondary(),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick Prompt Chips
          Text(
            'Câu hỏi gợi ý nhanh',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textPrimary(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrompts.map((prompt) {
              return ActionChip(
                label: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: context.textPrimary(),
                  ),
                ),
                backgroundColor: context.cardBg(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.cardBorder(), width: 0.8),
                ),
                onPressed: () {
                  _moodPromptController.text = prompt;
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Note prompt textfield
          Container(
            decoration: BoxDecoration(
              color: context.cardBg(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.cardBorder(), width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: TextField(
              controller: _moodPromptController,
              maxLines: 3,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: context.textPrimary(),
              ),
              decoration: InputDecoration(
                hintText:
                    'Nhập cảm nhận hoặc thắc mắc (ví dụ: đang đói ở giờ thứ 15, tim đập nhẹ...)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: context.textMuted(),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
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
                backgroundColor: isDark
                    ? const Color(0xFF108A55)
                    : const Color(0xFF0F5B38),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: state.isCoachLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Nhận lời khuyên từ chuyên gia',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Editorial AI Reply Card
          if (state.lastCoachReply != null)
            _buildEditorialCoachReplyCard(context, state.lastCoachReply!),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCircularMoodDisc(int score, String emoji, String label) {
    final isSelected = _selectedMood == score;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => setState(() => _selectedMood = score),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? (isDark
                        ? context.colorScheme.surfaceContainerHighest
                        : const Color(0xFFE8F5E9))
                  : context.cardBg(),
              border: Border.all(
                color: isSelected
                    ? (isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF0F5B38))
                    : context.cardBorder(),
                width: isSelected ? 1.5 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
              color: isSelected
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38))
                  : context.textSecondary(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialCoachReplyCard(
    BuildContext context,
    WellnessCoachReply reply,
  ) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.cardBorder(), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vertical Forest Jade Accent Stripe
            Container(
              width: 4,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.chipBg(false),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Chuyên gia Wellness',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.chipText(false),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Vừa phản hồi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: context.textMuted(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      reply.reply,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w300,
                        height: 1.6,
                        color: context.textPrimary(),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlannerView(BuildContext context, WellnessState state) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bento Info
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.cardBg(),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.cardBorder(), width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_outlined,
                    color: context.textPrimary(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cá nhân hóa Thực đơn',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tận dụng nguyên liệu trong tủ lạnh để tối ưu bữa ăn không gây tích mỡ.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: context.textSecondary(),
                          height: 1.3,
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
          Text(
            'Nguyên liệu bạn đang có',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textPrimary(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.cardBorder(), width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: TextField(
              controller: _ingredientsController,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: context.textPrimary(),
              ),
              decoration: InputDecoration(
                hintText: 'Nhập nguyên liệu, phân cách bằng dấu phẩy...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: context.textMuted(),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Dietary preference chips
          Text(
            'Mục tiêu / Phong cách ăn',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textPrimary(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Eat Clean', 'Low Carb', 'Keto', 'Chay thanh lọc'].map((
              pref,
            ) {
              final isSelected = _dietaryPreference == pref;
              return ChoiceChip(
                label: Text(pref),
                selected: isSelected,
                selectedColor: isDark
                    ? const Color(0xFF108A55)
                    : const Color(0xFF0F5B38),
                backgroundColor: context.cardBg(),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                  color: isSelected ? Colors.white : context.textPrimary(),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? (isDark
                              ? const Color(0xFF108A55)
                              : const Color(0xFF0F5B38))
                        : context.cardBorder(),
                    width: 0.8,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _dietaryPreference = pref);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
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
                backgroundColor: isDark
                    ? const Color(0xFF108A55)
                    : const Color(0xFF0F5B38),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: state.isCoachLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Tạo gợi ý thực đơn',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Meal Suggestion Display
          if (state.lastMealSuggestion != null)
            _buildEditorialMealCard(context, state.lastMealSuggestion!),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildEditorialMealCard(
    BuildContext context,
    WellnessMealSuggestion suggestion,
  ) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.cardBorder(), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thực đơn đề xuất',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: context.chipBg(false),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${suggestion.servings} khẩu phần',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.chipText(false),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: context.cardBorder(), thickness: 0.8, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            suggestion.menu,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w300,
              color: context.textPrimary(),
              height: 1.6,
            ),
          ),
          if (suggestion.nutritionNotes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? context.colorScheme.surfaceContainerHighest
                    : const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.cardBorder(), width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF0F5B38),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lưu ý: ${suggestion.nutritionNotes}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: context.textSecondary(),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  String _getEnergyLabel(int level) {
    switch (level) {
      case 1:
        return 'Cạn kiệt';
      case 2:
        return 'Uể oải';
      case 3:
        return 'Trung bình';
      case 4:
        return 'Tỉnh táo';
      case 5:
        return 'Đỉnh cao';
      default:
        return 'Bình thường';
    }
  }
}
