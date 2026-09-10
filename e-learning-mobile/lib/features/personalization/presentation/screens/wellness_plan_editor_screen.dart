import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  final List<Map<String, dynamic>> _fastingRatios = const [
    {
      'fasting': 16,
      'eating': 8,
      'name': '16:8 Cân bằng',
      'desc': 'Dễ duy trì hằng ngày, đốt mỡ ổn định',
    },
    {
      'fasting': 18,
      'eating': 6,
      'name': '18:6 Nâng cao',
      'desc': 'Tăng sinh Ketone & tự thực bào (Autophagy)',
    },
    {
      'fasting': 20,
      'eating': 4,
      'name': '20:4 Chiến binh',
      'desc': 'Khung ăn 4 giờ, tối đa hóa đốt mỡ sâu',
    },
    {
      'fasting': 23,
      'eating': 1,
      'name': '23:1 OMAD',
      'desc': 'Một bữa mỗi ngày, thanh lọc đường ruột',
    },
  ];

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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A2520),
            size: 18,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/app/wellness');
            }
          },
        ),
        title: const Text(
          'Thiết lập Kế hoạch Nhịn ăn',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: -0.3,
            color: Color(0xFF1A2520),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF9FBF9),
        iconTheme: const IconThemeData(color: Color(0xFF1A2520)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro Zen Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: const Color(0xFFEAEFE9),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_outlined,
                        color: Color(0xFF0F5B38),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cấu hình Chế độ Cá nhân hóa',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A2520),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tùy chỉnh tỷ lệ nhịn ăn và mục tiêu cân nặng theo thể trạng và nhịp sinh hoạt của bạn.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF6B7280),
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

              // Section 1: Visual Fasting Ratio Selector
              const Text(
                '1. Chọn tỷ lệ Nhịn / Ăn',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A2520),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Thanh biểu thị tỷ lệ thời gian nhịn (xanh lá) và thời gian nạp thức ăn (xám) trong ngày.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Column(
                children: _fastingRatios.map((ratio) {
                  final fH = ratio['fasting'] as int;
                  final eH = ratio['eating'] as int;
                  final isSelected = _fastingHours == fH && _eatingHours == eH;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _fastingHours = fH;
                        _eatingHours = eH;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F5B38)
                              : const Color(0xFFEAEFE9),
                          width: isSelected ? 1.5 : 0.8,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F5B38).withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ratio['name'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF0F5B38)
                                      : const Color(0xFF1A2520),
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: Color(0xFF0F5B38),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ratio['desc'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Dual-tone Ratio Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 8,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: fH,
                                    child: Container(
                                      color: isSelected
                                          ? const Color(0xFF0F5B38)
                                          : const Color(0xFF7A9E88),
                                    ),
                                  ),
                                  Expanded(
                                    flex: eH,
                                    child: Container(
                                      color: const Color(0xFFE5E7EB),
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
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Section 2: Daily Start Time Picker
              const Text(
                '2. Thời điểm bắt đầu nhịn mỗi ngày',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A2520),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _fastingStartTime,
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.0),
                        ),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _fastingStartTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: const Color(0xFFEAEFE9),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Khung giờ bắt đầu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fastingStartTime.hour.toString().padLeft(2, '0')}:${_fastingStartTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF1A2520),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          size: 20,
                          color: Color(0xFF0F5B38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 3: Weight Targets
              const Text(
                '3. Mục tiêu Cân nặng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A2520),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: const Color(0xFFEAEFE9),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cân nặng ban đầu (kg)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _startWeightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF1A2520),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            validator: (val) =>
                                double.tryParse(val ?? '') == null
                                    ? 'Nhập số hợp lệ'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: const Color(0xFFEAEFE9),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mục tiêu (kg)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _targetWeightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF0F5B38),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            validator: (val) =>
                                double.tryParse(val ?? '') == null
                                    ? 'Nhập số hợp lệ'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
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
                                    backgroundColor: Color(0xFF0F5B38),
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
                    backgroundColor: const Color(0xFF0F5B38),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: state.status == WellnessStatus.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu Kế Hoạch',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

