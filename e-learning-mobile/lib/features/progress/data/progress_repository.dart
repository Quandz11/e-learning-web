import 'package:e_learning_mobile/features/progress/data/models/progress_models.dart';
import 'package:e_learning_mobile/features/progress/data/progress_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(api: ref.read(progressApiProvider));
});

class ProgressRepository {
  const ProgressRepository({required ProgressApi api}) : _api = api;

  final ProgressApi _api;

  Future<LearningProgressSummary> getProgressSummary() => _api.getProgressSummary();
}
