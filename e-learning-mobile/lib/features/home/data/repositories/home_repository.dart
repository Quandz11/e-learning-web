import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../models/home_models.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.read(apiClientProvider));
});

final homeSectionProvider = FutureProvider.autoDispose<HomeVideoSectionModel?>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  try {
    return await repository.getHomeSection();
  } catch (e) {
    return null;
  }
});

final whyChooseUsProvider = FutureProvider.autoDispose<List<WhyChooseUsModel>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  try {
    return await repository.getWhyChooseUs();
  } catch (e) {
    return [];
  }
});

class HomeRepository {
  HomeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<HomeVideoSectionModel> getHomeSection() async {
    final data = await _apiClient.get<Map<String, dynamic>>('/HomeSection');
    return HomeVideoSectionModel.fromJson(data);
  }

  Future<List<WhyChooseUsModel>> getWhyChooseUs() async {
    final data = await _apiClient.get<List<dynamic>>('/why-choose-us/active');
    return data
        .whereType<Map<String, dynamic>>()
        .map(WhyChooseUsModel.fromJson)
        .toList();
  }
}
