import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_avatar.dart';
import 'package:e_learning_mobile/shared/widgets/app_badge.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_empty_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_section_header.dart';
import 'package:e_learning_mobile/shared/widgets/app_skeleton.dart';
import 'package:e_learning_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

class ComponentsShowcaseScreen extends StatelessWidget {
  const ComponentsShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBarTitle: 'Components',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            title: 'Design foundation',
            subtitle: 'Shared visual components for app screens and states.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ShowcaseCard(
            title: 'Typography',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page title',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Section title',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Card title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Body text for educational content and descriptions.'),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Secondary body text for supporting details.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ShowcaseCard(
            title: 'Buttons',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                AppButton(label: 'Primary action'),
                SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Secondary action',
                  variant: AppButtonVariant.secondary,
                ),
                SizedBox(height: AppSpacing.sm),
                AppButton(label: 'Text action', variant: AppButtonVariant.text),
                SizedBox(height: AppSpacing.sm),
                AppButton(label: 'Loading', loading: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ShowcaseCard(
            title: 'Inputs',
            child: const Column(
              children: [
                AppTextField(
                  labelText: 'Email',
                  hintText: 'name@example.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                SizedBox(height: AppSpacing.md),
                AppTextField(
                  labelText: 'Password',
                  errorText: 'Example validation message.',
                  obscureText: true,
                  suffixIcon: Icon(Icons.visibility_off_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ShowcaseCard(
            title: 'Status and identity',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                AppAvatar(name: 'Nguyễn Văn'),
                AppBadge(label: 'Neutral'),
                AppBadge(label: 'Info', tone: AppBadgeTone.info),
                AppBadge(label: 'Success', tone: AppBadgeTone.success),
                AppBadge(label: 'Warning', tone: AppBadgeTone.warning),
                AppBadge(label: 'Error', tone: AppBadgeTone.error),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ShowcaseCard(
            title: 'States',
            child: const Column(
              children: [
                AppSkeleton(width: double.infinity, height: 16),
                SizedBox(height: AppSpacing.sm),
                AppSkeleton(width: 220, height: 16),
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 120,
                  child: AppLoadingView(label: 'Loading content'),
                ),
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 160,
                  child: AppErrorView(
                    message: 'Unable to load data right now.',
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 100,
                  child: AppEmptyView(message: 'No items available yet.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ShowcaseCard(
            title: 'Dark preview',
            child: Theme(
              data: AppTheme.dark(),
              child: const Material(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppBadge(label: 'Dark surface', tone: AppBadgeTone.info),
                      SizedBox(height: AppSpacing.sm),
                      AppButton(label: 'Dark button'),
                    ],
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

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
