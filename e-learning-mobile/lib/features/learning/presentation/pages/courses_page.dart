import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/repositories/learning_repository.dart';

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(learningRepositoryProvider);

    return AppScaffold(
      title: 'Courses',
      child: FutureBuilder(
        future: repository.getCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load courses: ${snapshot.error}'),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No courses found.'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final course = items[index];
              return ListTile(
                title: Text(course.title),
                subtitle: Text(course.isFree ? 'Free' : '${course.price} VND'),
              );
            },
          );
        },
      ),
    );
  }
}
