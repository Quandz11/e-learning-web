import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusOption {
  const StatusOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color iconColor;
}

class PlannerDailyStatusSheet extends ConsumerStatefulWidget {
  const PlannerDailyStatusSheet({super.key});

  static const List<StatusOption> options = [
    StatusOption(
      id: 'thirsty',
      label: 'Tôi cảm thấy khát.',
      icon: Icons.water_drop_outlined,
      iconColor: Color(0xFF0284C7),
    ),
    StatusOption(
      id: 'hungry',
      label: 'Tôi thấy đói.',
      icon: Icons.sentiment_neutral_rounded,
      iconColor: Color(0xFFF59E0B),
    ),
    StatusOption(
      id: 'stomach_upset',
      label: 'Bụng tôi thấy khó chịu.',
      icon: Icons.sentiment_dissatisfied_rounded,
      iconColor: Color(0xFFEF4444),
    ),
    StatusOption(
      id: 'no_progress',
      label: 'Tôi cảm thấy bản thân không có bất kỳ tiến bộ nào.',
      icon: Icons.directions_walk_rounded,
      iconColor: Color(0xFF6B7280),
    ),
    StatusOption(
      id: 'tired',
      label: 'Tôi cảm thấy mệt mỏi.',
      icon: Icons.sentiment_very_dissatisfied_rounded,
      iconColor: Color(0xFF8B5CF6),
    ),
    StatusOption(
      id: 'motivated',
      label: 'Tôi cảm thấy có động lực để tập thể dục.',
      icon: Icons.fitness_center_rounded,
      iconColor: Color(0xFF10B981),
    ),
    StatusOption(
      id: 'craving',
      label: 'Tôi đang thèm ăn kinh khủng.',
      icon: Icons.ramen_dining_rounded,
      iconColor: Color(0xFFF97316),
    ),
    StatusOption(
      id: 'insomnia',
      label: 'Tôi gặp khó khăn khi ngủ.',
      icon: Icons.bedtime_rounded,
      iconColor: Color(0xFF6366F1),
    ),
    StatusOption(
      id: 'great',
      label: 'Tôi cảm thấy tuyệt vời. Cơ thể tôi đang thay đổi theo hướng tốt hơn.',
      icon: Icons.thumb_up_alt_rounded,
      iconColor: Color(0xFF10B981),
    ),
  ];

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlannerDailyStatusSheet(),
    );
  }

  @override
  ConsumerState<PlannerDailyStatusSheet> createState() =>
      _PlannerDailyStatusSheetState();
}

class _PlannerDailyStatusSheetState
    extends ConsumerState<PlannerDailyStatusSheet> {
  String? _selectedOptionId;

  Future<void> _handleSelect(StatusOption option) async {
    setState(() => _selectedOptionId = option.id);

    final request = WellnessCoachMoodRequest(
      mood: option.id,
      energy: option.id == 'tired' ? 'low' : 'normal',
      hunger: option.id == 'hungry' || option.id == 'craving' ? 'high' : 'normal',
      thirst: option.id == 'thirsty' ? 'high' : 'normal',
      notes: option.label,
    );

    await ref.read(wellnessControllerProvider.notifier).askMoodCoach(request);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider);
    final isDark = context.isDark;
    final coachReply = state.lastCoachReply;
    final isCoachLoading = state.isCoachLoading;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cardBorder(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái hàng ngày',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textMuted(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Việc nhịn ăn của bạn hôm nay diễn ra như thế nào?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary(),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Scrollable Options List or Coach Reply
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    if (_selectedOptionId != null) ...[
                      // Display instant feedback card
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF13221C)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E3A2F)
                                : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Lời khuyên từ Huấn luyện viên:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                const Spacer(),
                                if (isCoachLoading)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isCoachLoading
                                  ? 'Đang lắng nghe và chuẩn bị lời khuyên khoa học cho bạn...'
                                  : coachReply?.reply ??
                                      _getFallbackAdvice(_selectedOptionId!),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Option items
                    ...PlannerDailyStatusSheet.options.map((option) {
                      final isSelected = _selectedOptionId == option.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _handleSelect(option),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? const Color(0xFF1E3A2F)
                                      : const Color(0xFFF0FDF4))
                                  : context.cardBg(),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : context.cardBorder(),
                                width: isSelected ? 1.4 : 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  option.icon,
                                  size: 20,
                                  color: option.iconColor,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: context.textPrimary(),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: Color(0xFF10B981),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F623F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFallbackAdvice(String optionId) {
    switch (optionId) {
      case 'thirsty':
        return 'Hãy uống một cốc nước ấm hoặc thêm một chút muối khoáng. Cảm giác đói đôi khi thực chất là tín hiệu cơ thể đang thiếu nước.';
      case 'hungry':
        return 'Cơn đói thường đến theo đợt từ hormone ghrelin và sẽ dịu đi sau 15–20 phút. Hãy uống một tách trà thảo dược hoặc cà phê đen nguyên chất không đường.';
      case 'stomach_upset':
        return 'Nước ấm hoặc trà gừng nhẹ sẽ giúp làm dịu đường ruột. Nếu cảm thấy đau quặn, bạn hoàn toàn có thể kết thúc chu kỳ nhịn sớm bằng một bữa ăn nhẹ.';
      case 'no_progress':
        return 'Quá trình thích nghi trao đổi chất và tái tạo tế bào (autophagy) diễn ra âm thầm từ bên trong. Sự kiên trì tích lũy từng ngày sẽ mang lại bước ngoặt lớn!';
      case 'tired':
        return 'Cơ thể bạn đang chuyển đổi cơ chế sang đốt chất béo dự trữ. Hãy bổ sung điện giải và cho phép bản thân chợp mắt ngắn 15–20 phút.';
      case 'motivated':
        return 'Tuyệt vời! Năng lượng tinh thần tích cực này là thời điểm lý tưởng cho một bài tập vận động nhẹ, giãn cơ hoặc đi bộ sảng khoái.';
      case 'craving':
        return 'Cơn thèm ăn là tâm lý tạm thời. Hãy chuyển hướng chú ý bằng cách đi dạo nhẹ, nghe một bài thiền hoặc chuẩn bị sẵn danh sách thực phẩm lành mạnh cho bữa tiếp theo.';
      case 'insomnia':
        return 'Thử tắm nước ấm và tránh màn hình điện thoại 30 phút trước khi ngủ. Uống một ngụm trà hoa cúc ấm cũng giúp thư giãn hệ thần kinh.';
      case 'great':
      default:
        return 'Thật tuyệt vời! Cơ thể bạn đang vận hành nhịp nhàng ở trạng thái đốt mỡ tự nhiên và làm sạch tế bào. Hãy duy trì tinh thần hứng khởi này nhé!';
    }
  }
}
