import 'package:flutter/material.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/core/services/home_widget_service.dart';
import 'package:e_learning_mobile/features/widgets/domain/mobile_widget_models.dart';
import 'package:e_learning_mobile/features/widgets/presentation/components/mobile_widget_components.dart';

class WidgetPreviewGalleryScreen extends StatefulWidget {
  const WidgetPreviewGalleryScreen({super.key});

  @override
  State<WidgetPreviewGalleryScreen> createState() =>
      _WidgetPreviewGalleryScreenState();
}

class _WidgetPreviewGalleryScreenState
    extends State<WidgetPreviewGalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileWidgetStateData _widgetData = MobileWidgetStateData.defaultData();
  bool _isSyncing = false;
  bool _isSyncEnabled = true;
  String _selectedWidgetId = 'streak_small';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final rawMap = await HomeWidgetService.instance.getWidgetData();
    final enabled = await HomeWidgetService.instance.isSyncEnabled();
    final selectedId = await HomeWidgetService.instance.getSelectedWidgetId();
    if (mounted) {
      setState(() {
        _widgetData = MobileWidgetStateData.fromMap(rawMap);
        _isSyncEnabled = enabled;
        _selectedWidgetId = selectedId;
      });
    }
  }

  Future<void> _toggleSync(bool val) async {
    setState(() => _isSyncEnabled = val);
    await HomeWidgetService.instance.setSyncEnabled(val);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val
                ? '✅ Đã BẬT tự động đồng bộ Widget hệ thống.'
                : '⏸ Đã TẮT tự động đồng bộ Widget hệ thống.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectWidget(String id, String name) async {
    setState(() => _selectedWidgetId = id);
    await HomeWidgetService.instance.setSelectedWidgetId(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎯 Đã kích hoạt mẫu "$name" làm Widget chính!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _syncToDevice() async {
    setState(() => _isSyncing = true);
    final success = await HomeWidgetService.instance.updateWidgetData(
      streakDays: _widgetData.streakDays,
      targetMinutes: _widgetData.targetMinutes,
      learnedMinutes: _widgetData.learnedMinutes,
      activeCourseTitle: _widgetData.activeCourseTitle,
      activeCourseProgress: _widgetData.activeCourseProgress,
      nextLessonTitle: _widgetData.nextLessonTitle,
      nextReminderTime: _widgetData.nextReminderTime,
    );
    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Đã đồng bộ dữ liệu mới nhất ra Widget hệ thống!'
                : '❌ Đồng bộ Widget thất bại.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16251E) : AppColors.surface;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text(
          'Cấu hình & Chọn Widget',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: surfaceColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Màn hình chính'),
            Tab(text: 'Màn hình khóa'),
            Tab(text: 'Thông báo'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Toggle Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF1B2B23) : AppColors.mint.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.sync, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tự động đồng bộ dữ liệu Widget',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch.adaptive(
                    value: _isSyncEnabled,
                    activeColor: AppColors.primary,
                    onChanged: _toggleSync,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHomeScreenWidgetsTab(isDark),
                  _buildLockScreenWidgetsTab(isDark),
                  _buildNotificationTab(isDark),
                ],
              ),
            ),
            _buildBottomSyncPanel(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreenWidgetsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWidgetCardHeader('1. Widget Nhỏ (2x2) - Chuỗi học tập', 'streak_small'),
          const SizedBox(height: 10),
          Center(
            child: SmallStreakWidgetView(
              data: _widgetData,
              onTap: () => _selectWidget('streak_small', 'Widget Nhỏ 2x2'),
            ),
          ),
          const SizedBox(height: 8),
          _buildSelectButton('streak_small', 'Widget Nhỏ 2x2'),

          const SizedBox(height: 24),
          _buildWidgetCardHeader('2. Widget Vừa (4x2) - Bài học dở dang', 'course_medium'),
          const SizedBox(height: 10),
          Center(
            child: MediumCourseWidgetView(
              data: _widgetData,
              onTap: () => _selectWidget('course_medium', 'Widget Vừa 4x2'),
            ),
          ),
          const SizedBox(height: 8),
          _buildSelectButton('course_medium', 'Widget Vừa 4x2'),

          const SizedBox(height: 24),
          _buildWidgetCardHeader('3. Widget Lớn (4x4) - Bảng tin học tập', 'dashboard_large'),
          const SizedBox(height: 10),
          Center(
            child: LargeDashboardWidgetView(
              data: _widgetData,
              onTap: () => _selectWidget('dashboard_large', 'Widget Lớn 4x4'),
            ),
          ),
          const SizedBox(height: 8),
          _buildSelectButton('dashboard_large', 'Widget Lớn 4x4'),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLockScreenWidgetsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWidgetCardHeader('1. Circular (Khung tròn 1x1)', 'lock_circular'),
          const SizedBox(height: 12),
          Center(
            child: LockScreenCircularWidgetView(data: _widgetData),
          ),
          const SizedBox(height: 8),
          _buildSelectButton('lock_circular', 'Widget Màn hình khóa Tròn 1x1'),

          const SizedBox(height: 24),
          _buildWidgetCardHeader('2. Inline (Dòng chữ sát giờ)', 'lock_inline'),
          const SizedBox(height: 12),
          Center(
            child: LockScreenInlineWidgetView(data: _widgetData),
          ),
          const SizedBox(height: 8),
          _buildSelectButton('lock_inline', 'Widget Màn hình khóa Dòng đơn'),

          const SizedBox(height: 24),
          _buildWidgetCardHeader('3. Rectangular (Khung chữ nhật 2x1)', 'lock_rectangular'),
          const SizedBox(height: 12),
          Center(
            child: LockScreenRectangularWidgetView(data: _widgetData),
          ),
          const SizedBox(height: 8),
          _buildSelectButton('lock_rectangular', 'Widget Màn hình khóa Khung nhật 2x1'),
        ],
      ),
    );
  }

  Widget _buildNotificationTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWidgetCardHeader('Thông báo Nhắc học Tương tác (Rich Notification Widget)', 'notification_banner'),
          const SizedBox(height: 12),
          RichNotificationPreviewView(data: _widgetData),
          const SizedBox(height: 12),
          _buildSelectButton('notification_banner', 'Thông báo Trung tâm Tương tác'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2E25) : AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Widget Thông báo cố định ở Trung tâm thông báo và Màn hình khóa giúp bấm chọn [Học ngay] hoặc [Hoãn 15p] tức thì.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetCardHeader(String title, String id) {
    final isSelected = _selectedWidgetId == id;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isSelected) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'ĐANG KÍCH HOẠT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectButton(String id, String name) {
    final isSelected = _selectedWidgetId == id;
    return Center(
      child: OutlinedButton.icon(
        onPressed: isSelected ? null : () => _selectWidget(id, name),
        icon: Icon(
          isSelected ? Icons.check_circle : Icons.touch_app_outlined,
          size: 16,
          color: isSelected ? AppColors.primary : null,
        ),
        label: Text(isSelected ? 'Đã kích hoạt mẫu này' : 'Chọn mẫu này'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSyncPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2B23) : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C3E35) : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chuỗi: ${_widgetData.streakDays}d • Tiến độ: ${_widgetData.learnedMinutes}/${_widgetData.targetMinutes}m',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  _isSyncEnabled
                      ? 'Tự động đồng bộ đang BẬT'
                      : 'Tự động đồng bộ đang TẮT',
                  style: TextStyle(
                    fontSize: 10,
                    color: _isSyncEnabled
                        ? (isDark ? const Color(0xFF4CAF50) : AppColors.primary)
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSyncing ? null : _syncToDevice,
            icon: _isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync, size: 16),
            label: const Text('Đồng bộ ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
