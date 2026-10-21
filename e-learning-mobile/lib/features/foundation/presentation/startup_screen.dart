import 'package:flutter/material.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  static const appName = 'Nhịn Ăn Chữa Lành';
  static const message = 'Lắng nghe cơ thể, sống cân bằng';
  static const slogan = message;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EE),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Serene Nature Art
          Image.asset(
            'assets/images/startup_bg.jpg',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF7F5EE),
            ),
          ),

          // Gentle ambient light gradient for optimal legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 0.65, 1.0],
                colors: [
                  const Color(0xFFFAF8F2).withValues(alpha: 0.92),
                  const Color(0xFFFAF8F2).withValues(alpha: 0.25),
                  const Color(0xFF163A29).withValues(alpha: 0.05),
                  const Color(0xFF0F2E20).withValues(alpha: 0.65),
                ],
              ),
            ),
          ),

          // Main Foreground Content
          SafeArea(
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: 'Đang khởi động ${StartupScreen.appName}',
              child: FadeTransition(
                opacity: _fadeAnimation,
                alwaysIncludeSemantics: true,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

                        // Logo: Rising Sun & Leaves Emblem
                        const _SunLeavesLogo(size: 88),
                        const SizedBox(height: 20),

                        // Brand Name (Constrained so it wraps gracefully to 2 lines)
                        const SizedBox(
                          width: 220,
                          child: Text(
                            StartupScreen.appName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.18,
                              letterSpacing: -0.6,
                              color: Color(0xFF163A29),
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Slogan / Message
                        const Text(
                          StartupScreen.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.2,
                            color: Color(0xFF436050),
                          ),
                        ),

                        // Flexible spacer to frame the serene lake landscape
                        const Spacer(),

                        // Loading Indicator with Semantics
                        Semantics(
                          container: true,
                          label: 'Đang tải dữ liệu khởi động',
                          value: 'Đang xử lý',
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFFD4E5DB).withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 3 Pillars / Keywords
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildKeyword('KIẾN THỨC'),
                            _buildDot(),
                            _buildKeyword('THÓI QUEN'),
                            _buildDot(),
                            _buildKeyword('CỘNG ĐỒNG'),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Sub-motto
                        const Text(
                          'VÌ MỘT PHIÊN BẢN KHỎE HƠN\nCỦA CHÍNH BẠN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            height: 1.4,
                            color: Color(0xFFE8F1EC),
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
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

  Widget _buildKeyword(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
        color: Color(0xFFD6E6DC),
        shadows: [
          Shadow(
            color: Colors.black45,
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFFE0ECE4),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Logo composed of a rising sun arc and natural herbal leaves
class _SunLeavesLogo extends StatelessWidget {
  const _SunLeavesLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFAF8F2).withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163A29).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.72, size * 0.72),
          painter: _LogoPainter(),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Rising Sun Arch
    final sunCenter = Offset(w * 0.5, h * 0.44);
    final sunRadius = w * 0.28;

    final sunGradient = const RadialGradient(
      colors: [Color(0xFFFBE4A8), Color(0xFFE89D38)],
    ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));

    final sunPaint = Paint()
      ..shader = sunGradient
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: sunCenter, radius: sunRadius),
      3.14159,
      3.14159,
      true,
      sunPaint,
    );

    // Sun corona halo ring
    final haloPaint = Paint()
      ..color = const Color(0xFFECAE4B).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawArc(
      Rect.fromCircle(center: sunCenter, radius: sunRadius + 5),
      3.14159 + 0.2,
      3.14159 - 0.4,
      false,
      haloPaint,
    );

    // 2. Left Leaf
    final leftLeafPath = Path();
    leftLeafPath.moveTo(w * 0.5, h * 0.88);
    leftLeafPath.cubicTo(
      w * 0.18,
      h * 0.76,
      w * 0.12,
      h * 0.46,
      w * 0.36,
      h * 0.36,
    );
    leftLeafPath.cubicTo(
      w * 0.42,
      h * 0.52,
      w * 0.46,
      h * 0.72,
      w * 0.5,
      h * 0.88,
    );
    leftLeafPath.close();

    final leftLeafPaint = Paint()
      ..color = const Color(0xFF1E523A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftLeafPath, leftLeafPaint);

    // 3. Right Leaf
    final rightLeafPath = Path();
    rightLeafPath.moveTo(w * 0.5, h * 0.88);
    rightLeafPath.cubicTo(
      w * 0.54,
      h * 0.72,
      w * 0.58,
      h * 0.52,
      w * 0.64,
      h * 0.36,
    );
    rightLeafPath.cubicTo(
      w * 0.88,
      h * 0.46,
      w * 0.82,
      h * 0.76,
      w * 0.5,
      h * 0.88,
    );
    rightLeafPath.close();

    final rightLeafPaint = Paint()
      ..color = const Color(0xFF2C6D4F)
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightLeafPath, rightLeafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle gentle breathing dots
class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.25;
            final progress = (_controller.value + delay) % 1.0;
            final opacity = 0.35 + (progress * 0.65);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD4E5DB).withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
