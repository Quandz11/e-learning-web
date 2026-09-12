import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Hills/Forest Artwork
          const Positioned.fill(child: _WelcomeBackgroundDecoration()),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),

                            // Brand Logo Image
                            Image.asset(
                              'assets/images/app_logo.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                                      : AppColors.primaryLight.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.spa_rounded,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Tagline / Slogan
                            Text(
                              'Lắng nghe để chữa lành',
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: isDark ? colorScheme.onSurface : AppColors.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                fontSize: 20,
                              ),
                            ),
                            const Spacer(flex: 2),

                            // Dot Indicators (3 dots, 1st active)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isDark ? colorScheme.outlineVariant : AppColors.border,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isDark ? colorScheme.outlineVariant : AppColors.border,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Primary CTA: Bắt đầu
                            AppButton(
                              buttonKey: const Key('welcome_start_button'),
                              label: 'Bắt đầu',
                              onPressed: () => context.go(AppRoutes.appHome),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Secondary Link: Đã có tài khoản? Đăng nhập
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Đã có tài khoản? ',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary(),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.login),
                                  child: Text(
                                    'Đăng nhập',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: isDark ? colorScheme.onSurface : AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackgroundDecoration extends StatelessWidget {
  const _WelcomeBackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WelcomePainter());
  }
}

class _WelcomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFFEDF7F0).withValues(alpha: 0.6);
    final hillPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.35);
    final forestPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08);

    // Top soft glow
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      120,
      bgPaint,
    );

    // Bottom Hills
    final hillPath = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.65,
        size.width * 0.6,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.78,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(hillPath, hillPaint);

    final forestPath = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.76,
        size.width * 0.75,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.88,
        size.width,
        size.height * 0.82,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(forestPath, forestPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
