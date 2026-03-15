import React, { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { userApi, type UserDto, type UserStatus } from '../../../services/userApi';
import { referralApi, type ReferralItemDto } from '../../../services/referralApi';
import { toast } from 'react-hot-toast';

const AdminAgentsPage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const locale = i18n.resolvedLanguage?.startsWith('vi') ? 'vi-VN' : 'en-US';

  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | UserStatus>('all');
  const [agents, setAgents] = useState<UserDto[]>([]);
  const [cabins, setCabins] = useState<ReferralItemDto[]>([]);
  const [totalPending, setTotalPending] = useState(0);

  const formatCurrency = (value: number) => `${value.toLocaleString(locale)} ${t('payments.common.currency')}`;

  const load = async () => {
    try {
      setLoading(true);

      const [agentResult, cabinResult, commissionSummary] = await Promise.all([
        userApi.getPaged({ role: 'CABIN_OWNER', page: 1, pageSize: 300 }),
        referralApi.getPaged({ page: 1, pageSize: 300 }),
        referralApi.getCommissionSummary(),
      ]);

      setAgents(agentResult.items);
      setCabins(cabinResult.items);
      setTotalPending(commissionSummary.totalPending);
    } catch (error: any) {
      toast.error(error.message || t('adminAgents.toasts.loadFailed'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const cabinStatsByOwner = useMemo(() => {
    const map = new Map<string, { total: number; active: number; wallet: number }>();

    for (const cabin of cabins) {
      const current = map.get(cabin.ownerUserId) ?? { total: 0, active: 0, wallet: 0 };
      current.total += 1;
      if (cabin.isActive) {
        current.active += 1;
      }
      current.wallet += cabin.walletBalance;
      map.set(cabin.ownerUserId, current);
    }

    return map;
  }, [cabins]);

  const filteredAgents = useMemo(() => {
    const keyword = search.trim().toUpperCase();

    return agents.filter((agent) => {
      if (statusFilter !== 'all' && agent.status !== statusFilter) {
        return false;
      }

      if (!keyword) {
        return true;
      }

      const fullName = (agent.fullName ?? '').toUpperCase();
      const email = (agent.email ?? '').toUpperCase();
      const phone = (agent.phone ?? '').toUpperCase();

      return fullName.includes(keyword) || email.includes(keyword) || phone.includes(keyword);
    });
  }, [agents, search, statusFilter]);

  const activeAgents = useMemo(() => agents.filter((agent) => agent.status === 'ACTIVE').length, [agents]);
  const totalActiveCabins = useMemo(() => cabins.filter((cabin) => cabin.isActive).length, [cabins]);

  const statusBadgeClass = (status: UserStatus) => {
    if (status === 'ACTIVE') {
      return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300';
    }

    if (status === 'SUSPENDED') {
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300';
    }

    return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300';
  };

  const statusLabel = (status: UserStatus) => t(`admin.users.statuses.${status}`, { defaultValue: status });

  return (
    <AdminLayout>
      <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{t('adminAgents.title')}</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{t('adminAgents.subtitle')}</p>
        </div>

        <div className="flex w-full sm:w-auto flex-wrap gap-2">
          <Link
            to="/admin/referrals"
            className="inline-flex h-10 items-center rounded-lg border border-slate-300 px-3 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
          >
            {t('adminAgents.actions.manageReferrals')}
          </Link>
          <Link
            to="/admin/referrals#commissions"
            className="inline-flex h-10 items-center rounded-lg bg-emerald-600 px-3 text-sm font-semibold text-white hover:bg-emerald-700"
          >
            {t('adminAgents.actions.managePayouts')}
          </Link>
        </div>
      </div>

      <div className="mb-5 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 dark:border-slate-700 dark:bg-dashboard-surface-dark">
          <p className="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400">
            {t('adminAgents.stats.totalAgents')}
          </p>
          <p className="mt-2 text-lg font-bold text-slate-900 dark:text-white">{agents.length}</p>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 dark:border-slate-700 dark:bg-dashboard-surface-dark">
          <p className="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400">
            {t('adminAgents.stats.activeAgents')}
          </p>
          <p className="mt-2 text-lg font-bold text-slate-900 dark:text-white">{activeAgents}</p>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 dark:border-slate-700 dark:bg-dashboard-surface-dark">
          <p className="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400">
            {t('adminAgents.stats.activeCabins')}
          </p>
          <p className="mt-2 text-lg font-bold text-slate-900 dark:text-white">{totalActiveCabins}</p>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 dark:border-slate-700 dark:bg-dashboard-surface-dark">
          <p className="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400">
            {t('adminAgents.stats.pendingPayout')}
          </p>
          <p className="mt-2 text-lg font-bold text-slate-900 dark:text-white">{formatCurrency(totalPending)}</p>
        </div>
      </div>

      <div className="mb-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <div className="sm:col-span-2">
          <input
            type="text"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder={t('adminAgents.searchPlaceholder')}
            className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
          />
        </div>

        <select
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value as 'all' | UserStatus)}
          className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
        >
          <option value="all">{t('adminAgents.filters.allStatuses')}</option>
          <option value="ACTIVE">{statusLabel('ACTIVE')}</option>
          <option value="INACTIVE">{statusLabel('INACTIVE')}</option>
          <option value="SUSPENDED">{statusLabel('SUSPENDED')}</option>
        </select>
      </div>

      <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark overflow-hidden">
        <div className="md:hidden divide-y divide-slate-200 dark:divide-slate-700">
          {loading ? (
            <div className="px-4 py-8 text-sm text-slate-500 dark:text-slate-400">{t('adminAgents.table.loading')}</div>
          ) : filteredAgents.length === 0 ? (
            <div className="px-4 py-8 text-sm text-slate-500 dark:text-slate-400">{t('adminAgents.table.empty')}</div>
          ) : (
            filteredAgents.map((agent) => {
              const stats = cabinStatsByOwner.get(agent.id) ?? { total: 0, active: 0, wallet: 0 };

              return (
                <div key={agent.id} className="space-y-3 p-4">
                  <div>
                    <p className="font-medium text-slate-900 dark:text-white">{agent.fullName || t('adminReferrals.table.noName')}</p>
                    <p className="text-xs text-slate-500 dark:text-slate-400 break-all">{agent.email}</p>
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${statusBadgeClass(agent.status)}`}>
                      {statusLabel(agent.status)}
                    </span>
                    <span className="text-slate-600 dark:text-slate-300">
                      {t('adminAgents.table.cabinsSummary', {
                        total: stats.total,
                        active: stats.active,
                      })}
                    </span>
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-500 dark:text-slate-400">{t('adminAgents.table.pendingWallet')}</span>
                    <span className="font-semibold text-slate-900 dark:text-white">{formatCurrency(stats.wallet)}</span>
                  </div>

                  <div className="flex items-center justify-end gap-2">
                    <Link
                      to={`/admin/users/${agent.id}`}
                      className="h-9 rounded-md border border-slate-300 px-3 text-sm text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                      {t('adminAgents.actions.viewUser')}
                    </Link>
                  </div>
                </div>
              );
            })
          )}
        </div>

        <div className="hidden md:block overflow-x-auto">
          <table className="min-w-[980px] w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800/50 dark:text-slate-400">
              <tr>
                <th className="px-6 py-4 font-semibold">{t('adminAgents.table.agent')}</th>
                <th className="px-6 py-4 font-semibold">{t('adminAgents.table.status')}</th>
                <th className="px-6 py-4 font-semibold">{t('adminAgents.table.totalCabins')}</th>
                <th className="px-6 py-4 font-semibold">{t('adminAgents.table.activeCabins')}</th>
                <th className="px-6 py-4 font-semibold">{t('adminAgents.table.pendingWallet')}</th>
                <th className="px-6 py-4 text-right font-semibold">{t('adminAgents.table.actions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-10 text-center text-slate-500 dark:text-slate-400">
                    {t('adminAgents.table.loading')}
                  </td>
                </tr>
              ) : filteredAgents.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-10 text-center text-slate-500 dark:text-slate-400">
                    {t('adminAgents.table.empty')}
                  </td>
                </tr>
              ) : (
                filteredAgents.map((agent) => {
                  const stats = cabinStatsByOwner.get(agent.id) ?? { total: 0, active: 0, wallet: 0 };

                  return (
                    <tr key={agent.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/40">
                      <td className="px-6 py-4">
                        <p className="font-medium text-slate-900 dark:text-white">{agent.fullName || t('adminReferrals.table.noName')}</p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">{agent.email}</p>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${statusBadgeClass(agent.status)}`}>
                          {statusLabel(agent.status)}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-slate-700 dark:text-slate-200">{stats.total}</td>
                      <td className="px-6 py-4 text-slate-700 dark:text-slate-200">{stats.active}</td>
                      <td className="px-6 py-4 font-semibold text-slate-900 dark:text-white">{formatCurrency(stats.wallet)}</td>
                      <td className="px-6 py-4 text-right">
                        <Link
                          to={`/admin/users/${agent.id}`}
                          className="inline-flex h-9 items-center rounded-md border border-slate-300 px-3 text-sm text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        >
                          {t('adminAgents.actions.viewUser')}
                        </Link>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </AdminLayout>
  );
};

export default AdminAgentsPage;
