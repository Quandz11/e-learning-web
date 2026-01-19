import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../components/admin/AdminLayout';
import { userApi, type UserDto, type UserRole, type UserStatus, type CreateUserRequest, type UpdateUserRequest } from '../../services/userApi';
import { format } from 'date-fns';

const roles: UserRole[] = ['ADMIN', 'CARE', 'CABIN_OWNER', 'STUDENT', 'LECTURER'];
const statuses: UserStatus[] = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];

const emptyCreate = (email?: string): CreateUserRequest => ({
  email: email || '',
  password: '',
  fullName: '',
  phone: '',
  role: 'STUDENT',
  status: 'ACTIVE',
  avatarUrl: '',
});

const UsersPage: React.FC = () => {
  const { t } = useTranslation();
  const [data, setData] = useState<UserDto[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [showReset, setShowReset] = useState(false);
  const [saving, setSaving] = useState(false);
  const [resetting, setResetting] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<CreateUserRequest>(emptyCreate());
  const [resetPassword, setResetPassword] = useState('');
  const [showCreatePassword, setShowCreatePassword] = useState(false);
  const [showResetPassword, setShowResetPassword] = useState(false);

  const totalPages = useMemo(() => Math.max(1, Math.ceil(total / pageSize)), [total, pageSize]);

  const roleLabel = (value: UserRole) => t(`admin.users.roles.${value}`);
  const statusLabel = (value: UserStatus) => t(`admin.users.statuses.${value}`);

  useEffect(() => {
    void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, pageSize, roleFilter, statusFilter]);

  const load = async () => {
    try {
      setLoading(true);
      const res = await userApi.getPaged({ search, role: roleFilter, status: statusFilter, page, pageSize });
      setData(res.items);
      setTotal(res.total);
    } catch (err: any) {
      setError(err.message || t('admin.users.errors.loadFailed'));
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    await load();
  };

  const openCreate = () => {
    setEditingId(null);
    setForm(emptyCreate());
    setShowForm(true);
  };

  const openEdit = (u: UserDto) => {
    setEditingId(u.id);
    const update: UpdateUserRequest = {
      fullName: u.fullName,
      phone: u.phone,
      role: u.role,
      status: u.status,
      avatarUrl: u.avatarUrl,
    };
    setForm({ ...emptyCreate(u.email), ...update, password: '' });
    setShowForm(true);
  };

  const closeForm = () => {
    setShowForm(false);
    setError(null);
    setResetPassword('');
  };

  const save = async () => {
    if (!form.email.trim()) {
      setError(t('admin.users.errors.emailRequired'));
      return;
    }
    if (!editingId && !form.password.trim()) {
      setError(t('admin.users.errors.passwordRequired'));
      return;
    }
    try {
      setSaving(true);
      setError(null);
      if (editingId) {
        const payload: UpdateUserRequest = {
          fullName: form.fullName,
          phone: form.phone,
          role: form.role,
          status: form.status,
          avatarUrl: form.avatarUrl,
        };
        await userApi.update(editingId, payload);
      } else {
        await userApi.create(form);
      }
      await load();
      setShowForm(false);
    } catch (err: any) {
      setError(err.message || t('admin.users.errors.saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  const confirmDelete = async (id: string) => {
    if (!confirm(t('admin.users.deleteConfirm'))) return;
    try {
      await userApi.delete(id);
      await load();
    } catch (err: any) {
      setError(err.message || t('admin.users.errors.deleteFailed'));
    }
  };

  const openResetPassword = (id: string) => {
    setEditingId(id);
    setResetPassword('');
    setShowReset(true);
  };

  const resetPasswordSubmit = async () => {
    if (!resetPassword.trim()) {
      setError(t('admin.users.errors.passwordRequired'));
      return;
    }
    try {
      setResetting(true);
      setError(null);
      await userApi.resetPassword(editingId!, { newPassword: resetPassword });
      setShowReset(false);
    } catch (err: any) {
      setError(err.message || t('admin.users.errors.resetFailed'));
    } finally {
      setResetting(false);
    }
  };

  return (
    <AdminLayout>
      <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{t('admin.users.title')}</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.users.subtitle')}</p>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          {t('admin.users.new')}
        </button>
      </div>

      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
          {error}
        </div>
      )}

      <form onSubmit={handleSearch} className="mb-4 flex flex-wrap items-center gap-3">
        <input
          className="w-full max-w-sm rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
          placeholder={t('admin.users.searchPlaceholder')}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select
          className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
        >
          <option value="">{t('admin.users.filters.roleAll')}</option>
          {roles.map((r) => (
            <option key={r} value={r}>{roleLabel(r)}</option>
          ))}
        </select>
        <select
          className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="">{t('admin.users.filters.statusAll')}</option>
          {statuses.map((s) => (
            <option key={s} value={s}>{statusLabel(s)}</option>
          ))}
        </select>
        <button
          type="submit"
          className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
        >
          <span className="material-symbols-outlined text-[18px]">search</span>
          {t('admin.users.buttons.search')}
        </button>
      </form>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
        <div className="overflow-x-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="bg-slate-50 text-slate-600 dark:bg-slate-800 dark:text-slate-300">
              <tr>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.email')}</th>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.name')}</th>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.role')}</th>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.status')}</th>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.created')}</th>
                <th className="px-4 py-3 font-semibold text-right">{t('admin.users.table.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td className="px-4 py-4" colSpan={6}>{t('admin.users.table.loading')}</td></tr>
              ) : data.length === 0 ? (
                <tr><td className="px-4 py-4 text-slate-500" colSpan={6}>{t('admin.users.table.noData')}</td></tr>
              ) : (
                data.map((u) => (
                  <tr key={u.id} className="border-t border-slate-100 dark:border-slate-800">
                    <td className="px-4 py-3">
                      <div className="font-semibold text-slate-900 dark:text-white">{u.email}</div>
                      <div className="text-xs text-slate-500 dark:text-slate-400">{u.phone}</div>
                    </td>
                    <td className="px-4 py-3">{u.fullName || '-'}</td>
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">{roleLabel(u.role)}</span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold ${u.status === 'ACTIVE' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'}`}>
                        {statusLabel(u.status)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-500 dark:text-slate-400">{format(new Date(u.createdAt), 'yyyy-MM-dd')}</td>
                    <td className="px-4 py-3 text-right space-x-2">
                      <button
                        className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        onClick={() => openEdit(u)}
                      >
                        {t('admin.users.buttons.edit')}
                      </button>
                      <button
                        className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        onClick={() => openResetPassword(u.id)}
                      >
                        {t('admin.users.buttons.reset')}
                      </button>
                      <button
                        className="rounded-lg border border-red-200 px-3 py-1.5 text-sm text-red-600 transition hover:bg-red-50 dark:border-red-700 dark:text-red-300 dark:hover:bg-red-900/20"
                        onClick={() => confirmDelete(u.id)}
                      >
                        {t('admin.users.buttons.delete')}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-slate-200 bg-slate-50 px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="text-slate-600 dark:text-slate-300">
            {t('admin.users.pagination.summary', { from: (page - 1) * pageSize + 1, to: Math.min(total, page * pageSize), total })}
          </div>
          <div className="flex items-center gap-2">
            <button
              className="rounded-md border border-slate-200 px-3 py-1 text-sm text-slate-700 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200"
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
            >
              {t('admin.users.pagination.prev')}
            </button>
            <span className="text-slate-700 dark:text-slate-200">{page} / {totalPages}</span>
            <button
              className="rounded-md border border-slate-200 px-3 py-1 text-sm text-slate-700 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200"
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages}
            >
              {t('admin.users.pagination.next')}
            </button>
            <select
              className="rounded-md border border-slate-200 bg-white px-2 py-1 text-sm dark:border-slate-700 dark:bg-slate-900"
              value={pageSize}
              onChange={(e) => { setPageSize(Number(e.target.value)); setPage(1); }}
            >
              {[10, 20, 50].map((s) => <option key={s} value={s}>{s}/page</option>)}
            </select>
          </div>
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 z-40 flex items-start justify-center overflow-y-auto bg-black/50 p-4">
          <div className="w-full max-w-3xl rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700">
              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">{editingId ? t('admin.users.form.editTitle') : t('admin.users.form.newTitle')}</h3>
                <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.users.subtitle')}</p>
              </div>
              <button onClick={closeForm} className="rounded-full p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            <div className="max-h-[70vh] overflow-y-auto px-6 py-5 space-y-4">
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.email')}</label>
                  <input
                    className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                    value={form.email}
                    onChange={(e) => setForm({ ...form, email: e.target.value })}
                    disabled={!!editingId}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.fullName')}</label>
                  <input
                    className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                    value={form.fullName || ''}
                    onChange={(e) => setForm({ ...form, fullName: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.phone')}</label>
                  <input
                    className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                    value={form.phone || ''}
                    onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.avatar')}</label>
                  <input
                    className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                    value={form.avatarUrl || ''}
                    onChange={(e) => setForm({ ...form, avatarUrl: e.target.value })}
                  />
                </div>
                {!editingId && (
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.password')}</label>
                    <input
                      className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                      type={showCreatePassword ? 'text' : 'password'}
                      value={form.password}
                      onChange={(e) => setForm({ ...form, password: e.target.value })}
                    />
                    <button
                      type="button"
                      className="text-xs font-medium text-dashboard-primary hover:text-dashboard-primary-dark"
                      onClick={() => setShowCreatePassword((v) => !v)}
                    >
                      {showCreatePassword ? t('admin.users.passwordToggle.hide') : t('admin.users.passwordToggle.show')}
                    </button>
                  </div>
                )}
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.role')}</label>
                  <select
                    className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
                    value={form.role}
                    onChange={(e) => setForm({ ...form, role: e.target.value as UserRole })}
                  >
                    {roles.map((r) => <option key={r} value={r}>{roleLabel(r)}</option>)}
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.status')}</label>
                  <select
                    className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
                    value={form.status}
                    onChange={(e) => setForm({ ...form, status: e.target.value as UserStatus })}
                  >
                    {statuses.map((s) => <option key={s} value={s}>{statusLabel(s)}</option>)}
                  </select>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 border-t border-slate-200 px-6 py-4 dark:border-slate-700">
              <button
                onClick={closeForm}
                className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
              >
                {t('admin.users.form.cancel')}
              </button>
              <button
                onClick={save}
                disabled={saving}
                className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
              >
                {saving ? t('common.saving', { defaultValue: 'Saving...' }) : t('admin.users.form.save')}
              </button>
            </div>
          </div>
        </div>
      )}

      {showReset && (
        <div className="fixed inset-0 z-40 flex items-start justify-center overflow-y-auto bg-black/50 p-4">
          <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700">
              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">{t('admin.users.reset.title')}</h3>
                <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.users.reset.subtitle')}</p>
              </div>
              <button onClick={() => setShowReset(false)} className="rounded-full p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            <div className="px-6 py-5 space-y-3">
              <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.reset.password')}</label>
              <input
                className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                type={showResetPassword ? 'text' : 'password'}
                value={resetPassword}
                onChange={(e) => setResetPassword(e.target.value)}
              />
              <button
                type="button"
                className="text-xs font-medium text-dashboard-primary hover:text-dashboard-primary-dark"
                onClick={() => setShowResetPassword((v) => !v)}
              >
                {showResetPassword ? t('admin.users.passwordToggle.hide') : t('admin.users.passwordToggle.show')}
              </button>
            </div>
            <div className="flex items-center justify-end gap-3 border-t border-slate-200 px-6 py-4 dark:border-slate-700">
              <button
                onClick={() => setShowReset(false)}
                className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
              >
                {t('admin.users.form.cancel')}
              </button>
              <button
                onClick={resetPasswordSubmit}
                disabled={resetting}
                className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
              >
                {resetting ? t('common.saving', { defaultValue: 'Saving...' }) : t('admin.users.reset.submit')}
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
};

export default UsersPage;
