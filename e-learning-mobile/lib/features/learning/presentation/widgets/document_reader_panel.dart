import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

final documentReaderBuilderProvider = Provider<DocumentReaderBuilder>(
  (ref) =>
      ({required url, required title}) =>
          DocumentReaderWebView(url: url, title: title),
);

typedef DocumentReaderBuilder =
    Widget Function({required Uri url, required String title});

class DocumentReaderPanel extends ConsumerWidget {
  const DocumentReaderPanel({required this.part, super.key});

  final LearningLessonPart part;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentUrl = part.documentUrl?.trim();
    final url = documentUrl == null ? null : Uri.tryParse(documentUrl);
    if (url == null || !_isSupportedDocumentUrl(url)) {
      return const _InvalidDocumentUrlCard();
    }

    final builder = ref.watch(documentReaderBuilderProvider);
    return builder(url: url, title: part.documentFileName ?? part.title);
  }
}

class DocumentReaderWebView extends StatefulWidget {
  const DocumentReaderWebView({
    required this.url,
    required this.title,
    super.key,
  });

  final Uri url;
  final String title;

  @override
  State<DocumentReaderWebView> createState() => _DocumentReaderWebViewState();
}

class _DocumentReaderWebViewState extends State<DocumentReaderWebView> {
  late final WebViewController _controller;
  var _isLoading = true;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AppErrorView(
        message: 'Không thể tải tài liệu. Vui lòng thử lại.',
        onRetry: () {
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
          _controller.reload();
        },
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: WebViewWidget(controller: _controller),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x99FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _InvalidDocumentUrlCard extends StatelessWidget {
  const _InvalidDocumentUrlCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Tài liệu chưa có đường dẫn hợp lệ. Vui lòng quay lại sau.',
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSupportedDocumentUrl(Uri uri) {
  return uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http');
}
