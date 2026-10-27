import 'package:e_learning_mobile/features/running/presentation/controllers/running_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LogManualRunSheet extends ConsumerStatefulWidget {
  const LogManualRunSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LogManualRunSheet(),
    );
  }

  @override
  ConsumerState<LogManualRunSheet> createState() => _LogManualRunSheetState();
}

class _LogManualRunSheetState extends ConsumerState<LogManualRunSheet> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController(text: '5.0');
  final _minutesController = TextEditingController(text: '30');
  final _titleController = TextEditingController(text: 'Chạy máy trong nhà');
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  double get _distance => double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0.0;
  int get _minutes => int.tryParse(_minutesController.text) ?? 0;

  String get _calculatedPace {
    if (_distance <= 0 || _minutes <= 0) return '--';
    final pace = _minutes / _distance;
    final m = pace.toInt();
    final s = ((pace - m) * 60).round();
    return "$m'${s.toString().padLeft(2, '0')}\"/km";
  }

  int get _calculatedCalories {
    if (_distance <= 0) return 0;
    return (_distance * 65.0 * 1.036).round();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập quãng đường lớn hơn 0')),
      );
      return;
    }
    if (_minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập thời gian lớn hơn 0')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref.read(runningControllerProvider.notifier).logManualRun(
      distanceKm: _distance,
      durationSeconds: _minutes * 60,
      activityDate: _selectedDate,
      title: _titleController.text.trim().isEmpty ? 'Chạy bộ' : _titleController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã ghi nhận buổi chạy thành công!'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textMuted().withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ghi nhận Buổi chạy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Distance & Time Inputs
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quãng đường (km)', style: TextStyle(fontSize: 12, color: context.textMuted())),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _distanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: '5.0',
                            suffixText: 'km',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Bắt buộc';
                            final val = double.tryParse(v.replaceAll(',', '.'));
                            if (val == null || val <= 0) return 'Hợp lệ > 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thời gian (phút)', style: TextStyle(fontSize: 12, color: context.textMuted())),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _minutesController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: '30',
                            suffixText: 'phút',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Bắt buộc';
                            final val = int.tryParse(v);
                            if (val == null || val <= 0) return 'Hợp lệ > 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Presets chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _presetKmChip(3.0),
                    _presetKmChip(5.0),
                    _presetKmChip(10.0),
                    const SizedBox(width: 8),
                    _presetMinChip(20),
                    _presetMinChip(30),
                    _presetMinChip(45),
                    _presetMinChip(60),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Calculated info preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF132B20) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Tốc độ Pace', style: TextStyle(fontSize: 11, color: context.textMuted())),
                        const SizedBox(height: 2),
                        Text(
                          _calculatedPace,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: context.textMuted().withValues(alpha: 0.2)),
                    Column(
                      children: [
                        Text('Calo ước tính', style: TextStyle(fontSize: 11, color: context.textMuted())),
                        const SizedBox(height: 2),
                        Text(
                          '$_calculatedCalories kcal',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title input
              Text('Tiêu đề buổi chạy', style: TextStyle(fontSize: 12, color: context.textMuted())),
              const SizedBox(height: 4),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Chạy sáng, Chạy máy...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Date picker row
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: context.textMuted()),
                  const SizedBox(width: 8),
                  Text(
                    'Ngày chạy: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: TextStyle(fontSize: 13, color: context.textPrimary()),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        'Đổi ngày',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Lưu Buổi Chạy',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetKmChip(double km) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text('${km.toStringAsFixed(0)} km'),
        onPressed: () {
          _distanceController.text = km.toString();
          setState(() {});
        },
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _presetMinChip(int min) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text('$min phút'),
        onPressed: () {
          _minutesController.text = min.toString();
          setState(() {});
        },
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}
