import 'package:e_learning_mobile/features/personalization/data/personalization_repository.dart';
import 'package:e_learning_mobile/features/personalization/domain/reminder_model.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(
              context,
            ).textScaler.clamp(maxScaleFactor: 1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/app/wellness/reminders');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reminderId != null;
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FBF9),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary(),
            size: 18,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/app/wellness/reminders');
            }
          },
        ),
        title: Text(
          isEditing ? 'Chỉnh sửa nhắc nhở' : 'Tạo nhắc nhở mới',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: -0.3,
            color: context.textPrimary(),
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FBF9),
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
              Text(
                'Loại nhắc nhở',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary(),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReminderType.values.map((type) {
                  final selected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(type.displayName),
                    avatar: Icon(
                      type.icon,
                      size: 16,
                      color: selected
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF0F5B38)),
                    ),
                    selected: selected,
                    selectedColor: isDark
                        ? const Color(0xFF108A55)
                        : const Color(0xFF0F5B38),
                    backgroundColor: isDark
                        ? colorScheme.surfaceContainerHighest
                        : Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : context.textPrimary(),
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w300,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: selected
                            ? (isDark
                                  ? const Color(0xFF108A55)
                                  : const Color(0xFF0F5B38))
                            : context.cardBorder(),
                        width: 0.8,
                      ),
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

              // Title input
              Text(
                'Tên nhắc nhở',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary(),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg(),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.cardBorder(), width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: context.textPrimary(),
                  ),
                  decoration: InputDecoration(
                    hintText: 'VD: Uống 1 ly nước ấm',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: context.textMuted(),
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tên nhắc nhở';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Message input
              Text(
                'Nội dung lời nhắn',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary(),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg(),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.cardBorder(), width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: TextFormField(
                  controller: _messageController,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: context.textPrimary(),
                  ),
                  decoration: InputDecoration(
                    hintText: 'VD: Đã đến lúc tiếp nước cho cơ thể rồi!',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: context.textMuted(),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Time picker section
              Text(
                'Khung giờ nhắc nhở',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary(),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(isStart: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.cardBg(),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: context.cardBorder(),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Từ: ${_startTime.format(context)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: context.textPrimary(),
                              ),
                            ),
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF0F5B38),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(isStart: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.cardBg(),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: context.cardBorder(),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đến: ${_endTime.format(context)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: context.textPrimary(),
                              ),
                            ),
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF0F5B38),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Switches card
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg(),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: context.cardBorder(), width: 0.8),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: Text(
                        'Âm thanh thông báo',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: context.textPrimary(),
                        ),
                      ),
                      value: _soundEnabled,
                      activeThumbColor: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF0F5B38),
                      onChanged: (val) => setState(() => _soundEnabled = val),
                    ),
                    Divider(
                      color: context.cardBorder(),
                      thickness: 0.8,
                      height: 1,
                    ),
                    SwitchListTile.adaptive(
                      title: Text(
                        'Rung thiết bị',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: context.textPrimary(),
                        ),
                      ),
                      value: _vibrationEnabled,
                      activeThumbColor: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF0F5B38),
                      onChanged: (val) =>
                          setState(() => _vibrationEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF108A55)
                        : const Color(0xFF0F5B38),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Lưu thay đổi' : 'Lưu nhắc nhở',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
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
