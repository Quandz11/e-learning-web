import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useDailyPlanner } from '../../hooks/useDailyPlanner';
import { toast } from 'react-hot-toast';
import { extractErrorMessage } from '../../utils/errorHandler';

const inputLabelClassName = 'text-[11px] font-bold uppercase tracking-[0.08em] text-slate-500 mb-1.5 block dark:text-slate-400';
const inputClassName = 'w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm transition-colors focus:border-emerald-400 focus:bg-white focus:outline-none focus:ring-1 focus:ring-emerald-400 dark:border-slate-700 dark:bg-slate-900/50 dark:focus:border-emerald-500 dark:focus:ring-emerald-500 dark:text-white';

const PlannerPlanSetupCard: React.FC = () => {
  const { t } = useTranslation();
  const planner = useDailyPlanner();

  // State initialization 
  const plan = planner.wellnessPlan;
  const access = planner.wellnessAccess;
  const checkoutConfig = planner.checkoutConfig;

  const [packageType, setPackageType] = useState(plan?.packageType ?? access?.currentPackage ?? '');
  
  const getLocalDateString = (d: Date) => {
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };

  const [startDate, setStartDate] = useState(plan?.startDate?.split('T')[0] ?? getLocalDateString(new Date()));
  const [endDate, setEndDate] = useState(plan?.endDate?.split('T')[0] ?? getLocalDateString(new Date(Date.now() + 30 * 86400000)));
  const [fastingHours, setFastingHours] = useState(plan?.fastingHours ?? 16);
  const [eatingHours, setEatingHours] = useState(plan?.eatingHours ?? 8);
  
  const defaultFastStart = plan ? `${String(Math.floor(plan.dailyFastStartMinuteOfDay / 60)).padStart(2, '0')}:${String(plan.dailyFastStartMinuteOfDay % 60).padStart(2, '0')}` : '20:00';
  const [fastStart, setFastStart] = useState(defaultFastStart);
  
  const [startWeight, setStartWeight] = useState(plan?.startWeightKg?.toString() ?? '');
  const [targetWeight, setTargetWeight] = useState(plan?.targetWeightKg?.toString() ?? '');
  const [timezone, setTimezone] = useState(plan?.timezone ?? Intl.DateTimeFormat().resolvedOptions().timeZone);
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isExpanded, setIsExpanded] = useState(!plan); // Expanded by default if no plan exists

  const availablePackages = useMemo(() => {
    const catalog = checkoutConfig?.packages || [];
    const allowedCodes = new Set((access?.allowedPackages ?? []).map((code) => code.trim().toUpperCase()));

    if (allowedCodes.size === 0) {
      return catalog;
    }

    const allowedOnly = catalog.filter((pkg) => allowedCodes.has(pkg.code.trim().toUpperCase()));
    return allowedOnly.length > 0 ? allowedOnly : catalog;
  }, [access?.allowedPackages, checkoutConfig?.packages]);

  useEffect(() => {
    if (availablePackages.length === 0) {
      return;
    }

    const normalizedSelected = packageType.trim().toUpperCase();
    const hasSelected = availablePackages.some((pkg) => pkg.code.trim().toUpperCase() === normalizedSelected);
    if (hasSelected) {
      return;
    }

    const preferredCode = (access?.currentPackage || plan?.packageType || availablePackages[0].code).trim().toUpperCase();
    const preferredPackage = availablePackages.find((pkg) => pkg.code.trim().toUpperCase() === preferredCode);
    setPackageType(preferredPackage?.code || availablePackages[0].code);
  }, [access?.currentPackage, availablePackages, packageType, plan?.packageType]);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    const toastId = toast.loading(t('wellness.dashboard.status.savingPlan', { defaultValue: 'Đang lưu kế hoạch...' }));
    
    try {
      const [hours, minutes] = fastStart.split(':').map(Number);
      const dailyFastStartMinuteOfDay = hours * 60 + minutes;

      await planner.saveWellnessPlan({
        packageType,
        startDate: new Date(startDate).toISOString(),
        endDate: new Date(endDate).toISOString(),
        fastingHours,
        eatingHours,
        dailyFastStartMinuteOfDay,
        startWeightKg: startWeight ? Number(startWeight) : 0,
        targetWeightKg: targetWeight ? Number(targetWeight) : 0,
        timezone,
      });
      toast.success(t('wellness.dashboard.success.savePlan', { defaultValue: 'Cập nhật lịch trình thành công!' }), { id: toastId });
      if (plan) setIsExpanded(false);
    } catch (error: unknown) {
      toast.error(extractErrorMessage(error) || t('common.error'), { id: toastId });
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isExpanded && plan) {
    return (
      <div id="wellness-plan-form" className="rounded-3xl border border-slate-200 bg-white p-5 cursor-pointer hover:bg-slate-50 transition-colors shadow-sm dark:border-slate-700/60 dark:bg-slate-800 dark:hover:bg-slate-800/80" onClick={() => setIsExpanded(true)}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="grid h-10 w-10 place-items-center rounded-xl bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-500">
              <span className="material-symbols-outlined">tune</span>
            </div>
            <div>
              <div className="text-sm font-bold text-slate-900 dark:text-white">{t('wellness.dashboard.setup.title', { defaultValue: 'Hồ sơ sức khỏe (Wellness Plan)' })}</div>
              <div className="text-xs text-slate-500 dark:text-slate-400">
                {t('wellness.dashboard.setup.summary', { fastingHours, eatingHours, startDate, endDate, defaultValue: `Lịch nhịn ăn ${fastingHours}:${eatingHours} • Từ ${startDate} đến ${endDate}` })}
              </div>
            </div>
          </div>
          <button className="text-slate-400 hover:text-emerald-600 dark:text-slate-500 dark:hover:text-emerald-400 bg-slate-100 hover:bg-emerald-50 dark:bg-slate-700 dark:hover:bg-emerald-900/30 p-2 rounded-full transition-all flex items-center justify-center">
            <span className="material-symbols-outlined text-[20px]">edit</span>
          </button>
        </div>
      </div>
    );
  }

  return (
    <div id="wellness-plan-form" className="rounded-3xl border border-emerald-200 bg-white dark:border-slate-700/60 dark:bg-slate-800 overflow-hidden shadow-sm">
      <div className="bg-emerald-50/50 p-5 border-b border-emerald-100 flex items-center justify-between dark:bg-emerald-900/10 dark:border-slate-700">
        <div className="inline-flex items-center gap-2 text-[15px] font-bold text-emerald-900 dark:text-emerald-400">
          <span className="material-symbols-outlined text-lg">health_metrics</span>
          {t('wellness.dashboard.setup.configTitle', { defaultValue: 'Cấu hình Kế Hoạch Wellness' })}
        </div>
        {plan && (
           <button onClick={() => setIsExpanded(false)} className="text-slate-400 hover:text-slate-600 dark:text-slate-500 dark:hover:text-slate-300 transition-colors flex items-center">
             <span className="material-symbols-outlined">keyboard_arrow_up</span>
           </button>
        )}
      </div>

      <form onSubmit={handleSave} className="p-5 space-y-4">
        {!plan && (
          <p className="text-sm text-slate-600 dark:text-slate-400 mb-4 bg-orange-50 dark:bg-orange-900/20 text-orange-800 dark:text-orange-300 p-3 rounded-xl border border-orange-100 dark:border-orange-900/50 flex gap-2">
            <span className="material-symbols-outlined text-[18px]">info</span>
            {t('wellness.dashboard.setup.hint', { defaultValue: 'Hãy thiết lập chi tiết gói của bạn để bắt đầu tính toán lịch theo dõi nhé.' })}
          </p>
        )}
        
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.setup.package', { defaultValue: 'Gói theo dõi' })}</span>
            <select aria-label="Gói" value={packageType} onChange={(event) => setPackageType(event.target.value)} className={inputClassName}>
              <option value="" disabled>{t('wellness.dashboard.setup.selectPlaceholder', { defaultValue: '-- Chọn --' })}</option>
              {availablePackages.map((pkg) => (
                 <option key={pkg.code} value={pkg.code}>{pkg.name}</option>
              ))}
              {/* Fallback in case packageType is arbitrary set from server */}
              {packageType && !availablePackages.some(p => p.code === packageType) && (
                 <option value={packageType}>{packageType}</option>
              )}
            </select>
          </label>
          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.form.startDate', { defaultValue: 'Ngày bắt đầu' })}</span>
            <input type="date" required value={startDate} onChange={(event) => setStartDate(event.target.value)} className={inputClassName} />
          </label>
          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.form.endDate', { defaultValue: 'Ngày kết thúc' })}</span>
            <input type="date" required value={endDate} onChange={(event) => setEndDate(event.target.value)} className={inputClassName} />
          </label>

          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.form.fastingHours', { defaultValue: 'Giờ nhịn (Fasting)' })}</span>
            <input type="number" required min={12} max={24} value={fastingHours} onChange={(event) => setFastingHours(Number(event.target.value))} className={inputClassName} />
          </label>
          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.form.eatingHours', { defaultValue: 'Giờ ăn (Eating)' })}</span>
            <input type="number" required min={1} max={12} value={eatingHours} onChange={(event) => setEatingHours(Number(event.target.value))} className={inputClassName} />
          </label>
          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.form.fastStart', { defaultValue: 'Bắt đầu nhịn lúc' })}</span>
            <input type="time" required value={fastStart} onChange={(event) => setFastStart(event.target.value)} className={inputClassName} />
          </label>

          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.form.startWeight', { defaultValue: 'Cân nặng hiện tại (kg)' })}</span>
            <input type="number" step="0.1" placeholder="VD: 65.5" value={startWeight} onChange={(event) => setStartWeight(event.target.value)} className={inputClassName} />
          </label>
          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.form.targetWeight', { defaultValue: 'Cân nặng mục tiêu (kg)' })}</span>
            <input type="number" step="0.1" placeholder="VD: 60" value={targetWeight} onChange={(event) => setTargetWeight(event.target.value)} className={inputClassName} />
          </label>
          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.form.timezone', { defaultValue: 'Múi giờ' })}</span>
            <input value={timezone} required onChange={(event) => setTimezone(event.target.value)} className={inputClassName} />
          </label>
        </div>

        <div className="pt-2">
          <button type="submit" disabled={isSubmitting} className="flex items-center justify-center gap-2 rounded-xl bg-emerald-600 px-6 py-3 text-sm font-bold text-white shadow-md shadow-emerald-600/20 transition-all hover:bg-emerald-700 focus:ring-2 focus:ring-emerald-600 focus:ring-offset-2 disabled:opacity-50">
            {isSubmitting ? (
               <><div className="h-4 w-4 animate-spin rounded-full border-2 border-white/40 border-t-white" /> {t('wellness.dashboard.status.savingPlan', { defaultValue: 'Đang lưu...' })}</>
            ) : (
               <><span className="material-symbols-outlined text-[18px]">save</span> {t('wellness.dashboard.actions.savePlan', { defaultValue: 'Lưu cấu hình' })}</>
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default PlannerPlanSetupCard;
