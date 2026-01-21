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
import ProtectedRoute from './components/ProtectedRoute';
import { setAuthState } from './store/authSlice';
import { authApi } from './services/authApi';
import HomePage from './pages/HomePage';
import UsersPage from './pages/admin/user/UsersPage';
import UserDetailPage from './pages/admin/user/UserDetailPage';
import CourseDetailPage from './pages/admin/course/CourseDetailPage';
import AdminSettingsPage from './pages/admin/settings/AdminSettingsPage';
import InstructorsPage from './pages/admin/instructor/InstructorsPage';
import InstructorDetailPage from './pages/admin/instructor/InstructorDetailPage';
import ProfilePage from './pages/ProfilePage';

function App() {
  const dispatch = useDispatch<AppDispatch>();
  const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);
  const [isInitializing, setIsInitializing] = useState(true);

  const role = user?.role?.toUpperCase();

  // Create router dynamically - re-create when isAuthenticated changes  
  const router = useMemo(
    () =>
      createBrowserRouter([
        {
          path: '/',
          element: isAuthenticated ? (
            <Navigate
              to={role === 'ADMIN' ? '/admin/dashboard' : '/home'}
              replace
            />
          ) : (
            <Navigate to="/login" replace />
          ),
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
          path: 'admin/courses',
          element: (
            <ProtectedRoute requiredRole="ADMIN">
              <CoursesPage />
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
      ]),
    [isAuthenticated, role]
  );

  // On app load, always try to refresh token using HTTP-only cookie
  useEffect(() => {


    authApi
      .refreshToken()
      .then((response) => {
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
        }
      })
      .catch(() => {
        console.error('Failed to fetch user profile');
        authApi.setAccessToken(null);
      })
      .finally(() => {
        setIsInitializing(false);
      });
  }, [dispatch]);

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

  return <RouterProvider router={router} />;
}

export default App;
