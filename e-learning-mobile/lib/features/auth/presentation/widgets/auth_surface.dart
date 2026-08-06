import 'dart:math' as math;

import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AuthSurface extends StatelessWidget {
  const AuthSurface({required this.child, super.key, this.leading});

  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.035),
      colorScheme.surface,
    );

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: ExcludeSemantics(
              child: _AuthDecorations(colorScheme: colorScheme),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - AppSpacing.sm,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (leading != null) ...[
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: leading!,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                              child,
                            ],
                          ),
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

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        const AuthBrandMark(),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 58,
        backgroundColor: colorScheme.surface,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.spa_rounded,
              size: 54,
              color: colorScheme.primary.withValues(alpha: 0.55),
            ),
            Transform.translate(
              offset: const Offset(4, 8),
              child: Icon(
                Icons.eco_rounded,
                size: 58,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({
    required this.title,
    required this.subtitle,
    super.key,
    this.centered = false,
  });

  final String title;
  final String subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: textAlign,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: textAlign,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class AuthMessageCard extends StatelessWidget {
  const AuthMessageCard({
    required this.message,
    super.key,
    this.isError = true,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isError ? colorScheme.error : colorScheme.primary;
    final background = isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    return Semantics(
      liveRegion: true,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: foreground,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
    super.key,
    this.buttonKey,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback? onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            prompt,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          key: buttonKey,
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSizes.controlHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: 'Quay lại',
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
    );
  }
}

class _AuthDecorations extends StatelessWidget {
  const _AuthDecorations({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -36,
          left: -48,
          right: -48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
            child: const SizedBox(height: 220),
          ),
        ),
        Positioned(
          left: -28,
          top: 120,
          child: _LeafCluster(
            color: colorScheme.primary.withValues(alpha: 0.14),
            size: 126,
            angle: -0.35,
          ),
        ),
        Positioned(
          right: -12,
          top: 88,
          child: _LeafCluster(
            color: colorScheme.primary.withValues(alpha: 0.16),
            size: 96,
            angle: 0.42,
          ),
        ),
        Positioned(
          right: -20,
          bottom: 72,
          child: _LeafCluster(
            color: colorScheme.primary.withValues(alpha: 0.14),
            size: 104,
            angle: 0.25,
          ),
        ),
        Positioned(
          left: -16,
          bottom: -8,
          right: -16,
          child: SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _HillPainter(
                baseColor: colorScheme.primary.withValues(alpha: 0.12),
                accentColor: colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeafCluster extends StatelessWidget {
  const _LeafCluster({
    required this.color,
    required this.size,
    required this.angle,
  });

  final Color color;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Icon(Icons.spa_rounded, color: color, size: size),
    );
  }
}

class _HillPainter extends CustomPainter {
  const _HillPainter({required this.baseColor, required this.accentColor});

  final Color baseColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = baseColor;
    final accentPaint = Paint()..color = accentColor;

    final basePath = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.32,
        size.width * 0.48,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.84,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final accentPath = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.58,
        size.width * 0.58,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.94,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(basePath, basePaint);
    canvas.drawPath(accentPath, accentPaint);

    final sunPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.white.withValues(alpha: 0.82), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.18),
              radius: math.max(size.width, size.height) * 0.28,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.18),
      math.max(size.width, size.height) * 0.28,
      sunPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HillPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor;
  }
}
