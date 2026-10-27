import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/presentation/controllers/running_controller.dart';
import 'package:e_learning_mobile/features/running/presentation/widgets/goal_added_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectGoalSheet extends ConsumerStatefulWidget {
  const SelectGoalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SelectGoalSheet(),
    );
  }

  @override
  ConsumerState<SelectGoalSheet> createState() => _SelectGoalSheetState();
}

class _SelectGoalSheetState extends ConsumerState<SelectGoalSheet> {
  String? _selectedId;
  bool _isCreatingNew = false;
  final TextEditingController _customGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final runningState = ref.read(runningControllerProvider);
    _selectedId = runningState.selectedGoalId ??
        (runningState.availableGoals.isNotEmpty ? runningState.availableGoals.first.id : null);
  }

  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final notifier = ref.read(runningControllerProvider.notifier);
    RunningGoal? selectedGoal;

    if (_isCreatingNew) {
      final title = _customGoalController.text.trim();
      if (title.isEmpty) return;
      notifier.addGoal(title);
      final updatedState = ref.read(runningControllerProvider);
      selectedGoal = updatedState.selectedGoal;
    } else {
      notifier.selectGoal(_selectedId);
      final runningState = ref.read(runningControllerProvider);
      selectedGoal = runningState.selectedGoal;
    }

    Navigator.of(context).pop();

    if (selectedGoal != null) {
      GoalAddedDialog.show(context, selectedGoal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final runningState = ref.watch(runningControllerProvider);
    final goals = runningState.availableGoals;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Thêm vào Mục tiêu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'Chọn Mục tiêu để thêm hoạt động Chạy bộ vào:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // List of goals
          ...goals.map((goal) {
            final isChosen = !_isCreatingNew && _selectedId == goal.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isChosen ? AppColors.mint : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isChosen ? AppColors.primary : AppColors.border,
                  width: isChosen ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  setState(() {
                    _isCreatingNew = false;
                    _selectedId = goal.id;
                  });
                },
                leading: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isChosen ? AppColors.primary : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isChosen ? AppColors.primary : Colors.transparent,
                  ),
                  child: isChosen
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                title: Text(
                  goal.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isChosen ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${goal.activitiesCount} hoạt động liên kết',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }),

          // Create new goal option
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _isCreatingNew ? AppColors.mint : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isCreatingNew ? AppColors.primary : AppColors.border,
                width: _isCreatingNew ? 1.5 : 1.0,
              ),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onTap: () {
                setState(() {
                  _isCreatingNew = true;
                });
              },
              leading: Icon(
                Icons.add_circle_outline,
                color: _isCreatingNew ? AppColors.primary : Colors.grey.shade500,
              ),
              title: const Text(
                'Mục tiêu mới',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Tạo mục tiêu rèn luyện mới',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),

          if (_isCreatingNew) ...[
            TextField(
              controller: _customGoalController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nhập tên mục tiêu (ví dụ: Chinh phục 50km)',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Thêm Activity',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
