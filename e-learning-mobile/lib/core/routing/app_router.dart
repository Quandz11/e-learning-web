import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/chat_notification/presentation/pages/chat_notification_page.dart';
import '../../features/forum/presentation/pages/forum_page.dart';
import '../../features/learning/presentation/pages/courses_page.dart';
import '../../features/learning/presentation/pages/my_courses_page.dart';
import '../../features/payment/presentation/pages/checkout_page.dart';
import '../../features/payment/presentation/pages/orders_page.dart';
import '../../features/payment/presentation/pages/payment_result_page.dart';
import '../../features/referral/presentation/pages/referral_page.dart';
import '../../features/wellness_ai/presentation/pages/wellness_ai_page.dart';
import '../auth/session_controller.dart';
import '../auth/session_state.dart';
import '../../shared/constants/app_roles.dart';
import 'deep_link_mapper.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: false,
    redirect: (_, state) {
      final deepLinkRoute = mapExternalDeepLinkToRoute(state.uri);
      final currentLocation =
          state.uri.path +
          (state.uri.query.isEmpty ? '' : '?${state.uri.query}');
      if (deepLinkRoute != null && deepLinkRoute != currentLocation) {
        return deepLinkRoute;
      }

      final isAuthResolving = auth.maybeWhen(
        initial: () => true,
        loading: () => true,
        orElse: () => false,
      );

      if (isAuthResolving) {
        return null;
      }

      final isAuthed = auth.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final isStudent = auth.maybeWhen(
        authenticated: (session) =>
            session.user.role.toUpperCase() == AppRoles.student,
        orElse: () => false,
      );
      final isAuthRoute =
          state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register;

      if (!isAuthed && !isAuthRoute) {
        final fromLocation =
            state.uri.path +
            (state.uri.query.isEmpty ? '' : '?${state.uri.query}');
        final encodedFrom = Uri.encodeComponent(fromLocation);
        return '${RoutePaths.login}?from=$encodedFrom';
      }

      if (isAuthed && isAuthRoute) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          try {
            final decoded = Uri.decodeComponent(from);
            if (decoded.startsWith('/') &&
                decoded != RoutePaths.login &&
                decoded != RoutePaths.register) {
              return decoded;
            }
          } catch (_) {}
        }

        return RoutePaths.home;
      }

      if (isAuthed &&
          !isStudent &&
          state.matchedLocation != RoutePaths.profile) {
        return RoutePaths.profile;
      }

      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: RoutePaths.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(path: RoutePaths.home, builder: (_, __) => const HomePage()),
      GoRoute(
        path: RoutePaths.courses,
        builder: (_, __) => const CoursesPage(),
      ),
      GoRoute(
        path: RoutePaths.myCourses,
        builder: (_, __) => const MyCoursesPage(),
      ),
      GoRoute(
        path: RoutePaths.checkout,
        builder: (_, __) => const CheckoutPage(),
      ),
      GoRoute(path: RoutePaths.orders, builder: (_, __) => const OrdersPage()),
      GoRoute(
        path: RoutePaths.paymentResult,
        builder: (_, state) {
          final orderId = state.uri.queryParameters['orderId'];
          final orderCode = int.tryParse(
            state.uri.queryParameters['orderCode'] ?? '',
          );
          return PaymentResultPage(orderId: orderId, orderCode: orderCode);
        },
      ),
      GoRoute(path: RoutePaths.forum, builder: (_, __) => const ForumPage()),
      GoRoute(
        path: RoutePaths.referral,
        builder: (_, __) => const ReferralPage(),
      ),
      GoRoute(
        path: RoutePaths.wellnessAi,
        builder: (_, __) => const WellnessAiPage(),
      ),
      GoRoute(
        path: RoutePaths.chatNotification,
        builder: (_, __) => const ChatNotificationPage(),
      ),
      GoRoute(
        path: RoutePaths.profile,
        builder: (_, __) => const ProfilePage(),
      ),
    ],
  );
});
