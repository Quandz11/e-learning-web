import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WellnessPlanEditorScreen extends ConsumerStatefulWidget {
  const WellnessPlanEditorScreen({super.key});

  @override
  ConsumerState<WellnessPlanEditorScreen> createState() =>
      _WellnessPlanEditorScreenState();
}

class _WellnessPlanEditorScreenState
    extends ConsumerState<WellnessPlanEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _startWeightController;
  late TextEditingController _targetWeightController;

  int _fastingHours = 16;
  int _eatingHours = 8;
  TimeOfDay _fastingStartTime = const TimeOfDay(hour: 20, minute: 0);

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _startWeightController = TextEditingController(text: '65.0');
    _targetWeightController = TextEditingController(text: '60.0');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final state = ref.read(wellnessControllerProvider);
      if (state.dashboard?.plan != null) {
        final plan = state.dashboard!.plan!;
        _fastingHours = plan.fastingHours;
        _eatingHours = plan.eatingHours;
        _startWeightController.text = plan.startWeightKg.toString();
        _targetWeightController.text = plan.targetWeightKg.toString();
        final startMinutes = plan.dailyFastStartMinuteOfDay;
        _fastingStartTime = TimeOfDay(
          hour: startMinutes ~/ 60,
          minute: startMinutes % 60,
        );
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _startWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thiết lập Kế hoạch Nhịn ăn',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Tùy chỉnh chế độ nhịn ăn gián đoạn và mục tiêu cân nặng theo thể trạng cá nhân.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section: Fasting Ratio
              _buildSectionTitle('1. Chế độ Nhịn ăn gián đoạn'),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: '$_fastingHours/$_eatingHours',
                decoration: InputDecoration(
                  labelText: 'Tỷ lệ Nhịn / Ăn',
                  prefixIcon: const Icon(Icons.timer_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: '16/8',
                    child: Text('16/8 (Phổ biến nhất - Nhịn 16h, Ăn 8h)'),
                  ),
                  DropdownMenuItem(
                    value: '18/6',
                    child: Text('18/6 (Nâng cao - Nhịn 18h, Ăn 6h)'),
                  ),
                  DropdownMenuItem(
                    value: '20/4',
                    child: Text('20/4 (Chiến binh - Nhịn 20h, Ăn 4h)'),
                  ),
                  DropdownMenuItem(
                    value: '23/1',
                    child: Text('23/1 OMAD (Mỗi ngày 1 bữa)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    final parts = val.split('/');
                    setState(() {
                      _fastingHours = int.parse(parts[0]);
                      _eatingHours = int.parse(parts[1]);
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Fasting Start Time Picker
              _buildTimePickerTile(
                context,
                label: 'Khung giờ bắt đầu nhịn ăn hằng ngày',
                time: _fastingStartTime,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _fastingStartTime,
                  );
                  if (picked != null) {
                    setState(() {
                      _fastingStartTime = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section: Weight Target
              _buildSectionTitle('2. Mục tiêu Cân nặng'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Cân nặng ban đầu (kg)',
                        prefixIcon: const Icon(Icons.monitor_weight_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      validator: (val) =>
                          double.tryParse(val ?? '') == null ? 'Nhập số hợp lệ' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _targetWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Cân nặng mục tiêu (kg)',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      validator: (val) =>
                          double.tryParse(val ?? '') == null ? 'Nhập số hợp lệ' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: state.status == WellnessStatus.loading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final startMinute = _fastingStartTime.hour * 60 +
                                _fastingStartTime.minute;
                            await ref
                                .read(wellnessControllerProvider.notifier)
                                .savePlan(
                                  UpsertWellnessPlanRequest(
                                    startDate: DateTime.now(),
                                    fastingHours: _fastingHours,
                                    eatingHours: _eatingHours,
                                    dailyFastStartMinuteOfDay: startMinute,
                                    startWeightKg: double.parse(
                                      _startWeightController.text,
                                    ),
                                    targetWeightKg: double.parse(
                                      _targetWeightController.text,
                                    ),
                                  ),
                                );

                            if (context.mounted) {
                              final updatedState =
                                  ref.read(wellnessControllerProvider);
                              if (updatedState.status ==
                                  WellnessStatus.success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Lưu kế hoạch nhịn ăn thành công!',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                                Navigator.pop(context);
                              } else if (updatedState.failure != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      updatedState.failure!.message,
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: state.status == WellnessStatus.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    state.status == WellnessStatus.loading
                        ? 'Đang lưu...'
                        : 'Lưu Kế Hoạch',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTimePickerTile(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
