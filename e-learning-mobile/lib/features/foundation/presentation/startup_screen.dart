import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  static const appName = 'SKVI Mobile';
  static const message = 'Preparing your learning space.';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Semantics(
                      container: true,
                      label: 'Starting $appName',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          _StartupMark(
                            foreground: colorScheme.primary,
                            background: colorScheme.primaryContainer,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            appName,
                            style: textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            message,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                children: [
                                  Semantics(
                                    label: 'Startup in progress',
                                    value: 'Loading',
                                    child: const SizedBox(
                                      width: AppSizes.controlHeight,
                                      height: AppSizes.controlHeight,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Starting the app',
                                          style: textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Checking configuration and restoring your session.',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
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
    );
  }
}

class _StartupMark extends StatelessWidget {
  const _StartupMark({required this.foreground, required this.background});

  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${StartupScreen.appName} app mark',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SizedBox(
          width: 96,
          height: 96,
          child: Icon(Icons.school_outlined, size: 48, color: foreground),
        ),
      ),
    );
  }
}
