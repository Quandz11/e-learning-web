import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RunningHistoryItem extends StatelessWidget {
  const RunningHistoryItem({
    required this.activity,
    required this.onDelete,
    super.key,
  });

  final RunningActivity activity;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final dateStr =
        DateFormat('dd/MM/yyyy HH:mm').format(activity.activityDate.toLocal());

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activity.isGps
                      ? (isDark
                          ? const Color(0xFF132B20)
                          : AppColors.mint)
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : AppColors.warmSurface),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: activity.isGps
                        ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.primaryLight)
                        : Colors.transparent,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activity.isGps
                          ? Icons.gps_fixed_rounded
                          : Icons.edit_note_rounded,
                      size: 12,
                      color: activity.isGps
                          ? AppColors.primary
                          : context.textMuted(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity.isGps ? 'GPS Live' : 'Thủ công',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: activity.isGps
                            ? AppColors.primary
                            : context.textMuted(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textMuted(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: context.textMuted(),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Xóa buổi chạy',
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: const Text(
                        'Bạn có chắc chắn muốn xóa bản ghi buổi chạy này?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx, true);
                            onDelete();
                          },
                          child: const Text(
                            'Xóa',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            activity.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary(),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (activity.notes != null && activity.notes!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              activity.notes!,
              style: TextStyle(
                fontSize: 12,
                color: context.textMuted(),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'Quãng đường',
                  value: '${activity.distanceKm.toStringAsFixed(2)} km',
                  highlight: true,
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  label: 'Thời gian',
                  value: activity.durationFormatted,
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  label: 'Pace TB',
                  value: activity.paceFormatted,
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  label: 'Calo',
                  value: '${activity.caloriesBurned} kcal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textMuted(),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 15 : 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.primary : context.textPrimary(),
            ),
          ),
        ),
      ],
    );
  }
}
