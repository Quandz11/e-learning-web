import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

final documentReaderBuilderProvider = Provider<DocumentReaderBuilder>(
  (ref) =>
      ({required url, required title}) =>
          DocumentReaderPdfViewer(url: url, title: title),
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

class DocumentReaderPdfViewer extends StatefulWidget {
  const DocumentReaderPdfViewer({
    required this.url,
    required this.title,
    this.controller,
    this.onDocumentLoaded,
    this.onPageChanged,
    super.key,
  });

  final Uri url;
  final String title;
  final PdfViewerController? controller;
  final void Function(PdfDocumentLoadedDetails details)? onDocumentLoaded;
  final void Function(PdfPageChangedDetails details)? onPageChanged;

  @override
  State<DocumentReaderPdfViewer> createState() =>
      _DocumentReaderPdfViewerState();
}

class _DocumentReaderPdfViewerState extends State<DocumentReaderPdfViewer> {
  var _isLoading = true;
  String? _errorMessage;
  var _reloadToken = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return AppErrorView(
        message: 'Không thể tải tài liệu. Vui lòng thử lại.',
        onRetry: _reload,
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 520,
          child: Stack(
            children: [
              KeyedSubtree(
                key: ValueKey(_reloadToken),
                child: SfPdfViewer.network(
                  widget.url.toString(),
                  controller: widget.controller,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  enableDoubleTapZooming: true,
                  pageLayoutMode: PdfPageLayoutMode.continuous,
                  onPageChanged: widget.onPageChanged,
                  onDocumentLoaded: (details) {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _errorMessage = null;
                      });
                    }
                    widget.onDocumentLoaded?.call(details);
                  },
                  onDocumentLoadFailed: (details) {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _errorMessage = details.description;
                      });
                    }
                  },
                ),
              ),
              if (_isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x99FFFFFF),
                    child: AppLoadingView(label: 'Đang tải tài liệu...'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _reloadToken += 1;
    });
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
