import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.child,
    super.key,
    this.appBarTitle,
    this.scrollable = true,
    this.includeScaffold = true,
    this.maxContentWidth = AppSizes.contentMaxWidth,
    this.padding = AppSpacing.pagePadding,
  });

  final Widget child;
  final String? appBarTitle;
  final bool scrollable;
  final bool includeScaffold;
  final double maxContentWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget content = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: maxContentWidth,
                ),
                child: Padding(padding: padding, child: child),
              ),
            );

            if (scrollable) {
              content = SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: content,
              );
            }

            return content;
          },
        ),
      ),
    );

    if (!includeScaffold) {
      return body;
    }

    return Scaffold(
      appBar: appBarTitle == null ? null : AppBar(title: Text(appBarTitle!)),
      body: body,
    );
  }
}
