import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import type { AppDispatch, RootState } from './store/store';
import AuthLayout from './components/layout/AuthLayout';
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import ForgotPasswordPage from './pages/auth/ForgotPasswordPage';
import OtpVerifyPage from './pages/auth/OtpVerifyPage';
import AdminDashboardPage from './pages/admin/AdminDashboardPage';
import ProtectedRoute from './components/ProtectedRoute';
import { setAuthState } from './store/authSlice';
import { authApi } from './services/authApi';

const router = createBrowserRouter([
  {
    path: '/',
    element: <Navigate to="/login" replace />,
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
    path: 'admin/dashboard',
    element: (
      <ProtectedRoute requiredRole="ADMIN">
        <AdminDashboardPage />
      </ProtectedRoute>
    ),
  },
]);

function App() {
  const dispatch = useDispatch<AppDispatch>();
  const { isAuthenticated } = useSelector((state: RootState) => state.auth);

  // Restore auth state from localStorage on app load
  useEffect(() => {
    const accessToken = localStorage.getItem('accessToken');
    const expiresAt = localStorage.getItem('expiresAt');

    if (accessToken && expiresAt && !isAuthenticated) {
      // Check if token is still valid
      if (!authApi.isTokenExpired(expiresAt)) {
        const user = authApi.decodeToken(accessToken);
        if (user) {
          dispatch(
            setAuthState({
              user,
              accessToken,
              expiresAt,
              isAuthenticated: true,
            })
          );
        }
      } else {
        // Token expired - try to refresh
        authApi
          .refreshToken()
          .then((response) => {
            const user = authApi.decodeToken(response.accessToken);
            if (user) {
              localStorage.setItem('accessToken', response.accessToken);
              localStorage.setItem('expiresAt', response.expiresAt);
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
            // Refresh failed - user needs to login again
            localStorage.removeItem('accessToken');
            localStorage.removeItem('expiresAt');
          });
      }
    }
  }, [dispatch, isAuthenticated]);

  return <RouterProvider router={router} />;
}

export default App;
