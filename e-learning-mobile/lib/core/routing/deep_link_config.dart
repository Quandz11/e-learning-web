import 'package:e_learning_mobile/core/config/app_config.dart';

class DeepLinkConfig {
  const DeepLinkConfig(this.config);

  final AppConfig config;

  static const supportedHosts = {'nhinanchualanh.vn', 'www.nhinanchualanh.vn'};
  static const supportedSchemes = {'skvi', 'skvi-dev', 'skvi-staging'};

  String? mapExternalUri(Uri uri) {
    if (_matchesExact(uri, config.paymentReturnUrl)) {
      return AppRoutes.paymentReturn;
    }
    if (_matchesExact(uri, config.paymentCancelUrl)) {
      return AppRoutes.paymentCancel;
    }

    if (_isPaymentReturnAlias(uri)) {
      return AppRoutes.paymentReturn;
    }

    return null;
  }

  bool _matchesExact(Uri incoming, Uri configured) {
    return incoming.scheme == configured.scheme &&
        incoming.host == configured.host &&
        incoming.path == configured.path;
  }

  bool _isPaymentReturnAlias(Uri uri) {
    if (uri.scheme == 'https' &&
        supportedHosts.contains(uri.host.toLowerCase())) {
      return uri.path == '/payment/result' || uri.path == '/payment-result';
    }

    if (supportedSchemes.contains(uri.scheme)) {
      final path = uri.path.isEmpty ? '/${uri.host}' : uri.path;
      return path == '/payment/result' || path == '/payment-result';
    }

    return false;
  }
}

abstract final class AppRoutes {
  static const devComponents = '/dev/components';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const verifyOtp = '/verify-otp';
  static const forgotPassword = '/forgot-password';
  static const forgotPasswordVerify = '/forgot-password/verify';
  static const appRoot = '/app';
  static const appHome = '/app/home';
  static const appLearning = '/app/learning';
  static const appCourses = '/app/courses';
  static const appLearningCoursePattern = '/app/learning/course/:courseId';
  static const appLearningLessonPattern =
      '/app/learning/course/:courseId/lesson/:lessonPartId';
  static const appLearningMediaPattern =
      '/app/learning/course/:courseId/lesson/:lessonPartId/media';
  static const appLearningDocumentPattern =
      '/app/learning/course/:courseId/lesson/:lessonPartId/document';
  static const appPersonalization = '/app/personalization';
  static const appPersonalizationCoach = '/app/personalization/coach';
  static const appPersonalizationPlanEditor = '/app/personalization/plan-editor';
  static const appPersonalizationProgressTimeline = '/app/personalization/progress-timeline';
  static const appPersonalizationResources = '/app/personalization/resources';
  static const appPersonalizationReminders = '/app/personalization/reminders';
  static const appPersonalizationReminderNew =
      '/app/personalization/reminders/new';
  static const appPersonalizationReminderEditPattern =
      '/app/personalization/reminders/:reminderId/edit';
  static const appProgress = '/app/progress';
  static const appSettings = '/app/settings';
  static const appCommunity = '/app/community';
  static const appProfile = '/app/profile';
  static const appProfileEdit = '/app/profile/edit';
  static const appProfileChangePassword = '/app/profile/change-password';
  static const appProfileSecurity = '/app/profile/security';
  static const appProfileAchievements = '/app/profile/achievements';
  static const appProfileHistory = '/app/profile/history';
  static const protectedHome = appRoot;
  static const paymentReturn = '/payment-return';
  static const paymentCancel = '/payment-cancel';

  static const shellDestinations = <String>[
    appHome,
    appLearning,
    appPersonalization,
    appProfile,
  ];

  static String courseDetailPath(String courseId) {
    return '/app/learning/course/${Uri.encodeComponent(courseId)}';
  }

  static String lessonPath({
    required String courseId,
    required String lessonPartId,
  }) {
    return '/app/learning/course/${Uri.encodeComponent(courseId)}/lesson/${Uri.encodeComponent(lessonPartId)}';
  }

  static String mediaPlayerPath({
    required String courseId,
    required String lessonPartId,
  }) {
    return '${lessonPath(courseId: courseId, lessonPartId: lessonPartId)}/media';
  }

  static String documentReaderPath({
    required String courseId,
    required String lessonPartId,
  }) {
    return '${lessonPath(courseId: courseId, lessonPartId: lessonPartId)}/document';
  }

  static String reminderEditPath(String reminderId) {
    return '/app/personalization/reminders/${Uri.encodeComponent(reminderId)}/edit';
  }

  static String shellDestinationForLocation(String location) {
    if (location == appProfile || location.startsWith('$appProfile/')) {
      return appProfile;
    }
    if (location == appPersonalization ||
        location.startsWith('$appPersonalization/')) {
      return appPersonalization;
    }
    if (location == appLearning ||
        location.startsWith('$appLearning/') ||
        location == appCourses ||
        location.startsWith('$appCourses/')) {
      return appLearning;
    }
    return appHome;
  }

  static bool isProtectedLocation(String matchedLocation) {
    return matchedLocation == appRoot ||
        matchedLocation.startsWith('$appRoot/');
  }

  static String? safeAuthenticatedRedirect(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = Uri.decodeComponent(raw).trim();
    if (!decoded.startsWith('/app') || decoded.startsWith('//')) {
      return null;
    }

    final uri = Uri.tryParse(decoded);
    if (uri == null || uri.hasScheme) {
      return null;
    }

    return decoded;
  }
}
