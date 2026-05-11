import React, { useEffect, useMemo, useState } from 'react';
import { toast } from 'react-hot-toast';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import {
  wellnessApi,
  type WellnessAdminSettings,
  type WellnessPackageAdmin,
  type WellnessPackageUpsertPayload,
} from '../../../services/wellnessApi';

const FIXED_WELLNESS_CHECKOUT_PATH = '/checkout?single=1&source=wellness';
const DEFAULT_SETTINGS: WellnessAdminSettings = {
  id: '',
  packages: [],
  ctaPath: FIXED_WELLNESS_CHECKOUT_PATH,
  isPersonalizedRoadmapPaid: true,
};

const createDraftPackage = (index: number): WellnessPackageAdmin => ({
  id: `draft-${Date.now()}-${index}`,
  code: `PACKAGE_${index + 1}`,
  name: '',
  description: '',
  priceVnd: 0,
  durationDays: 30,
  isActive: true,
  isFeatured: false,
  sortOrder: index * 10,
});

const normalizeCode = (value: string) =>
  value
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9_]/g, '_')
    .slice(0, 32);

const sanitizePackage = (value: WellnessPackageAdmin): WellnessPackageUpsertPayload => ({
  code: normalizeCode(value.code),
  name: value.name.trim(),
  description: (value.description || '').trim(),
  priceVnd: Number(value.priceVnd || 0),
  durationDays: Math.max(1, Number(value.durationDays || 1)),
  isActive: Boolean(value.isActive),
  isFeatured: Boolean(value.isFeatured),
  sortOrder: Number(value.sortOrder || 0),
});

const AdminWellnessSettingsPage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const locale = i18n.resolvedLanguage?.startsWith('vi') ? 'vi-VN' : 'en-US';
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [settings, setSettings] = useState<WellnessAdminSettings>(DEFAULT_SETTINGS);

  const packageRows = settings.packages ?? [];
  const normalizedPackages = useMemo(() => packageRows.map(sanitizePackage), [packageRows]);
  const activePackages = normalizedPackages.filter((pkg) => pkg.isActive);
  const featuredPackages = normalizedPackages.filter((pkg) => pkg.isFeatured && pkg.isActive);
  const duplicateCodes = useMemo(() => {
    const map = new Map<string, number>();
    normalizedPackages.forEach((pkg) => {
      if (!pkg.code) return;
      map.set(pkg.code, (map.get(pkg.code) ?? 0) + 1);
    });

    return Array.from(map.entries())
      .filter(([, count]) => count > 1)
      .map(([code]) => code);
  }, [normalizedPackages]);

  const invalidPackages = useMemo(
    () => normalizedPackages.filter((pkg) => !pkg.code || !pkg.name || pkg.durationDays <= 0 || pkg.priceVnd < 0),
    [normalizedPackages],
  );

  const prices = normalizedPackages.map((pkg) => pkg.priceVnd);
  const minPrice = prices.length ? Math.min(...prices) : 0;
  const maxPrice = prices.length ? Math.max(...prices) : 0;

  const warnings = useMemo(() => {
    const values: string[] = [];
    if (normalizedPackages.length === 0) {
      values.push(t('wellness.admin.warnings.noPackage', { defaultValue: 'No package configured yet.' }));
    }
    if (activePackages.length === 0) {
      values.push(t('wellness.admin.warnings.noActivePackage', { defaultValue: 'No active package. Users cannot unlock wellness.' }));
    }
    if (duplicateCodes.length > 0) {
      values.push(t('wellness.admin.warnings.duplicateCode', {
        defaultValue: 'Duplicate package codes: {{codes}}',
        codes: duplicateCodes.join(', '),
      }));
    }
    if (invalidPackages.length > 0) {
      values.push(t('wellness.admin.warnings.invalidPackage', {
        defaultValue: '{{count}} package row(s) have missing code/name or invalid price/duration.',
        count: invalidPackages.length,
      }));
    }

    return values;
  }, [activePackages.length, duplicateCodes, invalidPackages.length, normalizedPackages.length, t]);

  const isConfigHealthy = warnings.length === 0;
  const configStatusLabel = isConfigHealthy
    ? t('wellness.admin.status.ready', { defaultValue: 'Ready' })
    : t('wellness.admin.status.needsConfig', { defaultValue: 'Needs config' });
  const configStatusIcon = isConfigHealthy ? 'verified' : 'warning';
  const configStatusClass = isConfigHealthy
    ? 'border-emerald-200 bg-emerald-50 text-emerald-700'
    : 'border-amber-200 bg-amber-50 text-amber-700';

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true);
        const data = await wellnessApi.getAdminSettings();
        setSettings({
          ...DEFAULT_SETTINGS,
          ...data,
          ctaPath: FIXED_WELLNESS_CHECKOUT_PATH,
          packages: (data.packages ?? []).map((pkg, index) => ({
            ...pkg,
            sortOrder: Number.isFinite(pkg.sortOrder) ? pkg.sortOrder : index * 10,
          })),
        });
      } catch (error: any) {
        toast.error(error?.message || t('wellness.admin.errors.loadFailed', { defaultValue: 'Unable to load wellness settings' }));
      } finally {
        setLoading(false);
      }
    };

    void load();
  }, [t]);

  const formatMoney = (value: number) =>
    new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: 'VND',
      maximumFractionDigits: 0,
    }).format(value || 0);

  const updatePackage = <K extends keyof WellnessPackageAdmin>(
    id: string,
    key: K,
    value: WellnessPackageAdmin[K],
  ) => {
    setSettings((prev) => ({
      ...prev,
      packages: (prev.packages ?? []).map((pkg) => (pkg.id === id ? { ...pkg, [key]: value } : pkg)),
    }));
  };

  const addPackage = () => {
    setSettings((prev) => ({
      ...prev,
      packages: [...(prev.packages ?? []), createDraftPackage(prev.packages?.length ?? 0)],
    }));
  };

  const removePackage = (id: string) => {
    setSettings((prev) => ({
      ...prev,
      packages: (prev.packages ?? []).filter((pkg) => pkg.id !== id),
    }));
  };

  const saveSettings = async (event: React.FormEvent) => {
    event.preventDefault();
    if (duplicateCodes.length > 0 || invalidPackages.length > 0) {
      toast.error(t('wellness.admin.errors.invalidPackageData', {
        defaultValue: 'Please fix duplicate package codes and invalid package rows before saving.',
      }));
      return;
    }

    try {
      setSaving(true);
      const updated = await wellnessApi.updateAdminSettings({
        ctaPath: FIXED_WELLNESS_CHECKOUT_PATH,
        packages: normalizedPackages,
        isPersonalizedRoadmapPaid: settings.isPersonalizedRoadmapPaid,
      });

      setSettings({
        ...updated,
        ctaPath: FIXED_WELLNESS_CHECKOUT_PATH,
        packages: (updated.packages ?? []).map((pkg, index) => ({
          ...pkg,
          sortOrder: Number.isFinite(pkg.sortOrder) ? pkg.sortOrder : index * 10,
        })),
      });
      toast.success(t('wellness.admin.success.saved', { defaultValue: 'Wellness settings saved' }));
    } catch (error: any) {
      toast.error(error?.message || t('wellness.admin.errors.saveFailed', { defaultValue: 'Unable to save wellness settings' }));
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <AdminLayout>
        <div className="mx-auto max-w-7xl space-y-6 p-6">
          <div className="animate-pulse rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="h-7 w-72 rounded-full bg-slate-200" />
            <div className="mt-3 h-4 w-full max-w-2xl rounded-full bg-slate-100" />
            <div className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
              {Array.from({ length: 4 }).map((_, index) => (
                <div key={index} className="h-24 rounded-2xl bg-slate-100" />
              ))}
            </div>
          </div>
          <div className="animate-pulse rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="h-7 w-64 rounded-full bg-slate-200" />
            <div className="mt-4 h-[420px] rounded-2xl bg-slate-100" />
          </div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout>
      <div className="mx-auto max-w-7xl space-y-6 p-6">
        <section className="relative overflow-hidden rounded-3xl border border-cyan-100 bg-[linear-gradient(145deg,#ecfeff_0%,#f8fafc_45%,#fff7ed_100%)] p-6 shadow-[0_20px_70px_-35px_rgba(15,118,110,0.45)]">
          <div className="pointer-events-none absolute -right-12 -top-14 h-40 w-40 rounded-full bg-cyan-200/70 blur-2xl" />
          <div className="pointer-events-none absolute -bottom-16 left-20 h-44 w-44 rounded-full bg-orange-200/60 blur-3xl" />

          <div className="relative flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div className="max-w-3xl">
              <div className="inline-flex items-center gap-2 rounded-full border border-cyan-200/80 bg-white/80 px-3 py-1 text-xs font-semibold uppercase tracking-[0.12em] text-cyan-700">
                <span className="material-symbols-outlined text-[16px]">auto_awesome</span>
                {t('wellness.admin.title', { defaultValue: 'Wellness package settings' })}
              </div>
              <p className="mt-4 text-sm leading-relaxed text-slate-700">
                {t('wellness.admin.subtitle', { defaultValue: 'Manage standalone wellness packages and pricing from admin dashboard.' })}
              </p>
              <div className="mt-4 inline-flex max-w-full items-center gap-2 rounded-xl border border-slate-200 bg-white/90 px-3 py-2 text-xs text-slate-600 shadow-sm">
                <span className="material-symbols-outlined text-[16px] text-cyan-600">route</span>
                <span className="font-semibold">{t('wellness.admin.overview.checkout', { defaultValue: 'Checkout CTA' })}:</span>
                <span className="truncate font-mono">{FIXED_WELLNESS_CHECKOUT_PATH}</span>
              </div>

              <div className="mt-4 flex items-center gap-4">
                <label className="relative inline-flex cursor-pointer items-center">
                  <input
                    type="checkbox"
                    className="peer sr-only"
                    checked={settings.isPersonalizedRoadmapPaid}
                    onChange={(e) => setSettings(prev => ({ ...prev, isPersonalizedRoadmapPaid: e.target.checked }))}
                  />
                  <div className="peer h-6 w-11 rounded-full bg-slate-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-cyan-600 peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-cyan-300 dark:border-gray-600 dark:bg-gray-700 dark:peer-focus:ring-cyan-800"></div>
                  <span className="ml-3 text-sm font-medium text-slate-700">
                    {settings.isPersonalizedRoadmapPaid 
                      ? t('wellness.admin.accessMode.paid', { defaultValue: 'Paid features (Requires package)' }) 
                      : t('wellness.admin.accessMode.free', { defaultValue: 'Free features (Everyone access)' })}
                  </span>
                </label>
              </div>
            </div>

            <div className={`inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-semibold shadow-sm ${configStatusClass}`}>
              <span className="material-symbols-outlined text-[18px]">{configStatusIcon}</span>
              {configStatusLabel}
            </div>
          </div>
        </section>

        <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <article className="rounded-2xl border border-cyan-100 bg-white p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                {t('wellness.admin.overview.totalPackages', { defaultValue: 'Total packages' })}
              </p>
              <span className="material-symbols-outlined text-[20px] text-cyan-600">deployed_code</span>
            </div>
            <p className="mt-2 text-2xl font-black text-slate-900">{normalizedPackages.length}</p>
          </article>

          <article className="rounded-2xl border border-emerald-100 bg-white p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                {t('wellness.admin.overview.activePackages', { defaultValue: 'Active packages' })}
              </p>
              <span className="material-symbols-outlined text-[20px] text-emerald-600">toggle_on</span>
            </div>
            <p className="mt-2 text-2xl font-black text-slate-900">{activePackages.length}</p>
          </article>

          <article className="rounded-2xl border border-amber-100 bg-white p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                {t('wellness.admin.overview.featuredPackages', { defaultValue: 'Featured packages' })}
              </p>
              <span className="material-symbols-outlined text-[20px] text-amber-600">stars</span>
            </div>
            <p className="mt-2 text-2xl font-black text-slate-900">{featuredPackages.length}</p>
          </article>

          <article className="rounded-2xl border border-violet-100 bg-white p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                {t('wellness.admin.overview.priceRange', { defaultValue: 'Price range' })}
              </p>
              <span className="material-symbols-outlined text-[20px] text-violet-600">payments</span>
            </div>
            <p className="mt-2 text-sm font-bold text-slate-900">{formatMoney(minPrice)} - {formatMoney(maxPrice)}</p>
          </article>
        </section>

        {warnings.length > 0 && (
          <section className="rounded-2xl border border-amber-200 bg-amber-50/80 p-4 shadow-sm">
            <div className="flex items-center gap-2 text-amber-900">
              <span className="material-symbols-outlined text-[20px]">warning</span>
              <h2 className="text-sm font-bold">
                {t('wellness.admin.warnings.title', { defaultValue: 'Configuration warnings' })}
              </h2>
            </div>
            <ul className="mt-3 grid gap-2 sm:grid-cols-2">
              {warnings.map((warning, index) => (
                <li key={`warning-${index}`} className="flex items-start gap-2 rounded-xl border border-amber-200 bg-white px-3 py-2 text-sm text-amber-800">
                  <span className="material-symbols-outlined text-[16px] leading-5">error</span>
                  <span>{warning}</span>
                </li>
              ))}
            </ul>
          </section>
        )}

        <form onSubmit={saveSettings} className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="mb-4 flex flex-col gap-3 border-b border-slate-100 pb-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 className="flex items-center gap-2 text-lg font-bold text-slate-900">
                <span className="material-symbols-outlined text-[22px] text-cyan-700">inventory_2</span>
                {t('wellness.admin.title', { defaultValue: 'Wellness package settings' })}
              </h2>
              <p className="mt-1 text-xs text-slate-500">
                {t('wellness.admin.overview.checkout', { defaultValue: 'Checkout CTA' })}: {FIXED_WELLNESS_CHECKOUT_PATH}
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={addPackage}
                className="inline-flex items-center gap-1.5 rounded-xl border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 transition-colors hover:border-cyan-500 hover:text-cyan-700"
              >
                <span className="material-symbols-outlined text-[18px]">add_circle</span>
                {t('wellness.admin.actions.addPackage', { defaultValue: 'Add package' })}
              </button>
              <button
                type="submit"
                disabled={saving}
                className="inline-flex items-center gap-1.5 rounded-xl bg-cyan-700 px-5 py-2 text-sm font-semibold text-white transition-colors hover:bg-cyan-800 disabled:opacity-60"
              >
                <span className="material-symbols-outlined text-[18px]">save</span>
                {saving
                  ? t('wellness.admin.actions.saving', { defaultValue: 'Saving...' })
                  : t('wellness.admin.actions.save', { defaultValue: 'Save settings' })}
              </button>
            </div>
          </div>

          <div className="overflow-hidden rounded-2xl border border-slate-200">
            <div className="overflow-x-auto">
              <div className="min-w-[980px]">
                <div className="grid grid-cols-[130px_minmax(0,1.2fr)_minmax(0,1.2fr)_120px_90px_90px_90px_90px] gap-2 bg-slate-50 px-3 py-2 text-[11px] font-semibold uppercase tracking-wide text-slate-500">
                  <span className="flex items-center gap-1">
                    <span className="material-symbols-outlined text-[14px]">tag</span>Code
                  </span>
                  <span className="flex items-center gap-1">
                    <span className="material-symbols-outlined text-[14px]">title</span>{t('common.name', { defaultValue: 'Name' })}
                  </span>
                  <span className="flex items-center gap-1">
                    <span className="material-symbols-outlined text-[14px]">notes</span>{t('common.description', { defaultValue: 'Description' })}
                  </span>
                  <span className="text-right">{t('common.price', { defaultValue: 'Price' })}</span>
                  <span className="text-right">{t('common.duration', { defaultValue: 'Days' })}</span>
                  <span className="text-center">{t('common.active', { defaultValue: 'Active' })}</span>
                  <span className="text-center">{t('wellness.admin.labels.featured', { defaultValue: 'Featured' })}</span>
                  <span className="text-center">{t('common.actions', { defaultValue: 'Actions' })}</span>
                </div>

                <div className="max-h-[620px] divide-y divide-slate-100 overflow-auto">
                  {settings.packages.map((pkg, index) => (
                    <div
                      key={pkg.id || `${pkg.code}-${index}`}
                      className={`grid grid-cols-[130px_minmax(0,1.2fr)_minmax(0,1.2fr)_120px_90px_90px_90px_90px] gap-2 px-3 py-3 transition-colors ${
                        pkg.isFeatured
                          ? 'bg-amber-50/50 hover:bg-amber-50'
                          : index % 2 === 0
                            ? 'bg-white hover:bg-cyan-50/50'
                            : 'bg-slate-50/60 hover:bg-cyan-50/60'
                      }`}
                    >
                      <input
                        value={pkg.code}
                        onChange={(event) => updatePackage(pkg.id, 'code', event.target.value)}
                        className="rounded-lg border border-slate-300 bg-white px-2 py-1.5 text-xs font-semibold text-slate-900 focus:border-cyan-500 focus:outline-none"
                        placeholder="PLAN_30_DAYS"
                      />
                      <input
                        value={pkg.name}
                        onChange={(event) => updatePackage(pkg.id, 'name', event.target.value)}
                        className="rounded-lg border border-slate-300 bg-white px-2 py-1.5 text-xs text-slate-900 focus:border-cyan-500 focus:outline-none"
                        placeholder={t('wellness.admin.placeholders.packageName', { defaultValue: 'Package name' })}
                      />
                      <input
                        value={pkg.description}
                        onChange={(event) => updatePackage(pkg.id, 'description', event.target.value)}
                        className="rounded-lg border border-slate-300 bg-white px-2 py-1.5 text-xs text-slate-900 focus:border-cyan-500 focus:outline-none"
                        placeholder={t('wellness.admin.placeholders.packageDescription', { defaultValue: 'What users get from this package' })}
                      />
                      <input
                        type="number"
                        min={0}
                        step={1000}
                        value={pkg.priceVnd}
                        onChange={(event) => updatePackage(pkg.id, 'priceVnd', Number(event.target.value))}
                        className="rounded-lg border border-slate-300 bg-white px-2 py-1.5 text-right text-xs text-slate-900 focus:border-cyan-500 focus:outline-none"
                      />
                      <input
                        type="number"
                        min={1}
                        max={3650}
                        value={pkg.durationDays}
                        onChange={(event) => updatePackage(pkg.id, 'durationDays', Number(event.target.value))}
                        className="rounded-lg border border-slate-300 bg-white px-2 py-1.5 text-right text-xs text-slate-900 focus:border-cyan-500 focus:outline-none"
                      />
                      <label className="grid place-items-center">
                        <input
                          type="checkbox"
                          checked={pkg.isActive}
                          onChange={(event) => updatePackage(pkg.id, 'isActive', event.target.checked)}
                          className="h-4 w-4 rounded border-slate-300 accent-cyan-700"
                        />
                      </label>
                      <label className="grid place-items-center">
                        <input
                          type="checkbox"
                          checked={pkg.isFeatured}
                          onChange={(event) => updatePackage(pkg.id, 'isFeatured', event.target.checked)}
                          className="h-4 w-4 rounded border-slate-300 accent-amber-500"
                        />
                      </label>
                      <div className="flex items-center justify-center">
                        <button
                          type="button"
                          onClick={() => removePackage(pkg.id)}
                          className="inline-flex items-center gap-1 rounded-lg border border-rose-200 bg-white px-2 py-1 text-[11px] font-semibold text-rose-700 transition-colors hover:bg-rose-50"
                        >
                          <span className="material-symbols-outlined text-[14px]">delete</span>
                          {t('common.delete', { defaultValue: 'Delete' })}
                        </button>
                      </div>
                    </div>
                  ))}

                  {settings.packages.length === 0 && (
                    <div className="px-4 py-12 text-center text-sm text-slate-500">
                      {t('wellness.admin.table.empty', { defaultValue: 'No package configured yet.' })}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    </AdminLayout>
  );
};

export default AdminWellnessSettingsPage;
