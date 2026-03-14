import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { referralApi, type ReferralItemDto } from '../../../services/referralApi';
import { userApi, type UserDto } from '../../../services/userApi';
import { toast } from 'react-hot-toast';

interface ReferralFormState {
  name: string;
  ownerUserId: string;
  referralCode: string;
  commissionRate: string;
  isActive: boolean;
}

const initialFormState: ReferralFormState = {
  name: '',
  ownerUserId: '',
  referralCode: '',
  commissionRate: '10',
  isActive: true,
};

const AdminReferralsPage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const locale = i18n.resolvedLanguage?.startsWith('vi') ? 'vi-VN' : 'en-US';

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [referrals, setReferrals] = useState<ReferralItemDto[]>([]);
  const [owners, setOwners] = useState<UserDto[]>([]);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<ReferralItemDto | null>(null);
  const [form, setForm] = useState<ReferralFormState>(initialFormState);

  const totalActive = useMemo(() => referrals.filter((item) => item.isActive).length, [referrals]);
  const formatCurrency = (value: number) => `${value.toLocaleString(locale)} ${t('payments.common.currency')}`;

  const fetchReferrals = async () => {
    try {
      setLoading(true);
      const data = await referralApi.getPaged({
        search: search.trim() || undefined,
        isActive: statusFilter === 'all' ? undefined : statusFilter === 'active',
        page: 1,
        pageSize: 100,
      });
      setReferrals(data.items);
    } catch (error: any) {
      toast.error(error.message || t('adminReferrals.toasts.loadReferralsFailed'));
    } finally {
      setLoading(false);
    }
  };

  const fetchOwners = async () => {
    try {
      const data = await userApi.getPaged({ role: 'CABIN_OWNER', page: 1, pageSize: 200 });
      setOwners(data.items);
    } catch (error: any) {
      toast.error(error.message || t('adminReferrals.toasts.loadOwnersFailed'));
    }
  };

  useEffect(() => {
    void fetchReferrals();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, statusFilter]);

  useEffect(() => {
    void fetchOwners();
  }, []);

  const openCreate = () => {
    setEditing(null);
    setForm(initialFormState);
    setDialogOpen(true);
  };

  const openEdit = (item: ReferralItemDto) => {
    setEditing(item);
    setForm({
      name: item.name,
      ownerUserId: item.ownerUserId,
      referralCode: item.referralCode,
      commissionRate: String(item.commissionRate),
      isActive: item.isActive,
    });
    setDialogOpen(true);
  };

  const closeDialog = () => {
    if (!submitting) {
      setDialogOpen(false);
      setEditing(null);
      setForm(initialFormState);
    }
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!form.name.trim() || !form.ownerUserId || !form.referralCode.trim()) {
      toast.error(t('adminReferrals.validation.required'));
      return;
    }

    const commissionRate = Number(form.commissionRate);
    if (Number.isNaN(commissionRate)) {
      toast.error(t('adminReferrals.validation.invalidRate'));
      return;
    }

    try {
      setSubmitting(true);

      if (editing) {
        await referralApi.update(editing.id, {
          name: form.name.trim(),
          ownerUserId: form.ownerUserId,
          referralCode: form.referralCode.trim().toUpperCase(),
          commissionRate,
          isActive: form.isActive,
        });
        toast.success(t('adminReferrals.toasts.updateSuccess'));
      } else {
        await referralApi.create({
          name: form.name.trim(),
          ownerUserId: form.ownerUserId,
          referralCode: form.referralCode.trim().toUpperCase(),
          commissionRate,
          isActive: form.isActive,
        });
        toast.success(t('adminReferrals.toasts.createSuccess'));
      }

      closeDialog();
      await fetchReferrals();
    } catch (error: any) {
      toast.error(error.message || t('adminReferrals.toasts.saveFailed'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeactivate = async (item: ReferralItemDto) => {
    if (!window.confirm(t('adminReferrals.confirmDeactivate', { code: item.referralCode }))) {
      return;
    }

    try {
      await referralApi.remove(item.id);
      toast.success(t('adminReferrals.toasts.deactivateSuccess'));
      await fetchReferrals();
    } catch (error: any) {
      toast.error(error.message || t('adminReferrals.toasts.deactivateFailed'));
    }
  };

  return (
    <AdminLayout>
      <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{t('adminReferrals.title')}</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {t('adminReferrals.subtitle', { total: referrals.length, active: totalActive })}
          </p>
        </div>

        <button
          type="button"
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white hover:bg-dashboard-primary-dark"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          {t('adminReferrals.actions.create')}
        </button>
      </div>

      <div className="mb-4 grid gap-3 md:grid-cols-3">
        <div className="md:col-span-2">
          <input
            type="text"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder={t('adminReferrals.searchPlaceholder')}
            className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
          />
        </div>

        <select
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value as 'all' | 'active' | 'inactive')}
          className="rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
        >
          <option value="all">{t('adminReferrals.filters.all')}</option>
          <option value="active">{t('adminReferrals.filters.active')}</option>
          <option value="inactive">{t('adminReferrals.filters.inactive')}</option>
        </select>
      </div>

      <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800/50 dark:text-slate-400">
              <tr>
                <th className="px-6 py-4 font-semibold">{t('adminReferrals.table.referral')}</th>
                <th className="px-6 py-4 font-semibold">{t('adminReferrals.table.cabin')}</th>
                <th className="px-6 py-4 font-semibold">{t('adminReferrals.table.owner')}</th>
                <th className="px-6 py-4 font-semibold">{t('adminReferrals.table.commission')}</th>
                <th className="px-6 py-4 font-semibold">{t('adminReferrals.table.wallet')}</th>
                <th className="px-6 py-4 font-semibold">{t('adminReferrals.table.status')}</th>
                <th className="px-6 py-4 text-right font-semibold">{t('adminReferrals.table.actions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-6 py-10 text-center text-slate-500 dark:text-slate-400">
                    {t('adminReferrals.table.loading')}
                  </td>
                </tr>
              ) : referrals.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-10 text-center text-slate-500 dark:text-slate-400">
                    {t('adminReferrals.table.empty')}
                  </td>
                </tr>
              ) : (
                referrals.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/40">
                    <td className="px-6 py-4 font-mono font-semibold text-slate-900 dark:text-white">
                      {item.referralCode || '-'}
                    </td>
                    <td className="px-6 py-4 text-slate-700 dark:text-slate-200">{item.name}</td>
                    <td className="px-6 py-4">
                      <p className="font-medium text-slate-800 dark:text-slate-100">{item.ownerName || t('adminReferrals.table.noName')}</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{item.ownerEmail}</p>
                    </td>
                    <td className="px-6 py-4 text-slate-700 dark:text-slate-200">{item.commissionRate}%</td>
                    <td className="px-6 py-4 text-slate-700 dark:text-slate-200">
                      {formatCurrency(item.walletBalance)}
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${
                          item.isActive
                            ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300'
                            : 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300'
                        }`}
                      >
                        {item.isActive ? t('adminReferrals.status.active') : t('adminReferrals.status.inactive')}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex justify-end gap-2">
                        <button
                          type="button"
                          onClick={() => openEdit(item)}
                          className="rounded-md p-2 text-slate-500 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800"
                          title={t('common.edit')}
                        >
                          <span className="material-symbols-outlined text-[18px]">edit</span>
                        </button>
                        {item.isActive && (
                          <button
                            type="button"
                            onClick={() => void handleDeactivate(item)}
                            className="rounded-md p-2 text-slate-500 hover:bg-red-50 hover:text-red-600 dark:text-slate-400 dark:hover:bg-red-900/20"
                            title={t('adminReferrals.actions.deactivate')}
                          >
                            <span className="material-symbols-outlined text-[18px]">block</span>
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {dialogOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-xl rounded-xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 px-5 py-4">
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
                {editing ? t('adminReferrals.dialog.editTitle') : t('adminReferrals.dialog.createTitle')}
              </h2>
              <button
                type="button"
                onClick={closeDialog}
                className="rounded-md p-1 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 px-5 py-5">
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="sm:col-span-2">
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">{t('adminReferrals.dialog.fields.cabinName')}</label>
                  <input
                    type="text"
                    value={form.name}
                    onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                    required
                  />
                </div>

                <div className="sm:col-span-2">
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">{t('adminReferrals.dialog.fields.owner')}</label>
                  <select
                    value={form.ownerUserId}
                    onChange={(event) => setForm((prev) => ({ ...prev, ownerUserId: event.target.value }))}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                    required
                  >
                    <option value="">{t('adminReferrals.dialog.fields.selectOwner')}</option>
                    {owners.map((owner) => (
                      <option key={owner.id} value={owner.id}>
                        {owner.fullName || owner.email} ({owner.email})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">{t('adminReferrals.dialog.fields.referralCode')}</label>
                  <input
                    type="text"
                    value={form.referralCode}
                    onChange={(event) =>
                      setForm((prev) => ({
                        ...prev,
                        referralCode: event.target.value.toUpperCase(),
                      }))
                    }
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                    required
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">{t('adminReferrals.dialog.fields.commissionRate')}</label>
                  <input
                    type="number"
                    min={0}
                    max={100}
                    step="0.01"
                    value={form.commissionRate}
                    onChange={(event) => setForm((prev) => ({ ...prev, commissionRate: event.target.value }))}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                    required
                  />
                </div>

                <label className="sm:col-span-2 inline-flex items-center gap-2 text-sm text-slate-700 dark:text-slate-300">
                  <input
                    type="checkbox"
                    checked={form.isActive}
                    onChange={(event) => setForm((prev) => ({ ...prev, isActive: event.target.checked }))}
                    className="rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                  />
                  {t('adminReferrals.dialog.fields.isActive')}
                </label>
              </div>

              <div className="flex justify-end gap-3 border-t border-slate-200 dark:border-slate-700 pt-4">
                <button
                  type="button"
                  onClick={closeDialog}
                  className="rounded-lg border border-slate-300 dark:border-slate-700 px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-200"
                  disabled={submitting}
                >
                  {t('adminReferrals.actions.cancel')}
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white hover:bg-dashboard-primary-dark disabled:opacity-70"
                  disabled={submitting}
                >
                  {submitting ? t('adminReferrals.actions.saving') : editing ? t('adminReferrals.actions.update') : t('adminReferrals.actions.create')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AdminLayout>
  );
};

export default AdminReferralsPage;
