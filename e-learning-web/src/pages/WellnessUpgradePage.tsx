import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { wellnessApi, type WellnessDashboard, type WellnessCheckoutPackage } from '../services/wellnessApi';
import { extractErrorMessage } from '../utils/errorHandler';

const normalizePackageCode = (value?: string | null) => (value ?? '').trim().toUpperCase();

const buildCheckoutPath = (packageCode: string, returnTo: string) => {
  const params = new URLSearchParams();
  params.set('single', '1');
  params.set('source', 'wellness');
  params.set('wellnessPackage', normalizePackageCode(packageCode));
  params.set('returnTo', returnTo);
  return `/checkout?${params.toString()}`;
};

const WellnessUpgradePage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const locale = i18n.resolvedLanguage?.startsWith('vi') ? 'vi-VN' : 'en-US';
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dashboard, setDashboard] = useState<WellnessDashboard | null>(null);
  const searchParams = useMemo(() => new URLSearchParams(location.search), [location.search]);
  const returnTo = searchParams.get('returnTo') || '/my-learning-plan';

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const response = await wellnessApi.getDashboard();
      setDashboard(response);
    } catch (err: unknown) {
      setError(extractErrorMessage(err) || 'Không thể tải thông tin gói Wellness.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  const packages = useMemo<WellnessCheckoutPackage[]>(
    () =>
      [...(dashboard?.checkoutConfig?.packages ?? [])].sort(
        (a, b) => a.sortOrder - b.sortOrder || a.durationDays - b.durationDays || a.code.localeCompare(b.code),
      ),
    [dashboard?.checkoutConfig?.packages],
  );

  const formatCurrency = (value: number) =>
    `${Number(value || 0).toLocaleString(locale)} ${t('payments.common.currency')}`;

  if (!loading && dashboard?.access?.isUnlocked) {
    return <Navigate to={returnTo} replace />;
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-emerald-50 via-white to-white px-4 py-10 dark:from-slate-900 dark:via-slate-950 dark:to-slate-950">
      <div className="mx-auto max-w-5xl">
        <div className="mx-auto max-w-3xl text-center">
          <div className="inline-flex items-center rounded-full bg-emerald-100 px-4 py-1 text-xs font-bold uppercase tracking-[0.2em] text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-200">
            Wellness Access
          </div>
          <h1 className="mt-5 text-4xl font-black text-slate-900 dark:text-white">
            Cần có gói Wellness để mở lộ trình cá nhân hóa
          </h1>
          <p className="mt-4 text-base text-slate-600 dark:text-slate-300">
            Trang lộ trình học của anh chỉ mở khi tài khoản đang có một gói Wellness còn hiệu lực.
          </p>
          {!loading && dashboard?.access?.message && (
            <div className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 px-5 py-4 text-sm text-amber-800 dark:border-amber-900/40 dark:bg-amber-900/20 dark:text-amber-200">
              {dashboard.access.message}
            </div>
          )}
        </div>

        {loading ? (
          <div className="mt-12 flex items-center justify-center">
            <div className="rounded-3xl border border-slate-200 bg-white px-8 py-10 text-center shadow-sm dark:border-slate-700 dark:bg-slate-800">
              <div className="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-4 border-emerald-500 border-t-transparent" />
              <p className="text-sm font-semibold text-slate-600 dark:text-slate-300">Đang tải các gói Wellness...</p>
            </div>
          </div>
        ) : error ? (
          <div className="mx-auto mt-12 max-w-xl rounded-3xl border border-red-200 bg-white p-8 text-center shadow-sm dark:border-red-900/50 dark:bg-slate-800">
            <span className="material-symbols-outlined text-5xl text-red-500">error</span>
            <h2 className="mt-4 text-2xl font-bold text-slate-900 dark:text-white">Không tải được dữ liệu Wellness</h2>
            <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{error}</p>
            <button
              type="button"
              onClick={() => void loadData()}
              className="mt-6 inline-flex items-center rounded-full bg-emerald-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-emerald-700"
            >
              Thử lại
            </button>
          </div>
        ) : packages.length === 0 ? (
          <div className="mx-auto mt-12 max-w-xl rounded-3xl border border-slate-200 bg-white p-8 text-center shadow-sm dark:border-slate-700 dark:bg-slate-800">
            <span className="material-symbols-outlined text-5xl text-slate-400 dark:text-slate-500">inventory_2</span>
            <h2 className="mt-4 text-2xl font-bold text-slate-900 dark:text-white">Chưa có gói Wellness khả dụng</h2>
            <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">
              Hiện chưa có gói nào đang mở bán. Anh vui lòng liên hệ hỗ trợ để được kích hoạt hoặc cấu hình gói.
            </p>
            <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
              <Link
                to="/contact"
                className="inline-flex items-center rounded-full bg-emerald-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-emerald-700"
              >
                Liên hệ hỗ trợ
              </Link>
              <button
                type="button"
                onClick={() => navigate(-1)}
                className="inline-flex items-center rounded-full border border-slate-300 px-5 py-2.5 text-sm font-semibold text-slate-700 hover:border-slate-400 dark:border-slate-600 dark:text-slate-200"
              >
                Quay lại
              </button>
            </div>
          </div>
        ) : (
          <>
            <div className="mt-12 grid gap-6 md:grid-cols-2 xl:grid-cols-3">
              {packages.map((pkg) => (
                <div
                  key={pkg.code}
                  className={`rounded-3xl border bg-white p-6 shadow-sm dark:bg-slate-800 ${
                    pkg.isFeatured
                      ? 'border-emerald-300 shadow-emerald-100 dark:border-emerald-700'
                      : 'border-slate-200 dark:border-slate-700'
                  }`}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <h3 className="text-2xl font-black text-slate-900 dark:text-white">{pkg.name}</h3>
                      <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{pkg.description}</p>
                    </div>
                    {pkg.isFeatured && (
                      <span className="rounded-full bg-emerald-100 px-3 py-1 text-[11px] font-bold uppercase tracking-[0.15em] text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-200">
                        Phù hợp
                      </span>
                    )}
                  </div>

                  <div className="mt-6 space-y-2">
                    <p className="text-3xl font-black text-slate-900 dark:text-white">{formatCurrency(pkg.priceVnd)}</p>
                    <p className="text-sm text-slate-500 dark:text-slate-400">Thời hạn {pkg.durationDays} ngày</p>
                  </div>

                  <Link
                    to={buildCheckoutPath(pkg.code, returnTo)}
                    className="mt-6 inline-flex w-full items-center justify-center rounded-2xl bg-emerald-600 px-4 py-3 text-sm font-semibold text-white hover:bg-emerald-700"
                  >
                    Mua gói này
                  </Link>
                </div>
              ))}
            </div>

            <div className="mt-10 flex flex-wrap items-center justify-center gap-3">
              <button
                type="button"
                onClick={() => navigate(-1)}
                className="inline-flex items-center rounded-full border border-slate-300 px-5 py-2.5 text-sm font-semibold text-slate-700 hover:border-slate-400 dark:border-slate-600 dark:text-slate-200"
              >
                Quay lại trang trước
              </button>
              <Link
                to="/"
                className="inline-flex items-center rounded-full border border-emerald-300 px-5 py-2.5 text-sm font-semibold text-emerald-700 hover:border-emerald-400 dark:border-emerald-700 dark:text-emerald-200"
              >
                Về trang chủ
              </Link>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default WellnessUpgradePage;
