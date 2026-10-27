import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/data/running_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final runningRepositoryProvider = Provider<RunningRepository>((ref) {
  return RunningRepository(api: ref.read(runningApiProvider));
});

class RunningRepository {
  RunningRepository({required RunningApi api}) : _api = api;

  final RunningApi _api;

  Future<RunningSummary> getSummary() => _api.getSummary();

  Future<({List<RunningActivity> items, int totalCount})> getActivities({
    int page = 1,
    int pageSize = 20,
    int? month,
    int? year,
  }) => _api.getActivities(page: page, pageSize: pageSize, month: month, year: year);

  Future<RunningActivity> createActivity(CreateRunningActivityDto dto) =>
      _api.createActivity(dto);

  Future<bool> deleteActivity(String id) => _api.deleteActivity(id);
}
