import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import { useEffect, useState, useMemo } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import type { AppDispatch, RootState } from './store/store';
import AuthLayout from './components/layout/AuthLayout';
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import ForgotPasswordPage from './pages/auth/ForgotPasswordPage';
import OtpVerifyPage from './pages/auth/OtpVerifyPage';
import AdminDashboardPage from './pages/admin/dashboard/AdminDashboardPage';
import CoursesPage from './pages/admin/course/CoursesPage';
import LessonsPage from './pages/admin/lesson/LessonsPage';
import LessonDetailPage from './pages/admin/lesson/LessonDetailPage';
import LessonPartDetailPage from './pages/admin/lesson/LessonPartDetailPage';
import ProtectedRoute from './components/ProtectedRoute';
import { setAuthState, updateUser } from './store/authSlice';
import { authApi } from './services/authApi';
import { loadAuth, saveAuth, clearAuth } from './services/authStorage';
import HomePage from './pages/HomePage';
import UsersPage from './pages/admin/user/UsersPage';
import UserDetailPage from './pages/admin/user/UserDetailPage';
import CourseDetailPage from './pages/admin/course/CourseDetailPage';
import AdminSettingsPage from './pages/admin/settings/AdminSettingsPage';
import InstructorsPage from './pages/admin/instructor/InstructorsPage';
import InstructorDetailPage from './pages/admin/instructor/InstructorDetailPage';
import AdminChatPage from './pages/admin/chat/AdminChatPage';
import ProfilePage from './pages/ProfilePage';
import StudentCoursesPage from './pages/CoursesPage';
import StudentCourseDetailPage from './pages/StudentCourseDetailPage';
import LearningPage from './pages/LearningPage';
import RootLayout from './components/layout/RootLayout';
import { profileApi } from './services/profileApi';
import { ToastProvider } from './contexts/ToastContext';
import ToastContainer from './components/ui/Toast/ToastContainer';
import { NotificationProvider } from './context/NotificationContext';
import AdminNotificationPage from './pages/admin/notification/AdminNotificationPage';

// Helper component to handle root path redirection
const RootRedirect = () => {
  const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);
  const role = user?.role?.toUpperCase();

  if (isAuthenticated) {
    return <Navigate to={role === 'ADMIN' ? '/admin/dashboard' : '/home'} replace />;
  }
  return <HomePage />;
};

function App() {
  const dispatch = useDispatch<AppDispatch>();
  const [isInitializing, setIsInitializing] = useState(true);

  // Create router once - stable across re-renders
  const router = useMemo(
    () =>
      createBrowserRouter([
        {
          element: <RootLayout />,
          children: [
            {
              path: '/',
              element: <RootRedirect />,
            },
            {
              element: <AuthLayout />,
              children: [
                {
                  path: 'login',
                  element: <LoginPage />,
                },
                {
                  path: 'register',
                  element: <RegisterPage />,
                },
                {
                  path: 'forgot-password',
                  element: <ForgotPasswordPage />,
                },
                {
                  path: 'otp-verify',
                  element: <OtpVerifyPage />,
                },
              ],
            },
            {
              path: 'home',
              element: (
                <ProtectedRoute>
                  <HomePage />
                </ProtectedRoute>
              ),
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
          ]
        }
      ]),
    []
  );

  // On app load, always try to refresh token using HTTP-only cookie
  useEffect(() => {
    const initAuth = async () => {
      // 1) Try to restore from localStorage quickly (non-expired access token)
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
    const REFRESH_INTERVAL = 13 * 60 * 1000; // 13 minutes
    let refreshTimer: ReturnType<typeof setInterval>;

    const startRefreshTimer = () => {
      refreshTimer = setInterval(async () => {
        const token = authApi.getAccessToken();
        if (token) {
          try {
            console.log('Proactive token refresh...');
            const response = await authApi.refreshToken();
            authApi.setAccessToken(response.accessToken);
            // Optionally update Redux if needed, though memory token is most critical for api calls
          } catch (error) {
            console.error('Proactive refresh failed', error);
            // If proactive refresh fails, we might let the interceptor handle it next time
            // or clear auth if it's a hard failure (like 401 on refresh).
            // For now, allow interceptor to catch it later.
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

  return (
    <ToastProvider>
      <NotificationProvider>
        <RouterProvider router={router} />
        <ToastContainer />
      </NotificationProvider>
    </ToastProvider>
  );
}

export default App;
