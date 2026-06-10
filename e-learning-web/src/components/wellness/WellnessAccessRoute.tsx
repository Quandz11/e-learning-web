import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { wellnessApi, type WellnessDashboard } from '../../services/wellnessApi';
import { extractErrorMessage } from '../../utils/errorHandler';

interface WellnessAccessRouteProps {
  children: React.ReactNode;
}

const WellnessAccessRoute: React.FC<WellnessAccessRouteProps> = ({ children }) => {
  const location = useLocation();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dashboard, setDashboard] = useState<WellnessDashboard | null>(null);
  const returnTo = useMemo(
    () => `${location.pathname}${location.search}${location.hash}`,
    [location.hash, location.pathname, location.search],
  );

  const loadAccess = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const response = await wellnessApi.getDashboard();
      setDashboard(response);
    } catch (err: unknown) {
      setError(extractErrorMessage(err) || 'Không thể kiểm tra quyền truy cập Wellness.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadAccess();
  }, [loadAccess]);

  if (loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center px-4">
        <div className="rounded-3xl border border-slate-200 bg-white px-8 py-10 text-center shadow-sm dark:border-slate-700 dark:bg-slate-800">
          <div className="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-4 border-emerald-500 border-t-transparent" />
          <p className="text-sm font-semibold text-slate-600 dark:text-slate-300">
            Đang kiểm tra quyền truy cập Wellness...
          </p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center px-4">
        <div className="max-w-md rounded-3xl border border-red-200 bg-white p-8 text-center shadow-sm dark:border-red-900/50 dark:bg-slate-800">
          <span className="material-symbols-outlined text-5xl text-red-500">error</span>
          <h2 className="mt-4 text-xl font-bold text-slate-900 dark:text-white">
            Không thể kiểm tra quyền truy cập
          </h2>
          <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{error}</p>
          <button
            type="button"
            onClick={() => void loadAccess()}
            className="mt-6 inline-flex items-center rounded-full bg-emerald-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-emerald-700"
          >
            Thử lại
          </button>
        </div>
      </div>
    );
  }

  if (!dashboard?.access?.isUnlocked) {
    const params = new URLSearchParams();
    params.set('returnTo', returnTo);
    return <Navigate to={`/wellness-upgrade?${params.toString()}`} replace />;
  }

  return <>{children}</>;
};

export default WellnessAccessRoute;
