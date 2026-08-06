import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/home/data/home_api.dart';
import 'package:e_learning_mobile/features/home/data/home_repository.dart';
import 'package:e_learning_mobile/features/home/data/models/home_models.dart';

class FakeHomeRepository extends HomeRepository {
  FakeHomeRepository({this.result, this.error, this.onLoad})
    : super(api: _UnusedHomeApi());

  final HomeLoadResult? result;
  final AppFailure? error;
  final Future<HomeLoadResult> Function()? onLoad;
  int loadCallCount = 0;

  @override
  Future<HomeLoadResult> loadHome() async {
    loadCallCount += 1;
    if (onLoad != null) {
      return onLoad!();
    }
    if (error != null) {
      throw error!;
    }
    return result ?? fakeHomeLoadResult();
  }
}

HomeLoadResult fakeHomeLoadResult({
  List<HomeCourse>? featuredCourses,
  HomeEnrollment? continueLearning,
  List<HomeCategory>? categories,
  List<HomeArticle>? articles,
  List<HomeTestimonial>? testimonials,
  HomeSectionIssue? enrollmentIssue,
  HomeSectionIssue? categoryIssue,
  HomeSectionIssue? articleIssue,
  HomeSectionIssue? testimonialIssue,
}) {
  return HomeLoadResult(
    featuredCourses:
        featuredCourses ??
        [
          HomeCourse(
            id: 'course-1',
            title: 'Nhập môn nhịn ăn chữa lành',
            price: 1200000,
            isFree: false,
            isPublished: true,
            createdAt: DateTime.utc(2026, 1, 1),
            instructorName: 'Giảng viên An',
            thumbnailUrl: null,
          ),
          HomeCourse(
            id: 'course-2',
            title: 'Bắt đầu sống khỏe mỗi ngày',
            price: 0,
            isFree: true,
            isPublished: true,
            createdAt: DateTime.utc(2026, 1, 2),
            instructorName: 'Giảng viên Bình',
            thumbnailUrl: null,
          ),
        ],
    continueLearning:
        continueLearning ??
        HomeEnrollment(
          id: 'enrollment-1',
          courseId: 'course-1',
          courseTitle: 'Nhập môn nhịn ăn chữa lành',
          courseThumbnail: null,
          enrolledAt: DateTime.utc(2026, 1, 1),
          progressPercentage: 60,
          completedAt: null,
          lastAccessedAt: DateTime.utc(2026, 1, 5),
          accessDurationDays: 30,
          accessExpiresAt: DateTime.utc(2026, 2, 1),
          isExpired: false,
          status: 'ACTIVE',
        ),
    categories:
        categories ??
        const [
          HomeCategory(
            id: 'category-1',
            name: 'Dinh dưỡng',
            description: null,
            order: 1,
            isActive: true,
          ),
          HomeCategory(
            id: 'category-2',
            name: 'Lối sống',
            description: null,
            order: 2,
            isActive: true,
          ),
        ],
    articles:
        articles ??
        [
          HomeArticle(
            id: 'article-1',
            title: 'Khởi động thói quen lành mạnh',
            slug: 'khoi-dong-thoi-quen-lanh-manh',
            excerpt: 'Mẹo bắt đầu hành trình chăm sóc sức khỏe.',
            featuredImageUrl: null,
            categoryName: 'Kiến thức',
            isPublished: true,
            publishedAt: DateTime.utc(2026, 1, 3),
            createdAt: DateTime.utc(2026, 1, 2),
          ),
        ],
    testimonials:
        testimonials ??
        const [
          HomeTestimonial(
            id: 'testimonial-1',
            name: 'Mai Lan',
            content: 'Lộ trình học rõ ràng và dễ theo dõi.',
            order: 1,
            position: 'Học viên',
            avatarUrl: null,
          ),
        ],
    enrollmentIssue: enrollmentIssue,
    categoryIssue: categoryIssue,
    articleIssue: articleIssue,
    testimonialIssue: testimonialIssue,
  );
}

class _UnusedHomeApi extends HomeApi {
  _UnusedHomeApi()
    : super(
        apiClient: ApiClient(Dio()),
        errorMapper: const DioErrorMapper(),
        apiBaseUrl: Uri.parse('https://api.example.com/api'),
      );
}
