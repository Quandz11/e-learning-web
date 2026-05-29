import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/repositories/learning_repository.dart';

class MyCoursesPage extends ConsumerWidget {
  const MyCoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(learningRepositoryProvider);

    return AppScaffold(
      title: 'My courses',
      child: FutureBuilder(
        future: repository.getMyCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load enrollments: ${snapshot.error}'),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('You have not enrolled in any course yet.'),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index) {
              final enrollment = items[index];
              return ListTile(
                title: Text(enrollment['courseTitle']?.toString() ?? 'Unknown'),
                subtitle: Text(
                  'Progress: ${enrollment['progressPercentage'] ?? 0}%',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
