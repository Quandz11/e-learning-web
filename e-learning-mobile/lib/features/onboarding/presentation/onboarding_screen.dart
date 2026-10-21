import 'package:e_learning_mobile/app/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingKey = 'has_seen_onboarding';

Future<bool> hasSeenOnboarding() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> markOnboardingDone() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  } catch (_) {}
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _stepsData = [
    _StepInfo(
      stepNumber: 1,
      title: 'Khám phá trang chủ',
      subtitle:
          'Cập nhật bài viết, video và nội dung hữu ích về nhịn ăn, dinh dưỡng và lối sống lành mạnh.',
    ),
    _StepInfo(
      stepNumber: 2,
      title: 'Tìm khóa học phù hợp',
      subtitle:
          'Khám phá các khóa học được thiết kế bởi chuyên gia, phù hợp với nhiều trình độ.',
    ),
    _StepInfo(
      stepNumber: 3,
      title: 'Tham gia cộng đồng',
      subtitle:
          'Trao đổi, đặt câu hỏi và kết nối với những người cùng quan tâm đến lối sống lành mạnh.',
    ),
    _StepInfo(
      stepNumber: 4,
      title: 'Quản lý tài khoản',
      subtitle:
          'Cập nhật thông tin cá nhân, theo dõi khóa học, bài viết đã lưu và cài đặt dễ dàng.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _stepsData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    if (mounted) {
      ref.read(hasSeenOnboardingProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _stepsData.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: Stack(
        children: [
          // Subtle Botanical Leaves in Corners
          Positioned(
            top: -20,
            left: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.35,
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: _CornerLeavesPainter(isTopLeft: true),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.35,
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: _CornerLeavesPainter(isTopLeft: false),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 18, top: 4),
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF133E2B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'Bỏ qua',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF133E2B),
                        ),
                      ),
                    ),
                  ),
                ),

                // Main Page View (Steps)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _stepsData.length,
                    itemBuilder: (context, index) {
                      return _OnboardingStepView(
                        info: _stepsData[index],
                        stepIndex: index,
                      );
                    },
                  ),
                ),

                // Bottom Controls: Indicators + Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    children: [
                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_stepsData.length, (i) {
                          final isActive = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF133E2B)
                                  : const Color(0xFFD3DDD7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      // CTA Button
                      SizedBox(
                        width: isLastPage ? 280 : 200,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF133E2B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            isLastPage ? 'Bắt đầu sử dụng →' : 'Tiếp tục →',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  final int stepNumber;
  final String title;
  final String subtitle;

  const _StepInfo({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingStepView extends StatelessWidget {
  const _OnboardingStepView({
    required this.info,
    required this.stepIndex,
  });

  final _StepInfo info;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Step Circle Badge
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF133E2B),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${info.stepNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            info.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF133E2B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          SizedBox(
            width: 330,
            child: Text(
              info.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF50665B),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Device Preview Mockup
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 310, maxHeight: 420),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2E26),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF14241B), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF133E2B).withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    color: const Color(0xFFF9F8F5),
                    child: Column(
                      children: [
                        // Dynamic Island / Phone top notch
                        Container(
                          height: 16,
                          color: const Color(0xFFF9F8F5),
                          alignment: Alignment.center,
                          child: Container(
                            width: 60,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2E26),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),

                        // Inner Screen Mockup Content based on stepIndex
                        Expanded(
                          child: switch (stepIndex) {
                            0 => const _HomeMockup(),
                            1 => const _CourseMockup(),
                            2 => const _CommunityMockup(),
                            _ => const _ProfileMockup(),
                          },
                        ),

                        // Mini Phone Bottom Navigation Bar
                        _MiniBottomNav(activeTab: stepIndex),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Step 1: Home Mockup
class _HomeMockup extends StatelessWidget {
  const _HomeMockup();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Logo Row
          Row(
            children: [
              const Icon(Icons.spa_rounded, size: 16, color: Color(0xFF133E2B)),
              const SizedBox(width: 4),
              const Text(
                'Nhịn Ăn Chữa Lành',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF133E2B),
                ),
              ),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded, size: 16, color: Color(0xFF50665B)),
            ],
          ),
          const SizedBox(height: 6),

          // Search Bar + Callout
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E9E4)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tìm bài viết, khóa học, chủ đề...',
                        style: TextStyle(fontSize: 9.5, color: Color(0xFF889990)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF133E2B).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF133E2B), width: 1.2),
                      ),
                      child: const Icon(Icons.search_rounded, size: 12, color: Color(0xFF133E2B)),
                    ),
                  ],
                ),
              ),
              // Callout Tooltip
              Positioned(
                top: 26,
                right: -6,
                child: _TooltipBubble(
                  text: 'Tìm kiếm nhanh\nnội dung bạn quan tâm',
                  pointerAtTop: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Hero Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE9F1EB), Color(0xFFDCE9DF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sống chậm\nSống cân bằng mỗi ngày',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF133E2B),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF133E2B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Xem ngay →',
                          style: TextStyle(fontSize: 7.5, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: const Color(0xFFCFDFC4),
                    child: const Icon(Icons.self_improvement_rounded, size: 28, color: Color(0xFF133E2B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section Title
          const Text(
            'Bài viết nổi bật',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF133E2B)),
          ),
          const SizedBox(height: 6),

          // Mini Cards
          Row(
            children: [
              Expanded(
                child: _miniArticleCard(
                  'Nhịn ăn gián đoạn là gì? Hướng dẫn...',
                  Icons.restaurant_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _miniArticleCard(
                  'Tạo thói quen lành mạnh mỗi ngày',
                  Icons.nature_people_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniArticleCard(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5EDE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2ED),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Icon(icon, size: 18, color: const Color(0xFF133E2B))),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Color(0xFF22362C)),
          ),
        ],
      ),
    );
  }
}

// MARK: - Step 2: Course Mockup
class _CourseMockup extends StatelessWidget {
  const _CourseMockup();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Khóa học',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF133E2B)),
              ),
              const Spacer(),
              const Icon(Icons.search_rounded, size: 16, color: Color(0xFF50665B)),
            ],
          ),
          const SizedBox(height: 6),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _miniChip('Tất cả', isSelected: true),
                _miniChip('Dành cho người mới'),
                _miniChip('Dinh dưỡng'),
                _miniChip('Lối sống'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Highlighted Featured Course with Callout Tooltip
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2D8259), width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D8259).withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F0E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF133E2B), size: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F0E8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Phổ biến',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFF133E2B)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Nhịn ăn gián đoạn cho người mới bắt đầu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF1B2F25)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '📖 12 bài học • ⏱ 1.5 giờ',
                            style: TextStyle(fontSize: 8, color: Color(0xFF6B7E74)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF133E2B)),
                  ],
                ),
              ),
              // Callout Tooltip
              Positioned(
                top: 48,
                right: 4,
                child: _TooltipBubble(
                  text: 'Chọn khóa học\nđể xem chi tiết',
                  pointerAtTop: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),

          // Course 2
          _miniCourseRow('Dinh dưỡng cân bằng trong cuộc sống', '10 bài học • 1.2 giờ', Icons.eco_rounded),
          const SizedBox(height: 6),

          // Course 3
          _miniCourseRow('Xây dựng thói quen lành mạnh mỗi ngày', '8 bài học • 1 giờ', Icons.schedule_rounded),
        ],
      ),
    );
  }

  Widget _miniChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF133E2B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFF133E2B) : const Color(0xFFE0E8E3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF50665B),
        ),
      ),
    );
  }

  Widget _miniCourseRow(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EFEA)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5F1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: const Color(0xFF133E2B), size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF1B2F25)),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 7.5, color: Color(0xFF6B7E74))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Step 3: Community Mockup
class _CommunityMockup extends StatelessWidget {
  const _CommunityMockup();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Cộng đồng',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF133E2B)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF133E2B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 10, color: Colors.white),
                    SizedBox(width: 2),
                    Text('Tạo bài viết', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Community Tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _miniTab('Tất cả', active: true),
                _miniTab('Thảo luận'),
                _miniTab('Kinh nghiệm'),
                _miniTab('Hỏi đáp'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Community Post with Callout Tooltip
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4EDE7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: const Color(0xFFD3E7DC),
                          child: const Icon(Icons.person, size: 12, color: Color(0xFF133E2B)),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Nguyễn Thị Mai',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF1B2F25)),
                        ),
                        const Spacer(),
                        const Text('2 giờ trước', style: TextStyle(fontSize: 7.5, color: Color(0xFF889990))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mọi người có thể chia sẻ kinh nghiệm bắt đầu nhịn ăn gián đoạn được không ạ? Mình là người mới...',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 8.5, color: Color(0xFF33463C), height: 1.25),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.favorite_rounded, size: 11, color: Color(0xFFE55A5A)),
                        SizedBox(width: 2),
                        Text('12', style: TextStyle(fontSize: 8, color: Color(0xFF6B7E74))),
                        SizedBox(width: 10),
                        Icon(Icons.chat_bubble_outline_rounded, size: 10, color: Color(0xFF6B7E74)),
                        SizedBox(width: 2),
                        Text('28', style: TextStyle(fontSize: 8, color: Color(0xFF6B7E74))),
                        Spacer(),
                        Icon(Icons.share_outlined, size: 10, color: Color(0xFF6B7E74)),
                      ],
                    ),
                  ],
                ),
              ),
              // Callout Tooltip
              Positioned(
                top: 42,
                right: 6,
                child: _TooltipBubble(
                  text: 'Đọc bài viết\nvà đặt câu hỏi',
                  pointerAtTop: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Post 2
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4EDE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: const Color(0xFFE3EDDE),
                      child: const Icon(Icons.person, size: 12, color: Color(0xFF2C6D4F)),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Trần Minh Đức',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF1B2F25)),
                    ),
                    const Spacer(),
                    const Text('5 giờ trước', style: TextStyle(fontSize: 7.5, color: Color(0xFF889990))),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hôm nay mình hoàn thành 16:8 được 2 tuần. Cảm thấy năng lượng tốt hơn rất nhiều!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8.5, color: Color(0xFF33463C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTab(String text, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF133E2B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? const Color(0xFF133E2B) : const Color(0xFFE0E8E3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
          color: active ? Colors.white : const Color(0xFF50665B),
        ),
      ),
    );
  }
}

// MARK: - Step 4: Profile Mockup
class _ProfileMockup extends StatelessWidget {
  const _ProfileMockup();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Cá nhân',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF133E2B)),
              ),
              const Spacer(),
              const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF50665B)),
            ],
          ),
          const SizedBox(height: 6),

          // User Card with Callout Tooltip
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4EDE7)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFD6EAE0),
                      child: const Icon(Icons.person, size: 22, color: Color(0xFF133E2B)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Học viên SKVI',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1B2F25)),
                          ),
                          const SizedBox(height: 1),
                          const Text('Xem hồ sơ >', style: TextStyle(fontSize: 8, color: Color(0xFF6B7E74))),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFFD591), width: 0.6),
                            ),
                            child: const Text(
                              '👑 Thành viên chính thức',
                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFFD48806)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Callout Tooltip
              Positioned(
                top: 44,
                right: -4,
                child: _TooltipBubble(
                  text: 'Quản lý thông tin\ncá nhân tại đây',
                  pointerAtTop: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Settings Items
          _miniProfileRow(Icons.school_outlined, 'Khóa học của tôi'),
          _miniProfileRow(Icons.bookmark_outline_rounded, 'Bài viết đã lưu'),
          _miniProfileRow(Icons.history_rounded, 'Lịch sử hoạt động'),
          _miniProfileRow(Icons.notifications_none_rounded, 'Thông báo'),
          _miniProfileRow(Icons.tune_rounded, 'Cài đặt học tập'),
        ],
      ),
    );
  }

  Widget _miniProfileRow(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEDF3EE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF133E2B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w500, color: Color(0xFF22362C)),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF9FB0A7)),
        ],
      ),
    );
  }
}

// MARK: - Mini Bottom Navigation Bar for Mockup
class _MiniBottomNav extends StatelessWidget {
  const _MiniBottomNav({required this.activeTab});

  final int activeTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EFEA), width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, 'Trang chủ', activeTab == 0),
          _navItem(Icons.play_circle_filled_rounded, 'Khóa học', activeTab == 1),
          _navItem(Icons.groups_rounded, 'Cộng đồng', activeTab == 2),
          _navItem(Icons.notifications_rounded, 'Thông báo', false),
          _navItem(Icons.person_rounded, 'Cá nhân', activeTab == 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    final color = active ? const Color(0xFF133E2B) : const Color(0xFFA0B2A8);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: color),
        Text(
          label,
          style: TextStyle(
            fontSize: 6.5,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// MARK: - Tooltip Bubble with Pointer Callout
class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({
    required this.text,
    this.pointerAtTop = true,
  });

  final String text;
  final bool pointerAtTop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF16A34A), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14532D),
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

// MARK: - Corner Leaves Decorative Painter
class _CornerLeavesPainter extends CustomPainter {
  final bool isTopLeft;

  const _CornerLeavesPainter({required this.isTopLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.save();
    if (!isTopLeft) {
      canvas.translate(size.width, size.height);
      canvas.rotate(3.14159);
    }

    // Branch curve
    final branch = Path()
      ..moveTo(0, 0)
      ..cubicTo(size.width * 0.4, size.height * 0.2, size.width * 0.7, size.height * 0.5, size.width, size.height * 0.8);
    final strokePaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(branch, strokePaint);

    // Leaves
    void drawLeaf(double x, double y, double radius, double angle) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final p = Path()
        ..moveTo(0, 0)
        ..cubicTo(radius * 0.5, -radius * 0.4, radius * 0.8, -radius * 0.3, radius, 0)
        ..cubicTo(radius * 0.8, radius * 0.3, radius * 0.5, radius * 0.4, 0, 0);
      canvas.drawPath(p, paint);
      canvas.restore();
    }

    drawLeaf(size.width * 0.25, size.height * 0.18, 24, 0.4);
    drawLeaf(size.width * 0.45, size.height * 0.32, 28, -0.3);
    drawLeaf(size.width * 0.65, size.height * 0.52, 26, 0.5);
    drawLeaf(size.width * 0.85, size.height * 0.72, 22, -0.4);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
