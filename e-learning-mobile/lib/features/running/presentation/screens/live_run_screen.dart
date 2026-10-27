import 'package:e_learning_mobile/features/running/presentation/controllers/live_gps_controller.dart';
import 'package:e_learning_mobile/features/running/presentation/screens/run_result_screen.dart';
import 'package:e_learning_mobile/features/running/presentation/widgets/route_map_canvas.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LiveRunScreen extends ConsumerStatefulWidget {
  const LiveRunScreen({super.key});

  @override
  ConsumerState<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends ConsumerState<LiveRunScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveGpsControllerProvider.notifier).start();
    });
  }

  Future<void> _handleFinish() async {
    final liveState = ref.read(liveGpsControllerProvider);
    final distanceKm = liveState.distanceKm;

    if (distanceKm < 0.05 && liveState.elapsedSeconds < 10) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Kết thúc hoạt động?'),
          content: const Text(
            'Quãng đường chưa đủ để ghi nhận kết quả. Bạn có muốn hủy buổi chạy này không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tiếp tục'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Hủy buổi chạy',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );

      if (discard == true && mounted) {
        ref.read(liveGpsControllerProvider.notifier).reset();
        context.pop();
      }
      return;
    }

    // Screen 6: Confirm Finish Sheet
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_run,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Kết thúc hoạt động?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildConfirmStatRow('Thời gian', liveState.durationFormatted),
                  const Divider(height: 16),
                  _buildConfirmStatRow('Quãng đường', '${distanceKm.toStringAsFixed(2)} KM'),
                  const Divider(height: 16),
                  _buildConfirmStatRow('Tốc độ trung bình', liveState.currentPaceFormatted),
                  const Divider(height: 16),
                  _buildConfirmStatRow('Năng lượng tích lũy', '+${liveState.energyEarned} E'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Kết thúc',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      final savedActivity =
          await ref.read(liveGpsControllerProvider.notifier).finishAndSave();
      if (mounted) {
        if (savedActivity != null) {
          // Navigate to Screen 7: RunResultScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => RunResultScreen(activity: savedActivity),
            ),
          );
        } else {
          context.pop();
        }
      }
    }
  }

  Widget _buildConfirmStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveGpsControllerProvider);
    final controller = ref.read(liveGpsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1811), // Deep athletic forest night
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
            if (liveState.isActive) {
              _handleFinish();
            } else {
              context.pop();
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: liveState.isRunning
                    ? const Color(0xFF34D399)
                    : Colors.amberAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (liveState.isRunning
                            ? const Color(0xFF34D399)
                            : Colors.amberAccent)
                        .withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              liveState.isRunning
                  ? 'ĐANG CHẠY'
                  : (liveState.isPaused ? 'ĐÃ TẠM DỪNG' : 'CHẠY BỘ GPS'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      if (liveState.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  liveState.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Route Map Canvas View (Screen 5 in mockup)
                      const SizedBox(height: 8),
                      RouteMapCanvas(
                        waypoints: liveState.waypoints,
                        height: 165,
                        isLive: liveState.isRunning,
                      ),
                      const SizedBox(height: 16),

                      // Metrics Grid: 2 rows of 2 cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              label: 'THỜI GIAN',
                              value: liveState.durationFormatted,
                              icon: Icons.timer_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'QUÃNG ĐƯỜNG',
                              value: '${liveState.distanceKm.toStringAsFixed(2)} KM',
                              valueColor: const Color(0xFF34D399),
                              icon: Icons.straighten,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              label: 'TỐC ĐỘ (PACE)',
                              value: liveState.currentPaceFormatted,
                              icon: Icons.speed_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'NĂNG LƯỢNG (+E)',
                              value: '+${liveState.energyEarned} E',
                              valueColor: const Color(0xFFFBBF24),
                              icon: Icons.bolt,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Control Buttons: Tạm dừng / Tiếp tục & Kết thúc
                      if (liveState.status == LiveRunStatus.initial ||
                          liveState.status == LiveRunStatus.permissionDenied ||
                          liveState.status == LiveRunStatus.serviceDisabled) ...[
                        ElevatedButton.icon(
                          onPressed: controller.start,
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: const Text(
                            'BẮT ĐẦU CHẠY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            // Pause / Resume
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (liveState.isRunning) {
                                      controller.pause();
                                    } else {
                                      controller.resume();
                                    }
                                  },
                                  icon: Icon(
                                    liveState.isRunning
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 22,
                                  ),
                                  label: Text(
                                    liveState.isRunning ? 'Tạm dừng' : 'Tiếp tục',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: liveState.isRunning
                                        ? const Color(0xFFD97706)
                                        : AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Finish
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _handleFinish,
                                  icon: const Icon(Icons.stop_rounded, size: 22),
                                  label: const Text(
                                    'Kết thúc',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
