import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/course_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_skeleton.dart';

import '../../data/repositories/learning_repository.dart';

class CoursesPage extends ConsumerStatefulWidget {
  const CoursesPage({super.key});

  @override
  ConsumerState<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends ConsumerState<CoursesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all'; // all | free | paid

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncCourses = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Khóa học'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm khóa học...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Tất cả',
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Miễn phí',
                        selected: _filter == 'free',
                        onTap: () => setState(() => _filter = 'free'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Trả phí',
                        selected: _filter == 'paid',
                        onTap: () => setState(() => _filter = 'paid'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: asyncCourses.when(
        loading: () => _buildSkeleton(),
        error: (error, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          message: 'Không thể tải khóa học.\nVui lòng thử lại.',
          actionLabel: 'Thử lại',
          onAction: () => ref.refresh(coursesProvider),
        ),
        data: (data) {
          var courses = data;

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            courses = courses
                .where((c) => c.title.toLowerCase().contains(_searchQuery))
                .toList();
          }

          // Apply free/paid filter
          if (_filter == 'free') {
            courses = courses.where((c) => c.isFree).toList();
          } else if (_filter == 'paid') {
            courses = courses.where((c) => !c.isFree).toList();
          }

          if (courses.isEmpty) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              message: 'Không tìm thấy khóa học phù hợp.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: courses.length,
            itemBuilder: (_, index) {
              final course = courses[index];
              return CourseCard(
                title: course.title,
                isFree: course.isFree,
                price: course.price,
                thumbnailUrl: course.thumbnailUrl,
                onTap: () => context.push(RoutePaths.courseDetailPath(course.id)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const CourseCardSkeleton(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? Colors.white
                : (isDark ? AppColors.textDark : AppColors.textLight),
          ),
        ),
      ),
    );
  }
}
