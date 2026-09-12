import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex.clamp(0, 1),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Pháp lý & Quyền riêng tư',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              letterSpacing: -0.3,
              color: colorScheme.onSurface,
            ),
          ),
          elevation: 0,
          backgroundColor: colorScheme.surface,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: context.textSecondary(),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Điều khoản sử dụng'),
              Tab(text: 'Chính sách bảo mật'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TermsOfUseTab(isDark: isDark),
            _PrivacyPolicyTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _TermsOfUseTab extends StatelessWidget {
  const _TermsOfUseTab({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Medical Disclaimer Warning Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF92400E) : const Color(0xFFFCD34D),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuyên bố miễn trừ trách nhiệm y tế',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nội dung trên ứng dụng Nhịn Ăn Chữa Lành chỉ mang tính chất giáo dục và theo dõi thể trạng cá nhân. Ứng dụng KHÔNG cung cấp chẩn đoán hay thay thế tư vấn y khoa chuyên nghiệp. Hãy tham khảo ý kiến bác sĩ trước khi bắt đầu bất kỳ lộ trình nhịn ăn nâng cao nào.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          icon: Icons.gavel_outlined,
          title: '1. Quy định chung & Điều kiện tham gia',
          content:
              'Khi truy cập và sử dụng ứng dụng Nhịn Ăn Chữa Lành, bạn đồng ý tuân thủ toàn bộ các điều khoản được quy định tại đây. Nếu bạn không đồng ý với bất kỳ phần nào, vui lòng ngừng sử dụng dịch vụ.\n\nNgười dùng cần đảm bảo đủ 18 tuổi hoặc có sự giám sát của người giám hộ pháp lý khi theo dõi các lộ trình thể trạng trên ứng dụng.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          icon: Icons.menu_book_outlined,
          title: '2. Quyền sở hữu trí tuệ',
          content:
              'Toàn bộ nội dung học tập, video hướng dẫn, bài viết khoa học, công thức dinh dưỡng và tài liệu trên ứng dụng thuộc bản quyền của Học viện Nhịn Ăn Chữa Lành.\n\nNghiêm cấm sao chép, phát tán, kinh doanh lại hoặc chỉnh sửa nội dung khi chưa có sự đồng ý bằng văn bản từ chúng tôi.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          icon: Icons.account_circle_outlined,
          title: '3. Trách nhiệm người dùng',
          content:
              '• Cung cấp thông tin trung thực khi ghi nhận chỉ số thể trạng (cân nặng, lượng nước, thời gian nhịn ăn).\n'
              '• Bảo mật thông tin tài khoản và mật khẩu cá nhân.\n'
              '• Không chia sẻ tài khoản cho người khác dùng chung hoặc khai thác hệ thống trái phép.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          icon: Icons.update_outlined,
          title: '4. Cập nhật & Thay đổi điều khoản',
          content:
              'Chúng tôi có quyền điều chỉnh nội dung điều khoản này vào bất kỳ lúc nào để phù hợp với quy định pháp luật và sự phát triển của ứng dụng. Thay đổi sẽ có hiệu lực ngay khi đăng tải.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'Cập nhật lần cuối: Tháng 09/2026',
            style: TextStyle(
              fontSize: 12,
              color: context.textMuted(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _PrivacyPolicyTab extends StatelessWidget {
  const _PrivacyPolicyTab({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Security Callout Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF047857) : const Color(0xFF86EFAC),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cam kết bảo vệ dữ liệu sức khỏe',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dữ liệu thể trạng của bạn được bảo mật tuyệt đối với công nghệ mã hóa AES-256 mã hóa cục bộ. Chúng tôi cam kết KHÔNG bán hoặc chia sẻ thông tin cá nhân cho mục đích quảng cáo thương mại.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          icon: Icons.data_usage_outlined,
          title: '1. Dữ liệu chúng tôi thu thập',
          content:
              '• Thông tin tài khoản: Họ tên, địa chỉ email, ảnh đại diện.\n'
              '• Dữ liệu thể trạng & Nhật ký: Chỉ số cân nặng, lượng nước uống hàng ngày, lịch trình nhịn ăn (Fasting log) và tiến trình học tập.\n'
              '• Thông tin thiết bị: Nhằm tối ưu hóa trải nghiệm ứng dụng và gửi thông báo nhắc nhở cục bộ.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          icon: Icons.lock_outline_rounded,
          title: '2. Phương thức lưu trữ & Mã hóa',
          content:
              '• Dữ liệu đăng nhập và phiên làm việc được lưu trong bộ nhớ bảo mật thiết bị (FlutterSecureStorage / Keystore / Keychain).\n'
              '• Mọi kết nối giữa ứng dụng di động và máy chủ đều được mã hóa SSL/TLS (HTTPS) đạt chuẩn an ninh cao.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          icon: Icons.manage_accounts_outlined,
          title: '3. Quyền hạn của bạn đối với dữ liệu',
          content:
              '• Xem và chỉnh sửa thông tin cá nhân trong trang Hồ sơ.\n'
              '• Dọn dẹp bộ nhớ đệm (Cache) và dữ liệu tạm thời bất cứ lúc nào tại trang Cài đặt.\n'
              '• Yêu cầu trích xuất hoặc xóa toàn bộ dữ liệu tài khoản bằng cách liên hệ với bộ phận hỗ trợ.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          icon: Icons.contact_support_outlined,
          title: '4. Liên hệ bộ phận bảo mật',
          content:
              'Nếu bạn có bất kỳ thắc mắc hoặc góp ý nào về chính sách bảo mật, vui lòng liên hệ:\n\n'
              '• Email: hotro@nhinanchualanh.vn\n'
              '• Website: https://nhinanchualanh.vn\n'
              '• Hotline: 1900 6868',
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'Phiên bản chính sách: 2.1 • Cập nhật 09/2026',
            style: TextStyle(
              fontSize: 12,
              color: context.textMuted(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

Widget _buildSectionCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String content,
}) {
  return Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.cardBg(),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: context.cardBorder(),
        width: 0.8,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: context.textPrimary(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          content,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: context.textSecondary(),
          ),
        ),
      ],
    ),
  );
}
