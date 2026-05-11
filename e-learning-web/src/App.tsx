import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import { lazy, Suspense, useEffect, useState, useMemo } from 'react';
import { useDispatch } from 'react-redux';
import type { AppDispatch } from './store/store';
import { setAuthState, updateUser } from './store/authSlice';
import { authApi } from './services/authApi';
import { loadAuth, saveAuth, clearAuth } from './services/authStorage';
import { profileApi } from './services/profileApi';

// Layouts
import AdminLayout from './components/admin/AdminLayout';
import AuthLayout from './components/layout/AuthLayout';
import RootLayout from './components/layout/RootLayout';
import UserLayout from './components/layout/UserLayout';

// Core
import ProtectedRoute from './components/ProtectedRoute';
import RouteErrorFallback from './components/common/RouteErrorFallback';
import ToastContainer from './components/ui/Toast/ToastContainer';
import { ToastProvider } from './contexts/ToastContext';
import { NotificationProvider } from './context/NotificationContext';
import { Toaster } from 'react-hot-toast';

// Lazy Loaded Pages - Auth
const LoginPage = lazy(() => import('./pages/auth/LoginPage'));
const RegisterPage = lazy(() => import('./pages/auth/RegisterPage'));
const ForgotPasswordPage = lazy(() => import('./pages/auth/ForgotPasswordPage'));
const OtpVerifyPage = lazy(() => import('./pages/auth/OtpVerifyPage'));
const PhoneOtpVerifyPage = lazy(() => import('./pages/auth/PhoneOtpVerifyPage'));

// Lazy Loaded Pages - Admin
const AdminDashboardPage = lazy(() => import('./pages/admin/dashboard/AdminDashboardPage'));
const CoursesPage = lazy(() => import('./pages/admin/course/CoursesPage'));
const LessonsPage = lazy(() => import('./pages/admin/lesson/LessonsPage'));
const LessonDetailPage = lazy(() => import('./pages/admin/lesson/LessonDetailPage'));
const LessonPartDetailPage = lazy(() => import('./pages/admin/lesson/LessonPartDetailPage'));
const UsersPage = lazy(() => import('./pages/admin/user/UsersPage'));
const UserDetailPage = lazy(() => import('./pages/admin/user/UserDetailPage'));
const CourseDetailPage = lazy(() => import('./pages/admin/course/CourseDetailPage'));
const AdminSettingsPage = lazy(() => import('./pages/admin/settings/AdminSettingsPage'));
const InstructorsPage = lazy(() => import('./pages/admin/instructor/InstructorsPage'));
const InstructorDetailPage = lazy(() => import('./pages/admin/instructor/InstructorDetailPage'));
const AdminChatPage = lazy(() => import('./pages/admin/chat/AdminChatPage'));
const AdminNotificationPage = lazy(() => import('./pages/admin/notification/AdminNotificationPage'));
const AdminArticlesPage = lazy(() => import('./pages/admin/article/AdminArticlesPage'));
const AdminCategoriesPage = lazy(() => import('./pages/admin/article/AdminCategoriesPage'));
const ArticleEditorPage = lazy(() => import('./pages/admin/article/ArticleEditorPage'));
const AdminQuizPage = lazy(() => import('./pages/admin/quiz/AdminQuizPage'));
const AdminQuizEditorPage = lazy(() => import('./pages/admin/quiz/AdminQuizEditorPage'));
const AdminQuizSubmissionsPage = lazy(() => import('./pages/admin/quiz/AdminQuizSubmissionsPage'));
const AdminTestimonialsPage = lazy(() => import('./pages/admin/testimonials/AdminTestimonialsPage'));
const AdminTestimonialEditorPage = lazy(() => import('./pages/admin/testimonials/AdminTestimonialEditorPage'));
const AdminLessonCategoriesPage = lazy(() => import('./pages/admin/categories/AdminCategoriesPage'));
const AdminLessonCategoryEditorPage = lazy(() => import('./pages/admin/categories/AdminCategoryEditorPage'));
const AdminWhyChooseUsPage = lazy(() => import('./pages/admin/why-choose-us/AdminWhyChooseUsPage'));
const AdminWhyChooseUsEditorPage = lazy(() => import('./pages/admin/why-choose-us/AdminWhyChooseUsEditorPage'));
const AdminAiSettingsPage = lazy(() => import('./pages/admin/ai/AdminAiSettingsPage'));
const AdminWellnessSettingsPage = lazy(() => import('./pages/admin/wellness/AdminWellnessSettingsPage'));
const AdminForumCategoriesPage = lazy(() => import('./pages/admin/forum/AdminForumCategoriesPage'));
const AdminHomeSectionPage = lazy(() => import('./pages/admin/home-section/AdminHomeSectionPage'));
const AdminReferralsPage = lazy(() => import('./pages/admin/referrals/AdminReferralsPage'));
const AdminUserReferralsPage = lazy(() => import('./pages/admin/referrals/AdminUserReferralsPage.tsx'));
const AdminAgentsPage = lazy(() => import('./pages/admin/agents/AdminAgentsPage'));
const AdminLeadRegistrationsPage = lazy(() => import('./pages/admin/leads/AdminLeadRegistrationsPage'));

// Lazy Loaded Pages - Student/User
const HomePage = lazy(() => import('./pages/HomePage'));
const ProfilePage = lazy(() => import('./pages/ProfilePage'));
const StudentCoursesPage = lazy(() => import('./pages/CoursesPage'));
const StudentCourseDetailPage = lazy(() => import('./pages/StudentCourseDetailPage'));
const LearningPage = lazy(() => import('./pages/LearningPage'));
const ArticlesPage = lazy(() => import('./pages/ArticlesPage'));
const ArticleDetailPage = lazy(() => import('./pages/ArticleDetailPage'));
const TestimonialsPage = lazy(() => import('./pages/TestimonialsPage'));
const ForumPage = lazy(() => import('./pages/ForumPage'));
const ForumCategoryPage = lazy(() => import('./pages/ForumCategoryPage'));
const ForumThreadPage = lazy(() => import('./pages/ForumThreadPage'));
const NewThreadPage = lazy(() => import('./pages/NewThreadPage'));
const MyCoursesPage = lazy(() => import('./pages/MyCoursesPage'));
const MyLearningPlanPage = lazy(() => import('./pages/MyLearningPlanPage'));
const CheckoutPage = lazy(() => import('./pages/CheckoutPage'));
const PaymentResultPage = lazy(() => import('./pages/PaymentResultPage'));
const OrderHistoryPage = lazy(() => import('./pages/OrderHistoryPage'));
const PricingPage = lazy(() => import('./pages/PricingPage'));
const AmbassadorPage = lazy(() => import('./pages/AmbassadorPage'));
const Challenge10DayPage = lazy(() => import('./pages/Challenge10DayPage'));
const PrivacyPolicyPage = lazy(() => import('./pages/PrivacyPolicyPage'));
const ContactUsPage = lazy(() => import('./pages/ContactUsPage'));
const MissionVisionPage = lazy(() => import('./pages/MissionVisionPage'));

// Dashboards
const CareDashboardPage = lazy(() => import('./pages/care/CareDashboardPage'));
const AgentDashboardPage = lazy(() => import('./pages/agent/AgentDashboardPage'));
const LecturerDashboardPage = lazy(() => import('./pages/lecturer/LecturerDashboardPage'));

function App() {
  const dispatch = useDispatch<AppDispatch>();
  const [isInitializing, setIsInitializing] = useState(true);

  // Create router once - stable across re-renders
  const router = useMemo(
    () =>
      createBrowserRouter([
        {
          element: <RootLayout />,
          errorElement: <RouteErrorFallback />,
          children: [
            {
              element: <AuthLayout />,
              children: [
                {
                  path: 'login',
                  element: <LoginPage />,
                },
                {
                  path: 'login-phone',
                  element: <Navigate to="/login" replace />,
                },
                {
                  path: 'register',
                  element: <RegisterPage />,
                },
                {
                  path: 'register-phone',
                  element: <Navigate to="/register" replace />,
                },
                {
                  path: 'forgot-password',
                  element: <ForgotPasswordPage />,
                },
                {
                  path: 'otp-verify',
                  element: <OtpVerifyPage />,
                },
                {
                  path: 'otp-verify-phone',
                  element: <PhoneOtpVerifyPage />,
                },
              ],
            },
            {
              element: <UserLayout />,
              children: [
                {
                  path: '/',
                  element: <HomePage />,
                },
                {
                  path: 'home',
                  element: <Navigate to="/" replace />,
                },
                {
                  path: 'profile',
                  element: (
                    <ProtectedRoute>
                      <ProfilePage />
                    </ProtectedRoute>
                  ),
                },
                {
                  path: 'courses',
                  element: <StudentCoursesPage />,
                },
                {
                  path: 'courses/:id',
                  element: <StudentCourseDetailPage />,
                },
                {
                  path: 'pricing',
                  element: <PricingPage />,
                },
                {
                  path: 'ambassador',
                  element: <AmbassadorPage />,
                },
                {
                  path: 'challenge-10-days',
                  element: <Challenge10DayPage />,
                },
                {
                  path: 'privacy-policy',
                  element: <PrivacyPolicyPage />
                },
                {
                  path: 'contact',
                  element: <ContactUsPage />
                },
                {
                  path: 'mission-vision',
                  element: <MissionVisionPage />
                },
                {
                  path: 'my-courses',
                  element: (
                    <ProtectedRoute>
                      <MyCoursesPage />
                    </ProtectedRoute>
                  ),
                },
                {
                  path: 'my-learning-plan',
                  element: (
                    <ProtectedRoute>
                      <MyLearningPlanPage />
                    </ProtectedRoute>
                  ),
                },
                {
                  path: 'checkout',
                  element: (
                    <ProtectedRoute>
                      <CheckoutPage />
                    </ProtectedRoute>
                  ),
                },
                {
                  path: 'payment/result',
                  element: (
                    <ProtectedRoute>
                      <PaymentResultPage />
                    </ProtectedRoute>
                  ),
                },
                {
                  path: 'my-orders',
                  element: (
                    <ProtectedRoute>
                      <OrderHistoryPage />
                    </ProtectedRoute>
                  ),
                },
                {
                  path: 'articles',
                  element: <ArticlesPage />,
                },
                {
                  path: 'articles/:slug',
                  element: <ArticleDetailPage />,
                },
                {
                  path: 'testimonials',
                  element: <TestimonialsPage />,
                },
                {
                  path: 'forum',
                  element: <ForumPage />,
                },
                {
                  path: 'forum/category/:categoryId',
                  element: <ForumCategoryPage />,
                },
                {
                  path: 'forum/thread/:threadId',
                  element: <ForumThreadPage />,
                },
                {
                  path: 'forum/category/:categoryId/new-thread',
                  element: (
                    <ProtectedRoute>
                      <NewThreadPage />
                    </ProtectedRoute>
                  ),
                },
              ],
            },
            {
              path: 'courses/:id/learn',
              element: (
                <ProtectedRoute>
                  <LearningPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/courses/:id',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <CourseDetailPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/dashboard',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminDashboardPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/chat',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminChatPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/articles',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminArticlesPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/articles/new',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <ArticleEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/articles/:id/edit',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <ArticleEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/courses',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <CoursesPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/lessons',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <LessonsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/lessons/:id',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <LessonDetailPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/lessons/:lessonId/parts/:partId',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <LessonPartDetailPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/lessons/:lessonId/parts/new',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <LessonPartDetailPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/users',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <UsersPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/users/:id',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <UserDetailPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/profile',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminLayout>
                    <ProfilePage />
                  </AdminLayout>
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/settings',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminSettingsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/notifications',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminNotificationPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/categories',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminCategoriesPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/quizzes',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminQuizPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/quizzes/new',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminQuizEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/quizzes/:id',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminQuizEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/quizzes/:id/submissions',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminQuizSubmissionsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/testimonials',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminTestimonialsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/testimonials/new',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminTestimonialEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/testimonials/:id',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminTestimonialEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/lesson-categories',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminLessonCategoriesPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/lesson-categories/new',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminLessonCategoryEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/lesson-categories/:id',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminLessonCategoryEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/forum/categories',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminForumCategoriesPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/instructors',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <InstructorsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/instructors/:id',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <InstructorDetailPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/home-section',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminHomeSectionPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/referrals',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminReferralsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/user-referrals',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminUserReferralsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/agents',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminAgentsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/lead-registrations',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminLeadRegistrationsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/why-choose-us',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminWhyChooseUsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/why-choose-us/new',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminWhyChooseUsEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/why-choose-us/:id',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminWhyChooseUsEditorPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/ai-settings',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminAiSettingsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'admin/wellness-settings',
              element: (
                <ProtectedRoute requiredRole="ADMIN">
                  <AdminWellnessSettingsPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'care/dashboard',
              element: (
                <ProtectedRoute requiredRole="CARE">
                  <CareDashboardPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'agent/dashboard',
              element: (
                <ProtectedRoute requiredRole="CABIN_OWNER">
                  <AgentDashboardPage />
                </ProtectedRoute>
              ),
            },
            {
              path: 'lecturer/dashboard',
              element: (
                <ProtectedRoute requiredRole="LECTURER">
                  <LecturerDashboardPage />
                </ProtectedRoute>
              ),
            },
          ],
        },
      ]),
    []
  );

  // On app load, always try to refresh token using HTTP-only cookie
  useEffect(() => {
    const initAuth = async () => {
      const cached = loadAuth();
      if (cached && !authApi.isTokenExpired(cached.expiresAt)) {
        authApi.setAccessToken(cached.accessToken);
        dispatch(
          setAuthState({
            user: cached.user,
            accessToken: cached.accessToken,
            expiresAt: cached.expiresAt,
            isAuthenticated: true,
          })
        );
        setIsInitializing(false);
        return;
      }

      try {
        const response = await authApi.refreshToken();
        const user = authApi.decodeToken(response.accessToken);

        if (user) {
          authApi.setAccessToken(response.accessToken);
          dispatch(
            setAuthState({
              user,
              accessToken: response.accessToken,
              expiresAt: response.expiresAt,
              isAuthenticated: true,
            })
          );
          saveAuth({ user, accessToken: response.accessToken, expiresAt: response.expiresAt });

          try {
            const profile = await profileApi.getMyProfile();
            dispatch(
              updateUser({
                email: profile.email,
                fullName: profile.fullName || '',
                phone: profile.phone,
                avatarUrl: profile.avatarUrl,
                role: profile.role,
                id: profile.id,
              })
            );
          } catch (profileError) {
            console.error('Failed to load profile', profileError);
          }
        }
      } catch (error) {
        console.error('Failed to fetch user profile', error);
        authApi.setAccessToken(null);
        clearAuth();
      } finally {
        setIsInitializing(false);
      }
    };

    initAuth();
  }, [dispatch]);

  // Proactive silent refresh
  useEffect(() => {
    const REFRESH_INTERVAL = 13 * 60 * 1000;
    let refreshTimer: ReturnType<typeof setInterval>;

    const startRefreshTimer = () => {
      refreshTimer = setInterval(async () => {
        const token = authApi.getAccessToken();
        if (token) {
          try {
            const response = await authApi.refreshToken();
            authApi.setAccessToken(response.accessToken);
          } catch (error) {
            console.error('Proactive refresh failed', error);
          }
        }
      }, REFRESH_INTERVAL);
    };

    startRefreshTimer();

    return () => {
      if (refreshTimer) clearInterval(refreshTimer);
    };
  }, []);

  if (isInitializing) {
    return (
      <div className="flex items-center justify-center h-screen bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800">
        <div className="text-center">
          <div className="mb-4 flex justify-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
          </div>
          <p className="text-gray-600 dark:text-gray-400">Loading...</p>
        </div>
      </div>
    );
  }

  const loadingFallback = (
    <div className="flex items-center justify-center min-h-[400px]">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
    </div>
  );

  return (
    <ToastProvider>
      <NotificationProvider>
        <Suspense fallback={loadingFallback}>
          <RouterProvider router={router} />
        </Suspense>
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 3200,
            style: {
              borderRadius: '12px',
              fontSize: '13px',
            },
          }}
        />
        <ToastContainer />
      </NotificationProvider>
    </ToastProvider>
  );
}

export default App;
