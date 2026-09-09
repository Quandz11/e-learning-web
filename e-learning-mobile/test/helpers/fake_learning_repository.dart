import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/learning/data/learning_api.dart';
import 'package:e_learning_mobile/features/learning/data/learning_repository.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';

class FakeLearningRepository extends LearningRepository {
  FakeLearningRepository({this.result, this.error, this.onLoad})
    : super(api: _UnusedLearningApi());

  final LearningLoadResult? result;
  final AppFailure? error;
  final Future<LearningLoadResult> Function()? onLoad;
  int loadCallCount = 0;

  @override
  Future<LearningLoadResult?> loadLearningFromCache() async => null;

  @override
  Future<LearningLoadResult> loadLearning() async {
    loadCallCount += 1;
    if (onLoad != null) {
      return onLoad!();
    }
    if (error != null) {
      throw error!;
    }
    return result ?? fakeLearningLoadResult();
  }
}

LearningLoadResult fakeLearningLoadResult({
  List<LearningCourse>? courses,
  List<LearningEnrollment>? enrollments,
  List<LearningCategory>? categories,
  LearningSectionIssue? enrollmentIssue,
  LearningSectionIssue? categoryIssue,
}) {
  return LearningLoadResult(
    courses:
        courses ??
        [
          LearningCourse(
            id: 'course-1',
            title: 'Nhập môn nhịn ăn chữa lành',
            description: '<p>Nền tảng cho hành trình học tập bền vững.</p>',
            price: 0,
            isFree: true,
            isPublished: true,
            createdAt: DateTime.utc(2026, 1),
            learningOutcomes: const ['Hiểu nguyên tắc cơ bản'],
            instructorName: 'Giảng viên An',
            thumbnailUrl: null,
            defaultAccessDurationDays: null,
          ),
          LearningCourse(
            id: 'course-2',
            title: 'Thực hành sống khỏe mỗi ngày',
            description: null,
            price: 1200000,
            isFree: false,
            isPublished: true,
            createdAt: DateTime.utc(2026, 2),
            learningOutcomes: const [],
            instructorName: 'Giảng viên Bình',
            thumbnailUrl: null,
            defaultAccessDurationDays: 30,
          ),
        ],
    enrollments:
        enrollments ??
        [
          LearningEnrollment(
            id: 'enrollment-1',
            courseId: 'course-1',
            courseTitle: 'Nhập môn nhịn ăn chữa lành',
            courseThumbnail: null,
            enrolledAt: DateTime.utc(2026, 1),
            progressPercentage: 60,
            completedAt: null,
            lastAccessedAt: DateTime.utc(2026, 1, 5),
            accessDurationDays: 30,
            accessExpiresAt: DateTime.utc(2026, 2),
            isExpired: false,
            status: 'ACTIVE',
          ),
        ],
    categories:
        categories ??
        [
          LearningCategory(
            id: 'category-1',
            name: 'Dinh dưỡng',
            description: null,
            order: 1,
            isActive: true,
            createdAt: DateTime.utc(2026, 1),
          ),
          LearningCategory(
            id: 'category-2',
            name: 'Lối sống',
            description: null,
            order: 2,
            isActive: true,
            createdAt: DateTime.utc(2026, 1, 2),
          ),
        ],
    enrollmentIssue: enrollmentIssue,
    categoryIssue: categoryIssue,
  );
}

class _UnusedLearningApi extends LearningApi {
  _UnusedLearningApi()
    : super(
        apiClient: ApiClient(Dio()),
        errorMapper: const DioErrorMapper(),
        apiBaseUrl: Uri.parse('https://api.example.com/api'),
      );
}
