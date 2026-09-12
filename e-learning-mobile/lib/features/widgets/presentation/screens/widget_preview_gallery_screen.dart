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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final rawMap = await HomeWidgetService.instance.getWidgetData();
    setState(() {
      _widgetData = MobileWidgetStateData.fromMap(rawMap);
    });
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
                ? '✅ Đã đồng bộ dữ liệu ra Widget hệ thống!'
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
          'Thiết kế Widget Mobile',
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
          _buildSectionHeader('1. Widget Nhỏ (2x2) - Chuỗi học tập'),
          const SizedBox(height: 10),
          Center(
            child: SmallStreakWidgetView(
              data: _widgetData,
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('2. Widget Vừa (4x2) - Bài học dở dang'),
          const SizedBox(height: 10),
          Center(
            child: MediumCourseWidgetView(
              data: _widgetData,
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('3. Widget Lớn (4x4) - Bảng tin học tập'),
          const SizedBox(height: 10),
          Center(
            child: LargeDashboardWidgetView(
              data: _widgetData,
              onTap: () {},
            ),
          ),
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
          _buildSectionHeader('1. Circular (Khung tròn 1x1)'),
          const SizedBox(height: 12),
          Center(
            child: LockScreenCircularWidgetView(data: _widgetData),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('2. Inline (Dòng chữ sát giờ)'),
          const SizedBox(height: 12),
          Center(
            child: LockScreenInlineWidgetView(data: _widgetData),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('3. Rectangular (Khung chữ nhật 2x1)'),
          const SizedBox(height: 12),
          Center(
            child: LockScreenRectangularWidgetView(data: _widgetData),
          ),
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
          _buildSectionHeader('Thẻ Thông báo Nhắc học Tương tác (Rich Notification)'),
          const SizedBox(height: 12),
          RichNotificationPreviewView(data: _widgetData),
          const SizedBox(height: 20),
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
                    'Thông báo này cho phép người học bấm trực tiếp [Học ngay] để mở ứng dụng hoặc [Hoãn 15p] để hẹn lại giờ nhắc.',
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
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
                  'Bấm để đồng bộ dữ liệu mới nhất ra Widget thật',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
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
            label: const Text('Đồng bộ'),
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
