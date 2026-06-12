import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useSelector } from 'react-redux';
import { Link, useNavigate } from 'react-router-dom';
import type { RootState } from '../../../store/store';
import type { WellnessCheckoutPackage } from '../../../services/wellnessApi';
import { useDailyPlanner } from '../../../hooks/useDailyPlanner';

const normalizePackageCode = (value?: string | null) => (value ?? '').trim().toUpperCase();
const toPackageLabel = (code: string) => normalizePackageCode(code).replace(/_/g, ' ');

const buildCheckoutPath = (packageCode: string) => {
  const params = new URLSearchParams();
  params.set('single', '1');
  params.set('source', 'wellness');
  params.set('wellnessPackage', normalizePackageCode(packageCode));
  return `/checkout?${params.toString()}`;
};

const PlannerSidebarLeft: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { user } = useSelector((state: RootState) => state.auth);
  const planner = useDailyPlanner();

  const name = user?.fullName?.trim() || user?.email || t('wellness.dashboard.defaults.userName');
  
  // Navigation steps logic
  const hasPlan = !!planner.wellnessPlan;
  const flowSteps = [
    {
      id: 'step-plan',
      title: t('wellness.dashboard.flow.steps.plan.title', { defaultValue: 'Lập kế hoạch' }),
      hint: t('wellness.dashboard.flow.steps.plan.hint', { defaultValue: 'Chọn gói, thời gian và khung giờ' }),
      done: hasPlan,
      targetId: 'wellness-plan-form',
    },
    {
      id: 'step-log',
      title: t('wellness.dashboard.flow.steps.log.title', { defaultValue: 'Nhật ký hôm nay' }),
      hint: t('wellness.dashboard.flow.steps.log.hint', { defaultValue: 'Ghi nước, vận động & tín hiệu' }),
      done: false,
      targetId: 'wellness-log-form',
    },
    {
      id: 'step-progress',
      title: t('wellness.dashboard.flow.steps.progress.title', { defaultValue: 'Xem tiến độ' }),
      hint: t('wellness.dashboard.flow.steps.progress.hint', { defaultValue: 'Theo dõi giai đoạn nhịn ăn' }),
      done: false,
      targetId: 'wellness-progress',
    },
  ];

  const scrollToId = (id: string) => {
    if (typeof document === 'undefined') return;
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  // Checkout packages calculation
  const checkoutConfig = planner.checkoutConfig;
  const checkoutCatalog = useMemo<WellnessCheckoutPackage[]>(() => {
    return (checkoutConfig?.packages ?? [])
      .map((pkg) => ({ ...pkg, code: normalizePackageCode(pkg.code) }))
      .filter((pkg) => Boolean(pkg.code))
      .sort((a, b) => a.sortOrder - b.sortOrder || a.durationDays - b.durationDays || a.code.localeCompare(b.code));
  }, [checkoutConfig?.packages]);

  const checkoutCatalogMap = useMemo(() => new Map(checkoutCatalog.map((pkg) => [pkg.code, pkg])), [checkoutCatalog]);
  const resolvePackageName = (code: string) => {
    const normalizedCode = normalizePackageCode(code);
    if (!normalizedCode) return '';
    const fromCatalog = checkoutCatalogMap.get(normalizedCode)?.name?.trim();
    return fromCatalog || t(`wellness.dashboard.packages.${normalizedCode}`, { defaultValue: toPackageLabel(normalizedCode) });
  };

  const access = planner.wellnessAccess;
  const checkoutPackages = useMemo(() => {
    const catalog = checkoutCatalog.map((pkg) => ({
      code: pkg.code,
      name: pkg.name?.trim() || resolvePackageName(pkg.code),
      priceVnd: pkg.priceVnd,
      durationDays: pkg.durationDays,
      isFeatured: pkg.isFeatured,
    }));

    if (access?.isUnlocked || !(access?.requiredPackages?.length)) return catalog;

    const required = Array.from(new Set((access?.requiredPackages ?? []).map(normalizePackageCode).filter(Boolean)));
    return required.map((code) => catalog.find((pkg) => pkg.code === code) || { code, name: resolvePackageName(code), durationDays: 0, isFeatured: false });
  }, [checkoutCatalog, access?.isUnlocked, access?.requiredPackages]);

  return (
    <div className="space-y-4 h-fit">
      {/* Profile Card */}
      <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-[0_2px_12px_-4px_rgba(0,0,0,0.06)] dark:border-slate-700/60 dark:bg-slate-800">
        <div className="text-[11px] font-bold uppercase tracking-widest text-slate-400 dark:text-slate-500 mb-4">
          WELLNESS
        </div>
        <div className="flex items-center gap-3">
          <div className="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-emerald-700 text-lg font-bold text-white shadow-md shadow-emerald-700/20">
            {name.charAt(0).toUpperCase()}
          </div>
          <div className="min-w-0">
            <div className="truncate text-base font-bold text-slate-900 dark:text-white leading-tight">
              {name}
            </div>
            <Link to="/profile" className="inline-flex items-center gap-1 text-sm font-semibold text-emerald-600 hover:text-emerald-700 transition-colors mt-0.5">
              <span className="material-symbols-outlined text-[16px]">person</span>
              {t('wellness.dashboard.viewProfile', { defaultValue: 'Xem hồ sơ' })}
            </Link>
          </div>
        </div>
      </div>

      {/* Steps Navigation */}
      <div className="rounded-3xl border border-slate-200 bg-white p-4 shadow-[0_2px_12px_-4px_rgba(0,0,0,0.06)] dark:border-slate-700/60 dark:bg-slate-800">
        <div className="grid gap-3">
          {flowSteps.map((step, index) => {
            const isDone = step.done;
            return (
              <button
                key={step.id}
                type="button"
                onClick={() => scrollToId(step.targetId)}
                className={`flex items-start gap-3 rounded-2xl border p-3 text-left transition-all ${
                  isDone 
                  ? 'border-emerald-200 bg-emerald-50/50 hover:bg-emerald-50 dark:border-emerald-900/50 dark:bg-emerald-900/20' 
                  : 'border-slate-100 bg-slate-50/50 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800/80'
                }`}
              >
                <div className={`grid h-6 w-6 shrink-0 place-items-center rounded-full text-[11px] font-black mt-0.5 ${
                  isDone 
                  ? 'bg-emerald-600 text-white shadow-sm' 
                  : 'bg-slate-200 text-slate-600 dark:bg-slate-700 dark:text-slate-300'
                }`}>
                  {isDone ? <span className="material-symbols-outlined text-[14px]">check</span> : index + 1}
                </div>
                <div className="min-w-0 leading-tight">
                  <div className="text-[13px] font-bold text-slate-900 dark:text-white mb-0.5">{step.title}</div>
                  <div className="text-[11px] text-slate-500 dark:text-slate-400">{step.hint}</div>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Upgrade Call To Action */}
      {checkoutPackages.length > 0 && (
        <div className="rounded-3xl border border-emerald-100 bg-emerald-50/40 p-5 dark:border-emerald-900/40 dark:bg-emerald-900/10">
          <div className="inline-flex items-center gap-2 text-sm font-bold text-emerald-800 dark:text-emerald-400 mb-2">
            <span className="material-symbols-outlined text-lg">workspace_premium</span>
            {t('wellness.dashboard.upgrade.title', { defaultValue: 'Nâng cấp gói' })}
          </div>
          <p className="text-[12px] text-emerald-900/70 dark:text-emerald-200/60 leading-relaxed mb-4 font-medium">
            {t('wellness.dashboard.upgrade.desc', { defaultValue: 'Thanh toán tự động qua checkout có sẵn.' })}
          </p>
          <div className="grid gap-2">
            {checkoutPackages.map((pkg) => (
              <button
                key={pkg.code}
                type="button"
                onClick={() => navigate(buildCheckoutPath(pkg.code))}
                className={`rounded-xl px-4 py-2.5 text-[13px] font-bold text-white shadow-sm transition-all focus:ring-2 focus:ring-offset-2 ${
                  pkg.isFeatured || pkg.code.includes('TRIAL')
                    ? 'bg-emerald-600 hover:bg-emerald-700 shadow-emerald-600/20 focus:ring-emerald-600'
                    : 'bg-slate-800 hover:bg-slate-900 shadow-slate-900/20 focus:ring-slate-900 dark:bg-slate-700 dark:hover:bg-slate-600'
                }`}
              >
                {pkg.name}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default PlannerSidebarLeft;
