import 'package:e_learning_mobile/features/personalization/data/personalization_repository.dart';
import 'package:e_learning_mobile/features/personalization/domain/reminder_model.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReminderEditorScreen extends ConsumerStatefulWidget {
  const ReminderEditorScreen({this.reminderId, super.key});

  final String? reminderId;

  @override
  ConsumerState<ReminderEditorScreen> createState() =>
      _ReminderEditorScreenState();
}

class _ReminderEditorScreenState extends ConsumerState<ReminderEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late ReminderType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late List<int> _repeatDays;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedType = ReminderType.water;
    _titleController = TextEditingController();
    _messageController = TextEditingController();
    _startTime = const TimeOfDay(hour: 8, minute: 0);
    _endTime = const TimeOfDay(hour: 21, minute: 0);
    _soundEnabled = true;
    _vibrationEnabled = true;
    _repeatDays = [1, 2, 3, 4, 5, 6, 7];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      if (widget.reminderId != null) {
        final profileState = ref.read(personalizationStateProvider).value;
        final existing = profileState?.reminders.firstWhere(
          (r) => r.id == widget.reminderId,
          orElse: () => Reminder(
            id: '',
            type: ReminderType.custom,
            title: '',
            message: '',
          ),
        );
        if (existing != null && existing.id.isNotEmpty) {
          _selectedType = existing.type;
          _titleController.text = existing.title;
          _messageController.text = existing.message;
          _startTime = TimeOfDay(
            hour: existing.startTimeHour,
            minute: existing.startTimeMinute,
          );
          _endTime = TimeOfDay(
            hour: existing.endTimeHour,
            minute: existing.endTimeMinute,
          );
          _soundEnabled = existing.soundEnabled;
          _vibrationEnabled = existing.vibrationEnabled;
          _repeatDays = List.from(existing.repeatDays);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.reminderId ?? 'rem_${DateTime.now().millisecondsSinceEpoch}';

    final reminder = Reminder(
      id: id,
      type: _selectedType,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      enabled: true,
      startTimeHour: _startTime.hour,
      startTimeMinute: _startTime.minute,
      endTimeHour: _endTime.hour,
      endTimeMinute: _endTime.minute,
      repeatDays: _repeatDays,
      soundEnabled: _soundEnabled,
      vibrationEnabled: _vibrationEnabled,
    );

    await ref
        .read(personalizationStateProvider.notifier)
        .saveReminder(reminder);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.reminderId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Chỉnh sửa nhắc nhở' : 'Tạo nhắc nhở mới',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loại nhắc nhở',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: ReminderType.values.map((type) {
                  final selected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(type.displayName),
                    avatar: Icon(
                      type.icon,
                      size: 18,
                      color: selected ? Colors.white : AppColors.primary,
                    ),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedType = type;
                          if (_titleController.text.isEmpty) {
                            _titleController.text = type.displayName;
                          }
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên nhắc nhở',
                  hintText: 'VD: Uống 1 ly nước ấm',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên nhắc nhở';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung lời nhắn',
                  hintText: 'VD: Đã đến lúc tiếp nước cho cơ thể rồi!',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Khung giờ nhắc nhở',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(isStart: true),
                      icon: const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Từ: ${_startTime.format(context)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(isStart: false),
                      icon: const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Đến: ${_endTime.format(context)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              SwitchListTile.adaptive(
                title: const Text(
                  'Âm thanh thông báo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: _soundEnabled,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _soundEnabled = val),
              ),
              SwitchListTile.adaptive(
                title: const Text(
                  'Rung thiết bị',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: _vibrationEnabled,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _vibrationEnabled = val),
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Lưu thay đổi' : 'Lưu nhắc nhở',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
}
