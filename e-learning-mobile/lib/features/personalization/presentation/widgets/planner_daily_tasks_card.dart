import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class PlannerDailyTasksCard extends StatelessWidget {
  const PlannerDailyTasksCard({
    super.key,
    required this.tasks,
    required this.onToggleTask,
  });

  final List<WellnessDailyTask> tasks;
  final ValueChanged<String> onToggleTask;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder(), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 20,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhiệm vụ Ngày của Bạn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary(),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Hoàn thành $completedCount/$totalCount nhiệm vụ',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary(),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress line
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
            ),
          ),
          const SizedBox(height: 12),

          // Task items list
          ...tasks.map((task) {
            final isDone = task.isCompleted;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onToggleTask(task.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFFF0FDF4)
                        : (context.isDark
                            ? context.colorScheme.surfaceContainerHighest
                            : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFFBBF7D0)
                          : context.cardBorder(),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 20,
                        color: isDone
                            ? const Color(0xFF10B981)
                            : context.textMuted(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.lessonTitle.isNotEmpty
                              ? task.lessonTitle
                              : task.description,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? context.textMuted()
                                : context.textPrimary(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
