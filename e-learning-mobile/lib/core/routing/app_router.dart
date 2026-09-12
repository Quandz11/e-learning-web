import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/forgot_password_verify_screen.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/app_shell.dart';
import 'package:e_learning_mobile/features/foundation/presentation/components_showcase_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/payment_cancel_placeholder_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/payment_return_placeholder_screen.dart';
import 'package:e_learning_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/course_detail_screen.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/document_reader_screen.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/lesson_screen.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/learning_screen.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/media_player_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/unknown_route_screen.dart';
import 'package:e_learning_mobile/features/profile/presentation/screens/change_password_screen.dart';
import 'package:e_learning_mobile/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:e_learning_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:e_learning_mobile/features/profile/presentation/screens/security_screen.dart';
import 'package:e_learning_mobile/features/personalization/presentation/screens/personalization_screen.dart';
import 'package:e_learning_mobile/features/personalization/presentation/screens/wellness_coach_screen.dart';
import 'package:e_learning_mobile/features/personalization/presentation/screens/wellness_plan_editor_screen.dart';
import 'package:e_learning_mobile/features/personalization/presentation/screens/wellness_progress_screen.dart';
import 'package:e_learning_mobile/features/personalization/presentation/screens/wellness_resources_screen.dart';
import 'package:e_learning_mobile/features/personalization/presentation/screens/reminder_list_screen.dart';
import 'package:e_learning_mobile/features/personalization/presentation/screens/reminder_editor_screen.dart';
import 'package:e_learning_mobile/features/articles/presentation/screens/article_detail_screen.dart';
import 'package:e_learning_mobile/features/articles/presentation/screens/articles_screen.dart';
import 'package:e_learning_mobile/features/chat/presentation/screens/support_chat_screen.dart';
import 'package:e_learning_mobile/features/forum/presentation/screens/create_thread_screen.dart';
import 'package:e_learning_mobile/features/forum/presentation/screens/forum_home_screen.dart';
import 'package:e_learning_mobile/features/forum/presentation/screens/forum_thread_detail_screen.dart';
import 'package:e_learning_mobile/features/notifications/presentation/screens/notification_inbox_screen.dart';
import 'package:e_learning_mobile/features/progress/presentation/screens/learning_progress_screen.dart';
import 'package:e_learning_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppRouterNotifier extends ChangeNotifier {
  AppRouterNotifier(this._ref) {
    _ref.listen<SessionState>(
      sessionControllerProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<AuthOtpChallenge?>(
      authOtpChallengeControllerProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<ForgotPasswordChallenge?>(
      forgotPasswordChallengeControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}

final appRouterNotifierProvider = Provider<AppRouterNotifier>((ref) {
  return AppRouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(appRouterNotifierProvider);
  final config = ref.watch(appConfigProvider);
  final deepLinks = DeepLinkConfig(config);

  return GoRouter(
    initialLocation: AppRoutes.appRoot,
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (_, state) => VerifyOtpScreen(
          initialChallenge: otpChallengeFromRouteState(state),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordVerify,
        builder: (_, state) => ForgotPasswordVerifyScreen(
          initialChallenge: forgotPasswordChallengeFromRouteState(state),
        ),
      ),
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.devComponents,
          builder: (_, __) => const ComponentsShowcaseScreen(),
        ),
      GoRoute(path: AppRoutes.appRoot, redirect: (_, __) => AppRoutes.appHome),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(currentLocation: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.appHome,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.appLearning,
            builder: (_, __) => const LearningScreen(),
            routes: [
              GoRoute(
                path: 'course/:courseId',
                builder: (_, state) => CourseDetailScreen(
                  courseId: state.pathParameters['courseId'] ?? '',
                ),
                routes: [
                  GoRoute(
                    path: 'lesson/:lessonPartId',
                    builder: (_, state) => LessonScreen(
                      courseId: state.pathParameters['courseId'] ?? '',
                      lessonPartId: state.pathParameters['lessonPartId'] ?? '',
                    ),
                    routes: [
                      GoRoute(
                        path: 'media',
                        builder: (_, state) => MediaPlayerScreen(
                          courseId: state.pathParameters['courseId'] ?? '',
                          lessonPartId:
                              state.pathParameters['lessonPartId'] ?? '',
                        ),
                      ),
                      GoRoute(
                        path: 'document',
                        builder: (_, state) => DocumentReaderScreen(
                          courseId: state.pathParameters['courseId'] ?? '',
                          lessonPartId:
                              state.pathParameters['lessonPartId'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.appPersonalization,
            builder: (_, __) => const PersonalizationScreen(),
            routes: [
              GoRoute(
                path: 'coach',
                builder: (_, __) => const WellnessCoachScreen(),
              ),
              GoRoute(
                path: 'plan-editor',
                builder: (_, __) => const WellnessPlanEditorScreen(),
              ),
              GoRoute(
                path: 'progress-timeline',
                builder: (_, __) => const WellnessProgressScreen(),
              ),
              GoRoute(
                path: 'resources',
                builder: (_, __) => const WellnessResourcesScreen(),
              ),
              GoRoute(
                path: 'reminders',
                builder: (_, __) => const ReminderListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const ReminderEditorScreen(),
                  ),
                  GoRoute(
                    path: ':reminderId/edit',
                    builder: (_, state) => ReminderEditorScreen(
                      reminderId: state.pathParameters['reminderId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.appProgress,
            builder: (_, __) => const LearningProgressScreen(),
          ),
          GoRoute(
            path: AppRoutes.appSettings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.appNotifications,
            builder: (_, __) => const NotificationInboxScreen(),
          ),
          GoRoute(
            path: AppRoutes.appArticles,
            builder: (_, __) => const ArticlesScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                builder: (_, state) => ArticleDetailScreen(
                  slug: state.pathParameters['slug'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.appCommunity,
            builder: (_, __) => const ForumHomeScreen(),
            routes: [
              GoRoute(
                path: 'threads/:threadId',
                builder: (_, state) => ForumThreadDetailScreen(
                  threadId: state.pathParameters['threadId'] ?? '',
                ),
              ),
              GoRoute(
                path: 'create-thread',
                builder: (_, state) => const CreateThreadScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.appChat,
            builder: (_, __) => const SupportChatScreen(),
          ),
          GoRoute(
            path: AppRoutes.appProfile,
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, __) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'change-password',
                builder: (_, __) => const ChangePasswordScreen(),
              ),
              GoRoute(
                path: 'security',
                builder: (_, __) => const SecurityScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.paymentReturn,
        builder: (_, state) => PaymentReturnPlaceholderScreen(uri: state.uri),
      ),
      GoRoute(
        path: AppRoutes.paymentCancel,
        builder: (_, state) => PaymentCancelPlaceholderScreen(uri: state.uri),
      ),
    ],
    errorBuilder: (_, state) => UnknownRouteScreen(uri: state.uri),
    redirect: (_, state) => appRedirect(
      sessionState: ref.read(sessionControllerProvider),
      otpChallenge: ref.read(authOtpChallengeControllerProvider),
      forgotPasswordChallenge: ref.read(
        forgotPasswordChallengeControllerProvider,
      ),
      deepLinks: deepLinks,
      uri: state.uri,
      matchedLocation: state.matchedLocation,
      extra: state.extra,
    ),
  );
});

String? appRedirect({
  required SessionState sessionState,
  required AuthOtpChallenge? otpChallenge,
  required ForgotPasswordChallenge? forgotPasswordChallenge,
  required DeepLinkConfig deepLinks,
  required Uri uri,
  required String matchedLocation,
  Object? extra,
}) {
  final mappedDeepLink = deepLinks.mapExternalUri(uri);
  final currentLocation = uri.path;
  if (mappedDeepLink != null && mappedDeepLink != currentLocation) {
    final query = uri.query;
    return query.isEmpty ? mappedDeepLink : '$mappedDeepLink?$query';
  }

  if (sessionState.isRestoring) {
    return null;
  }

  final isProtected = AppRoutes.isProtectedLocation(matchedLocation);
  final isPublicWelcome = matchedLocation == AppRoutes.welcome;
  final isLogin = matchedLocation == AppRoutes.login;
  final isRegister = matchedLocation == AppRoutes.register;
  final isVerifyOtp = matchedLocation == AppRoutes.verifyOtp;
  final isForgotPassword = matchedLocation == AppRoutes.forgotPassword;
  final isForgotPasswordVerify =
      matchedLocation == AppRoutes.forgotPasswordVerify;

  final challengeFromRoute = otpChallengeFromRoute(uri: uri, extra: extra);
  final activeOtpChallenge = otpChallenge ?? challengeFromRoute;
  final forgotPasswordRouteChallenge = forgotPasswordChallengeFromRoute(
    uri: uri,
    extra: extra,
  );
  final activeForgotPasswordChallenge =
      forgotPasswordChallenge ?? forgotPasswordRouteChallenge;

  if (!sessionState.isAuthenticated && isProtected) {
    final targetPath = uri.path == AppRoutes.appRoot
        ? AppRoutes.appHome
        : uri.path;
    final encoded = Uri.encodeComponent(
      targetPath + (uri.query.isEmpty ? '' : '?${uri.query}'),
    );
    return '${AppRoutes.login}?from=$encoded';
  }

  if (!sessionState.isAuthenticated &&
      isVerifyOtp &&
      activeOtpChallenge == null) {
    return AppRoutes.login;
  }

  if (!sessionState.isAuthenticated &&
      isForgotPasswordVerify &&
      activeForgotPasswordChallenge == null) {
    return AppRoutes.forgotPassword;
  }

  if (sessionState.isAuthenticated &&
      (isPublicWelcome ||
          isLogin ||
          isRegister ||
          isVerifyOtp ||
          isForgotPassword ||
          isForgotPasswordVerify)) {
    if (isLogin) {
      final from = AppRoutes.safeAuthenticatedRedirect(
        uri.queryParameters['from'],
      );
      if (from != null) {
        return from;
      }
    }
    if (isVerifyOtp) {
      return activeOtpChallenge?.redirectPath ?? AppRoutes.appHome;
    }
    return AppRoutes.appHome;
  }

  return null;
}

AuthOtpChallenge? otpChallengeFromRouteState(GoRouterState state) {
  return otpChallengeFromRoute(uri: state.uri, extra: state.extra);
}

AuthOtpChallenge? otpChallengeFromRoute({required Uri uri, Object? extra}) {
  final challengeFromExtra = extra is AuthOtpChallenge && extra.isValid
      ? extra
      : null;
  if (challengeFromExtra != null) {
    return challengeFromExtra;
  }

  final handoffType = uri.queryParameters['type']?.trim().toLowerCase();
  final email = uri.queryParameters['email']?.trim();
  if (handoffType == 'registration' && email != null && email.isNotEmpty) {
    final challenge = AuthOtpChallenge.registration(email: email);
    return challenge.isValid ? challenge : null;
  }

  return null;
}

ForgotPasswordChallenge? forgotPasswordChallengeFromRouteState(
  GoRouterState state,
) {
  return forgotPasswordChallengeFromRoute(uri: state.uri, extra: state.extra);
}

ForgotPasswordChallenge? forgotPasswordChallengeFromRoute({
  required Uri uri,
  Object? extra,
}) {
  final challengeFromExtra = extra is ForgotPasswordChallenge && extra.isValid
      ? extra
      : null;
  if (challengeFromExtra != null) {
    return challengeFromExtra;
  }

  return null;
}
