import 'package:e_learning_mobile/features/running/presentation/controllers/live_gps_controller.dart';
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
          title: const Text('Buổi chạy quá ngắn'),
          content: const Text('Quãng đường chạy chưa đủ để lưu lại. Bạn có muốn thoát không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tiếp tục chạy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Bỏ qua', style: TextStyle(color: Colors.redAccent)),
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn tất buổi chạy 🎉'),
        content: Text(
          'Chúc mừng bạn đã hoàn thành:\n'
          '• Quãng đường: ${distanceKm.toStringAsFixed(2)} km\n'
          '• Thời gian: ${liveState.durationFormatted}\n'
          '• Tốc độ Pace: ${liveState.currentPaceFormatted}\n'
          '• Calo: ${liveState.caloriesBurned} kcal\n\n'
          'Lưu buổi chạy này vào hồ sơ học viên?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục chạy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu Buổi Chạy'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(liveGpsControllerProvider.notifier).finishAndSave();
      if (mounted) {
        if (success) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã lưu buổi chạy vào hồ sơ thành công!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể lưu buổi chạy. Vui lòng thử lại.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveGpsControllerProvider);
    final controller = ref.read(liveGpsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark athletic background
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
                color: liveState.isRunning ? const Color(0xFF10B981) : Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              liveState.isRunning
                  ? 'ĐANG CHẠY (GPS LIVE)'
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              if (liveState.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          liveState.errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(flex: 1),

              // Main Distance Display
              Text(
                'QUÃNG ĐƯỜNG',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      liveState.distanceKm.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 88,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'km',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 3 Metrics Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LiveMetricItem(
                      label: 'THỜI GIAN',
                      value: liveState.durationFormatted,
                      icon: Icons.timer_outlined,
                    ),
                    Container(height: 36, width: 1, color: Colors.white.withValues(alpha: 0.1)),
                    _LiveMetricItem(
                      label: 'PACE TB',
                      value: liveState.currentPaceFormatted,
                      icon: Icons.speed_rounded,
                    ),
                    Container(height: 36, width: 1, color: Colors.white.withValues(alpha: 0.1)),
                    _LiveMetricItem(
                      label: 'CALO',
                      value: '${liveState.caloriesBurned}',
                      unit: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Control Buttons
              if (liveState.status == LiveRunStatus.initial ||
                  liveState.status == LiveRunStatus.permissionDenied ||
                  liveState.status == LiveRunStatus.serviceDisabled) ...[
                ElevatedButton.icon(
                  onPressed: controller.start,
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text(
                    'BẮT ĐẦU CHẠY',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 58),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Pause or Resume button
                    GestureDetector(
                      onTap: () {
                        if (liveState.isRunning) {
                          controller.pause();
                        } else {
                          controller.resume();
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: liveState.isRunning ? Colors.amber.shade700 : const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (liveState.isRunning ? Colors.amber : const Color(0xFF10B981)).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          liveState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),

                    // Finish button
                    GestureDetector(
                      onTap: _handleFinish,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade700,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.stop_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveMetricItem extends StatelessWidget {
  const _LiveMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
