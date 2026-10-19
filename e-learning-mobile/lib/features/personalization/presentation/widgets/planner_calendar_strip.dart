import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class PlannerCalendarStrip extends StatelessWidget {
  const PlannerCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  static const List<String> _weekDayNames = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  DateTime _startOfWeek(DateTime date) {
    // DateTime.monday is 1
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final monday = _startOfWeek(selectedDate);
    final days = List.generate(7, (index) => monday.add(Duration(days: index)));

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final monthStr = selectedDate.month.toString().padLeft(2, '0');
    final dayStr = selectedDate.day.toString().padLeft(2, '0');
    final headerSubtitle = isToday
        ? 'HÔM NAY, THÁNG $monthStr $dayStr'
        : 'NGÀY $dayStr, THÁNG $monthStr ${selectedDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week strip row with prev/next buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: context.textSecondary(),
              ),
              onPressed: () {
                onSelectDate(selectedDate.subtract(const Duration(days: 7)));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              splashRadius: 18,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: days.map((day) {
                  final isSelected = day.year == selectedDate.year &&
                      day.month == selectedDate.month &&
                      day.day == selectedDate.day;
                  final dayIndex = (day.weekday - 1) % 7;
                  final dayName = _weekDayNames[dayIndex];

                  return Expanded(
                    child: InkWell(
                      onTap: () => onSelectDate(day),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFFE53935)
                                    : context.textMuted(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFFE53935) // BetterMe red accent
                                    : Colors.transparent,
                              ),
                              child: Text(
                                day.day.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : context.textPrimary(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: context.textSecondary(),
              ),
              onPressed: () {
                onSelectDate(selectedDate.add(const Duration(days: 7)));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              splashRadius: 18,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Subtitle label: HÔM NAY, THÁNG MM DD
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            headerSubtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
