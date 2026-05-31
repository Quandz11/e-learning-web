import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/models/course_models.dart';
import '../../data/repositories/learning_repository.dart';

class LearningPlayerPage extends ConsumerStatefulWidget {
  const LearningPlayerPage({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  ConsumerState<LearningPlayerPage> createState() => _LearningPlayerPageState();
}

class _LearningPlayerPageState extends ConsumerState<LearningPlayerPage> {
  String? _selectedPartId;
  LessonPartDto? _currentPart;
  Timer? _progressTimer;
  int _watchedDuration = 0;

  @override
  void initState() {
    super.initState();
    // In a real app, we might wait for the data to load before selecting the first part
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _selectPart(LessonPartDto part) {
    if (_selectedPartId == part.id) return;
    
    // Save progress of the current part before switching
    _saveProgress();

    setState(() {
      _selectedPartId = part.id;
      _currentPart = part;
      _watchedDuration = 0;
    });

    // Start a new timer for the newly selected part
    _progressTimer?.cancel();
    if (part.type.toLowerCase() == 'video') {
      _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _watchedDuration += 10;
        _saveProgress();
      });
    }
  }

  Future<void> _saveProgress() async {
    if (_selectedPartId == null || _watchedDuration == 0) return;
    try {
      await ref.read(learningRepositoryProvider).updateLessonProgress(
            courseId: widget.courseId,
            lessonPartId: _selectedPartId!,
            watchedDuration: _watchedDuration,
          );
      // We don't necessarily need to refresh the UI entirely for background saves
    } catch (_) {}
  }

  Future<void> _markAsComplete() async {
    if (_selectedPartId == null) return;
    try {
      await ref.read(learningRepositoryProvider).markLessonComplete(
            courseId: widget.courseId,
            lessonPartId: _selectedPartId!,
          );
      ref.invalidate(courseProgressProvider(widget.courseId));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã hoàn thành bài học!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (_) {}
  }

  String? _getYoutubeId(String url) {
    final regExp = RegExp(
        r'^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Widget _buildPlayerArea(bool isDark) {
    if (_currentPart == null) {
      return Container(
        height: 250,
        color: Colors.black,
        child: Center(
          child: Text(
            'Vui lòng chọn bài học ở bên dưới',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    }

    final part = _currentPart!;
    
    if (part.type.toLowerCase() == 'document') {
      final docUrl = part.documentUrl ?? '';
      final isPdf = docUrl.toLowerCase().endsWith('.pdf');
      
      // Render PDF using Google Docs Viewer if it's a PDF, otherwise just show a link or iframe
      final src = isPdf 
          ? 'https://docs.google.com/gview?embedded=true&url=$docUrl'
          : docUrl;

      return Container(
        height: 250,
        color: Colors.black,
        child: Opacity(
          opacity: 0.99,
          child: HtmlWidget(
            '<iframe src="$src" width="100%" height="100%" frameborder="0"></iframe>',
          ),
        ),
      );
    }

    // Video case
    final videoUrl = part.videoId ?? '';
    String? iframeSrc;

    // Check if it's youtube or bunny.
    // If it's bunny, the videoId here might be the full url or just the ID. 
    // Usually Bunny URL contains mediadelivery.
    if (videoUrl.contains('youtube') || videoUrl.contains('youtu.be')) {
      final ytId = _getYoutubeId(videoUrl);
      iframeSrc = 'https://www.youtube.com/embed/$ytId';
    } else {
      iframeSrc = videoUrl; // Fallback
    }

    return Container(
      height: 250,
      color: Colors.black,
      child: Opacity(
        opacity: 0.99,
        child: HtmlWidget(
          '<iframe src="$iframeSrc" width="100%" height="100%" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final progressAsync = ref.watch(courseProgressProvider(widget.courseId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Trình phát',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Because we pushed this view, we pop it.
            context.pop();
          },
        ),
      ),
      body: courseAsync.when(
        data: (course) {
          // Select first part automatically if nothing is selected
          if (_selectedPartId == null && course.lessons.isNotEmpty) {
            for (final lesson in course.lessons) {
              if (lesson.parts.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _selectPart(lesson.parts.first);
                });
                break;
              }
            }
          }

          return Column(
            children: [
              _buildPlayerArea(isDark),
              
              if (_selectedPartId != null)
                 Container(
                  padding: const EdgeInsets.all(16),
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentPart?.title ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _markAsComplete,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Hoàn thành'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                
              const Divider(height: 1),
              Expanded(
                child: progressAsync.when(
                  data: (progress) {
                    return ListView.builder(
                      itemCount: course.lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = course.lessons[index];
                        return ExpansionTile(
                          title: Text(
                            'Chương ${index + 1}: ${lesson.title}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textDark : AppColors.textLight,
                            ),
                          ),
                          initiallyExpanded: true,
                          iconColor: AppColors.primary,
                          children: lesson.parts.map((part) {
                            final isSelected = _selectedPartId == part.id;
                            
                            // Check if completed
                            final partProg = progress.partProgress.firstWhere(
                              (p) => p.lessonPartId == part.id,
                              orElse: () => LessonPartProgressModel(lessonPartId: part.id),
                            );
                            
                            return ListTile(
                              tileColor: isSelected 
                                ? AppColors.primary.withValues(alpha: 0.1) 
                                : null,
                              leading: Icon(
                                partProg.isCompleted
                                    ? Icons.check_circle
                                    : (part.type.toLowerCase() == 'video' 
                                        ? Icons.play_circle_outline 
                                        : Icons.article_outlined),
                                color: partProg.isCompleted
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                              ),
                              title: Text(
                                part.title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isSelected 
                                    ? AppColors.primary 
                                    : (isDark ? AppColors.textDark : AppColors.textLight),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              onTap: () => _selectPart(part),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Lỗi tải tiến độ')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
