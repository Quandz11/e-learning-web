import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/learning/data/models/offline_download_model.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/offline_download_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_empty_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OfflineDownloadsScreen extends ConsumerWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offlineDownloadControllerProvider);
    final controller = ref.read(offlineDownloadControllerProvider.notifier);

    return Scaffold(
      backgroundColor: context.isDark
          ? context.colorScheme.surface
          : AppColors.background,
      appBar: AppBar(
        backgroundColor: context.isDark
            ? context.colorScheme.surface
            : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary(),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nội Dung Đã Tải (Offline)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimary(),
          ),
        ),
        actions: [
          if (state.items.isNotEmpty)
            IconButton(
              tooltip: 'Xóa tất cả',
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.redAccent,
              ),
              onPressed: () => _confirmDeleteAll(context, controller),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Storage Summary Card
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? const Color(0xFF143823)
                            : const Color(0xFFEFF5F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sd_card_outlined,
                        color: context.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dung lượng đã sử dụng',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: context.textSecondary(),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatBytes(state.totalStorageBytes),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.items.length} tệp bài học lưu trên máy',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textMuted(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.items.isNotEmpty)
                      TextButton(
                        onPressed: () => _confirmDeleteAll(context, controller),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Xóa tất cả',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Item List
            Expanded(
              child: state.items.isEmpty
                  ? const AppEmptyView(
                      message:
                          'Chưa có video hoặc tài liệu nào được tải về.\n'
                          'Bạn có thể bấm "Tải xem Offline" ở bài học để xem mà không cần mạng!',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return _buildItemTile(context, controller, item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    OfflineDownloadController controller,
    OfflineDownloadItem item,
  ) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: item.isVideo
                ? (context.isDark
                      ? const Color(0xFF1C2D24)
                      : const Color(0xFFEBF5EE))
                : (context.isDark
                      ? const Color(0xFF3B2A1E)
                      : const Color(0xFFFFF3E0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.isVideo
                ? Icons.play_circle_fill_rounded
                : Icons.description_rounded,
            color: item.isVideo
                ? context.colorScheme.primary
                : (context.isDark ? Colors.orangeAccent : Colors.orange),
            size: 22,
          ),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textPrimary(),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              item.courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: context.textSecondary()),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.isVideo ? 'Video' : 'Tài liệu PDF'} • ${formatBytes(item.fileSizeBytes)}',
              style: TextStyle(fontSize: 11, color: context.textMuted()),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          onPressed: () async {
            await controller.deleteDownload(item.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa bản tải "${item.title}".')),
              );
            }
          },
        ),
        onTap: () {
          if (item.isVideo) {
            context.push(
              AppRoutes.mediaPlayerPath(
                courseId: item.courseId,
                lessonPartId: item.id,
              ),
            );
          } else {
            context.push(
              AppRoutes.documentReaderPath(
                courseId: item.courseId,
                lessonPartId: item.id,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteAll(
    BuildContext context,
    OfflineDownloadController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xóa tất cả bản tải?'),
        content: const Text(
          'Tất cả video và tài liệu offline sẽ bị xóa khỏi thiết bị.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await controller.deleteAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa toàn bộ nội dung offline.'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
